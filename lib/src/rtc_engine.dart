import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import 'constants.dart';
import 'events.dart';
import 'exceptions.dart';
import 'extensions.dart';
import 'internal/events.dart';
import 'logger.dart';
import 'managers/delay.dart';
import 'managers/event.dart';
import 'options.dart';
import 'proto/livekit_models.pb.dart' as lk_models;
import 'proto/livekit_rtc.pb.dart' as lk_rtc;
import 'signal_client.dart';
import 'support/disposable.dart';
import 'transport.dart';
import 'types.dart';

class RTCEngine extends Disposable with EventsEmittable<EngineEvent> {
  static const _lossyDCLabel = '_lossy';
  static const _reliableDCLabel = '_reliable';
  static const _maxReconnectAttempts = 5;

  final SignalClient signalClient;
  // config for RTCPeerConnection
  final RTCConfiguration? rtcConfig;

  @internal
  PCTransport? publisher;

  @internal
  PCTransport? subscriber;

  @internal
  PCTransport? get primary => _subscriberPrimary ? subscriber : publisher;

  // data channels for packets
  rtc.RTCDataChannel? _reliableDC;
  rtc.RTCDataChannel? _lossyDC;
  bool _iceConnected = false;

  ConnectionState _connectionState = ConnectionState.disconnected;

  /// connection state of the room
  ConnectionState get connectionState => _connectionState;

  // true if publisher connection has already been established.
  // this is helpful to know if we need to restart ICE on the publisher connection
  bool _hasPublished = false;

  // remember url and token for reconnect
  String? url;
  String? token;

  bool _subscriberPrimary = false;
  // server-provided ice servers
  List<lk_rtc.ICEServer> _providedIceServers = [];

  // internal
  int _reconnectAttempts = 0;

  late final _signalListener = signalClient.createListener(synchronized: true);

  final delays = CancelableDelayManager();

  RTCEngine(
    this.rtcConfig, {
    SignalClient? signalClient,
  }) : signalClient = signalClient ?? SignalClient() {
    if (kDebugMode) {
      // log all EngineEvents
      events.listen((event) => logger.fine('[EngineEvent] $objectId ${event.runtimeType}'));
    }

    _setUpListeners();

    onDispose(() async {
      await events.dispose();
      await delays.dispose();
      await close();
      await _signalListener.dispose();
    });
  }

  Future<lk_rtc.JoinResponse> join(
    String url,
    String token, {
    ConnectOptions? options,
  }) async {
    this.url = url;
    this.token = token;

    // connect to rtc server
    await signalClient.connect(url, token, options: options);

    // wait for join response
    final event = await _signalListener.waitFor<SignalConnectedEvent>(
      duration: Timeouts.connection,
      onTimeout: () => throw ConnectException(),
    );

    return event.response;
  }

  // there is no side-effect calling this method multiple times
  Future<void> close() async {
    logger.fine('[$objectId] close()');
    if (_connectionState == ConnectionState.disconnected) {
      logger.warning('[$objectId]: close() already disconnected');
    }
    // _statsTimer.cancel();
    // cancel all ongoing delays
    await delays.cancelAll();

    // PCTransport is responsible for disposing RTCPeerConnection
    await publisher?.dispose();
    publisher = null;

    await subscriber?.dispose();
    subscriber = null;

    await signalClient.close();

    _connectionState = ConnectionState.disconnected;
    // notifyListeners();
  }

  Future<lk_models.TrackInfo> addTrack({
    required String cid,
    required String name,
    required lk_models.TrackType kind,
    TrackDimension? dimension,
  }) async {
    // send request to add track
    signalClient.sendAddTrack(cid: cid, name: name, type: kind, dimension: dimension);

    // wait for response, or timeout
    final event = await _signalListener.waitFor<SignalLocalTrackPublishedEvent>(
      filter: (event) => event.cid == cid,
      duration: Timeouts.publish,
      onTimeout: () => throw TrackPublishException(),
    );

    return event.track;
  }

  Future<void> negotiate({bool? iceRestart}) async {
    if (publisher == null) {
      return;
    }

    _hasPublished = true;
    publisher!.negotiate();
  }

  /* @internal */
  Future<void> sendDataPacket(
    lk_models.DataPacket packet,
  ) async {
    // make sure we do have a data connection
    await _ensurePublisherConnected();

    final dcMessage = rtc.RTCDataChannelMessage.fromBinary(packet.writeToBuffer());

    if (packet.kind == lk_models.DataPacket_Kind.LOSSY && _lossyDC != null) {
      await _lossyDC?.send(dcMessage);
    } else if (packet.kind == lk_models.DataPacket_Kind.RELIABLE && _reliableDC != null) {
      await _reliableDC?.send(dcMessage);
    }
  }

  Future<void> _ensurePublisherConnected() async {
    logger.fine('ensurePublisherConnected()');
    if (!_subscriberPrimary) {
      return;
    }

    if (publisher?.pc.iceConnectionState?.isConnected() == true) {
      logger.warning('[$objectId] publisher is already connected');
      return;
    }

    // start negotiation
    await negotiate();

    logger.fine('[PUBLISHER] waiting for to ice-connect '
        '(current: ${publisher?.pc.iceConnectionState})');

    await events.waitFor<EnginePublisherIceStateUpdatedEvent>(
      filter: (event) => event.iceState.isConnected(),
      duration: Timeouts.iceConnection,
    );

    logger.fine('[PUBLISHER] connected');
  }

  Future<void> reconnect() async {
    if (_connectionState == ConnectionState.disconnected) {
      logger.fine('$objectId reconnect() already closed');
      return;
    }

    final url = this.url;
    final token = this.token;

    if (url == null || token == null) {
      throw ConnectException('could not reconnect without url and token');
    }

    if (_reconnectAttempts == 0) {
      events.emit(const EngineReconnectingEvent());
    }
    _reconnectAttempts++;

    try {
      // isReconnecting = true;
      _connectionState = ConnectionState.reconnecting;
      await signalClient.reconnect(url, token);

      if (publisher == null || subscriber == null) {
        throw UnexpectedStateException('publisher or subscribers is null');
      }

      subscriber!.restartingIce = true;

      // await negotiate(iceRestart: true);
      if (_hasPublished) {
        logger.fine('reconnect: publisher.createAndSendOffer');
        await publisher!.createAndSendOffer(const RTCOfferOptions(iceRestart: true));
      }

      if (!(primary?.pc.iceConnectionState?.isConnected() ?? false)) {
        logger.fine('reconnect: waiting for primary to ice-connect...');

        await events.waitFor<EngineIceStateUpdatedEvent>(
          filter: (event) => event.isPrimary && event.iceState.isConnected(),
          duration: Timeouts.iceRestart,
        );
      }

      logger.fine('reconnect: success');
      events.emit(const EngineReconnectedEvent());
      _reconnectAttempts = 0;

      // don't catch and pass up any exception
    } finally {
      // always set reconnecting to false
      // isReconnecting = false;
      _connectionState = ConnectionState.disconnected;
    }
  }

  Future<void> _configurePeerConnections() async {
    if (publisher != null || subscriber != null) {
      logger.warning('Already configured');
      return;
    }

    RTCConfiguration? config;
    // use server-provided iceServers if not provided by user
    if ((rtcConfig?.iceServers?.isEmpty ?? true) && _providedIceServers.isNotEmpty) {
      final iceServers = _providedIceServers.map((e) => e.toSDKType()).toList();
      config = (rtcConfig ?? const RTCConfiguration()).copyWith(iceServers: iceServers);
    }

    publisher = await PCTransport.create(config);
    subscriber = await PCTransport.create(config);

    publisher?.pc.onIceCandidate = (rtc.RTCIceCandidate candidate) {
      logger.fine('publisher onIceCandidate');
      signalClient.sendIceCandidate(candidate, lk_rtc.SignalTarget.PUBLISHER);
    };

    subscriber?.pc.onIceCandidate = (rtc.RTCIceCandidate candidate) {
      logger.fine('subscriber onIceCandidate');
      signalClient.sendIceCandidate(candidate, lk_rtc.SignalTarget.SUBSCRIBER);
    };

    publisher?.onOffer = (offer) {
      logger.fine('publisher onOffer');
      signalClient.sendOffer(offer);
    };

    // in subscriber primary mode, server side opens sub data channels.
    if (_subscriberPrimary) {
      subscriber?.pc.onDataChannel = _onDataChannel;
    }

    subscriber?.pc.onIceConnectionState =
        (state) => events.emit(EngineSubscriberIceStateUpdatedEvent(
              state: state,
              isPrimary: _subscriberPrimary,
            ));

    publisher?.pc.onIceConnectionState = (state) => events.emit(EnginePublisherIceStateUpdatedEvent(
          state: state,
          isPrimary: !_subscriberPrimary,
        ));

    events.on<EngineIceStateUpdatedEvent>((event) {
      // only listen to primary ice events
      if (!event.isPrimary) return;

      if (event.iceState == rtc.RTCIceConnectionState.RTCIceConnectionStateConnected) {
        if (!_iceConnected) {
          _iceConnected = true;
          if (_connectionState == ConnectionState.reconnecting) {
            events.emit(const EngineReconnectedEvent());
          } else {
            events.emit(const EngineConnectedEvent());
          }
        }
      } else if (event.iceState == rtc.RTCIceConnectionState.RTCIceConnectionStateFailed) {
        // trigger reconnect sequence
        if (_iceConnected) {
          _iceConnected = false;
          _onDisconnected('peerconnection');
        }
      }
    });

    subscriber?.pc.onTrack = (rtc.RTCTrackEvent event) {
      final stream = event.streams.firstOrNull;
      if (stream == null) {
        // we need the stream to get the track's id
        logger.severe('received track without mediastream');
        return;
      }

      events.emit(EngineTrackAddedEvent(
        track: event.track,
        stream: stream,
        receiver: event.receiver,
      ));
    };

    // also handle messages over the pub channel, for backwards compatibility
    try {
      final lossyInit = rtc.RTCDataChannelInit()
        ..binaryType = 'binary'
        ..ordered = true
        ..maxRetransmits = 0;
      _lossyDC = await publisher?.pc.createDataChannel(_lossyDCLabel, lossyInit);
      _lossyDC?.onMessage = _onDCMessage;
    } catch (_) {
      logger.severe('[$objectId] createDataChannel() did throw $_');
    }

    try {
      final reliableInit = rtc.RTCDataChannelInit()
        ..binaryType = 'binary'
        ..ordered = true;
      _reliableDC = await publisher?.pc.createDataChannel(_reliableDCLabel, reliableInit);
      _reliableDC?.onMessage = _onDCMessage;
    } catch (_) {
      logger.severe('[$objectId] createDataChannel() did throw $_');
    }
  }

  void _onDataChannel(rtc.RTCDataChannel dc) {
    switch (dc.label) {
      case _reliableDCLabel:
        logger.fine('Server opened DC label: ${dc.label}');
        _reliableDC = dc;
        _reliableDC?.onMessage = _onDCMessage;
        break;
      case _lossyDCLabel:
        logger.fine('Server opened DC label: ${dc.label}');
        _lossyDC = dc;
        _lossyDC?.onMessage = _onDCMessage;
        break;
      default:
        logger.warning('Unknown DC label: ${dc.label}');
        break;
    }
  }

  void _onDCMessage(rtc.RTCDataChannelMessage message) {
    // always expect binary
    if (!message.isBinary) {
      logger.warning('Data message is not binary');
      return;
    }

    final dp = lk_models.DataPacket.fromBuffer(message.binary);
    if (dp.whichValue() == lk_models.DataPacket_Value.speaker) {
      // Speaker packet
      events.emit(EngineActiveSpeakersUpdateEvent(speakers: dp.speaker.speakers));
    } else if (dp.whichValue() == lk_models.DataPacket_Value.user) {
      // User packet
      events.emit(EngineDataPacketReceivedEvent(
        packet: dp.user,
        kind: dp.kind,
      ));
    }
  }

  Future<void> _onDisconnected(String reason) async {
    if (_connectionState == ConnectionState.disconnected) {
      logger.fine('[$objectId] Already disconnected $reason');
      return;
    }

    logger.fine('[$objectId] Disconnected $reason');

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      logger.info('[$objectId] Could not connect after ${_reconnectAttempts} attempts, giving up');
      await close();
      events.emit(const EngineDisconnectedEvent());
      return;
    }

    final delay = Duration(milliseconds: (_reconnectAttempts * _reconnectAttempts) * 300);

    // if this instance is disposed, we probably don't want to continue any more
    // so the whole block will be canceled from being executed
    await delays.waitFor(delay, ifNotCancelled: () async {
      try {
        await reconnect();
        _reconnectAttempts = 0;
      } catch (_) {
        // doesn't need to be awaited
        // ignore: unawaited_futures
        _onDisconnected(reason);
      }
    });
  }

  void _setUpListeners() => _signalListener
    ..on<SignalConnectedEvent>((event) async {
      // create peer connections
      _connectionState = ConnectionState.connected;
      _subscriberPrimary = event.response.subscriberPrimary;
      _providedIceServers = event.response.iceServers;

      logger.fine('onConnected subscriberPrimary: ${_subscriberPrimary}, '
          'serverVersion: ${event.response.serverVersion}, '
          'iceServers: ${event.response.iceServers}');

      await _configurePeerConnections();

      if (!_subscriberPrimary) {
        // for subscriberPrimary, we negotiate when necessary (lazy)
        await negotiate();
      }
    })
    ..on<SignalCloseEvent>((_) async {
      await _onDisconnected('signal');
    })
    ..on<SignalOfferEvent>((event) async {
      if (subscriber == null) {
        logger.warning('[$objectId] subscriber is null');
        return;
      }

      logger.fine('[$objectId] Received server offer(type: ${event.sd.type}, '
          '${subscriber!.pc.signalingState})');

      await subscriber!.setRemoteDescription(event.sd);

      try {
        final answer = await subscriber!.pc.createAnswer();
        logger.fine('Created answer');
        logger.finer('sdp: ${answer.sdp}');
        await subscriber!.pc.setLocalDescription(answer);
        signalClient.sendAnswer(answer);
      } catch (_) {
        logger.severe('[$objectId] Failed to createAnswer()');
      }
    })
    ..on<SignalAnswerEvent>((event) async {
      if (publisher == null) {
        return;
      }
      logger.fine('received answer (type: ${event.sd.type})');
      logger.finer('sdp: ${event.sd.sdp}');
      await publisher!.setRemoteDescription(event.sd);
    })
    ..on<SignalTrickleEvent>((event) async {
      if (publisher == null || subscriber == null) {
        logger.warning('Received ${SignalTrickleEvent} but publisher or subscriber was null.');
        return;
      }
      logger.fine('got ICE candidate from peer');
      if (event.target == lk_rtc.SignalTarget.SUBSCRIBER) {
        await subscriber!.addIceCandidate(event.candidate);
      } else if (event.target == lk_rtc.SignalTarget.PUBLISHER) {
        await publisher!.addIceCandidate(event.candidate);
      }
    })
    // relay
    ..on<SignalParticipantUpdateEvent>((event) => events.emit(event))
    // relay
    ..on<SignalSpeakersChangedEvent>((event) => events.emit(event))
    ..on<SignalLeaveEvent>((event) async {
      await close();
      events.emit(const EngineDisconnectedEvent());
    })
    ..on<SignalMuteTrackEvent>((event) => events.emit(EngineRemoteMuteChangedEvent(
          sid: event.sid,
          muted: event.muted,
        )));
}
