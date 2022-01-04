import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../constants.dart';
import '../events.dart';
import '../exceptions.dart';
import '../extensions.dart';
import '../internal/events.dart';
import '../internal/types.dart';
import '../logger.dart';
import '../managers/delay.dart';
import '../managers/event.dart';
import '../options.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../support/disposable.dart';
import '../types.dart';
import 'room.dart';
import 'signal_client.dart';
import 'transport.dart';

class Engine extends Disposable with EventsEmittable<EngineEvent> {
  static const _lossyDCLabel = '_lossy';
  static const _reliableDCLabel = '_reliable';
  static const _maxReconnectAttempts = 5;

  // Reference to the Room
  final Room room;

  final SignalClient signalClient;

  @internal
  PCTransport? publisher;

  @internal
  PCTransport? subscriber;

  @internal
  PCTransport? get primary => _subscriberPrimary ? subscriber : publisher;

  // data channels for packets
  rtc.RTCDataChannel? _reliableDCPub;
  rtc.RTCDataChannel? _lossyDCPub;
  rtc.RTCDataChannel? _reliableDCSub;
  rtc.RTCDataChannel? _lossyDCSub;

  bool _iceConnected = false;

  ConnectionState _connectionState = ConnectionState.disconnected;

  /// Connection state of the [Room].
  ConnectionState get connectionState => _connectionState;

  // true if publisher connection has already been established.
  // this is helpful to know if we need to restart ICE on the publisher connection
  bool _hasPublished = false;

  // remember url and token for reconnect
  String? url;
  String? token;

  bool _subscriberPrimary = false;

  // server-provided ice servers
  List<lk_rtc.ICEServer> _serverProvidedIceServers = [];

  // internal
  int _reconnectAttempts = 0;

  late final _signalListener = signalClient.createListener(synchronized: true);

  final delays = CancelableDelayManager();

  Engine({
    required this.room,
    SignalClient? signalClient,
  }) : signalClient = signalClient ?? SignalClient() {
    if (kDebugMode) {
      // log all EngineEvents
      events.listen((event) => logger.fine('[EngineEvent] $objectId ${event}'));
    }

    _setUpListeners();

    onDispose(() async {
      await events.dispose();
      await delays.dispose();
      await close();
      await _signalListener.dispose();
    });
  }

  Future<lk_rtc.JoinResponse> connect(
    String url,
    String token,
  ) async {
    this.url = url;
    this.token = token;

    // connect to rtc server
    await signalClient.connect(
      url,
      token,
      connectOptions: room.connectOptions,
    );

    // wait for join response
    final event = await _signalListener.waitFor<SignalConnectedEvent>(
      duration: Timeouts.connection,
      onTimeout: () => throw ConnectException(),
    );

    return event.response;
  }

  /// Close connection between the server.
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

  @internal
  Future<lk_models.TrackInfo> addTrack({
    required String cid,
    required String name,
    required lk_models.TrackType kind,
    required lk_models.TrackSource source,
    VideoDimensions? dimensions,
    bool? dtx,
    List<lk_models.VideoLayer>? videoLayers,
  }) async {
    // TODO: Check if cid already published

    // send request to add track
    signalClient.sendAddTrack(
      cid: cid,
      name: name,
      type: kind,
      source: source,
      dimensions: dimensions,
      dtx: dtx,
      videoLayers: videoLayers,
    );

    // wait for response, or timeout
    final event = await _signalListener.waitFor<SignalLocalTrackPublishedEvent>(
      filter: (event) => event.cid == cid,
      duration: Timeouts.publish,
      onTimeout: () => throw TrackPublishException(),
    );

    return event.track;
  }

  @internal
  Future<void> negotiate({bool? iceRestart}) async {
    if (publisher == null) {
      return;
    }

    _hasPublished = true;
    publisher!.negotiate(null);
  }

  @internal
  Future<void> sendDataPacket(
    lk_models.DataPacket packet,
  ) async {
    //
    rtc.RTCDataChannel? publisherDataChannel(Reliability reliability) =>
        reliability == Reliability.reliable ? _reliableDCPub : _lossyDCPub;

    rtc.RTCDataChannelState publisherDataChannelState(
            Reliability reliability) =>
        publisherDataChannel(reliability)?.state ??
        rtc.RTCDataChannelState.RTCDataChannelClosed;

    final reliability = packet.kind.toSDKType();

    // construct the data channel message
    final message =
        rtc.RTCDataChannelMessage.fromBinary(packet.writeToBuffer());

    if (_subscriberPrimary) {
      // make sure publisher transport is connected

      if (publisher?.pc.iceConnectionState?.isConnected() != true) {
        logger.fine('Publisher is not connected...');

        // start negotiation
        if (publisher?.pc.iceConnectionState !=
            rtc.RTCIceConnectionState.RTCIceConnectionStateChecking) {
          await negotiate();
        }

        logger.fine('Waiting for publisher to ice-connect...');
        await events.waitFor<EnginePublisherIceStateUpdatedEvent>(
          filter: (event) => event.iceState.isConnected(),
          duration: Timeouts.iceConnection,
        );
      }

      // wait for data channel to open (if not already)
      if (publisherDataChannelState(packet.kind.toSDKType()) !=
          rtc.RTCDataChannelState.RTCDataChannelOpen) {
        logger.fine('Waiting for data channel ${reliability} to open...');
        await events.waitFor<PublisherDataChannelStateUpdatedEvent>(
          filter: (event) => event.type == reliability,
          duration: Timeouts.connection,
        );
      }
    }

    // chose data channel
    final rtc.RTCDataChannel? channel = publisherDataChannel(reliability);

    if (channel == null) {
      throw UnexpectedStateException(
          'Data channel for ${packet.kind.toSDKType()} is null');
    }

    logger.fine('sendDataPacket(label:${channel.label})');
    await channel.send(message);
  }

  @internal
  Future<void> reconnect() async {
    if (_connectionState == ConnectionState.disconnected) {
      logger.fine('Reconnect: Already closed.');
      return;
    }

    final url = this.url;
    final token = this.token;

    if (url == null || token == null) {
      throw ConnectException('could not reconnect without url and token');
    }

    _connectionState = ConnectionState.reconnecting;

    if (_reconnectAttempts == 0) {
      events.emit(const EngineReconnectingEvent());
    }
    _reconnectAttempts++;

    try {
      await signalClient.reconnect(
        url,
        token,
        connectOptions: room.connectOptions,
      );

      if (publisher == null || subscriber == null) {
        throw UnexpectedStateException('publisher or subscribers is null');
      }

      subscriber!.restartingIce = true;

      if (_hasPublished) {
        logger.fine('Reconnect: negotiating publisher...');
        await publisher!.createAndSendOffer(const RTCOfferOptions(
          iceRestart: true,
        ));
      }

      final iceConnected =
          primary?.pc.iceConnectionState?.isConnected() ?? false;

      logger.fine('Reconnect: iceConnected: $iceConnected');

      if (!iceConnected) {
        logger.fine('Reconnect: Waiting for primary to connect...');

        await events.waitFor<EngineIceStateUpdatedEvent>(
          filter: (event) => event.isPrimary && event.iceState.isConnected(),
          duration: Timeouts.iceRestart,
        );
      }

      logger.fine('Reconnect: success');
      _connectionState = ConnectionState.connected;
      events.emit(const EngineReconnectedEvent());
      _reconnectAttempts = 0;
    } catch (error) {
      logger.fine('Reconnect: error ${error}');
      // Pass up all exceptions
      _connectionState = ConnectionState.disconnected;
      rethrow;
    }
  }

  Future<void> _configurePeerConnections() async {
    if (publisher != null || subscriber != null) {
      logger.warning('Already configured');
      return;
    }

    // RTCConfiguration? config;
    // use server-provided iceServers if not provided by user
    final connectOptions = room.connectOptions ?? const ConnectOptions();
    final serverIceServers =
        _serverProvidedIceServers.map((e) => e.toSDKType()).toList();

    RTCConfiguration rtcConfiguration = connectOptions.rtcConfiguration;
    if (serverIceServers.isNotEmpty) {
      // use server provided iceServers if exists
      rtcConfiguration = connectOptions.rtcConfiguration
          .copyWith(iceServers: serverIceServers);
    }

    publisher = await PCTransport.create(rtcConfiguration);
    subscriber = await PCTransport.create(rtcConfiguration);

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
              iceState: state,
              isPrimary: _subscriberPrimary,
            ));

    publisher?.pc.onIceConnectionState =
        (state) => events.emit(EnginePublisherIceStateUpdatedEvent(
              state: state,
              isPrimary: !_subscriberPrimary,
            ));

    events.on<EngineIceStateUpdatedEvent>((event) {
      // only listen to primary ice events
      if (!event.isPrimary) return;

      if (event.iceState ==
          rtc.RTCIceConnectionState.RTCIceConnectionStateConnected) {
        if (!_iceConnected) {
          _iceConnected = true;
          if (_connectionState == ConnectionState.reconnecting) {
            events.emit(const EngineReconnectedEvent());
          } else {
            events.emit(const EngineConnectedEvent());
          }
        }
      } else if (event.iceState ==
          rtc.RTCIceConnectionState.RTCIceConnectionStateFailed) {
        // trigger reconnect sequence
        if (_iceConnected) {
          _iceConnected = false;
          _onDisconnected('peerconnection');
        }
      }
    });

    subscriber?.pc.onTrack = (rtc.RTCTrackEvent event) {
      logger.fine('[WebRTC] pc.onTrack');

      final stream = event.streams.firstOrNull;
      if (stream == null) {
        // we need the stream to get the track's id
        logger.severe('received track without mediastream');
        return;
      }

      // doesn't get called reliably
      event.track.onEnded = () {
        logger.fine('[WebRTC] track.onEnded');
      };

      // doesn't get called reliably
      stream.onRemoveTrack = (_) {
        logger.fine('[WebRTC] stream.onRemoveTrack');
      };

      events.emit(EngineTrackAddedEvent(
        track: event.track,
        stream: stream,
        receiver: event.receiver,
      ));
    };

    // doesn't get called reliably, doesn't work on mac
    subscriber?.pc.onRemoveTrack =
        (rtc.MediaStream stream, rtc.MediaStreamTrack track) {
      logger.fine('[WebRTC] ${track.id} pc.onRemoveTrack');
    };

    // also handle messages over the pub channel, for backwards compatibility
    try {
      final lossyInit = rtc.RTCDataChannelInit()
        ..binaryType = 'binary'
        ..ordered = true
        ..maxRetransmits = 0;
      _lossyDCPub =
          await publisher?.pc.createDataChannel(_lossyDCLabel, lossyInit);
      _lossyDCPub?.onMessage = _onDCMessage;
      _lossyDCPub?.stateChangeStream
          .listen((state) => events.emit(PublisherDataChannelStateUpdatedEvent(
                isPrimary: !_subscriberPrimary,
                state: state,
                type: Reliability.lossy,
              )));
      // _onDCStateUpdated(Reliability.lossy, state)
    } catch (_) {
      logger.severe('[$objectId] createDataChannel() did throw $_');
    }

    try {
      final reliableInit = rtc.RTCDataChannelInit()
        ..binaryType = 'binary'
        ..ordered = true;
      _reliableDCPub =
          await publisher?.pc.createDataChannel(_reliableDCLabel, reliableInit);
      _reliableDCPub?.onMessage = _onDCMessage;
      _reliableDCPub?.stateChangeStream
          .listen((state) => events.emit(PublisherDataChannelStateUpdatedEvent(
                isPrimary: !_subscriberPrimary,
                state: state,
                type: Reliability.reliable,
              )));
    } catch (_) {
      logger.severe('[$objectId] createDataChannel() did throw $_');
    }
  }

  void _onDataChannel(rtc.RTCDataChannel dc) {
    switch (dc.label) {
      case _reliableDCLabel:
        logger.fine('Server opened DC label: ${dc.label}');
        _reliableDCSub = dc;
        _reliableDCSub?.onMessage = _onDCMessage;
        _reliableDCSub?.stateChangeStream.listen((state) =>
            _reliableDCPub?.stateChangeStream.listen(
                (state) => events.emit(SubscriberDataChannelStateUpdatedEvent(
                      isPrimary: _subscriberPrimary,
                      state: state,
                      type: Reliability.reliable,
                    ))));
        break;
      case _lossyDCLabel:
        logger.fine('Server opened DC label: ${dc.label}');
        _lossyDCSub = dc;
        _lossyDCSub?.onMessage = _onDCMessage;
        _lossyDCSub?.stateChangeStream.listen((event) =>
            _reliableDCPub?.stateChangeStream.listen(
                (state) => events.emit(SubscriberDataChannelStateUpdatedEvent(
                      isPrimary: _subscriberPrimary,
                      state: state,
                      type: Reliability.lossy,
                    ))));
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
      events
          .emit(EngineActiveSpeakersUpdateEvent(speakers: dp.speaker.speakers));
    } else if (dp.whichValue() == lk_models.DataPacket_Value.user) {
      // User packet
      events.emit(EngineDataPacketReceivedEvent(
        packet: dp.user,
        kind: dp.kind,
      ));
    }
  }

  Future<void> _onDisconnected(String reason) async {
    logger.info('onDisconnected reason: $reason');
    if (_connectionState == ConnectionState.disconnected) {
      logger.fine('[$objectId] Already disconnected $reason');
      return;
    }

    logger.fine('[$objectId] Disconnected $reason');

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      logger.info('[$objectId] Could not connect '
          'after ${_reconnectAttempts} attempts, giving up');
      await close();
      events.emit(const EngineDisconnectedEvent());
      return;
    }

    final delay =
        Duration(milliseconds: (_reconnectAttempts * _reconnectAttempts) * 300);

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
      _serverProvidedIceServers = event.response.iceServers;

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
      logger.finer('sdp: ${event.sd.sdp}');

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
        logger.warning(
            'Received ${SignalTrickleEvent} but publisher or subscriber was null.');
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
    // relay
    ..on<SignalConnectionQualityUpdateEvent>((event) => events.emit(event))
    // relay
    ..on<SignalStreamStateUpdatedEvent>((event) => events.emit(event))
    // relay to Room
    ..on<SignalSubscribedQualityUpdatedEvent>((event) => events.emit(event))
    ..on<SignalLeaveEvent>((event) async {
      if (connectionState == ConnectionState.reconnecting) {
        logger.warning('Received leave signal while engine is reconnecting.');
      }
      await close();
      events.emit(const EngineDisconnectedEvent());
    })
    ..on<SignalMuteTrackEvent>(
        (event) => events.emit(EngineRemoteMuteChangedEvent(
              sid: event.sid,
              muted: event.muted,
            )));
}
