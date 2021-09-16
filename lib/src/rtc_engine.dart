import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/src/events.dart';
import 'package:livekit_client/src/types.dart';

import 'errors.dart';
import 'extensions.dart';
import 'logger.dart';
import 'managers/delay.dart';
import 'managers/event.dart';
import 'options.dart';
import 'proto/livekit_models.pb.dart' as lk_models;
import 'proto/livekit_rtc.pb.dart' as lk_rtc;
import 'signal_client.dart';
import 'track/track.dart';
import 'transport.dart';
import 'types.dart';

typedef GenericCallback = void Function();
typedef TrackCallback = void Function(
  rtc.MediaStreamTrack track,
  rtc.MediaStream? stream,
  rtc.RTCRtpReceiver? receiver,
);
typedef ParticipantUpdateCallback = void Function(List<lk_models.ParticipantInfo> participants);
typedef ActiveSpeakerChangedCallback = void Function(List<lk_models.SpeakerInfo> speakers);
typedef DataPacketCallback = void Function(
    lk_models.UserPacket packet, lk_models.DataPacket_Kind kind);
typedef RemoteMuteCallback = void Function(String sid, bool mute);

class RTCEngine with SignalClientDelegate {
  static const _lossyDCLabel = '_lossy';
  static const _reliableDCLabel = '_reliable';
  static const _maxReconnectAttempts = 5;
  static const _maxICEConnectTimeout = Duration(seconds: 5);
  static const _connectionTimeout = Duration(seconds: 5);
  static const _iceRestartTimeout = Duration(seconds: 10);

  final SignalClient client;
  // config for RTCPeerConnection
  final RTCConfiguration? rtcConfig;

  PCTransport? publisher;
  PCTransport? subscriber;
  PCTransport? get primary => _subscriberPrimary ? subscriber : publisher;

  // used for ice state notifications
  LKCancelListen? _primaryIceStateListener;

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

  // delegate methods
  GenericCallback? onICEConnected;
  TrackCallback? onTrack;
  ParticipantUpdateCallback? onParticipantUpdated;
  ActiveSpeakerChangedCallback? onActiveSpeakerUpdated;
  DataPacketCallback? onDataMessage;
  RemoteMuteCallback? onRemoteMute;
  GenericCallback? onReconnecting;
  GenericCallback? onReconnected;
  GenericCallback? onDisconnected;

  //
  // internal
  //
  final Map<String, Completer<lk_models.TrackInfo>> _pendingTrackResolvers = {};
  int _reconnectAttempts = 0;
  // to complete join request
  Completer<lk_rtc.JoinResponse>? _joinCompleter;

  final events = LKEventManager<LKEngineEvent>();
  final delays = LKCancelableDelayManager();

  RTCEngine(
    this.client,
    this.rtcConfig,
  ) {
    client.delegate = this;
  }

  Future<lk_rtc.JoinResponse> join(
    String url,
    String token, {
    ConnectOptions? options,
  }) async {
    this.url = url;
    this.token = token;

    final completer = Completer<lk_rtc.JoinResponse>();
    _joinCompleter = completer;

    await client.join(url, token, options: options);

    // if it's not complete after 5 seconds, fail
    Timer(_connectionTimeout, () {
      _joinCompleter?.completeError(LKConnectException());
      _joinCompleter = null;
    });

    return completer.future;
  }

  Future<void> close() async {
    logger.fine('${objectId} close()');
    if (isClosed) {
      logger.fine('${objectId} close() already closed');
      return;
    }
    isClosed = true;

    // cancel events
    await _primaryIceStateListener?.call();
    _primaryIceStateListener = null;

    await events.dispose();

    // cancel all ongoing delays
    await delays.dispose();

    // PCTransport is responsible for disposing RTCPeerConnection
    await publisher?.dispose();
    publisher = null;

    await subscriber?.dispose();
    subscriber = null;

    client.close();
  }

  Future<lk_models.TrackInfo> addTrack({
    required String cid,
    required String name,
    required lk_models.TrackType kind,
    TrackDimension? dimension,
  }) async {
    if (_pendingTrackResolvers[cid] != null) {
      throw LKTrackPublishException('a track with the same CID has already been published');
    }

    final completer = Completer<lk_models.TrackInfo>();
    _pendingTrackResolvers[cid] = completer;

    client.sendAddTrack(cid: cid, name: name, type: kind, dimension: dimension);

    return completer.future;
  }

  Future<void> negotiate({bool? iceRestart}) async {
    if (publisher == null) {
      return;
    }

    _hasPublished = true;
    publisher!.negotiate();
  }

  bool get _publisherIsConnected => [
        rtc.RTCIceConnectionState.RTCIceConnectionStateConnected,
        rtc.RTCIceConnectionState.RTCIceConnectionStateCompleted
      ].contains(publisher?.pc.iceConnectionState);

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

    if (_publisherIsConnected) {
      logger.warning('publisher is already connected');
      return;
    }

    // start negotiation
    await negotiate();

    logger.fine('start waiting for publisher ice connected '
        '(current: ${publisher?.pc.iceConnectionState})');

    await events.waitFor(
      (event) => _publisherIsConnected,
      duration: _maxICEConnectTimeout,
    );

    logger.fine('did publisher ice connected');
  }

  Future<void> reconnect() async {
    if (isClosed) {
      logger.fine('$objectId reconnect() already closed');
      return;
    }

    final url = this.url;
    final token = this.token;

    if (url == null || token == null) {
      throw LKConnectException('could not reconnect without url and token');
    }

    if (_reconnectAttempts == 0) {
      onReconnecting?.call();
      events.emit(LKEngineReconnectingEvent());
    }
    _reconnectAttempts++;

    try {
      isReconnecting = true;
      await client.reconnect(url, token);

      if (publisher == null || subscriber == null) {
        throw LKUnexpectedStateException('publisher or subscribers is null');
      }

      subscriber!.restartingIce = true;

      // await negotiate(iceRestart: true);
      if (_hasPublished) {
        logger.fine('reconnect: publisher.createAndSendOffer');
        await publisher!.createAndSendOffer(const RTCOfferOptions(iceRestart: true));
      }

      logger.fine('reconnect: starting to wait...');

      if (!iceConnected) {
        //
        await events.waitFor(
          (event) =>
              event is LKEngineIceStateUpdatedEvent &&
              event.isPrimary &&
              event.state == rtc.RTCIceConnectionState.RTCIceConnectionStateConnected,
          duration: _iceRestartTimeout,
        );
      }
      logger.fine('reconnect: success');

      // // wait for primary to ice connect
      // await _waitForEngineEvent((event, complete) {
      //   // only listen for primary ice state events
      //   if (event is! LKEngineIceStateUpdatedEvent || !event.isPrimary) return;
      //   if (event.state == rtc.RTCIceConnectionState.RTCIceConnectionStateConnected) complete();
      // }, timeout: _iceRestartTimeout);

      events.emit(LKEngineReconnectedEvent());

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
      client.sendIceCandidate(candidate, lk_rtc.SignalTarget.PUBLISHER);
    };

    subscriber?.pc.onIceCandidate = (rtc.RTCIceCandidate candidate) {
      logger.fine('subscriber onIceCandidate');
      client.sendIceCandidate(candidate, lk_rtc.SignalTarget.SUBSCRIBER);
    };

    publisher?.onOffer = (offer) {
      logger.fine('publisher onOffer');
      client.sendOffer(offer);
    };

    // in subscriber primary mode, server side opens sub data channels.
    if (_subscriberPrimary) {
      subscriber?.pc.onDataChannel = _onDataChannel;
    }

    // logger.fine('subscriber.pc: ${subscriber?.pc}');
    subscriber?.pc.onIceConnectionState = (state) {
      //
      logger.fine('subscriber ${state}, isPrimary: ${_subscriberPrimary}');

      events.emit(LKEngineIceStateUpdatedEvent(
        type: LKTransportType.subscriber,
        state: state,
        isPrimary: _subscriberPrimary,
      ));
    };

    publisher?.pc.onIceConnectionState = (state) {
      //
      logger.fine('publisher ${state}, isPrimary: ${!_subscriberPrimary}');

      events.emit(LKEngineIceStateUpdatedEvent(
        type: LKTransportType.publisher,
        state: state,
        isPrimary: !_subscriberPrimary,
      ));
    };

    _primaryIceStateListener ??= events.listen((LKEngineEvent event) {
      // only listen to primary ice events
      if (event is! LKEngineIceStateUpdatedEvent || !event.isPrimary) return;

      if (event.state == rtc.RTCIceConnectionState.RTCIceConnectionStateConnected) {
        if (!iceConnected) {
          iceConnected = true;
          if (isReconnecting) {
            onReconnected?.call();
          } else {
            onICEConnected?.call();
            events.emit(LKEngineConnectedEvent());
          }
        }
      } else if (event.state == rtc.RTCIceConnectionState.RTCIceConnectionStateFailed) {
        // trigger reconnect sequence
        if (iceConnected) {
          iceConnected = false;
          _onDisconnected('peerconnection');
        }
      }
    });

    subscriber?.pc.onTrack = (rtc.RTCTrackEvent event) {
      onTrack?.call(event.track, event.streams.firstOrNull, event.receiver);
      events.emit(LKEngineMediaTrackAddedEvent(
        track: event.track,
        stream: event.streams.firstOrNull,
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
      onActiveSpeakerUpdated?.call(dp.speaker.speakers);
      events.emit(LKEngineSpeakersUpdateEvent(speakers: dp.speaker.speakers));
    } else if (dp.whichValue() == lk_models.DataPacket_Value.user) {
      // User packet
      onDataMessage?.call(dp.user, dp.kind);
      events.emit(LKEngineDataPacketReceivedEvent(
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
      onDisconnected?.call();
      events.emit(LKEngineDisconnectedEvent());
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

  @override
  Future<void> onConnected(lk_rtc.JoinResponse response) async {
    // create peer connections
    isClosed = false;
    _subscriberPrimary = response.subscriberPrimary;
    _providedIceServers = response.iceServers;

    logger.fine('onConnected subscriberPrimary: ${_subscriberPrimary}, '
        'serverVersion: ${response.serverVersion}, '
        'iceServers: ${response.iceServers}');

    await _configurePeerConnections();

    if (!_subscriberPrimary) {
      // for subscriberPrimary, we negotiate when necessary (lazy)
      await negotiate();
    }

    _joinCompleter?.complete(Future.value(response));
    _joinCompleter = null;
  }

  @override
  Future<void> onClose([String? reason]) async {
    await _onDisconnected('signal');
  }

  @override
  Future<void> onOffer(rtc.RTCSessionDescription sd) async {
    if (subscriber == null) {
      return;
    }

    logger.fine('received server offer(type: ${sd.type}, ${subscriber!.pc.signalingState})');

    await subscriber!.setRemoteDescription(sd);

    final answer = await subscriber!.pc.createAnswer();
    logger.fine('Created answer');
    logger.finer('sdp: ${answer.sdp}');
    await subscriber!.pc.setLocalDescription(answer);
    client.sendAnswer(answer);
  }

  @override
  Future<void> onAnswer(rtc.RTCSessionDescription sd) async {
    if (publisher == null) {
      return;
    }
    logger.fine('received answer (type: ${sd.type})');
    logger.finer('sdp: ${sd.sdp}');
    await publisher!.setRemoteDescription(sd);
  }

  @override
  Future<void> onTrickle(rtc.RTCIceCandidate candidate, lk_rtc.SignalTarget target) async {
    if (publisher == null || subscriber == null) {
      return;
    }
    logger.fine('got ICE candidate from peer');
    if (target == lk_rtc.SignalTarget.SUBSCRIBER) {
      await subscriber!.addIceCandidate(candidate);
    } else if (target == lk_rtc.SignalTarget.PUBLISHER) {
      await publisher!.addIceCandidate(candidate);
    }
  }

  @override
  Future<void> onParticipantUpdate(List<lk_models.ParticipantInfo> updates) async {
    onParticipantUpdated?.call(updates);
    events.emit(LKEngineParticipantUpdateEvent(participants: updates));
  }

  @override
  Future<void> onLocalTrackPublished(lk_rtc.TrackPublishedResponse response) async {
    final completer = _pendingTrackResolvers.remove(response.cid);
    completer?.complete(Future.value(response.track));
  }

  @override
  Future<void> onActiveSpeakersChanged(List<lk_models.SpeakerInfo> speakers) async {
    onActiveSpeakerUpdated?.call(speakers);
    events.emit(LKEngineSpeakersUpdateEvent(speakers: speakers));
  }

  @override
  Future<void> onLeave(lk_rtc.LeaveRequest req) async {
    await close();
    onDisconnected?.call();
    events.emit(LKEngineDisconnectedEvent());
  }

  @override
  Future<void> onMuteTrack(lk_rtc.MuteTrackRequest req) async {
    onRemoteMute?.call(req.sid, req.muted);
    events.emit(LKEngineRemoteMuteChangedEvent(
      sid: req.sid,
      muted: req.muted,
    ));
  }
}

// extension _RTCEnginePrivateConvenienceMethods on RTCEngine {
//   // convenience method to wait for engine events with timeout
//   Future<void> _waitForEngineEvent(
//     Function(LKEngineEvent event, Function complete) onEvent, {
//     required Duration timeout,
//   }) async {
//     // create a temporary event listener
//     final completer = Completer<void>();
//     final cancelListen = events.listen((event) => onEvent(event, completer.complete));

//     try {
//       // wait to complete with timeout
//       await completer.future.timeout(
//         timeout,
//         onTimeout: () => throw LKTimeoutException(),
//       );
//       // do not catch exceptions and pass it up
//     } finally {
//       // always clean-up listener
//       await cancelListen.call();
//     }
//   }
// }
