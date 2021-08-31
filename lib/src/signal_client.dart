import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

import 'errors.dart';
import 'logger.dart';
import 'options.dart';
import 'track/track.dart';
import 'version.dart';
import 'proto/livekit_models.pb.dart';
import 'proto/livekit_rtc.pb.dart';
import '_websocket_api.dart'
    if (dart.library.io) '_websocket_io.dart'
    if (dart.library.html) '_websocket_html.dart' as platform;

mixin SignalClientDelegate {
  // initial connection established
  void onConnected(JoinResponse response);
  // websocket has closed
  void onClose([String? reason]);
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
  SignalClientDelegate? delegate;

  bool _connected = false;
  WebSocketChannel? _ws;

  SignalClient();

  bool get connected => _connected;

  Future<void> join(String url, String token, JoinOptions? options) async {
    final rtcUrl = '$url/rtc';
    var params = _joinParams(token);
    if (options != null && options.autoSubscribe != null) {
      params += '&auto_subscribe=${options.autoSubscribe! ? '1' : '0'}';
    }

    try {
      final ws = await platform.connectToWebSocket(Uri.parse(rtcUrl + params));
      ws.stream.listen(_handleMessage, onError: _handleError, onDone: _handleDone);
      _ws = ws;
    } catch (e) {
      final completer = Completer<void>();
      final validateUri = Uri.parse('http${rtcUrl.substring(2)}/validate$params');
      http.get(validateUri).then((response) {
        if (response.statusCode != 200) {
          completer.completeError(ConnectError(response.body));
        } else {
          completer.completeError(ConnectError());
        }
      }).catchError((dynamic e) {
        completer.completeError(ConnectError());
      });

      return completer.future;
    }
  }

  Future<void> reconnect(String url, String token) async {
    _connected = false;
    _ws?.sink.close();
    _ws = null;

    url += '/rtc';
    var params = _joinParams(token);
    params += '&reconnect=1';
    final uri = Uri.parse(url + params);

    final ws = await platform.connectToWebSocket(uri);
    _ws = ws;
    _connected = true;
  }

  void close() {
    _connected = false;
    _ws?.sink.close();
  }

  void sendOffer(RTCSessionDescription offer) {
    _sendRequest(SignalRequest(
      offer: fromRTCSessionDescription(offer),
    ));
  }

  void sendAnswer(RTCSessionDescription answer) {
    _sendRequest(SignalRequest(
      answer: fromRTCSessionDescription(answer),
    ));
  }

  void sendIceCandidate(RTCIceCandidate candidate, SignalTarget target) {
    _sendRequest(SignalRequest(
        trickle: TrickleRequest(
      candidateInit: fromRTCIceCandidate(candidate),
      target: target,
    )));
  }

  void sendMuteTrack(String trackSid, bool muted) {
    _sendRequest(SignalRequest(
      mute: MuteTrackRequest(
        sid: trackSid,
        muted: muted,
      ),
    ));
  }

  void sendAddTrack(
      {required String cid,
      required String name,
      required TrackType type,
      TrackDimension? dimension}) {
    final req = AddTrackRequest(
      cid: cid,
      name: name,
      type: type,
    );
    if (dimension != null) {
      req.width = dimension.width;
      req.height = dimension.height;
    }
    _sendRequest(SignalRequest(
      addTrack: req,
    ));
  }

  void sendUpdateTrackSettings(UpdateTrackSettings settings) {
    _sendRequest(SignalRequest(
      trackSetting: settings,
    ));
  }

  void sendUpdateSubscription(UpdateSubscription subscription) {
    _sendRequest(SignalRequest(
      subscription: subscription,
    ));
  }

  void sendSetSimulcastLayers(String trackSid, List<VideoQuality> layers) {
    _sendRequest(SignalRequest(
        simulcast: SetSimulcastLayers(
      trackSid: trackSid,
      layers: layers,
    )));
  }

  void sendLeave() {
    _sendRequest(SignalRequest(
      leave: LeaveRequest(),
    ));
  }

  void _sendRequest(SignalRequest req) {
    if (_ws == null) {
      log('could not send message, not connected');
      return;
    }

    final buf = req.writeToBuffer();
    _ws?.sink.add(buf);
  }

  void _handleMessage(dynamic message) {
    if (message is! List<int>) {
      return;
    }
    final msg = SignalResponse.fromBuffer(message);
    switch (msg.whichMessage()) {
      case SignalResponse_Message.join:
        if (!_connected) {
          _connected = true;
          delegate?.onConnected(msg.join);
        }
        break;
      case SignalResponse_Message.answer:
        delegate?.onAnswer(toRTCSessionDescription(msg.answer));
        break;
      case SignalResponse_Message.offer:
        delegate?.onOffer(toRTCSessionDescription(msg.offer));
        break;
      case SignalResponse_Message.trickle:
        delegate?.onTrickle(toRTCIceCandidate(msg.trickle.candidateInit), msg.trickle.target);
        break;
      case SignalResponse_Message.update:
        delegate?.onParticipantUpdate(msg.update.participants);
        break;
      case SignalResponse_Message.trackPublished:
        delegate?.onLocalTrackPublished(msg.trackPublished);
        break;
      case SignalResponse_Message.speaker:
        delegate?.onActiveSpeakersChanged(msg.speaker.speakers);
        break;
      case SignalResponse_Message.leave:
        delegate?.onLeave(msg.leave);
        break;
      default:
        log('unsupported message: ' + json.encode(msg));
    }
  }

  void _handleError(Object error) {
    logger.warning('received websocket error $error');
  }

  void _handleDone() {
    if (!_connected) {
      return;
    }
    _ws = null;
    _connected = false;
    delegate?.onClose();
  }
}

String _joinParams(String token) {
  return '?access_token=$token&protocol=$protocolVersion';
}

RTCSessionDescription toRTCSessionDescription(SessionDescription sd) {
  return RTCSessionDescription(sd.sdp, sd.type);
}

SessionDescription fromRTCSessionDescription(RTCSessionDescription rsd) {
  return SessionDescription(type: rsd.type, sdp: rsd.sdp);
}

RTCIceCandidate toRTCIceCandidate(String candidateInit) {
  final candInit = json.decode(candidateInit) as Map<String, dynamic>;
  return RTCIceCandidate(
    candInit['candidate'] as String?,
    candInit['sdpMid'] as String?,
    candInit['sdpMLineIndex'] as int?,
  );
}

String fromRTCIceCandidate(RTCIceCandidate candidate) {
  return json.encode(candidate.toMap());
}
