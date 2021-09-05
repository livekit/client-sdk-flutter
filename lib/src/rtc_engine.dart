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

const lossyDataChannel = '_lossy';
const reliableDataChannel = '_reliable';
const connectionTimeout = Duration(seconds: 5);
const maxReconnectAttempts = 5;
const iceRestartTimeout = Duration(seconds: 10);

typedef GenericCallback = void Function();
typedef TrackCallback = void Function(
  MediaStreamTrack track,
  MediaStream? stream,
  RTCRtpReceiver? receiver,
);
typedef ParticipantUpdateCallback = void Function(List<lk_models.ParticipantInfo> participants);
typedef ActiveSpeakerChangedCallback = void Function(List<lk_rtc.SpeakerInfo> speakers);
typedef DataPacketCallback = void Function(lk_rtc.UserPacket packet, lk_rtc.DataPacket_Kind kind);

class RTCEngine with SignalClientDelegate {
  PCTransport? publisher;
  PCTransport? subscriber;
  SignalClient client;
  // config for RTCPeerConnection
  RTCConfiguration rtcConfig = RTCConfiguration();
  // data channels for packets
  RTCDataChannel? reliableDC;
  RTCDataChannel? lossyDC;
  bool iceConnected = false;
  bool isReconnecting = false;
  bool isClosed = true;
  Map<String, Completer<lk_models.TrackInfo>> pendingTrackResolvers = {};
  int reconnectAttempts = 0;
  // to complete join request
  Completer<lk_rtc.JoinResponse>? joinCompleter;
  // remember url and token for reconnect
  String? url;
  String? token;

  // delegate methods
  GenericCallback? onICEConnected;
  TrackCallback? onTrack;
  ParticipantUpdateCallback? onParticipantUpdateCallback;
  ActiveSpeakerChangedCallback? onActiveSpeakerchangedCallback;
  DataPacketCallback? onDataMessageCallback;
  GenericCallback? onReconnecting;
  GenericCallback? onReconnected;
  GenericCallback? onDisconnected;

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
    joinCompleter = completer;

    await client.join(url, token, options: options);

    // if it's not complete after 5 seconds, fail
    Timer(connectionTimeout, () {
      joinCompleter?.completeError(ConnectError());
      joinCompleter = null;
    });

    return completer.future;
  }

  Future<void> close() async {
    //
    isClosed = true;

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
    if (pendingTrackResolvers[cid] != null) {
      throw TrackPublishError('a track with the same CID has already been published');
    }

    final completer = Completer<lk_models.TrackInfo>();
    pendingTrackResolvers[cid] = completer;

    client.sendAddTrack(cid: cid, name: name, type: kind, dimension: dimension);

    return completer.future;
  }

  Future<void> negotiate({bool? iceRestart}) async {
    final pub = publisher;
    if (pub == null) return;

    final remoteDesc = await pub.getRemoteDescription();

    // handle cases that we couldn't create a new offer due to a pending answer
    // that's lost in transit
    if (remoteDesc != null &&
        pub.pc.signalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      await pub.pc.setRemoteDescription(remoteDesc);
    }

    final constraints = <String, dynamic>{};
    if (iceRestart != null && iceRestart) {
      constraints['mandatory'] = {
        'IceRestart': true,
      };
    }
    final offer = await pub.pc.createOffer(constraints);
    logger.info('Created offer: ${offer.sdp}');
    await pub.pc.setLocalDescription(offer);
    client.sendOffer(offer);
  }

  Future<void> reconnect() async {
    //
    if (isClosed) return;

    final url = this.url;
    final token = this.token;
    if (url == null || token == null) {
      throw ConnectError('could not reconnect without url and token');
    }
    if (reconnectAttempts == 0) {
      onReconnecting?.call();
    }
    reconnectAttempts++;

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

      await negotiate(iceRestart: true);
    } catch (error) {
      isReconnecting = false;
      return Future.error(error);
    }

    // wait for connectivity to change
    final startTime = DateTime.now();
    while (DateTime.now().difference(startTime) < iceRestartTimeout) {
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
    if (publisher != null) {
      return;
    }

    final pubPC = await createPeerConnection(rtcConfig.toMap());
    publisher = PCTransport(pubPC);
    final subPC = await createPeerConnection(rtcConfig.toMap());
    subscriber = PCTransport(subPC);

    pubPC.onIceCandidate = (RTCIceCandidate candidate) {
      client.sendIceCandidate(candidate, lk_rtc.SignalTarget.PUBLISHER);
    };
    subPC.onIceCandidate = (RTCIceCandidate candidate) {
      client.sendIceCandidate(candidate, lk_rtc.SignalTarget.SUBSCRIBER);
    };

    pubPC.onRenegotiationNeeded = () async {
      if (pubPC.iceConnectionState == null ||
          pubPC.iceConnectionState == RTCIceConnectionState.RTCIceConnectionStateNew) {
        return;
      }
      await negotiate();
    };

    pubPC.onIceConnectionState = (RTCIceConnectionState state) {
      if (publisher == null) {
        return;
      }
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
          _handleDisconnect('peerconnection');
          break;

        default:
        // do nothing
      }
    };

    subPC.onTrack = (RTCTrackEvent event) {
      onTrack?.call(event.track, event.streams.first, event.receiver);
    };

    // create data channels
    final lossyInit = RTCDataChannelInit()
      ..maxRetransmits = 1
      ..ordered = true
      ..binaryType = 'binary';
    lossyDC = await pubPC.createDataChannel(lossyDataChannel, lossyInit);

    final reliableInit = RTCDataChannelInit()
      ..ordered = true
      ..maxRetransmits = 50
      ..binaryType = 'binary';
    reliableDC = await pubPC.createDataChannel(reliableDataChannel, reliableInit);

    lossyDC?.onMessage = _handleDataMessage;
    reliableDC?.onMessage = _handleDataMessage;
  }

  void _handleDataMessage(RTCDataChannelMessage message) {
    // always expect binary
    if (!message.isBinary) {
      return;
    }

    final dp = lk_rtc.DataPacket.fromBuffer(message.binary);
    switch (dp.whichValue()) {
      case lk_rtc.DataPacket_Value.speaker:
        onActiveSpeakerchangedCallback?.call(dp.speaker.speakers);
        break;
      case lk_rtc.DataPacket_Value.user:
        onDataMessageCallback?.call(dp.user, dp.kind);
        break;
      default:
      // do nothing
    }
  }

  Future<void> _handleDisconnect(String reason) async {
    //
    if (isClosed) return;

    logger.fine('disconnected $reason');
    if (reconnectAttempts >= maxReconnectAttempts) {
      logger.info('could not connect after $reconnectAttempts, giving up');
      await close();
      onDisconnected?.call();
      return;
    }

    final delay = (reconnectAttempts * reconnectAttempts) * 300;
    Future.delayed(Duration(milliseconds: delay), () {
      reconnect().then((_) {
        reconnectAttempts = 0;
      }).catchError((dynamic e) {
        _handleDisconnect(reason);
      });
    });
  }

  //------------------ SignalClient Delegate methods -------------------------//

  @override
  Future<void> onConnected(lk_rtc.JoinResponse response) async {
    // create peer connections
    isClosed = false;

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

    await negotiate();

    joinCompleter?.complete(Future.value(response));
    joinCompleter = null;
  }

  @override
  Future<void> onClose([String? reason]) async {
    await _handleDisconnect('signal');
  }

  @override
  Future<void> onOffer(RTCSessionDescription sd) async {
    final sub = subscriber;
    if (sub == null) return;

    await sub.setRemoteDescription(sd);

    final answer = await sub.pc.createAnswer();
    logger.info('Created answer: ${answer.sdp}');
    await sub.pc.setLocalDescription(answer);
    client.sendAnswer(answer);
  }

  @override
  Future<void> onAnswer(RTCSessionDescription sd) async {
    if (publisher == null) return;
    logger.info('Received answer: ${sd.sdp}');
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
    onParticipantUpdateCallback?.call(updates);
  }

  @override
  Future<void> onLocalTrackPublished(lk_rtc.TrackPublishedResponse response) async {
    final completer = pendingTrackResolvers.remove(response.cid);
    completer?.complete(Future.value(response.track));
  }

  @override
  Future<void> onActiveSpeakersChanged(List<lk_rtc.SpeakerInfo> speakers) async {
    onActiveSpeakerchangedCallback?.call(speakers);
  }

  @override
  Future<void> onLeave(lk_rtc.LeaveRequest req) async {
    await close();
    onDisconnected?.call();
  }
}
