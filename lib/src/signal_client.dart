import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/src/ws/interface.dart';
import 'package:synchronized/synchronized.dart' as sync;

import 'errors.dart';
import 'logger.dart';
import 'options.dart';
import 'proto/livekit_models.pb.dart' as lk_models;
import 'proto/livekit_rtc.pb.dart' as lk_rtc;
import 'track/track.dart';

mixin SignalClientDelegate {
  // initial connection established
  Future<void> onConnected(lk_rtc.JoinResponse response);
  // websocket has closed
  Future<void> onClose([String? reason]);
  // when a server offer is received
  Future<void> onOffer(RTCSessionDescription sd);
  // when an answer from server is received
  Future<void> onAnswer(RTCSessionDescription sd);
  // when server has a new ICE candidate
  Future<void> onTrickle(RTCIceCandidate candidate, lk_rtc.SignalTarget target);
  // participant has changed
  Future<void> onParticipantUpdate(List<lk_models.ParticipantInfo> updates);
  // when a track has been added successfully
  Future<void> onLocalTrackPublished(lk_rtc.TrackPublishedResponse response);
  // active speaker has changed
  Future<void> onActiveSpeakersChanged(List<lk_models.SpeakerInfo> speakers);
  // when server sends this client a leave message
  Future<void> onLeave(lk_rtc.LeaveRequest req);
  // explicit mute track
  Future<void> onMuteTrack(lk_rtc.MuteTrackRequest req);
}

extension LKUriExt on Uri {
  bool get isSecureScheme => ['https', 'wss'].contains(scheme);
}

class SignalClient {
  static const protocolVersion = 2;

  SignalClientDelegate? delegate;

  bool _connected = false;
  LKWebSocket? _ws;
  final lock = sync.Lock();

  SignalClient();

  bool get connected => _connected;

  Uri _buildUri(
    String uriOrString, {
    required String token,
    ConnectOptions? options,
    bool reconnect = false,
    bool validate = false,
    bool forceSecure = false,
  }) {
    final Uri uri = Uri.parse(uriOrString);

    final useSecure = uri.isSecureScheme || forceSecure;
    final httpScheme = useSecure ? 'https' : 'http';
    final wsScheme = useSecure ? 'wss' : 'ws';

    return uri.replace(
      scheme: validate ? httpScheme : wsScheme,
      path: validate ? 'validate' : 'rtc',
      queryParameters: <String, String>{
        'access_token': token,
        if (options != null) 'auto_subscribe': options.autoSubscribe ? '1' : '0',
        if (reconnect) 'reconnect': '1',
        'protocol': protocolVersion.toString(),
      },
    );
  }

  Future<void> join(
    String uriString,
    String token, {
    ConnectOptions? options,
  }) async {
    //
    // Create default options if null
    //
    options ??= const ConnectOptions();

    final rtcUri = _buildUri(
      uriString,
      token: token,
      options: options,
    );

    try {
      _ws = await LKWebSocket.connect(
        rtcUri,
        LKWebSocketOptions(
          onData: _handleMessage,
          onDispose: _onSocketDone,
        ),
      );
      // _ws = WebSocketChannel.connect(rtcUri);
      // logger.fine('SignalClient did join');
// _ws?.stream.
      // _ws?.stream.listen(
      //   _handleMessage,
      //   onError: _handleError,
      //   onDone: _onSocketDone,
      // );

      // _ws = ws;
    } catch (socketError) {
      //
      // Re-build same uri for validate mode
      //
      final validateUri = _buildUri(
        uriString,
        token: token,
        options: options,
        validate: true,
        forceSecure: rtcUri.isSecureScheme,
      );

      //
      // Attempt Validation
      //
      try {
        final validateResponse = await http.get(validateUri);
        if (validateResponse.statusCode != 200) throw ConnectError(validateResponse.body);
        throw ConnectError();
      } catch (error) {
        //
        // Pass it up if it's already a `ConnectError`
        //
        if (error is ConnectError) rethrow;
        //
        // HTTP doesn't work either
        //
        throw ConnectError();
      }
    }
  }

  Future<void> reconnect(
    String uriString,
    String token,
  ) async {
    _connected = false;
    _ws?.dispose();
    _ws = null;

    final rtcUri = _buildUri(
      uriString,
      token: token,
      reconnect: true,
    );

    _ws = await LKWebSocket.connect(
      rtcUri,
      LKWebSocketOptions(
        onData: _handleMessage,
        onDispose: _onSocketDone,
      ),
    );

    _connected = true;
  }

  void close() {
    _connected = false;
    _ws?.dispose();
  }

  void sendOffer(RTCSessionDescription offer) => _sendRequest(lk_rtc.SignalRequest(
        offer: fromRTCSessionDescription(offer),
      ));

  void sendAnswer(RTCSessionDescription answer) => _sendRequest(lk_rtc.SignalRequest(
        answer: fromRTCSessionDescription(answer),
      ));

  void sendIceCandidate(RTCIceCandidate candidate, lk_rtc.SignalTarget target) => _sendRequest(
        lk_rtc.SignalRequest(
          trickle: lk_rtc.TrickleRequest(
            candidateInit: fromRTCIceCandidate(candidate),
            target: target,
          ),
        ),
      );

  void sendMuteTrack(String trackSid, bool muted) => _sendRequest(lk_rtc.SignalRequest(
        mute: lk_rtc.MuteTrackRequest(
          sid: trackSid,
          muted: muted,
        ),
      ));

  void sendAddTrack({
    required String cid,
    required String name,
    required lk_models.TrackType type,
    TrackDimension? dimension,
  }) {
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

  void sendUpdateTrackSettings(lk_rtc.UpdateTrackSettings settings) =>
      _sendRequest(lk_rtc.SignalRequest(
        trackSetting: settings,
      ));

  void sendUpdateSubscription(lk_rtc.UpdateSubscription subscription) =>
      _sendRequest(lk_rtc.SignalRequest(
        subscription: subscription,
      ));

  void sendSetSimulcastLayers(String trackSid, List<lk_rtc.VideoQuality> layers) =>
      _sendRequest(lk_rtc.SignalRequest(
        simulcast: lk_rtc.SetSimulcastLayers(
          trackSid: trackSid,
          layers: layers,
        ),
      ));

  void sendLeave() => _sendRequest(lk_rtc.SignalRequest(
        leave: lk_rtc.LeaveRequest(),
      ));

  void _sendRequest(lk_rtc.SignalRequest req) {
    if (_ws == null) {
      log('could not send message, not connected');
      return;
    }

    final buf = req.writeToBuffer();
    _ws?.send(buf);
  }

  Future<void> _handleMessage(dynamic message) async {
    if (message is! List<int>) return;
    final msg = lk_rtc.SignalResponse.fromBuffer(message);

    await lock.synchronized(() async {
      //
      // Only fire events 1 by 1 (wait for previous async to finish)
      // This will prevent unintended bugs since websocket
      // may receive data while previous delegate handler is not finished
      //
      switch (msg.whichMessage()) {
        case lk_rtc.SignalResponse_Message.join:
          if (!_connected) {
            _connected = true;
            await delegate?.onConnected(msg.join);
          }
          break;
        case lk_rtc.SignalResponse_Message.answer:
          await delegate?.onAnswer(toRTCSessionDescription(msg.answer));
          break;
        case lk_rtc.SignalResponse_Message.offer:
          await delegate?.onOffer(toRTCSessionDescription(msg.offer));
          break;
        case lk_rtc.SignalResponse_Message.trickle:
          await delegate?.onTrickle(
            toRTCIceCandidate(msg.trickle.candidateInit),
            msg.trickle.target,
          );
          break;
        case lk_rtc.SignalResponse_Message.update:
          await delegate?.onParticipantUpdate(msg.update.participants);
          break;
        case lk_rtc.SignalResponse_Message.trackPublished:
          await delegate?.onLocalTrackPublished(msg.trackPublished);
          break;
        case lk_rtc.SignalResponse_Message.speaker:
          await delegate?.onActiveSpeakersChanged(msg.speaker.speakers);
          break;
        case lk_rtc.SignalResponse_Message.leave:
          await delegate?.onLeave(msg.leave);
          break;
        case lk_rtc.SignalResponse_Message.mute:
          await delegate?.onMuteTrack(msg.mute);
          break;
        default:
          log('unsupported message: ' + json.encode(msg));
      }
    });
  }

  void _handleError(Object error) {
    logger.warning('received websocket error $error');
  }

  void _onSocketDone() {
    if (!_connected) return;
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
