import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import './track/track.dart';
import './version.dart';
import './proto/livekit_models.pb.dart';
import './proto/livekit_rtc.pb.dart';

class JoinOptions {
  final bool? autoSubscribe;

  const JoinOptions({this.autoSubscribe});
}

mixin SignalClientDelegate {
  // initial connection established
  void onConnected(JoinResponse response);
  // websocket has closed
  void onClose(String? reason);
  // when a server offer is received
  void onOffer(RTCSessionDescription sd);
  // when an answer from server is received
  void onAnswer(RTCSessionDescription sd);
  // when server has a new ICE candidate
  void onTrickle(RTCIceCandidate candidate, SignalTarget target);
  // participant has changed
  void onParticipantUpdate(List<ParticipantInfo> updates);
  // when a track has been added successfully
  void onLocalTrackPublished(TrackPublishedResponse response);
  // active speaker has changed
  void onActiveSpeakersChanged(List<SpeakerInfo> speakers);
  // when server sends this client a leave message
  void onLeave(LeaveRequest req);
}

class SignalClient {
  SignalClientDelegate delegate;

  bool _connected = false;
  WebSocketChannel? _ws;

  SignalClient(this.delegate);

  bool get connected => this._connected;

  join(String url, String token, JoinOptions options) {
    url += '/rtc';
    var params = _paramsForToken(token);
    if (options.autoSubscribe != null) {
      params += '&auto_subscribe=${options.autoSubscribe! ? '1' : '0'}';
    }
    var uri = Uri.parse(url + params);

    try {
      var ws = WebSocketChannel.connect(uri);
      ws.stream
          .listen(_handleMessage, onError: _handleError, onDone: _handleDone);
      _ws = ws;
    } catch (e) {
      // failed before error handler is installed, fail immediately
    }
  }

  Future<void> reconnect(String url, String token) async {}

  close() {
    this._connected = false;
    this._ws?.sink.close();
  }

  sendOffer(RTCSessionDescription offer) {
    this._sendRequest(new SignalRequest(
      offer: fromRTCSessionDescription(offer),
    ));
  }

  sendAnswer(RTCSessionDescription answer) {
    this._sendRequest(new SignalRequest(
      answer: fromRTCSessionDescription(answer),
    ));
  }

  sendIceCandidate(RTCIceCandidate candidate, SignalTarget target) {
    this._sendRequest(new SignalRequest(
        trickle: new TrickleRequest(
      candidateInit: fromRTCIceCandidate(candidate),
      target: target,
    )));
  }

  sendMuteTrack(String trackSid, bool muted) {
    this._sendRequest(new SignalRequest(
      mute: new MuteTrackRequest(
        sid: trackSid,
        muted: muted,
      ),
    ));
  }

  sendAddTrack(
      {required String cid,
      required String name,
      required TrackType type,
      TrackDimension? dimension}) {
    var req = new AddTrackRequest(
      cid: cid,
      name: name,
      type: type,
    );
    if (dimension != null) {
      req.width = dimension.width;
      req.height = dimension.height;
    }
    this._sendRequest(new SignalRequest(
      addTrack: req,
    ));
  }

  sendUpdateTrackSettings(UpdateTrackSettings settings) {
    this._sendRequest(new SignalRequest(
      trackSetting: settings,
    ));
  }

  sendUpdateSubscription(UpdateSubscription subscription) {
    this._sendRequest(new SignalRequest(
      subscription: subscription,
    ));
  }

  sendSetSimulcastLayers(String trackSid, List<VideoQuality> layers) {
    this._sendRequest(new SignalRequest(
        simulcast: new SetSimulcastLayers(
      trackSid: trackSid,
      layers: layers,
    )));
  }

  sendLeave() {
    this._sendRequest(new SignalRequest(
      leave: new LeaveRequest(),
    ));
  }

  _sendRequest(SignalRequest req) {
    if (this._ws == null) {
      log('could not send message, not connected: ' + jsonEncode(req));
      return;
    }

    var buf = req.writeToBuffer();
    this._ws?.sink.add(buf);
  }

  _handleMessage(dynamic message) {
    if (!(message is List<int>)) {
      return;
    }
    var msg = SignalResponse.fromBuffer(message);
    switch (msg.whichMessage()) {
      case SignalResponse_Message.join:
        if (!_connected) {
          _connected = true;
          delegate.onConnected(msg.join);
        }
        break;
      case SignalResponse_Message.answer:
        delegate.onAnswer(toRTCSessionDescription(msg.answer));
        break;
      case SignalResponse_Message.offer:
        delegate.onOffer(toRTCSessionDescription(msg.offer));
        break;
      case SignalResponse_Message.trickle:
        delegate.onTrickle(toRTCIceCandidate(msg.trickle), msg.trickle.target);
        break;
      case SignalResponse_Message.update:
        delegate.onParticipantUpdate(msg.update.participants);
        break;
      case SignalResponse_Message.trackPublished:
        delegate.onLocalTrackPublished(msg.trackPublished);
        break;
      case SignalResponse_Message.speaker:
        delegate.onActiveSpeakersChanged(msg.speaker.speakers);
        break;
      case SignalResponse_Message.leave:
        delegate.onLeave(msg.leave);
        break;
      default:
        log('unsupported message: ' + jsonEncode(msg));
    }
  }

  _handleError(Object error) {
    // TODO: test HTTP endpoint
  }

  _handleDone() {
    _ws = null;
  }
}

String _paramsForToken(String token) {
  return '?access_token=$token&protocol=$protocolVersion';
}

RTCSessionDescription toRTCSessionDescription(SessionDescription sd) {
  return new RTCSessionDescription(sd.sdp, sd.type);
}

SessionDescription fromRTCSessionDescription(RTCSessionDescription rsd) {
  return new SessionDescription(type: rsd.type, sdp: rsd.sdp);
}

RTCIceCandidate toRTCIceCandidate(String candidateInit) {
  var candInit = jsonDecode(candidateInit);
  return new RTCIceCandidate(
      candInit['candidate'], candInit['sdpMid'], candInit['sdpMLineIndex']);
}

String fromRTCIceCandidate(RTCIceCandidate candidate) {
  return jsonEncode(candidate.toMap());
}
