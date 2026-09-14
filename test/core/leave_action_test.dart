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
import 'package:livekit_client/src/support/websocket.dart';
import 'package:livekit_client/src/types/internal.dart';
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';
import '../mock/websocket_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late E2EContainer container;
  late Room room;
  late MockWebSocketConnector ws;

  setUp(() {
    resetMockDataChannels();
    container = E2EContainer();
    room = container.room;
    ws = container.wsConnector;
  });

  tearDown(() async {
    await container.dispose();
  });

  /// Connect and inject one remote participant so the tests can observe
  /// whether the roster survives the reconnect.
  Future<void> connectWithRemoteParticipant({lk_models.ClientConfiguration? clientConfiguration}) async {
    await container.connectRoom(clientConfiguration: clientConfiguration);
    await container.simulateRemoteParticipantJoin('bob');
    expect(room.remoteParticipants, hasLength(1));
  }

  /// Feed a server-initiated `LeaveRequest` into the signal connection.
  void sendLeave(lk_rtc.LeaveRequest_Action action, lk_models.DisconnectReason reason) {
    ws.onData(
      lk_rtc.SignalResponse(
        leave: lk_rtc.LeaveRequest(action: action, reason: reason),
      ).writeToBuffer(),
    );
  }

  /// Wait until the SDK has opened a *new* websocket (the reconnect attempt).
  Future<void> waitForNewSignalConnection(WebSocketEventHandlers? previous) async {
    for (var i = 0; i < 200 && identical(ws.handlers, previous); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(identical(ws.handlers, previous), isFalse, reason: 'SDK never re-opened the signal connection');
  }

  /// Answer a resume attempt the way the receiving node would.
  Future<void> answerResume(WebSocketEventHandlers? previous) async {
    await waitForNewSignalConnection(previous);
    expect(
      ws.uri?.queryParameters['reconnect'],
      '1',
      reason: 'a resume must re-open the signal connection with reconnect=1',
    );
    ws.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());
  }

  /// Answer a full reconnect attempt: the SDK re-joins, so it gets a JoinResponse.
  Future<void> answerFullReconnect(WebSocketEventHandlers? previous) async {
    await waitForNewSignalConnection(previous);
    expect(
      ws.uri?.queryParameters.containsKey('reconnect'),
      isFalse,
      reason: 'a full reconnect must re-join without reconnect=1',
    );
    await container.answerJoin();
  }

  void expectFullReconnect(List<RoomEvent> roomEvents) {
    expect(
      roomEvents.whereType<RoomReconnectingEvent>(),
      isNotEmpty,
      reason: 'a full reconnect must emit RoomReconnectingEvent',
    );
    expect(roomEvents.whereType<RoomResumingEvent>(), isEmpty);
    expect(roomEvents.whereType<ParticipantDisconnectedEvent>(), hasLength(1));
    expect(roomEvents.whereType<RoomReconnectedEvent>(), hasLength(1));
    expect(room.remoteParticipants, isEmpty);
    expect(container.engine.fullReconnectOnNext, isFalse);
  }

  test('Leave{RESUME} (node migration) resumes and keeps remote participants', () async {
    await connectWithRemoteParticipant();

    final roomEvents = <RoomEvent>[];
    final sub = room.events.listen(roomEvents.add);
    final previousHandlers = ws.handlers;

    // The server also drops the socket right after the Leave, but that is
    // deliberately not simulated here: a bare socket drop reconnects with reason
    // `signal`, which resumes on its own. Delivering it before the leave-driven
    // attempt runs (in production it arrives a round-trip later, so it never
    // wins) makes this test pass even when the leave action is ignored entirely.
    sendLeave(lk_rtc.LeaveRequest_Action.RESUME, lk_models.DisconnectReason.MIGRATION);

    await answerResume(previousHandlers);
    await room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
    await sub();

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

    // The ICE servers from the ReconnectResponse must reach both transports.
    final publisher = container.engine.publisher?.pc as MockPeerConnection?;
    final subscriber = container.engine.subscriber?.pc as MockPeerConnection?;
    expect(publisher?.appliedConfiguration, isNotNull);
    expect(subscriber?.appliedConfiguration, isNotNull);
  });

  test('Leave{RECONNECT} performs a full reconnect', () async {
    await connectWithRemoteParticipant();

    final roomEvents = <RoomEvent>[];
    final sub = room.events.listen(roomEvents.add);
    final previousHandlers = ws.handlers;

    sendLeave(lk_rtc.LeaveRequest_Action.RECONNECT, lk_models.DisconnectReason.SERVER_SHUTDOWN);

    await answerFullReconnect(previousHandlers);
    await room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
    await sub();

    expectFullReconnect(roomEvents);
  });

  test('Leave{RESUME} does not downgrade a pending full reconnect', () async {
    await connectWithRemoteParticipant();

    final roomEvents = <RoomEvent>[];
    final sub = room.events.listen(roomEvents.add);
    final previousHandlers = ws.handlers;

    // An earlier failure already decided the next attempt must be a full
    // reconnect. The server asking for a resume must not undo that.
    container.engine.fullReconnectOnNext = true;
    sendLeave(lk_rtc.LeaveRequest_Action.RESUME, lk_models.DisconnectReason.MIGRATION);

    await answerFullReconnect(previousHandlers);
    await room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
    await sub();

    expectFullReconnect(roomEvents);
  });

  test('Leave{RESUME} performs a full reconnect when the server disabled resume', () async {
    await connectWithRemoteParticipant(
      clientConfiguration: lk_models.ClientConfiguration(
        resumeConnection: lk_models.ClientConfigSetting.DISABLED,
      ),
    );

    final roomEvents = <RoomEvent>[];
    final sub = room.events.listen(roomEvents.add);
    final previousHandlers = ws.handlers;

    sendLeave(lk_rtc.LeaveRequest_Action.RESUME, lk_models.DisconnectReason.MIGRATION);

    await answerFullReconnect(previousHandlers);
    await room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
    await sub();

    expectFullReconnect(roomEvents);
  });

  test('a Leave{RESUME} arriving before a peer failure retry keeps the escalation', () async {
    await connectWithRemoteParticipant();

    final roomEvents = <RoomEvent>[];
    final sub = room.events.listen(roomEvents.add);
    final previousHandlers = ws.handlers;

    // The peer connection failure schedules a retry that must be a full
    // reconnect. The Leave replaces that pending retry with its own reason;
    // the escalation decided for the failure must survive the swap.
    final failure = container.engine.handleReconnect(ClientDisconnectReason.peerConnectionFailed);
    sendLeave(lk_rtc.LeaveRequest_Action.RESUME, lk_models.DisconnectReason.MIGRATION);
    await failure;

    await answerFullReconnect(previousHandlers);
    await room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
    await sub();

    expectFullReconnect(roomEvents);
  });
}
