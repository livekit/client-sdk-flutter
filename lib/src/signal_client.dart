import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:http/http.dart' as http;
import 'package:livekit_client/src/ws/interface.dart';
import 'package:synchronized/synchronized.dart' as sync;

import 'errors.dart';
import 'logger.dart';
import 'extensions.dart';
import 'options.dart';
import 'proto/livekit_models.pb.dart' as lk_models;
import 'proto/livekit_rtc.pb.dart' as lk_rtc;
import 'track/track.dart';
import 'utils.dart';

mixin SignalClientDelegate {
  // initial connection established
  Future<void> onConnected(lk_rtc.JoinResponse response);
  // websocket has closed
  Future<void> onClose([String? reason]);
  // when a server offer is received
  Future<void> onOffer(rtc.RTCSessionDescription sd);
  // when an answer from server is received
  Future<void> onAnswer(rtc.RTCSessionDescription sd);
  // when server has a new ICE candidate
  Future<void> onTrickle(rtc.RTCIceCandidate candidate, lk_rtc.SignalTarget target);
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

class SignalClient {
  final _lock = sync.Lock();

  ProtocolVersion protocol;
  SignalClientDelegate? delegate;
  bool _connected = false;
  LiveKitWebSocket? _ws;

  SignalClient({
    this.protocol = ProtocolVersion.protocol3,
  });

  bool get connected => _connected;

  Future<void> join(
    String uriString,
    String token, {
    ConnectOptions? options,
  }) async {
    // Create default options if null
    options ??= const ConnectOptions();

    final rtcUri = Utils.buildUri(
      uriString,
      token: token,
      options: options,
      protocol: protocol,
    );

    try {
      _ws = await LiveKitWebSocket.connect(
        rtcUri,
        WebSocketOptions(
          onData: _onSocketData,
          onDispose: _onSocketDone,
          onError: _handleError,
        ),
      );
    } catch (socketError) {
      // Re-build same uri for validate mode
      final validateUri = Utils.buildUri(
        uriString,
        token: token,
        options: options,
        validate: true,
        forceSecure: rtcUri.isSecureScheme,
        protocol: protocol,
      );

      // Attempt Validation
      try {
        final validateResponse = await http.get(validateUri);
        if (validateResponse.statusCode != 200) throw ConnectException(validateResponse.body);
        throw ConnectException();
      } catch (error) {
        // Pass it up if it's already a `ConnectError`
        if (error is ConnectException) rethrow;
        // HTTP doesn't work either
        throw ConnectException();
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

    final rtcUri = Utils.buildUri(
      uriString,
      token: token,
      reconnect: true,
      protocol: protocol,
    );

    _ws = await LiveKitWebSocket.connect(
      rtcUri,
      WebSocketOptions(
        onData: _onSocketData,
        onDispose: _onSocketDone,
        onError: _handleError,
      ),
    );

    _connected = true;
  }

  void close() {
    _connected = false;
    _ws?.dispose();
  }

  void sendOffer(rtc.RTCSessionDescription offer) => _sendRequest(lk_rtc.SignalRequest(
        offer: offer.toSDKType(),
      ));

  void sendAnswer(rtc.RTCSessionDescription answer) => _sendRequest(lk_rtc.SignalRequest(
        answer: answer.toSDKType(),
      ));

  void sendIceCandidate(rtc.RTCIceCandidate candidate, lk_rtc.SignalTarget target) => _sendRequest(
        lk_rtc.SignalRequest(
          trickle: lk_rtc.TrickleRequest(
            candidateInit: candidate.toJson(),
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

  Future<void> _onSocketData(dynamic message) async {
    if (message is! List<int>) return;
    final msg = lk_rtc.SignalResponse.fromBuffer(message);

    // Ensure previous delegate method's future is completed
    // before calling another method
    await _lock.synchronized(() async {
      //
      switch (msg.whichMessage()) {
        case lk_rtc.SignalResponse_Message.join:
          if (!_connected) {
            _connected = true;
            await delegate?.onConnected(msg.join);
          }
          break;
        case lk_rtc.SignalResponse_Message.answer:
          await delegate?.onAnswer(msg.answer.toSDKType());
          break;
        case lk_rtc.SignalResponse_Message.offer:
          await delegate?.onOffer(msg.offer.toSDKType());
          break;
        case lk_rtc.SignalResponse_Message.trickle:
          await delegate?.onTrickle(
            RTCIceCandidateExt.fromJson(msg.trickle.candidateInit),
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

  void _handleError(dynamic error) {
    logger.warning('received websocket error $error');
  }

  void _onSocketDone() {
    if (!_connected) return;
    _ws = null;
    _connected = false;
    delegate?.onClose();
  }
}
