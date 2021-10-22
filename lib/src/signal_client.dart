import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:http/http.dart' as http;

import 'events.dart';
import 'exceptions.dart';
import 'extensions.dart';
import 'logger.dart';
import 'managers/event.dart';
import 'options.dart';
import 'proto/livekit_models.pb.dart' as lk_models;
import 'proto/livekit_rtc.pb.dart' as lk_rtc;
import 'support/disposable.dart';
import 'support/websocket.dart';
import 'types.dart';
import 'utils.dart';

class SignalClient extends Disposable with EventsEmittable<SignalEvent> {
  //
  final ProtocolVersion protocol;

  bool _connected = false;
  LiveKitWebSocket? _ws;

  SignalClient({
    this.protocol = ProtocolVersion.protocol3,
  }) {
    events.listen((event) {
      logger.fine('[SignalEvent] $event');
    });

    onDispose(() async {
      await events.dispose();
      await close();
    });
  }

  bool get connected => _connected;

  Future<void> connect(
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
        WebSocketEventHandlers(
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
        if (validateResponse.statusCode != 200) {
          throw ConnectException(validateResponse.body);
        }
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
    await _ws?.dispose();
    _ws = null;

    final rtcUri = Utils.buildUri(
      uriString,
      token: token,
      reconnect: true,
      protocol: protocol,
    );

    _ws = await LiveKitWebSocket.connect(
      rtcUri,
      WebSocketEventHandlers(
        onData: _onSocketData,
        onDispose: _onSocketDone,
        onError: _handleError,
      ),
    );

    _connected = true;
  }

  Future<void> close() async {
    _connected = false;
    await _ws?.dispose();
  }

  void sendOffer(rtc.RTCSessionDescription offer) =>
      _sendRequest(lk_rtc.SignalRequest(
        offer: offer.toSDKType(),
      ));

  void sendAnswer(rtc.RTCSessionDescription answer) =>
      _sendRequest(lk_rtc.SignalRequest(
        answer: answer.toSDKType(),
      ));

  void sendIceCandidate(
          rtc.RTCIceCandidate candidate, lk_rtc.SignalTarget target) =>
      _sendRequest(
        lk_rtc.SignalRequest(
          trickle: lk_rtc.TrickleRequest(
            candidateInit: candidate.toJson(),
            target: target,
          ),
        ),
      );

  void sendMuteTrack(String trackSid, bool muted) =>
      _sendRequest(lk_rtc.SignalRequest(
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

  // void sendSetSimulcastLayers(
  //         String trackSid, List<lk_rtc.VideoQuality> layers) =>
  //     _sendRequest(lk_rtc.SignalRequest(
  //       simulcast: lk_rtc.SetSimulcastLayers(
  //         trackSid: trackSid,
  //         layers: layers,
  //       ),
  //     ));

  void sendLeave() => _sendRequest(lk_rtc.SignalRequest(
        leave: lk_rtc.LeaveRequest(),
      ));

  void _sendRequest(lk_rtc.SignalRequest req) {
    if (_ws == null || isDisposed) {
      logger.warning(
          '[$objectId] Could not send message, not connected or already disposed');
      return;
    }

    final buf = req.writeToBuffer();
    _ws?.send(buf);
  }

  Future<void> _onSocketData(dynamic message) async {
    if (message is! List<int>) return;
    final msg = lk_rtc.SignalResponse.fromBuffer(message);

    switch (msg.whichMessage()) {
      case lk_rtc.SignalResponse_Message.join:
        if (!_connected) {
          _connected = true;
          events.emit(SignalConnectedEvent(response: msg.join));
        }
        break;
      case lk_rtc.SignalResponse_Message.answer:
        events.emit(SignalAnswerEvent(sd: msg.answer.toSDKType()));
        break;
      case lk_rtc.SignalResponse_Message.offer:
        events.emit(SignalOfferEvent(sd: msg.offer.toSDKType()));
        break;
      case lk_rtc.SignalResponse_Message.trickle:
        events.emit(SignalTrickleEvent(
          candidate: RTCIceCandidateExt.fromJson(msg.trickle.candidateInit),
          target: msg.trickle.target,
        ));
        break;
      case lk_rtc.SignalResponse_Message.update:
        events.emit(SignalParticipantUpdateEvent(
            participants: msg.update.participants));
        break;
      case lk_rtc.SignalResponse_Message.trackPublished:
        events.emit(SignalLocalTrackPublishedEvent(
          cid: msg.trackPublished.cid,
          track: msg.trackPublished.track,
        ));
        break;
      case lk_rtc.SignalResponse_Message.speakersChanged:
        events.emit(
            SignalSpeakersChangedEvent(speakers: msg.speakersChanged.speakers));
        break;
      case lk_rtc.SignalResponse_Message.leave:
        events.emit(SignalLeaveEvent(canReconnect: msg.leave.canReconnect));
        break;
      case lk_rtc.SignalResponse_Message.mute:
        events.emit(SignalMuteTrackEvent(
          sid: msg.mute.sid,
          muted: msg.mute.muted,
        ));
        break;
      default:
        logger.warning('skipping unsupported signal message');
    }
  }

  void _handleError(dynamic error) {
    logger.warning('received websocket error $error');
  }

  void _onSocketDone() {
    if (!_connected) return;
    _ws = null;
    _connected = false;
    events.emit(const SignalCloseEvent());
  }
}
