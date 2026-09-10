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
  Future<Uri> awaitNewSocket(Object? previousHandlers) async {
    for (var i = 0; i < 200 && identical(ws.handlers, previousHandlers); i++) {
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
