import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

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

  StreamController<RTCIceConnectionState>? _publisherIceStateStream;
  StreamController<RTCIceConnectionState>? _subscriberIceStateStream;
  StreamController<RTCIceConnectionState>? get primaryIceStateStream =>
      _subscriberPrimary ? _subscriberIceStateStream : _publisherIceStateStream;
  StreamSubscription<RTCIceConnectionState>? _primarySubscription;
  // final _subscriptions = <StreamSubscription<RTCIceConnectionState>>[];

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
      _joinCompleter?.completeError(ConnectError());
      _joinCompleter = null;
    });

    return completer.future;
  }

  Future<void> close() async {
    isClosed = true;

    // for (final sub in _subscriptions) {
    //   await sub.cancel();
    // }
    await _primarySubscription?.cancel();
    _primarySubscription = null;

    await _publisherIceStateStream?.close();
    _publisherIceStateStream = null;

    await _subscriberIceStateStream?.close();
    _subscriberIceStateStream = null;

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
      throw TrackPublishError('a track with the same CID has already been published');
    }

    final completer = Completer<lk_models.TrackInfo>();
    _pendingTrackResolvers[cid] = completer;

    client.sendAddTrack(cid: cid, name: name, type: kind, dimension: dimension);

    return completer.future;
  }

  Future<void> _negotiate({bool? iceRestart}) async {
    final pub = publisher;
    if (pub == null) return;

    _hasPublished = true;

    // handle cases that we couldn't create a new offer due to a pending answer
    // that's lost in transit
    if (pub.pc.signalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      logger.fine('has local offer');
      // it's still waiting for the last offer, and it won't be able to create
      // a new offer in this state. We'll reuse the last remote description to
      // get it out of this state
      final remoteDesc = await pub.getRemoteDescription();
      if (remoteDesc != null) await pub.pc.setRemoteDescription(remoteDesc);
    }

    final constraints = <String, dynamic>{};
    if (iceRestart != null && iceRestart) {
      constraints['mandatory'] = {
        'IceRestart': true,
      };
    }
    final offer = await pub.pc.createOffer(constraints);
    logger.fine('Created offer');
    logger.finer('sdp: ${offer.sdp}');
    await pub.pc.setLocalDescription(offer);
    client.sendOffer(offer);
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
    if (!_subscriberPrimary) return;
    logger.fine('ensurePublisherConnected()');

    if (_publisherIsConnected) {
      logger.warning('publisher is already connected');
      return;
    }

    // start negotiation
    await _negotiate();

    // wait for publisher ICE connected
    final completer = Completer<void>();
    final subscription = _publisherIceStateStream?.stream.listen((RTCIceConnectionState state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) completer.complete();
    });

    try {
      await completer.future.timeout(
        _maxICEConnectTimeout,
        onTimeout: () => throw ConnectError(),
      );
    } finally {
      await subscription?.cancel();
    }
  }

  Future<void> reconnect() async {
    if (isClosed) return;

    final url = this.url;
    final token = this.token;
    if (url == null || token == null) {
      throw ConnectError('could not reconnect without url and token');
    }
    if (_reconnectAttempts == 0) {
      onReconnecting?.call();
    }
    _reconnectAttempts++;

    try {
      isReconnecting = true;
      await client.reconnect(url, token);

      final pub = publisher;
      final sub = subscriber;
      if (pub == null || sub == null) {
        throw UnexpectedConnectionState('publisher or subscribers is null');
      }

      pub.restartingIce = true;
      sub.restartingIce = true;

      await _negotiate(iceRestart: true);
    } catch (error) {
      isReconnecting = false;
      return Future.error(error);
    }

    // wait for connectivity to change
    final startTime = DateTime.now();
    while (DateTime.now().difference(startTime) < _iceRestartTimeout) {
      if (iceConnected) {
        isReconnecting = false;
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    isReconnecting = false;
    throw ConnectError('could not reconnect ICE');
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

    primary?.pc.onRenegotiationNeeded = () async {
      if (primary?.pc.iceConnectionState == null ||
          primary?.pc.iceConnectionState == RTCIceConnectionState.RTCIceConnectionStateNew) {
        return;
      }
      await _negotiate();
    };

    _publisherIceStateStream ??= StreamController<RTCIceConnectionState>.broadcast(sync: true);
    publisher?.pc.onIceConnectionState = (state) => _publisherIceStateStream?.add(state);

    _subscriberIceStateStream ??= StreamController<RTCIceConnectionState>.broadcast(sync: true);
    subscriber?.pc.onIceConnectionState = (state) => _subscriberIceStateStream?.add(state);

    _primarySubscription ??= primaryIceStateStream?.stream.listen((RTCIceConnectionState state) {
      //
      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateConnected:
          if (!iceConnected) {
            iceConnected = true;
            if (isReconnecting) {
              onReconnected?.call();
            } else {
              onICEConnected?.call();
            }
          }
          break;

        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          iceConnected = false;
          // trigger reconnect sequence
          _onPCDisconnected('peerconnection');
          break;

        default:
          break;
      }
    });

    subscriber?.pc.onTrack = (RTCTrackEvent event) {
      onTrack?.call(event.track, event.streams.first, event.receiver);
    };

    // in subscriber primary mode, server side opens sub data channels.
    if (_subscriberPrimary) {
      //
      subscriber?.pc.onDataChannel = (RTCDataChannel dc) {
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
      };
    }

    // create data channels on publisher (for backward-compatibility)
    final lossyInit = RTCDataChannelInit()
      ..maxRetransmits = 0
      ..ordered = true
      ..binaryType = 'binary';
    lossyDC = await publisher?.pc.createDataChannel(_lossyDCLabel, lossyInit);
    lossyDC?.onMessage = _onDCMessage;

    final reliableInit = RTCDataChannelInit()
      ..ordered = true
      ..maxRetransmits = 50
      ..binaryType = 'binary';
    reliableDC = await publisher?.pc.createDataChannel(_reliableDCLabel, reliableInit);
    reliableDC?.onMessage = _onDCMessage;
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
        // do nothing
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

    logger.fine('onConnected subscriberPrimary: ${_subscriberPrimary}');

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
      await _negotiate();
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
    final sub = subscriber;
    if (sub == null) return;

    await sub.setRemoteDescription(sd);

    final answer = await sub.pc.createAnswer();
    logger.fine('Created answer');
    logger.finer('sdp: ${answer.sdp}');
    await sub.pc.setLocalDescription(answer);
    client.sendAnswer(answer);
  }

  @override
  Future<void> onAnswer(RTCSessionDescription sd) async {
    if (publisher == null) return;
    logger.fine('Received answer');
    logger.finer('sdp: ${sd.sdp}');
    await publisher!.setRemoteDescription(sd);
  }

  @override
  Future<void> onTrickle(RTCIceCandidate candidate, lk_rtc.SignalTarget target) async {
    if (target == lk_rtc.SignalTarget.SUBSCRIBER) {
      await subscriber?.addIceCandidate(candidate);
    } else if (target == lk_rtc.SignalTarget.PUBLISHER) {
      await publisher?.addIceCandidate(candidate);
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
