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
import 'package:livekit_client/src/connection_check/checks/reconnect.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import 'package:livekit_client/src/support/websocket.dart';
import '../mock/e2e_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late E2EContainer container;

  setUp(() {
    container = E2EContainer();
  });

  tearDown(() async {
    await container.dispose();
  });

  test('a close reported by a replaced socket does not disturb the next connection', () async {
    // the real sockets report their close some time after dispose()
    container.wsConnector.closeLatency = const Duration(milliseconds: 50);
    await container.connectRoom();
    await container.room.disconnect();

    // connect again before the first socket has reported its close
    final events = <RoomEvent>[];
    container.room.events.on<RoomReconnectingEvent>(events.add);
    container.room.events.on<RoomDisconnectedEvent>(events.add);
    container.room.events.on<RoomAttemptReconnectEvent>(events.add);
    await container.connectRoom();
    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(container.room.connectionState, ConnectionState.connected);
    expect(events, isEmpty, reason: 'the stale close belongs to the old socket and must be ignored');
  });

  for (final (name, action) in [
    ('resume', lk_rtc.LeaveRequest_Action.RESUME),
    ('full reconnect', lk_rtc.LeaveRequest_Action.RECONNECT),
  ]) {
    test('a late close of the socket a $name replaced does not start another reconnect', () async {
      // A browser reports the close when the server drops TCP, which can be
      // seconds after the close handshake. By then the reconnect is done and
      // the new socket is current.
      const closeLatency = Duration(milliseconds: 300);
      container.wsConnector.closeLatency = closeLatency;
      await container.connectRoom();

      final events = <RoomEvent>[];
      final sub = container.room.events.listen(events.add);
      final replaced = container.wsConnector.handlers;

      // the server asks for a reconnect while the socket is still open
      container.wsConnector.onData(
        lk_rtc.SignalResponse(
          leave: lk_rtc.LeaveRequest(action: action, reason: lk_models.DisconnectReason.MIGRATION),
        ).writeToBuffer(),
      );
      await _waitForNewSocket(container, replaced);
      if (action == lk_rtc.LeaveRequest_Action.RESUME) {
        container.wsConnector.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());
      } else {
        await container.answerJoin();
      }
      await container.room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
      final current = container.wsConnector.handlers;

      // let the replaced socket report its close, and give a reconnect it
      // might start time to open a socket
      await Future<void>.delayed(closeLatency * 3);
      await sub();

      expect(container.room.connectionState, ConnectionState.connected);
      expect(
        identical(container.wsConnector.handlers, current),
        isTrue,
        reason: 'the close of the replaced socket must not open another connection',
      );
      expect(events.whereType<RoomReconnectedEvent>(), hasLength(1));
      expect(events.whereType<RoomDisconnectedEvent>(), isEmpty);
    });
  }

  test('the signalReconnect debug scenario still drops the signal and starts a reconnect', () async {
    await container.connectRoom();
    final events = <RoomEvent>[];
    container.room.events.on<RoomAttemptReconnectEvent>(events.add);

    await container.room.sendSimulateScenario(signalReconnect: true);

    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (!(container.wsConnector.uri?.queryParameters['reconnect'] == '1') && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(
      container.wsConnector.uri?.queryParameters['reconnect'],
      '1',
      reason: 'the engine must re-open the signal connection as a resume',
    );
    expect(events, isNotEmpty);
  });

  test('the disconnectSignalOnResume debug action still starts a resume', () async {
    // the real sockets report their close a few milliseconds after dispose()
    container.wsConnector.closeLatency = const Duration(milliseconds: 50);
    await container.connectRoom();

    await container.room.sendSimulateScenario(disconnectSignalOnResume: true);

    expect(await _resumeStarted(container), isTrue, reason: 'the server only acts on the next resume');
  });

  test('the connection checker reconnect check still sees a resume', () async {
    container.wsConnector.closeLatency = const Duration(milliseconds: 50);
    await container.connectRoom();

    final check = ReconnectCheck('ws://www.example.com', 'token', room: container.room);
    final info = await check.run();

    expect(
      info.logs.map((l) => l.message),
      isNot(contains('Did not attempt to reconnect')),
      reason: 'the check drops the signal socket and expects the engine to notice',
    );
  });
}

Future<void> _waitForNewSocket(E2EContainer container, WebSocketEventHandlers? previous) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (identical(container.wsConnector.handlers, previous) && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(identical(container.wsConnector.handlers, previous), isFalse, reason: 'the SDK never opened a new socket');
}

Future<bool> _resumeStarted(E2EContainer container) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (DateTime.now().isBefore(deadline)) {
    if (container.wsConnector.uri?.queryParameters['reconnect'] == '1') return true;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  return false;
}
