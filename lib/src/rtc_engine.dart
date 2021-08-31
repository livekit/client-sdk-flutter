import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'errors.dart';
import 'extensions.dart';
import 'logger.dart';
import 'options.dart';
import 'proto/livekit_rtc.pb.dart';
import 'proto/livekit_models.pb.dart';
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
    MediaStreamTrack track, MediaStream? stream, RTCRtpReceiver? receiver);
typedef ParticipantUpdateCallback = void Function(
    List<ParticipantInfo> participants);
typedef ActiveSpeakerChangedCallback = void Function(
    List<SpeakerInfo> speakers);
typedef DataPacketCallback = void Function(
    UserPacket packet, DataPacket_Kind kind);

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
  Map<String, Completer<TrackInfo>> pendingTrackResolvers = {};
  int reconnectAttempts = 0;
  // to complete join request
  Completer<JoinResponse>? joinCompleter;
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

  Future<JoinResponse> join(String url, String token, JoinOptions? opts) async {
    this.url = url;
    this.token = token;

    final completer = Completer<JoinResponse>();
    joinCompleter = completer;

    try {
      await client.join(url, token, opts);
    } catch (e) {
      return Future.error(e);
    }

    // if it's not complete after 5 seconds, fail
    Timer(connectionTimeout, () {
      joinCompleter?.completeError(ConnectError());
      joinCompleter = null;
    });

    return completer.future;
  }

  void close() async {
    isClosed = true;

    if (publisher != null) {
      final senders = await publisher?.pc.getSenders();
      for (final element in (senders ?? <RTCRtpSender>[])) {
        await publisher?.pc.removeTrack(element);
      }

      publisher?.pc.close();
      publisher = null;
    }
    if (subscriber != null) {
      subscriber?.pc.close();
      subscriber = null;
    }
    client.close();
  }

  Future<TrackInfo> addTrack(
      {required String cid,
      required String name,
      required TrackType kind,
      TrackDimension? dimension}) async {
    if (pendingTrackResolvers[cid] != null) {
      throw TrackPublishError(
          'a track with the same CID has already been published');
    }

    final completer = Completer<TrackInfo>();
    pendingTrackResolvers[cid] = completer;

    client.sendAddTrack(cid: cid, name: name, type: kind, dimension: dimension);

    return completer.future;
  }

  Future<void> negotiate({bool? iceRestart}) async {
    final pub = publisher;
    if (pub == null) {
      return;
    }

    final remoteDesc = await pub.getRemoteDescription();

    // handle cases that we couldn't create a new offer due to a pending answer
    // that's lost in transit
    if (remoteDesc != null &&
        pub.pc.signalingState ==
            RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      await pub.pc.setRemoteDescription(remoteDesc);
    }

    final constraints = <String, dynamic>{};
    if (iceRestart != null && iceRestart) {
      constraints['mandatory'] = {
        'IceRestart': true,
      };
    }
    final offer = await pub.pc.createOffer(constraints);
    await pub.pc.setLocalDescription(offer);
    client.sendOffer(offer);
  }

  Future<void> reconnect() async {
    if (isClosed) {
      return;
    }
    final url = this.url;
    final token = this.token;
    if (url == null || token == null) {
      throw ConnectError("could not reconnect without url and token");
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
    } catch (e) {
      isReconnecting = false;
      return Future.error(e);
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
    return Future.error(ConnectError('could not reconnect ICE'));
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
      client.sendIceCandidate(candidate, SignalTarget.PUBLISHER);
    };
    subPC.onIceCandidate = (RTCIceCandidate candidate) {
      client.sendIceCandidate(candidate, SignalTarget.SUBSCRIBER);
    };

    pubPC.onRenegotiationNeeded = () {
      if (pubPC.iceConnectionState == null ||
          pubPC.iceConnectionState ==
              RTCIceConnectionState.RTCIceConnectionStateNew) {
        return;
      }
      negotiate();
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
    reliableDC =
        await pubPC.createDataChannel(reliableDataChannel, reliableInit);

    lossyDC?.onMessage = _handleDataMessage;
    reliableDC?.onMessage = _handleDataMessage;
  }

  void _handleDataMessage(RTCDataChannelMessage message) {
    // always expect binary
    if (!message.isBinary) {
      return;
    }

    final dp = DataPacket.fromBuffer(message.binary);
    switch (dp.whichValue()) {
      case DataPacket_Value.speaker:
        onActiveSpeakerchangedCallback?.call(dp.speaker.speakers);
        break;
      case DataPacket_Value.user:
        onDataMessageCallback?.call(dp.user, dp.kind);
        break;
      default:
      // do nothing
    }
  }

  void _handleDisconnect(String reason) {
    if (isClosed) {
      return;
    }
    logger.fine('disconnected $reason');
    if (reconnectAttempts >= maxReconnectAttempts) {
      logger.info('could not connect after $reconnectAttempts, giving up');
      close();
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
  void onConnected(JoinResponse response) async {
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

    negotiate();

    joinCompleter?.complete(Future.value(response));
    joinCompleter = null;
  }

  @override
  void onClose([String? reason]) {
    _handleDisconnect("signal");
  }

  @override
  void onOffer(RTCSessionDescription sd) async {
    final sub = subscriber;
    if (sub == null) {
      return;
    }
    await sub.setRemoteDescription(sd);

    final answer = await sub.pc.createAnswer();
    await sub.pc.setLocalDescription(answer);
    client.sendAnswer(answer);
  }

  @override
  void onAnswer(RTCSessionDescription sd) {
    if (publisher == null) {
      return;
    }

    publisher?.setRemoteDescription(sd);
  }

  @override
  void onTrickle(RTCIceCandidate candidate, SignalTarget target) {
    if (target == SignalTarget.SUBSCRIBER) {
      subscriber?.addIceCandidate(candidate);
    } else if (target == SignalTarget.PUBLISHER) {
      publisher?.addIceCandidate(candidate);
    }
  }

  @override
  void onParticipantUpdate(List<ParticipantInfo> updates) {
    onParticipantUpdateCallback?.call(updates);
  }

  @override
  void onLocalTrackPublished(TrackPublishedResponse response) {
    final completer = pendingTrackResolvers.remove(response.cid);
    completer?.complete(Future.value(response.track));
  }

  @override
  void onActiveSpeakersChanged(List<SpeakerInfo> speakers) {
    onActiveSpeakerchangedCallback?.call(speakers);
  }

  @override
  void onLeave(LeaveRequest req) {
    close();
    onDisconnected?.call();
  }
}
