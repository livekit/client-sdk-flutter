import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:http/http.dart' as http;

import '../events.dart';
import '../exceptions.dart';
import '../extensions.dart';
import '../internal/events.dart';
import '../logger.dart';
import '../managers/event.dart';
import '../options.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../support/disposable.dart';
import '../support/websocket.dart';
import '../types.dart';
import '../utils.dart';

class SignalClient extends Disposable with EventsEmittable<SignalEvent> {
  // Connection state of the socket conection.
  ConnectionState _connectionState = ConnectionState.disconnected;

  LiveKitWebSocket? _ws;

  SignalClient() {
    events.listen((event) {
      logger.fine('[SignalEvent] $event');
    });

    onDispose(() async {
      await events.dispose();
      await close();
    });
  }

  Future<void> connect(
    String uriString,
    String token, {
    ConnectOptions? connectOptions,
  }) async {
    final rtcUri = Utils.buildUri(
      uriString,
      token: token,
      connectOptions: connectOptions,
    );

    try {
      _ws = await LiveKitWebSocket.connect(
        rtcUri,
        WebSocketEventHandlers(
          onData: _onSocketData,
          onDispose: _onSocketDispose,
          onError: _handleError,
        ),
      );
    } catch (socketError) {
      // Re-build same uri for validate mode
      final validateUri = Utils.buildUri(
        uriString,
        token: token,
        connectOptions: connectOptions,
        validate: true,
        forceSecure: rtcUri.isSecureScheme,
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
    String token, {
    ConnectOptions? connectOptions,
  }) async {
    logger.fine('SignalClient reconnecting...');
    _connectionState = ConnectionState.reconnecting;
    await _ws?.dispose();
    _ws = null;

    final rtcUri = Utils.buildUri(
      uriString,
      token: token,
      reconnect: true,
      connectOptions: connectOptions,
    );

    _ws = await LiveKitWebSocket.connect(
      rtcUri,
      WebSocketEventHandlers(
        onData: _onSocketData,
        onDispose: _onSocketDispose,
        onError: _handleError,
      ),
    );

    logger.fine('SignalClient socket reconnected');
    _connectionState = ConnectionState.connected;
  }

  Future<void> close() async {
    logger.fine('SignalClient close');
    await _ws?.dispose();
    _ws = null;
  }

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
        events.emit(SignalConnectedEvent(response: msg.join));
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
      case lk_rtc.SignalResponse_Message.connectionQuality:
        events.emit(SignalConnectionQualityUpdateEvent(
          updates: msg.connectionQuality.updates,
        ));
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
      case lk_rtc.SignalResponse_Message.streamStateUpdate:
        events.emit(SignalStreamStateUpdatedEvent(
          updates: msg.streamStateUpdate.streamStates,
        ));
        break;
      default:
        logger.warning('skipping unsupported signal message');
    }
  }

  void _handleError(dynamic error) {
    logger.warning('received websocket error $error');
  }

  void _onSocketDispose() {
    logger.fine('SignalClient onSocketDispose $_connectionState');
    // don't emit event's when reconnecting state
    if (_connectionState != ConnectionState.reconnecting) {
      logger.fine('SignalClient did disconnect ${_connectionState}');
      _connectionState = ConnectionState.disconnected;
      events.emit(const SignalCloseEvent());
    }
  }
}

extension SignalClientRequests on SignalClient {
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
    required lk_models.TrackSource source,
    VideoDimensions? dimensions,
    bool? dtx,
    List<lk_models.VideoLayer>? videoLayers,
  }) {
    final req = lk_rtc.AddTrackRequest(
      cid: cid,
      name: name,
      type: type,
      source: source,
    );

    if (type == lk_models.TrackType.VIDEO) {
      // video specific
      if (dimensions != null) {
        req.width = dimensions.width;
        req.height = dimensions.height;
      }
      if (videoLayers != null && videoLayers.isNotEmpty) {
        req.layers
          ..clear()
          ..addAll(videoLayers);
      }
    }

    if (type == lk_models.TrackType.AUDIO && dtx != null) {
      // audio specific
      req.disableDtx = !dtx;
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

  void sendUpdateVideoLayers(
    String trackSid,
    List<lk_models.VideoLayer> layers,
  ) =>
      _sendRequest(lk_rtc.SignalRequest(
        updateLayers: lk_rtc.UpdateVideoLayers(
          trackSid: trackSid,
          layers: layers,
        ),
      ));

  void sendLeave() => _sendRequest(lk_rtc.SignalRequest(
        leave: lk_rtc.LeaveRequest(),
      ));
}
