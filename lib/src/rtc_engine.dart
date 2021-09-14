import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/src/events.dart';
import 'package:livekit_client/src/types.dart';

import 'errors.dart';
import 'extensions.dart';
import 'logger.dart';
import 'options.dart';
import 'proto/livekit_models.pb.dart' as lk_models;
import 'proto/livekit_rtc.pb.dart' as lk_rtc;
import 'signal_client.dart';
import 'track/track.dart';
import 'transport.dart';

typedef GenericCallback = void Function();
typedef TrackCallback = void Function(
  MediaStreamTrack track,
  MediaStream? stream,
  RTCRtpReceiver? receiver,
);
typedef ParticipantUpdateCallback = void Function(List<lk_models.ParticipantInfo> participants);
typedef ActiveSpeakerChangedCallback = void Function(List<lk_models.SpeakerInfo> speakers);
typedef DataPacketCallback = void Function(
    lk_models.UserPacket packet, lk_models.DataPacket_Kind kind);
typedef RemoteMuteCallback = void Function(String sid, bool mute);

extension _RTCEnginePrivateConvenienceMethods on RTCEngine {
  // simply emit an event
  void _emitEvent(LKEngineEvent event) => events.add(event);

  // convenience method to wait for engine events with timeout
  Future<void> _waitForEngineEvent(
    Function(LKEngineEvent event, Function complete) onEvent, {
    required Duration timeout,
  }) async {
    // create a temporary event listener
    final completer = Completer<void>();
    final listener = events.stream.listen((event) => onEvent(event, completer.complete));

    try {
      // wait to complete with timeout
      await completer.future.timeout(
        timeout,
        onTimeout: () => throw LKTimeoutException(),
      );
      // do not catch exceptions and pass it up
    } finally {
      // always clean-up listener
      await listener.cancel();
    }
  }
}

class RTCEngine with SignalClientDelegate {
  static const _lossyDCLabel = '_lossy';
  static const _reliableDCLabel = '_reliable';
  static const _maxReconnectAttempts = 5;
  static const _maxICEConnectTimeout = Duration(seconds: 5);
  static const _connectionTimeout = Duration(seconds: 5);
  static const _iceRestartTimeout = Duration(seconds: 10);

  SignalClient client;

  PCTransport? publisher;
  PCTransport? subscriber;
  PCTransport? get primary => _subscriberPrimary ? subscriber : publisher;

  // used for ice state notifications
  StreamSubscription<LKEngineEvent>? _primaryIceStateListener;

  final events = StreamController<LKEngineEvent>.broadcast();

  // config for RTCPeerConnection
  RTCConfiguration rtcConfig = RTCConfiguration();
  // data channels for packets
  RTCDataChannel? reliableDC;
  RTCDataChannel? lossyDC;
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

  RTCEngine(this.client, RTCConfiguration? rtcConfig) {
    if (rtcConfig != null) {
      this.rtcConfig = rtcConfig;
    }

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
    isClosed = true;

    // Clean-up events
    await events.close();

    await _primaryIceStateListener?.cancel();
    _primaryIceStateListener = null;

    // await _publisherIceStateStream?.close();
    // _publisherIceStateStream = null;

    // await _subscriberIceStateStream?.close();
    // _subscriberIceStateStream = null;

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

  bool get _publisherIsConnected =>
      publisher?.pc.iceConnectionState == RTCIceConnectionState.RTCIceConnectionStateConnected;

  /* @internal */
  Future<void> sendDataPacket(
    lk_models.DataPacket packet,
  ) async {
    // make sure we do have a data connection
    await _ensurePublisherConnected();

    final dcMessage = RTCDataChannelMessage.fromBinary(packet.writeToBuffer());

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

    await _waitForEngineEvent((event, complete) {
      // only listen for publisher ice state events
      if (event is! LKEngineIceStateUpdatedEvent || event.type != LKTransportType.publisher) {
        return;
      }
      if (event.state == RTCIceConnectionState.RTCIceConnectionStateConnected) complete();
    }, timeout: _maxICEConnectTimeout);
  }

  Future<void> reconnect() async {
    if (isClosed) {
      return;
    }

    final url = this.url;
    final token = this.token;
    if (url == null || token == null) {
      throw LKConnectException('could not reconnect without url and token');
    }

    if (_reconnectAttempts == 0) {
      onReconnecting?.call();
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
        await publisher!.createAndSendOffer(const RTCOfferOptions(iceRestart: true));
      }

      // wait for primary to ice connect
      await _waitForEngineEvent((event, complete) {
        // only listen for primary ice state events
        if (event is! LKEngineIceStateUpdatedEvent || !event.isPrimary) return;
        if (event.state == RTCIceConnectionState.RTCIceConnectionStateConnected) complete();
      }, timeout: _iceRestartTimeout);

      // emit event
      _emitEvent(LKEngineReconnectedEvent());

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

    publisher = await PCTransport.create(rtcConfig.toMap());
    subscriber = await PCTransport.create(rtcConfig.toMap());

    publisher?.pc.onIceCandidate = (RTCIceCandidate candidate) {
      client.sendIceCandidate(candidate, lk_rtc.SignalTarget.PUBLISHER);
    };

    subscriber?.pc.onIceCandidate = (RTCIceCandidate candidate) {
      client.sendIceCandidate(candidate, lk_rtc.SignalTarget.SUBSCRIBER);
    };

    publisher?.onOffer = (offer) {
      client.sendOffer(offer);
    };

    // in subscriber primary mode, server side opens sub data channels.
    if (_subscriberPrimary) {
      subscriber?.pc.onDataChannel = _onDataChannel;
    }

    subscriber?.pc.onIceConnectionState = (state) {
      _emitEvent(LKEngineIceStateUpdatedEvent(
        type: LKTransportType.subscriber,
        state: state,
        isPrimary: _subscriberPrimary,
      ));
    };

    publisher?.pc.onIceConnectionState = (state) {
      _emitEvent(LKEngineIceStateUpdatedEvent(
        type: LKTransportType.publisher,
        state: state,
        isPrimary: !_subscriberPrimary,
      ));
    };

    _primaryIceStateListener ??= events.stream.listen((LKEngineEvent event) {
      // only listen to primary ice events
      if (event is! LKEngineIceStateUpdatedEvent || !event.isPrimary) return;

      if (event.state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        if (!iceConnected) {
          iceConnected = true;
          if (isReconnecting) {
            onReconnected?.call();
          } else {
            onICEConnected?.call();
          }
        }
      } else if (event.state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        // trigger reconnect sequence
        if (iceConnected) {
          iceConnected = false;
          _onPCDisconnected('peerconnection');
        }
      }
    });

    subscriber?.pc.onTrack = (RTCTrackEvent event) {
      onTrack?.call(event.track, event.streams.first, event.receiver);
    };

    // data channels
    final lossyInit = RTCDataChannelInit()
      ..binaryType = 'binary'
      ..ordered = true
      ..maxRetransmits = 0;
    lossyDC = await publisher?.pc.createDataChannel(_lossyDCLabel, lossyInit);

    final reliableInit = RTCDataChannelInit()
      ..binaryType = 'binary'
      ..ordered = true;
    reliableDC = await publisher?.pc.createDataChannel(_reliableDCLabel, reliableInit);

    // also handle messages over the pub channel, for backwards compatibility
    lossyDC?.onMessage = _onDCMessage;
    reliableDC?.onMessage = _onDCMessage;
  }

  void _onDataChannel(RTCDataChannel dc) {
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

  void _onDCMessage(RTCDataChannelMessage message) {
    // always expect binary
    if (!message.isBinary) {
      logger.warning('Data message is not binary');
      return;
    }

    final dp = lk_models.DataPacket.fromBuffer(message.binary);
    switch (dp.whichValue()) {
      case lk_models.DataPacket_Value.speaker:
        onActiveSpeakerUpdated?.call(dp.speaker.speakers);
        break;
      case lk_models.DataPacket_Value.user:
        onDataMessage?.call(dp.user, dp.kind);
        break;
      default:
        break;
    }
  }

  Future<void> _onPCDisconnected(String reason) async {
    if (isClosed) return;

    logger.fine('disconnected $reason');
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      logger.info('could not connect after $_reconnectAttempts, giving up');
      await close();
      onDisconnected?.call();
      return;
    }

    final delay = (_reconnectAttempts * _reconnectAttempts) * 300;
    Future.delayed(Duration(milliseconds: delay), () {
      reconnect().then((_) {
        _reconnectAttempts = 0;
      }).catchError((dynamic e) {
        _onPCDisconnected(reason);
      });
    });
  }

  //------------------ SignalClient Delegate methods -------------------------//

  @override
  Future<void> onConnected(lk_rtc.JoinResponse response) async {
    // create peer connections
    isClosed = false;
    _subscriberPrimary = response.subscriberPrimary;

    logger.fine('onConnected subscriberPrimary: ${_subscriberPrimary}, '
        'serverVersion: ${response.serverVersion}, '
        'iceServers: ${response.iceServers}');

    // TODO: Organize
    if (rtcConfig.iceServers == null && response.iceServers.isNotEmpty) {
      List<RTCIceServer> iceServers = [];
      for (final item in response.iceServers) {
        final iceServer = RTCIceServer(urls: item.urls);
        if (item.username.isNotEmpty) {
          iceServer.username = item.username;
        }
        if (item.credential.isNotEmpty) {
          iceServer.credential = item.credential;
        }
        iceServers.add(iceServer);
      }
      rtcConfig.iceServers = iceServers;
    }

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
    await _onPCDisconnected('signal');
  }

  @override
  Future<void> onOffer(RTCSessionDescription sd) async {
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
  Future<void> onAnswer(RTCSessionDescription sd) async {
    if (publisher == null) {
      return;
    }
    logger.fine('received answer (type: ${sd.type})');
    logger.finer('sdp: ${sd.sdp}');
    await publisher!.setRemoteDescription(sd);
  }

  @override
  Future<void> onTrickle(RTCIceCandidate candidate, lk_rtc.SignalTarget target) async {
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
  }

  @override
  Future<void> onLocalTrackPublished(lk_rtc.TrackPublishedResponse response) async {
    final completer = _pendingTrackResolvers.remove(response.cid);
    completer?.complete(Future.value(response.track));
  }

  @override
  Future<void> onActiveSpeakersChanged(List<lk_models.SpeakerInfo> speakers) async {
    onActiveSpeakerUpdated?.call(speakers);
  }

  @override
  Future<void> onLeave(lk_rtc.LeaveRequest req) async {
    await close();
    onDisconnected?.call();
  }

  @override
  Future<void> onMuteTrack(lk_rtc.MuteTrackRequest req) async {
    onRemoteMute?.call(req.sid, req.muted);
  }
}
