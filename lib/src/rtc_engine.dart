import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'errors.dart';
import 'extensions.dart';
import 'proto/livekit_rtc.pb.dart';
import 'proto/livekit_models.pb.dart';
import 'signal_client.dart';
import 'track/track.dart';
import 'transport.dart';

const lossyDataChannel = '_lossy';
const reliableDataChannel = '_reliable';
final connectionTimeout = new Duration(seconds: 5);

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
  RTCConfiguration rtcConfig = new RTCConfiguration();
  // data channels for packets
  RTCDataChannel? reliableDC;
  RTCDataChannel? lossyDC;
  bool iceConnected = false;
  bool isClosed = true;
  Map<String, Completer<TrackInfo>> pendingTrackResolvers = {};
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
  GenericCallback? onDisconnected;

  RTCEngine(this.client, RTCConfiguration? rtcConfig) {
    if (rtcConfig != null) {
      this.rtcConfig = rtcConfig;
    }

    this.client.delegate = this;
  }

  Future<JoinResponse> join(String url, String token, JoinOptions? opts) {
    this.url = url;
    this.token = token;

    var completer = new Completer<JoinResponse>();
    joinCompleter = completer;

    client.join(url, token, opts);

    // if it's not complete after 5 seconds, fail
    new Timer(connectionTimeout, () {
      joinCompleter?.completeError(new ConnectError());
      joinCompleter = null;
    });

    return completer.future;
  }

  close() async {
    isClosed = true;

    if (publisher != null) {
      var senders = await publisher?.pc.getSenders();
      senders?.forEach((element) async {
        await publisher?.pc.removeTrack(element);
      });

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
      throw new TrackPublishError(
          'a track with the same CID has already been published');
    }

    var completer = new Completer<TrackInfo>();
    pendingTrackResolvers[cid] = completer;

    client.sendAddTrack(cid: cid, name: name, type: kind, dimension: dimension);

    return completer.future;
  }

  negotiate([Map<String, dynamic>? constraints]) async {
    var pub = this.publisher;
    if (pub == null) {
      return;
    }

    RTCSessionDescription? remoteDesc;
    if (pub.pc.iceConnectionState != null) {
      // when not initially connected, this crashes on iOS
      remoteDesc = await pub.pc.getRemoteDescription();
    }

    // handle cases that we couldn't create a new offer due to a pending answer
    // that's lost in transit
    if (remoteDesc != null &&
        pub.pc.signalingState ==
            RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      await pub.pc.setRemoteDescription(remoteDesc);
    }

    if (constraints == null) {
      constraints = {};
    }
    var offer = await pub.pc.createOffer(constraints);
    await pub.pc.setLocalDescription(offer);
    client.sendOffer(offer);
  }

  _configurePeerConnections() async {
    if (publisher != null) {
      return;
    }

    var pubPC = await createPeerConnection(rtcConfig.toMap());
    publisher = new PCTransport(pubPC);
    var subPC = await createPeerConnection(rtcConfig.toMap());
    subscriber = new PCTransport(subPC);

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
            onICEConnected?.call();
          }
          break;

        case RTCIceConnectionState.RTCIceConnectionStateFailed:
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
    var lossyInit = new RTCDataChannelInit()
      ..maxRetransmits = 1
      ..ordered = true
      ..binaryType = 'binary';
    lossyDC = await pubPC.createDataChannel(lossyDataChannel, lossyInit);

    var reliableInit = new RTCDataChannelInit()
      ..ordered = true
      ..maxRetransmits = 50
      ..binaryType = 'binary';
    reliableDC =
        await pubPC.createDataChannel(reliableDataChannel, reliableInit);

    lossyDC?.onMessage = _handleDataMessage;
    reliableDC?.onMessage = _handleDataMessage;
  }

  _handleDataMessage(RTCDataChannelMessage message) {
    // always expect binary
    if (!message.isBinary) {
      return;
    }

    var dp = DataPacket.fromBuffer(message.binary);
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

  _handleDisconnect(String reason) {
    // TODO: implement method
  }

  //------------------ SignalClient Delegate methods -------------------------//

  void onConnected(JoinResponse response) async {
    // create peer connections
    this.isClosed = false;

    if (rtcConfig.iceServers == null && response.iceServers.length > 0) {
      List<RTCIceServer> iceServers = [];
      response.iceServers.forEach((item) {
        var iceServer = new RTCIceServer(urls: item.urls);
        if (item.username.isNotEmpty) {
          iceServer.username = item.username;
        }
        if (item.credential.isNotEmpty) {
          iceServer.credential = item.credential;
        }
        iceServers.add(iceServer);
      });
      rtcConfig.iceServers = iceServers;
    }

    await _configurePeerConnections();

    negotiate();

    joinCompleter?.complete(Future.value(response));
    joinCompleter = null;
  }

  void onClose([String? reason]) {
    // TODO: handle reconnect when signal interrupted
  }

  void onOffer(RTCSessionDescription sd) async {
    var sub = subscriber;
    if (sub == null) {
      return;
    }
    await sub.setRemoteDescription(sd);

    var answer = await sub.pc.createAnswer();
    await sub.pc.setLocalDescription(answer);
    client.sendAnswer(answer);
  }

  void onAnswer(RTCSessionDescription sd) {
    if (publisher == null) {
      return;
    }

    publisher?.setRemoteDescription(sd);
  }

  void onTrickle(RTCIceCandidate candidate, SignalTarget target) {
    if (target == SignalTarget.SUBSCRIBER) {
      subscriber?.addIceCandidate(candidate);
    } else if (target == SignalTarget.PUBLISHER) {
      publisher?.addIceCandidate(candidate);
    }
  }

  void onParticipantUpdate(List<ParticipantInfo> updates) {
    onParticipantUpdateCallback?.call(updates);
  }

  void onLocalTrackPublished(TrackPublishedResponse response) {
    var completer = pendingTrackResolvers.remove(response.cid);
    completer?.complete(Future.value(response.track));
  }

  void onActiveSpeakersChanged(List<SpeakerInfo> speakers) {
    onActiveSpeakerchangedCallback?.call(speakers);
  }

  void onLeave(LeaveRequest req) {
    close();
    onDisconnected?.call();
  }
}
