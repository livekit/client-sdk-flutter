// Copyright 2024 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

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
import '../support/platform.dart';
import '../support/websocket.dart';
import '../types/other.dart';
import '../utils.dart';

class SignalClient extends Disposable with EventsEmittable<SignalEvent> {
  ConnectionState _connectionState = ConnectionState.disconnected;
  ConnectionState get connectionState => _connectionState;

  final WebSocketConnector _wsConnector;
  LiveKitWebSocket? _ws;

  final _queue = Queue<lk_rtc.SignalRequest>();
  Duration? _pingTimeoutDuration;
  Timer? _pingTimeoutTimer;

  Duration? _pingIntervalDuration;
  Timer? _pingIntervalTimer;

  int get pingCount => _pingCount;

  int _pingCount = 0;
  String? participantSid;

  List<ConnectivityResult> _connectivityResult = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  Future<bool> networkIsAvailable() async {
    // Skip check for web or flutter test
    if (kIsWeb || lkPlatformIsTest()) {
      return true;
    }
    _connectivityResult = await Connectivity().checkConnectivity();
    return _connectivityResult.isNotEmpty &&
        !_connectivityResult.contains(ConnectivityResult.none);
  }

  @internal
  SignalClient(WebSocketConnector wsConnector) : _wsConnector = wsConnector {
    events.listen((event) {
      logger.fine('[SignalEvent] $event');
    });

    onDispose(() async {
      await cleanUp();
      await events.cancelAll();
      await events.dispose();
      if (!kIsWeb && !lkPlatformIsTest()) {
        await _connectivitySubscription?.cancel();
        _connectivitySubscription = null;
      }
    });
  }

  @internal
  Future<void> connect(
    String uriString,
    String token, {
    required ConnectOptions connectOptions,
    required RoomOptions roomOptions,
    bool reconnect = false,
  }) async {
    if (!kIsWeb && !lkPlatformIsTest()) {
      _connectivityResult = await Connectivity().checkConnectivity();
      await _connectivitySubscription?.cancel();
      _connectivitySubscription = Connectivity()
          .onConnectivityChanged
          .listen((List<ConnectivityResult> result) {
        if (_connectivityResult != result) {
          if (result.contains(ConnectivityResult.none)) {
            logger.warning('lost connectivity');
          } else {
            logger.info(
                'Connectivity changed, ${_connectivityResult} => ${result}');
          }
          events.emit(SignalConnectivityChangedEvent(
            oldState: _connectivityResult,
            state: result,
          ));
          _connectivityResult = result;
        }
      });

      if (_connectivityResult.contains(ConnectivityResult.none)) {
        logger.warning('no internet connection');
        throw ConnectException('no internet connection',
            reason: ConnectionErrorReason.InternalError, statusCode: 503);
      }
    }

    final rtcUri = await Utils.buildUri(
      uriString,
      token: token,
      connectOptions: connectOptions,
      roomOptions: roomOptions,
      reconnect: reconnect,
      sid: reconnect ? participantSid : null,
    );

    logger.fine('SignalClient connecting with url: $rtcUri');

    try {
      if (reconnect == true) {
        _connectionState = ConnectionState.reconnecting;
        events.emit(const SignalReconnectingEvent());
      } else {
        _connectionState = ConnectionState.connecting;
        events.emit(const SignalConnectingEvent());
      }
      // Clean up existing socket
      await cleanUp();
      // Attempt to connect
      var future = _wsConnector(
        rtcUri,
        WebSocketEventHandlers(
          onData: _onSocketData,
          onDispose: _onSocketDispose,
          onError: _onSocketError,
        ),
      );
      future = future.timeout(connectOptions.timeouts.connection);
      _ws = await future;
      // Successful connection
      _connectionState = ConnectionState.connected;
      events.emit(const SignalConnectedEvent());
    } catch (socketError) {
      // Skip validation if reconnect mode
      if (reconnect) rethrow;

      // Attempt Validation
      var finalError = socketError;
      try {
        // Re-build same uri for validate mode
        final validateUri = await Utils.buildUri(
          uriString,
          token: token,
          connectOptions: connectOptions,
          roomOptions: roomOptions,
          validate: true,
          forceSecure: rtcUri.isSecureScheme,
        );

        final validateResponse = await http.get(validateUri);
        if (validateResponse.statusCode != 200) {
          finalError = ConnectException(validateResponse.body,
              reason: validateResponse.statusCode >= 400
                  ? ConnectionErrorReason.NotAllowed
                  : ConnectionErrorReason.InternalError,
              statusCode: validateResponse.statusCode);
        }
      } catch (error) {
        if (socketError.runtimeType != error.runtimeType) {
          finalError = error;
        }
      } finally {
        events.emit(SignalDisconnectedEvent(
            reason: DisconnectReason.signalingConnectionFailure));
        throw finalError;
      }
    }
  }

  Future<void> sendLeave() async {
    _sendRequest(lk_rtc.SignalRequest(
        leave: lk_rtc.LeaveRequest(
            canReconnect: false,
            reason: lk_models.DisconnectReason.CLIENT_INITIATED)));
  }

  // resets internal state to a re-usable state
  @internal
  Future<void> cleanUp() async {
    logger.fine('[${objectId}] cleanUp()');
    _connectionState = ConnectionState.disconnected;
    await _ws?.dispose();
    _ws = null;
    _queue.clear();
    _clearPingInterval();
  }

  void _sendRequest(
    lk_rtc.SignalRequest req, {
    bool enqueueIfReconnecting = true,
  }) {
    if (isDisposed) {
      logger.warning('[$objectId] Could not send message, already disposed');
      return;
    }

    if (connectionState == ConnectionState.reconnecting &&
        req._canQueue() &&
        enqueueIfReconnecting) {
      _queue.add(req);
      return;
    }

    if (connectionState != ConnectionState.connected) {
      logger
          .warning('[$objectId] Could not send message, socket not connected');
      return;
    }

    _ws?.send(req.writeToBuffer());
  }

  Future<void> _onSocketData(dynamic message) async {
    if (message is! List<int>) return;
    final msg = lk_rtc.SignalResponse.fromBuffer(message);

    switch (msg.whichMessage()) {
      case lk_rtc.SignalResponse_Message.join:
        if (msg.join.pingTimeout > 0) {
          _pingTimeoutDuration = Duration(seconds: msg.join.pingTimeout);
          _pingIntervalDuration = Duration(seconds: msg.join.pingInterval);
          logger.info(
              'ping config timeout: ${msg.join.pingTimeout}, interval: ${msg.join.pingInterval} ');
          _startPingInterval();
        }
        participantSid = msg.join.participant.sid;
        events.emit(SignalJoinResponseEvent(response: msg.join));
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
      case lk_rtc.SignalResponse_Message.trackUnpublished:
        events.emit(SignalTrackUnpublishedEvent(
          trackSid: msg.trackUnpublished.trackSid,
        ));
        break;
      case lk_rtc.SignalResponse_Message.trackSubscribed:
        events.emit(SignalLocalTrackSubscribedEvent(
          trackSid: msg.trackSubscribed.trackSid,
        ));
        break;
      case lk_rtc.SignalResponse_Message.speakersChanged:
        events.emit(
            SignalSpeakersChangedEvent(speakers: msg.speakersChanged.speakers));
        break;
      case lk_rtc.SignalResponse_Message.roomUpdate:
        events.emit(SignalRoomUpdateEvent(room: msg.roomUpdate.room));
        break;
      case lk_rtc.SignalResponse_Message.connectionQuality:
        events.emit(SignalConnectionQualityUpdateEvent(
          updates: msg.connectionQuality.updates,
        ));
        break;
      case lk_rtc.SignalResponse_Message.leave:
        events.emit(SignalLeaveEvent(request: msg.leave));
        break;
      case lk_rtc.SignalResponse_Message.mute:
        events.emit(SignalRemoteMuteTrackEvent(
          sid: msg.mute.sid,
          muted: msg.mute.muted,
        ));
        break;
      case lk_rtc.SignalResponse_Message.streamStateUpdate:
        events.emit(SignalStreamStateUpdatedEvent(
          updates: msg.streamStateUpdate.streamStates,
        ));
        break;
      case lk_rtc.SignalResponse_Message.subscribedQualityUpdate:
        events.emit(SignalSubscribedQualityUpdatedEvent(
          trackSid: msg.subscribedQualityUpdate.trackSid,
          // ignore: deprecated_member_use_from_same_package
          subscribedQualities: msg.subscribedQualityUpdate.subscribedQualities,
          subscribedCodecs: msg.subscribedQualityUpdate.subscribedCodecs,
        ));
        break;
      case lk_rtc.SignalResponse_Message.subscriptionPermissionUpdate:
        events.emit(SignalSubscriptionPermissionUpdateEvent(
          participantSid: msg.subscriptionPermissionUpdate.participantSid,
          trackSid: msg.subscriptionPermissionUpdate.trackSid,
          allowed: msg.subscriptionPermissionUpdate.allowed,
        ));
        break;
      case lk_rtc.SignalResponse_Message.refreshToken:
        events.emit(SignalTokenUpdatedEvent(token: msg.refreshToken));
        break;
      case lk_rtc.SignalResponse_Message.notSet:
        logger.info('signal message not set');
        break;
      case lk_rtc.SignalResponse_Message.pong:
        _pingCount++;
        _resetPingTimeout();
        break;
      case lk_rtc.SignalResponse_Message.reconnect:
        events.emit(SignalReconnectResponseEvent(response: msg.reconnect));
        break;
      default:
        logger.warning('received unknown signal message');
    }
  }

  void _onSocketError(dynamic error) {
    logger.warning('received websocket error $error');
  }

  void _onSocketDispose() {
    // don't emit event's when reconnecting state
    logger.fine('SignalClient did disconnect ${_connectionState}');
    if (_connectionState == ConnectionState.reconnecting) {
      return;
    }
    _connectionState = ConnectionState.disconnected;
    events.emit(SignalDisconnectedEvent(reason: DisconnectReason.disconnected));
  }

  void _sendPing() {
    _sendRequest(lk_rtc.SignalRequest()
      ..ping = Int64(DateTime.now().millisecondsSinceEpoch));
  }

  void _startPingInterval() {
    _clearPingInterval();
    _resetPingTimeout();

    if (_pingIntervalDuration == null) {
      logger.warning('ping timeout duration not set');
      return;
    }

    _pingIntervalTimer ??=
        Timer.periodic(_pingIntervalDuration!, (_) => _sendPing());
  }

  void _clearPingInterval() {
    _clearPingTimeout();
    _pingIntervalTimer?.cancel();
    _pingIntervalTimer = null;
  }

  void _resetPingTimeout() {
    _clearPingTimeout();
    if (_pingTimeoutDuration == null) {
      logger.warning('ping timeout duration not set');
      return;
    }
    _pingTimeoutTimer ??= Timer(_pingTimeoutDuration!, () {
      logger.warning('ping timeout');
      _onSocketDispose();
    });
  }

  void _clearPingTimeout() {
    _pingTimeoutTimer?.cancel();
    _pingTimeoutTimer = null;
  }
}

extension SignalClientRequests on SignalClient {
  @internal
  void sendOffer(rtc.RTCSessionDescription offer) =>
      _sendRequest(lk_rtc.SignalRequest(
        offer: offer.toPBType(),
      ));

  @internal
  void sendAnswer(rtc.RTCSessionDescription answer) =>
      _sendRequest(lk_rtc.SignalRequest(
        answer: answer.toPBType(),
      ));

  @internal
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

  @internal
  void sendMuteTrack(String trackSid, bool muted) =>
      _sendRequest(lk_rtc.SignalRequest(
        mute: lk_rtc.MuteTrackRequest(
          sid: trackSid,
          muted: muted,
        ),
      ));

  @internal
  void sendAddTrack(lk_rtc.AddTrackRequest req) =>
      _sendRequest(lk_rtc.SignalRequest(
        addTrack: req,
      ));

  @internal
  void sendUpdateLocalMetadata(lk_rtc.UpdateParticipantMetadata metadata) =>
      _sendRequest(lk_rtc.SignalRequest(
        updateMetadata: metadata,
      ));

  @internal
  void sendUpdateTrackSettings(lk_rtc.UpdateTrackSettings settings) =>
      _sendRequest(lk_rtc.SignalRequest(
        trackSetting: settings,
      ));

  @internal
  void sendUpdateSubscription(lk_rtc.UpdateSubscription subscription) =>
      _sendRequest(lk_rtc.SignalRequest(
        subscription: subscription,
      ));

  @internal
  void sendUpdateSubscriptionPermissions({
    required bool allParticipants,
    required Iterable<lk_rtc.TrackPermission> trackPermissions,
  }) =>
      _sendRequest(lk_rtc.SignalRequest(
        subscriptionPermission: lk_rtc.SubscriptionPermission(
          allParticipants: allParticipants,
          trackPermissions: trackPermissions,
        ),
      ));

  @internal
  void sendLeave() => _sendRequest(lk_rtc.SignalRequest(
        leave: lk_rtc.LeaveRequest(),
      ));

  @internal
  void sendSyncState({
    required lk_rtc.SessionDescription? answer,
    required lk_rtc.UpdateSubscription subscription,
    required Iterable<lk_rtc.TrackPublishedResponse>? publishTracks,
    required Iterable<lk_rtc.DataChannelInfo>? dataChannelInfo,
    required List<String> trackSidsDisabled,
  }) =>
      _sendRequest(lk_rtc.SignalRequest(
        syncState: lk_rtc.SyncState(
          answer: answer,
          subscription: subscription,
          publishTracks: publishTracks,
          dataChannels: dataChannelInfo,
          trackSidsDisabled: trackSidsDisabled,
        ),
      ));

  @internal
  void sendSimulateScenario({
    int? speakerUpdate,
    bool? nodeFailure,
    bool? migration,
    bool? serverLeave,
    bool? switchCandidate,
  }) =>
      _sendRequest(lk_rtc.SignalRequest(
        simulate: lk_rtc.SimulateScenario(
          speakerUpdate: speakerUpdate,
          nodeFailure: nodeFailure,
          migration: migration,
          serverLeave: serverLeave,
          switchCandidateProtocol: (switchCandidate != null && switchCandidate)
              ? lk_rtc.CandidateProtocol.TCP
              : null,
        ),
      ));
}

// private methods
extension on lk_rtc.SignalRequest {
  // returns if this request can be queued
  bool _canQueue() => ![
        // list of types that cannot be queued
        lk_rtc.SignalRequest_Message.syncState,
        lk_rtc.SignalRequest_Message.trickle,
        lk_rtc.SignalRequest_Message.answer,
        lk_rtc.SignalRequest_Message.simulate
      ].contains(whichMessage());
}

// internal methods
extension SignalClientInternalMethods on SignalClient {
  @internal
  void sendQueuedRequests() {
    // queue is empty
    if (_queue.isEmpty) return;
    // send requests
    for (final request in _queue) {
      _sendRequest(request, enqueueIfReconnecting: false);
    }
    _queue.clear();
  }

  @internal
  void clearQueue() => _queue.clear();
}
