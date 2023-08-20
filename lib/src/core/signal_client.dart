// Copyright 2023 LiveKit, Inc.
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
import '../support/websocket.dart';
import '../types/other.dart';
import '../types/video_dimensions.dart';
import '../utils.dart';

class SignalClient extends Disposable with EventsEmittable<SignalEvent> {
  // Connection state of the socket conection.
  ConnectionState _connectionState = ConnectionState.disconnected;

  final WebSocketConnector _wsConnector;
  LiveKitWebSocket? _ws;

  final _queue = Queue<lk_rtc.SignalRequest>();
  Duration? _pingTimeoutDuration;
  Timer? _pingTimeoutTimer;

  Duration? _pingIntervalDuration;
  Timer? _pingIntervalTimer;

  int get pingCount => _pingCount;

  int _pingCount = 0;

  @internal
  SignalClient(WebSocketConnector wsConnector) : _wsConnector = wsConnector {
    events.listen((event) {
      logger.fine('[SignalEvent] $event');
    });

    onDispose(() async {
      await cleanUp();
      await events.dispose();
    });
  }

  @internal
  Future<void> connect(
    String uriString,
    String token, {
    required ConnectOptions connectOptions,
    required RoomOptions roomOptions,
    bool reconnect = false,
    String? sid,
  }) async {
    final rtcUri = await Utils.buildUri(
      uriString,
      token: token,
      connectOptions: connectOptions,
      roomOptions: roomOptions,
      reconnect: reconnect,
      sid: sid,
    );

    logger.fine('SignalClient connecting with url: $rtcUri');

    try {
      _updateConnectionState(reconnect
          ? ConnectionState.reconnecting
          : ConnectionState.connecting);
      // Clean up existing socket
      await cleanUp();
      // Attempt to connect
      _ws = await _wsConnector(
        rtcUri,
        WebSocketEventHandlers(
          onData: _onSocketData,
          onDispose: _onSocketDispose,
          onError: _onSocketError,
        ),
      );
      // Successful connection
      _updateConnectionState(ConnectionState.connected);
    } catch (socketError) {
      // Attempt Validation
      var finalError = socketError;
      try {
        // Skip validation if reconnect mode
        if (reconnect) rethrow;

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
          finalError = ConnectException(validateResponse.body);
        }
      } catch (error) {
        if (socketError.runtimeType != error.runtimeType) {
          finalError = error;
        }
      } finally {
        _updateConnectionState(ConnectionState.disconnected);
        throw finalError;
      }
    }
  }

  // resets internal state to a re-usable state
  @internal
  Future<void> cleanUp() async {
    logger.fine('[${objectId}] cleanUp()');

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

    if (_connectionState == ConnectionState.reconnecting &&
        req._canQueue() &&
        enqueueIfReconnecting) {
      _queue.add(req);
      return;
    }

    if (_ws == null) {
      logger.warning('[$objectId] Could not send message, socket is null');
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
        events.emit(SignalLeaveEvent(
            canReconnect: msg.leave.canReconnect, reason: msg.leave.reason));
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
    logger.fine('SignalClient onSocketDispose $_connectionState');
    // don't emit event's when reconnecting state
    if (_connectionState != ConnectionState.reconnecting) {
      logger.fine('SignalClient did disconnect ${_connectionState}');
      _updateConnectionState(ConnectionState.disconnected);
    }
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
  void sendAddTrack({
    required String cid,
    required String name,
    required lk_models.TrackType type,
    required lk_models.TrackSource source,
    required lk_models.Encryption_Type encryptionType,
    VideoDimensions? dimensions,
    bool? dtx,
    Iterable<lk_models.VideoLayer>? videoLayers,
    Iterable<lk_rtc.SimulcastCodec>? simulcastCodecs,
    String? sid,
  }) {
    final req = lk_rtc.AddTrackRequest(
      cid: cid,
      name: name,
      type: type,
      source: source,
      encryption: encryptionType,
      simulcastCodecs: simulcastCodecs,
      sid: sid,
      muted: false,
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
  void sendUpdateVideoLayers(
    String trackSid,
    Iterable<lk_models.VideoLayer> layers,
  ) =>
      _sendRequest(lk_rtc.SignalRequest(
        updateLayers: lk_rtc.UpdateVideoLayers(
          trackSid: trackSid,
          layers: layers,
        ),
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
  }) =>
      _sendRequest(lk_rtc.SignalRequest(
        syncState: lk_rtc.SyncState(
          answer: answer,
          subscription: subscription,
          publishTracks: publishTracks,
          dataChannels: dataChannelInfo,
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
        lk_rtc.SignalRequest_Message.offer,
        lk_rtc.SignalRequest_Message.answer,
        lk_rtc.SignalRequest_Message.simulate
      ].contains(whichMessage());
}

extension SignalClientPrivateMethods on SignalClient {
  void _updateConnectionState(ConnectionState newValue) {
    if (_connectionState == newValue) return;

    logger.fine('SignalClient ConnectionState '
        '${_connectionState.name} -> ${newValue.name}');

    bool didReconnect = _connectionState == ConnectionState.reconnecting &&
        newValue == ConnectionState.connected;

    final oldState = _connectionState;

    if (newValue == ConnectionState.connected &&
        oldState == ConnectionState.reconnecting) {
      // restart ping interval as it's cleared for reconnection
      _startPingInterval();
    } else if (newValue == ConnectionState.reconnecting) {
      // clear ping interval and restart it once reconnected
      _clearPingInterval();
    }

    _connectionState = newValue;

    events.emit(SignalConnectionStateUpdatedEvent(
      newState: _connectionState,
      oldState: oldState,
      didReconnect: didReconnect,
    ));
  }
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
