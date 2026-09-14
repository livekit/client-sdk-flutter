// Copyright 2026 LiveKit, Inc.
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

// Reconnect-request bookkeeping: a request must not be dropped because another
// attempt was running, and the escalation implied by a request's reason must
// not be lost when a later request replaces it.
//
// The first test ports rust-sdks' `test_resume_escalation_sticks_across_cycles`
// (livekit/tests/peer_connection_signaling_test.rs). That test needs a live SFU,
// two participants and a published sine track, and observes the escalation via
// `LocalTrackRepublished` because only the full-reconnect path republishes.
// Here the mock transport lets us inject the concurrent request directly and
// observe the escalation as `RoomReconnectingEvent`, which only the full path
// emits.

@Timeout(Duration(seconds: 10))
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import 'package:livekit_client/src/types/internal.dart';
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';
import '../mock/websocket_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late E2EContainer container;
  late Room room;
  late MockWebSocketConnector ws;

  setUp(() async {
    resetMockDataChannels();
    container = E2EContainer();
    room = container.room;
    ws = container.wsConnector;
    await container.connectRoom();
  });

  tearDown(() async {
    await container.dispose();
  });

  /// Spin until the SDK opens a new signal socket, returning its URI.
  Future<Uri> awaitNewSocket(Object? previousHandlers, {int maxWaitMs = 2000}) async {
    for (var i = 0; i < maxWaitMs ~/ 10 && identical(ws.handlers, previousHandlers); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(identical(ws.handlers, previousHandlers), isFalse, reason: 'SDK never re-opened the signal connection');
    return ws.uri!;
  }

  test('a full-reconnect request arriving mid-resume is dispatched after it succeeds', () async {
    final roomEvents = <RoomEvent>[];
    final cancel = room.events.listen(roomEvents.add);

    // Cycle 1: a resume, with a full-reconnect request injected while it runs.
    final firstHandlers = ws.handlers;
    ws.onDispose();
    final resumeUri = await awaitNewSocket(firstHandlers);
    expect(resumeUri.queryParameters['reconnect'], '1', reason: 'cycle 1 must be a resume');

    // What a server `Leave{RECONNECT}` mid-resume does.
    container.engine.fullReconnectOnNext = true;

    final resumeHandlers = ws.handlers;
    ws.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());
    await room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));

    // Cycle 2 must be a full reconnect, dispatched from the request that
    // arrived while cycle 1 was in flight — not silently dropped.
    final restartUri = await awaitNewSocket(resumeHandlers);
    expect(restartUri.queryParameters['reconnect'], isNull, reason: 'cycle 2 must re-join, not resume');
    await cancel();

    expect(
      roomEvents.whereType<RoomResumingEvent>(),
      isNotEmpty,
      reason: 'cycle 1 must have been a resume, otherwise the cross-cycle behavior is not under test',
    );
    expect(
      roomEvents.whereType<RoomReconnectingEvent>(),
      isNotEmpty,
      reason: 'the mid-attempt full-reconnect request must still be honored',
    );
  });

  test('an escalating reason is not lost when a later request replaces it', () async {
    final roomEvents = <RoomEvent>[];
    final cancel = room.events.listen(roomEvents.add);
    final previousHandlers = ws.handlers;

    // A PeerConnection failure demands a full reconnect. The socket close that
    // follows lands a second request whose reason (`signal`) implies only a
    // resume, and it replaces the first request's pending timer.
    unawaited(container.engine.handleReconnect(ClientDisconnectReason.peerConnectionFailed));
    await container.engine.handleReconnect(ClientDisconnectReason.signal);

    final uri = await awaitNewSocket(previousHandlers);
    await cancel();

    expect(uri.queryParameters['reconnect'], isNull, reason: 'the peer-connection failure must still force a re-join');
    expect(roomEvents.whereType<RoomReconnectingEvent>(), isNotEmpty);
    expect(roomEvents.whereType<RoomResumingEvent>(), isEmpty);
  });

  test('a peer failure reported mid-resume is dispatched as a full reconnect afterwards', () async {
    final roomEvents = <RoomEvent>[];
    final cancel = room.events.listen(roomEvents.add);

    final firstHandlers = ws.handlers;
    ws.onDispose();
    final resumeUri = await awaitNewSocket(firstHandlers);
    expect(resumeUri.queryParameters['reconnect'], '1', reason: 'cycle 1 must be a resume');

    // The real request path, not a direct flag write: a PeerConnection reports
    // failed while the resume is in flight. handleReconnect records the
    // escalation and schedules a timer that the running attempt swallows.
    unawaited(container.engine.handleReconnect(ClientDisconnectReason.peerConnectionFailed));

    final resumeHandlers = ws.handlers;
    ws.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());
    await room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));

    final restartUri = await awaitNewSocket(resumeHandlers);
    await cancel();

    expect(restartUri.queryParameters['reconnect'], isNull, reason: 'the peer failure must still force a re-join');
    expect(roomEvents.whereType<RoomReconnectingEvent>(), isNotEmpty);
    expect(container.engine.fullReconnectOnNext, isFalse, reason: 'the request must be consumed, not left stale');
  });

  test('a RECONNECT leave arriving mid-restart is not lost', () async {
    final roomEvents = <RoomEvent>[];
    final cancel = room.events.listen(roomEvents.add);

    // Cycle 1: a full reconnect, answered with a JoinResponse.
    final firstHandlers = ws.handlers;
    container.engine.fullReconnectOnNext = true;
    ws.onDispose();
    final joinUri = await awaitNewSocket(firstHandlers);
    expect(joinUri.queryParameters['reconnect'], isNull, reason: 'cycle 1 must be a re-join');

    // The node we are joining asks for another full reconnect before the join
    // completes. restartConnection used to reset the flag after joining, which
    // erased this request.
    ws.onData(
      lk_rtc.SignalResponse(
        leave: lk_rtc.LeaveRequest(
          action: lk_rtc.LeaveRequest_Action.RECONNECT,
          reason: lk_models.DisconnectReason.STATE_MISMATCH,
        ),
      ).writeToBuffer(),
    );

    final joinHandlers = ws.handlers;
    await container.answerJoin();
    await room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));

    // Cycle 2: the leave-driven full reconnect must still run.
    final secondJoinUri = await awaitNewSocket(joinHandlers);
    await cancel();

    expect(secondJoinUri.queryParameters['reconnect'], isNull, reason: 'cycle 2 must be a re-join too');
    expect(roomEvents.whereType<RoomReconnectingEvent>(), hasLength(2));
  });

  test('a signal drop during the resume is retried instead of reported as success', () async {
    final roomEvents = <RoomEvent>[];
    final cancel = room.events.listen(roomEvents.add);

    final firstHandlers = ws.handlers;
    ws.onDispose();
    await awaitNewSocket(firstHandlers);

    // The server answers the resume and the socket dies right behind it, before
    // the peer connection work finishes. The attempt must not end in
    // RoomReconnectedEvent with a dead signal connection.
    final resumeHandlers = ws.handlers;
    ws.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());
    ws.onDispose();

    final retryUri = await awaitNewSocket(resumeHandlers);
    expect(retryUri.queryParameters['reconnect'], '1', reason: 'a severed signal is retried as a resume');
    expect(
      roomEvents.whereType<RoomReconnectedEvent>(),
      isEmpty,
      reason: 'the attempt with the dead socket must not be reported as a success',
    );

    ws.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());
    await room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
    await cancel();

    expect(roomEvents.whereType<RoomReconnectedEvent>(), hasLength(1));
  });

  test('repeated severed resumes count towards the retry limit', () async {
    final attempts = <int>[];
    final cancel = room.events.listen((event) {
      if (event is RoomAttemptReconnectEvent) attempts.add(event.attempt);
    });

    // Every resume opens its socket, gets its ReconnectResponse and then loses
    // the socket before the attempt completes. The socket connect used to reset
    // the attempt counter, so each failure scheduled "attempt 2" again and the
    // retry limit was never reached.
    var handlers = ws.handlers;
    ws.onDispose();
    for (var i = 0; i < 3; i++) {
      await awaitNewSocket(handlers, maxWaitMs: 6000);
      handlers = ws.handlers;
      ws.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());
      ws.onDispose();
      // let the attempt reach its final check, fail and schedule the retry
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    // Leave the engine in a clean state: answer the fourth attempt properly.
    await awaitNewSocket(handlers, maxWaitMs: 6000);
    ws.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());
    await room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
    await cancel();

    // Each failure schedules twice (the socket close and the retry), so look at
    // the distinct attempt numbers: they must climb, not repeat.
    expect(attempts.where((a) => a > 1).toSet().toList(), [
      2,
      3,
      4,
    ], reason: 'every failed attempt must advance the counter');
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('a successful resume leaves no full-reconnect state behind', () async {
    final previousHandlers = ws.handlers;
    ws.onDispose();
    await awaitNewSocket(previousHandlers);
    ws.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());
    await room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));

    expect(container.engine.fullReconnectOnNext, isFalse);
    expect(container.engine.isFullReconnectInProgress, isFalse);
  });
}
