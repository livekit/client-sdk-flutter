import 'package:http/http.dart' as http;

import '_websocket_api.dart'
    if (dart.library.io) '_websocket_io.dart'
    if (dart.library.html) '_websocket_html.dart' as platform;
import 'imports.dart';
import 'proto/livekit_models.pb.dart' as lk_models;
import 'proto/livekit_rtc.pb.dart' as lk_rtc;

mixin SignalClientDelegate {
  // initial connection established
  void onConnected(lk_rtc.JoinResponse response);
  // websocket has closed
  void onClose([String? reason]);
  // when a server offer is received
  void onOffer(RTCSessionDescription sd);
  // when an answer from server is received
  void onAnswer(RTCSessionDescription sd);
  // when server has a new ICE candidate
  void onTrickle(RTCIceCandidate candidate, lk_rtc.SignalTarget target);
  // participant has changed
  void onParticipantUpdate(List<lk_models.ParticipantInfo> updates);
  // when a track has been added successfully
  void onLocalTrackPublished(lk_rtc.TrackPublishedResponse response);
  // active speaker has changed
  void onActiveSpeakersChanged(List<lk_rtc.SpeakerInfo> speakers);
  // when server sends this client a leave message
  void onLeave(lk_rtc.LeaveRequest req);
}

class SignalClient {
  SignalClientDelegate? delegate;

  bool _connected = false;
  WebSocketChannel? _ws;

  SignalClient();

  bool get connected => _connected;

  Uri _buildUri(
    String uriString, {
    required String token,
    ConnectOptions? options,
    bool reconnect = false,
    bool validate = false,
  }) {
    final uri = Uri.parse(uriString);

    return uri.replace(
      //
      // It is possible to enforce WSS
      //
      scheme: validate ? 'http' : uri.scheme,
      path: validate ? 'validate' : 'rtc',
      queryParameters: <String, String>{
        'access_token': token,
        'protocol': protocolVersion.toString(),
        if (options != null) 'auto_subscribe': options.autoSubscribe ? '1' : '0',
        if (reconnect) 'reconnect': '1',
      },
    );
  }

  Future<void> join(
    String url,
    String token, {
    ConnectOptions? options,
  }) async {
    //
    // Create default options if null
    //
    options ??= const ConnectOptions();

    final uri = _buildUri(
      url,
      token: token,
      options: options,
    );

    try {
      final ws = await platform.connectToWebSocket(uri);
      ws.stream.listen(_handleMessage, onError: _handleError, onDone: _handleDone);
      _ws = ws;
    } catch (socketError) {
      //
      // Validate mode
      //
      final validateUri = _buildUri(
        url,
        token: token,
        options: options,
        validate: true,
      );

      //
      // Attempt Validation
      //
      try {
        final validateResponse = await http.get(validateUri);
        if (validateResponse.statusCode != 200) {
          throw ConnectError(validateResponse.body);
        } else {
          throw ConnectError();
        }
      } catch (httpError) {
        //
        // HTTP doesn't work either
        //
        throw ConnectError();
      }
    }
  }

  Future<void> reconnect(String url, String token) async {
    _connected = false;
    _ws?.sink.close();
    _ws = null;

    final uri = _buildUri(
      url,
      token: token,
      reconnect: true,
    );

    final ws = await platform.connectToWebSocket(uri);
    _ws = ws;
    _connected = true;
  }

  void close() {
    _connected = false;
    _ws?.sink.close();
  }

  void sendOffer(RTCSessionDescription offer) {
    _sendRequest(lk_rtc.SignalRequest(
      offer: fromRTCSessionDescription(offer),
    ));
  }

  void sendAnswer(RTCSessionDescription answer) {
    _sendRequest(lk_rtc.SignalRequest(
      answer: fromRTCSessionDescription(answer),
    ));
  }

  void sendIceCandidate(RTCIceCandidate candidate, lk_rtc.SignalTarget target) {
    _sendRequest(lk_rtc.SignalRequest(
        trickle: lk_rtc.TrickleRequest(
      candidateInit: fromRTCIceCandidate(candidate),
      target: target,
    )));
  }

  void sendMuteTrack(String trackSid, bool muted) {
    _sendRequest(lk_rtc.SignalRequest(
      mute: lk_rtc.MuteTrackRequest(
        sid: trackSid,
        muted: muted,
      ),
    ));
  }

  void sendAddTrack(
      {required String cid,
      required String name,
      required lk_models.TrackType type,
      TrackDimension? dimension}) {
    final req = lk_rtc.AddTrackRequest(
      cid: cid,
      name: name,
      type: type,
    );
    if (dimension != null) {
      req.width = dimension.width;
      req.height = dimension.height;
    }
    _sendRequest(lk_rtc.SignalRequest(
      addTrack: req,
    ));
  }

  void sendUpdateTrackSettings(lk_rtc.UpdateTrackSettings settings) {
    _sendRequest(lk_rtc.SignalRequest(
      trackSetting: settings,
    ));
  }

  void sendUpdateSubscription(lk_rtc.UpdateSubscription subscription) {
    _sendRequest(lk_rtc.SignalRequest(
      subscription: subscription,
    ));
  }

  void sendSetSimulcastLayers(String trackSid, List<lk_rtc.VideoQuality> layers) {
    _sendRequest(lk_rtc.SignalRequest(
        simulcast: lk_rtc.SetSimulcastLayers(
      trackSid: trackSid,
      layers: layers,
    )));
  }

  void sendLeave() {
    _sendRequest(lk_rtc.SignalRequest(
      leave: lk_rtc.LeaveRequest(),
    ));
  }

  void _sendRequest(lk_rtc.SignalRequest req) {
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
    final msg = lk_rtc.SignalResponse.fromBuffer(message);
    switch (msg.whichMessage()) {
      case lk_rtc.SignalResponse_Message.join:
        if (!_connected) {
          _connected = true;
          delegate?.onConnected(msg.join);
        }
        break;
      case lk_rtc.SignalResponse_Message.answer:
        delegate?.onAnswer(toRTCSessionDescription(msg.answer));
        break;
      case lk_rtc.SignalResponse_Message.offer:
        delegate?.onOffer(toRTCSessionDescription(msg.offer));
        break;
      case lk_rtc.SignalResponse_Message.trickle:
        delegate?.onTrickle(toRTCIceCandidate(msg.trickle.candidateInit), msg.trickle.target);
        break;
      case lk_rtc.SignalResponse_Message.update:
        delegate?.onParticipantUpdate(msg.update.participants);
        break;
      case lk_rtc.SignalResponse_Message.trackPublished:
        delegate?.onLocalTrackPublished(msg.trackPublished);
        break;
      case lk_rtc.SignalResponse_Message.speaker:
        delegate?.onActiveSpeakersChanged(msg.speaker.speakers);
        break;
      case lk_rtc.SignalResponse_Message.leave:
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

RTCSessionDescription toRTCSessionDescription(lk_rtc.SessionDescription sd) {
  return RTCSessionDescription(sd.sdp, sd.type);
}

lk_rtc.SessionDescription fromRTCSessionDescription(RTCSessionDescription rsd) {
  return lk_rtc.SessionDescription(type: rsd.type, sdp: rsd.sdp);
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
