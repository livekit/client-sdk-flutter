import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'errors.dart';
import 'events.dart';
import 'extensions.dart';
import 'logger.dart';
import 'managers/delay.dart';
import 'managers/event.dart';
import 'options.dart';
import 'proto/livekit_models.pb.dart' as lk_models;
import 'proto/livekit_rtc.pb.dart' as lk_rtc;
import 'signal_client.dart';
import 'transport.dart';
import 'types.dart';

// typedef GenericCallback = void Function();
// typedef TrackCallback = void Function(
//   rtc.MediaStreamTrack track,
//   rtc.MediaStream? stream,
//   rtc.RTCRtpReceiver? receiver,
// );
// typedef ParticipantUpdateCallback = void Function(List<lk_models.ParticipantInfo> participants);
// typedef ActiveSpeakerChangedCallback = void Function(List<lk_models.SpeakerInfo> speakers);
// typedef DataPacketCallback = void Function(
//     lk_models.UserPacket packet, lk_models.DataPacket_Kind kind);
// typedef RemoteMuteCallback = void Function(String sid, bool mute);

class RTCEngine {
  static const _lossyDCLabel = '_lossy';
  static const _reliableDCLabel = '_reliable';
  static const _maxReconnectAttempts = 5;
  static const _maxICEConnectTimeout = Duration(seconds: 5);
  static const _connectionTimeout = Duration(seconds: 5);
  static const _iceRestartTimeout = Duration(seconds: 10);

  final SignalClient signalClient;
  // config for RTCPeerConnection
  final RTCConfiguration? rtcConfig;

  PCTransport? publisher;
  PCTransport? subscriber;
  PCTransport? get primary => _subscriberPrimary ? subscriber : publisher;

  // used for ice state notifications
  CancelListenFunc? _primaryIceStateListener;

  // data channels for packets
  rtc.RTCDataChannel? reliableDC;
  rtc.RTCDataChannel? lossyDC;
  bool iceConnected = false;
  bool isReconnecting = false;
  bool isClosed = true;
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
  final Map<String, Completer<lk_models.TrackInfo>> _pendingTrackResolvers = {};
  int _reconnectAttempts = 0;
  // to complete join request
  // Completer<lk_rtc.JoinResponse>? _joinCompleter;

  final events = EventsEmitter<EngineEvent>();
  late final _signalListener = EventsListener(signalClient.events, synchronized: true);

  final delays = CancelableDelayManager();

  // late final Timer _statsTimer;

  RTCEngine(
    this.signalClient,
    this.rtcConfig,
  ) {
    if (kDebugMode) {
      // log all EngineEvents
      events.listen((event) => logger.fine('[EngineEvent] $objectId ${event.runtimeType}'));
    }

    _setUpListeners();
    // _statsTimer = Timer.periodic(const Duration(seconds: 1), _onStatTimer);
  }

  Future<void> dispose() async {
    await events.dispose();
    await _signalListener.dispose();
  }

  // void _onStatTimer(Timer _) async {
  //   //
  //   final stats = await publisher?.pc.getStats();
  //   if (stats == null || stats.isEmpty) return;

  //   for (final s in stats) {
  //     logger.fine('STATS ${s.values}');
  //   }
  // }

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
      duration: _connectionTimeout,
      onTimeout: () => throw ConnectException(),
    );

    return event.response;
  }

  Future<void> close() async {
    logger.fine('${objectId} close()');
    if (isClosed) {
      logger.fine('${objectId} close() already closed');
      return;
    }
    isClosed = true;

    // _statsTimer.cancel();

    // cancel events
    await _primaryIceStateListener?.call();
    _primaryIceStateListener = null;

    // cancel all ongoing delays
    await delays.dispose();

    // PCTransport is responsible for disposing RTCPeerConnection
    await publisher?.dispose();
    publisher = null;

    await subscriber?.dispose();
    subscriber = null;

    signalClient.close();
  }

  Future<lk_models.TrackInfo> addTrack({
    required String cid,
    required String name,
    required lk_models.TrackType kind,
    TrackDimension? dimension,
  }) async {
    if (_pendingTrackResolvers[cid] != null) {
      throw TrackPublishException('a track with the same CID has already been published');
    }

    final completer = Completer<lk_models.TrackInfo>();
    _pendingTrackResolvers[cid] = completer;

    signalClient.sendAddTrack(cid: cid, name: name, type: kind, dimension: dimension);

    return completer.future;
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

    if (packet.kind == lk_models.DataPacket_Kind.LOSSY && lossyDC != null) {
      await lossyDC?.send(dcMessage);
    } else if (packet.kind == lk_models.DataPacket_Kind.RELIABLE && reliableDC != null) {
      await reliableDC?.send(dcMessage);
    }
  }

  Future<void> _ensurePublisherConnected() async {
    logger.fine('ensurePublisherConnected()');
    if (!_subscriberPrimary) {
      return;
    }

    if (publisher?.pc.iceConnectionState?.isConnected() == true) {
      logger.warning('publisher is already connected');
      return;
    }

    // start negotiation
    await negotiate();

    logger.fine('[PUBLISHER] waiting for to ice-connect '
        '(current: ${publisher?.pc.iceConnectionState})');

    await events.waitFor<EnginePublisherIceStateUpdatedEvent>(
      filter: (event) => event.iceState.isConnected(),
      duration: _maxICEConnectTimeout,
    );

    logger.fine('[PUBLISHER] connected');
  }

  Future<void> reconnect() async {
    if (isClosed) {
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
      isReconnecting = true;
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
          duration: _iceRestartTimeout,
        );
      }

      logger.fine('reconnect: success');
      events.emit(const EngineReconnectedEvent());
      _reconnectAttempts = 0;

      // don't catch and pass up any exception
    } finally {
      // always set reconnecting to false
      isReconnecting = false;
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

    // logger.fine('subscriber.pc: ${subscriber?.pc}');
    subscriber?.pc.onIceConnectionState = (state) {
      //
      events.emit(EngineSubscriberIceStateUpdatedEvent(
        state: state,
        isPrimary: _subscriberPrimary,
      ));
    };

    publisher?.pc.onIceConnectionState = (state) {
      //
      events.emit(EnginePublisherIceStateUpdatedEvent(
        state: state,
        isPrimary: !_subscriberPrimary,
      ));
    };

    _primaryIceStateListener ??= events.on<EngineIceStateUpdatedEvent>((event) {
      // only listen to primary ice events
      if (!event.isPrimary) return;

      if (event.iceState == rtc.RTCIceConnectionState.RTCIceConnectionStateConnected) {
        if (!iceConnected) {
          iceConnected = true;
          if (isReconnecting) {
            events.emit(const EngineReconnectedEvent());
          } else {
            events.emit(const EngineConnectedEvent());
          }
        }
      } else if (event.iceState == rtc.RTCIceConnectionState.RTCIceConnectionStateFailed) {
        // trigger reconnect sequence
        if (iceConnected) {
          iceConnected = false;
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

    // data channels
    final lossyInit = rtc.RTCDataChannelInit()
      ..binaryType = 'binary'
      ..ordered = true
      ..maxRetransmits = 0;
    lossyDC = await publisher?.pc.createDataChannel(_lossyDCLabel, lossyInit);

    final reliableInit = rtc.RTCDataChannelInit()
      ..binaryType = 'binary'
      ..ordered = true;
    reliableDC = await publisher?.pc.createDataChannel(_reliableDCLabel, reliableInit);

    // also handle messages over the pub channel, for backwards compatibility
    lossyDC?.onMessage = _onDCMessage;
    reliableDC?.onMessage = _onDCMessage;
  }

  void _onDataChannel(rtc.RTCDataChannel dc) {
    switch (dc.label) {
      case _reliableDCLabel:
        logger.fine('Server opened DC label: ${dc.label}');
        reliableDC = dc;
        reliableDC?.onMessage = _onDCMessage;
        break;
      case _lossyDCLabel:
        logger.fine('Server opened DC label: ${dc.label}');
        lossyDC = dc;
        lossyDC?.onMessage = _onDCMessage;
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
      events.emit(EngineSpeakersUpdateEvent(speakers: dp.speaker.speakers));
    } else if (dp.whichValue() == lk_models.DataPacket_Value.user) {
      // User packet
      events.emit(EngineDataPacketReceivedEvent(
        packet: dp.user,
        kind: dp.kind,
      ));
    }
  }

  Future<void> _onDisconnected(String reason) async {
    if (isClosed) return;

    logger.fine('disconnected $reason');
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      logger.info('could not connect after $_reconnectAttempts, giving up');
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

  //------------------ SignalClient Delegate methods -------------------------//

  void _setUpListeners() => _signalListener
    ..on<SignalConnectedEvent>((event) async {
      // create peer connections
      isClosed = false;
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

      // _joinCompleter?.complete(Future.value(event.response));
      // _joinCompleter = null;
    })
    ..on<SignalCloseEvent>((_) async {
      await _onDisconnected('signal');
    })
    ..on<SignalOfferEvent>((event) async {
      if (subscriber == null) {
        return;
      }

      logger.fine('received server offer(type: ${event.sd.type}, '
          '${subscriber!.pc.signalingState})');

      await subscriber!.setRemoteDescription(event.sd);

      final answer = await subscriber!.pc.createAnswer();
      logger.fine('Created answer');
      logger.finer('sdp: ${answer.sdp}');
      await subscriber!.pc.setLocalDescription(answer);
      signalClient.sendAnswer(answer);
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
    ..on<SignalParticipantUpdateEvent>((event) async {
      events.emit(EngineParticipantUpdateEvent(participants: event.updates));
    })
    ..on<SignalLocalTrackPublishedEvent>((event) async {
      final completer = _pendingTrackResolvers.remove(event.cid);
      completer?.complete(event.track);
    })
    ..on<SignalActiveSpeakersChangedEvent>((event) async {
      events.emit(EngineSpeakersUpdateEvent(speakers: event.speakers));
    })
    ..on<SignalLeaveEvent>((event) async {
      await close();
      events.emit(const EngineDisconnectedEvent());
    })
    ..on<SignalMuteTrackEvent>((event) => events.emit(EngineRemoteMuteChangedEvent(
          sid: event.sid,
          muted: event.muted,
        )));
}
