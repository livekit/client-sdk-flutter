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

@Timeout(Duration(seconds: 10))
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
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

  /// Feed a server-initiated `LeaveRequest` into the signal connection.
  void sendLeave(lk_rtc.LeaveRequest_Action action, lk_models.DisconnectReason reason) {
    ws.onData(
      lk_rtc.SignalResponse(
        leave: lk_rtc.LeaveRequest(action: action, reason: reason),
      ).writeToBuffer(),
    );
  }

  /// Wait until the SDK has opened a *new* websocket (the reconnect attempt),
  /// then answer it the way the receiving node would.
  Future<void> answerReconnectAttempt(Object? previousHandlers) async {
    for (var i = 0; i < 200 && identical(ws.handlers, previousHandlers); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(identical(ws.handlers, previousHandlers), isFalse, reason: 'SDK never re-opened the signal connection');
    ws.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());
  }

  test('Leave{RESUME} (node migration) resumes and keeps remote participants', () async {
    await container.simulateRemoteParticipantJoin('bob');
    expect(room.remoteParticipants, hasLength(1));

    final roomEvents = <RoomEvent>[];
    final sub = room.events.listen(roomEvents.add);
    final previousHandlers = ws.handlers;

    // The server also drops the socket right after the Leave, but that is
    // deliberately not simulated here: a bare socket drop reconnects with reason
    // `signal`, which resumes on its own. Delivering it before the leave-driven
    // attempt runs (in production it arrives a round-trip later, so it never
    // wins) makes this test pass even when the leave action is ignored entirely.
    sendLeave(lk_rtc.LeaveRequest_Action.RESUME, lk_models.DisconnectReason.MIGRATION);

    await answerReconnectAttempt(previousHandlers);
    await room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
    await sub();

    expect(
      ws.uri?.queryParameters['reconnect'],
      '1',
      reason: 'a resume must re-open the signal connection with reconnect=1',
    );
    expect(
      roomEvents.whereType<RoomResumingEvent>(),
      isNotEmpty,
      reason: 'a migration must resume the session',
    );
    expect(
      roomEvents.whereType<RoomReconnectingEvent>(),
      isEmpty,
      reason: 'RoomReconnectingEvent signals a full reconnect, which drops session state',
    );
    expect(
      roomEvents.whereType<ParticipantDisconnectedEvent>(),
      isEmpty,
      reason: 'a migration must not kick out remote participants',
    );
    expect(room.remoteParticipants, hasLength(1));
    expect(container.engine.fullReconnectOnNext, isFalse);
  });

  test('Leave{RECONNECT} performs a full reconnect', () async {
    await container.simulateRemoteParticipantJoin('bob');
    expect(room.remoteParticipants, hasLength(1));

    final roomEvents = <RoomEvent>[];
    final sub = room.events.listen(roomEvents.add);
    final previousHandlers = ws.handlers;

    sendLeave(lk_rtc.LeaveRequest_Action.RECONNECT, lk_models.DisconnectReason.SERVER_SHUTDOWN);

    // a full reconnect re-joins, so it is answered with a JoinResponse
    for (var i = 0; i < 200 && identical(ws.handlers, previousHandlers); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(identical(ws.handlers, previousHandlers), isFalse, reason: 'SDK never re-opened the signal connection');

    await sub();

    expect(
      roomEvents.whereType<RoomReconnectingEvent>(),
      isNotEmpty,
      reason: 'a RECONNECT leave must trigger a full reconnect',
    );
    expect(roomEvents.whereType<RoomResumingEvent>(), isEmpty);
    expect(roomEvents.whereType<ParticipantDisconnectedEvent>(), hasLength(1));
  });
}
