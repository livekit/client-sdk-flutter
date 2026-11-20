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

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/connection_check/checks/reconnect.dart';
import 'package:livekit_client/src/core/signal_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import 'package:livekit_client/src/support/websocket.dart';
import '../mock/e2e_container.dart';
import '../mock/websocket_mock.dart';

const exampleUri = 'ws://www.example.com';
const token = 'token';

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
    container.wsConnector.holdCloses = true;
    await container.connectRoom();
    await container.room.disconnect();

    final events = <RoomEvent>[];
    container.room.events.on<RoomReconnectingEvent>(events.add);
    container.room.events.on<RoomDisconnectedEvent>(events.add);
    container.room.events.on<RoomAttemptReconnectEvent>(events.add);
    await container.connectRoom();
    // the first socket reports its close only now, with the second one up
    container.wsConnector.releaseCloses();
    await _settle();

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
      container.wsConnector.holdCloses = true;
      await container.connectRoom();

      final events = <RoomEvent>[];
      final sub = container.room.events.listen(events.add);
      final replaced = container.wsConnector.handlers;

      // the server asks for a reconnect while the socket is still open
      container.wsConnector.onData(_leave(action, lk_models.DisconnectReason.MIGRATION));
      await _waitForNewSocket(container, replaced);
      final reconnected = container.room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
      if (action == lk_rtc.LeaveRequest_Action.RESUME) {
        container.wsConnector.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());
      } else {
        await container.answerJoin();
      }
      await reconnected;
      final current = container.wsConnector.handlers;

      // the replaced socket reports its close only now
      container.wsConnector.releaseCloses();
      await _settle();
      await sub();

      expect(container.room.connectionState, ConnectionState.connected);
      expect(
        identical(container.wsConnector.handlers, current),
        isTrue,
        reason: 'the close of the replaced socket must not open another connection',
      );
      expect(events.whereType<RoomAttemptReconnectEvent>(), hasLength(1));
      expect(events.whereType<RoomReconnectedEvent>(), hasLength(1));
      expect(events.whereType<RoomDisconnectedEvent>(), isEmpty);
    });
  }

  test('data a replaced socket delivers late is ignored', () async {
    await container.connectRoom();
    final replaced = container.wsConnector.handlers;
    container.wsConnector.onData(_leave(lk_rtc.LeaveRequest_Action.RESUME, lk_models.DisconnectReason.MIGRATION));
    await _waitForNewSocket(container, replaced);
    final reconnected = container.room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
    container.wsConnector.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());
    await reconnected;

    final disconnected = <RoomDisconnectedEvent>[];
    container.room.events.on<RoomDisconnectedEvent>(disconnected.add);
    // the old socket still had a Leave on its way
    replaced!.onData!(_leave(lk_rtc.LeaveRequest_Action.DISCONNECT, lk_models.DisconnectReason.CLIENT_INITIATED));
    await _settle();

    expect(container.room.connectionState, ConnectionState.connected);
    expect(disconnected, isEmpty);
  });

  test('a connect that opens after disconnect() and a rejoin does not take over the rejoined session', () async {
    final gate = Completer<void>();
    container.wsConnector.connectGate = gate.future;
    final disconnected = <RoomDisconnectedEvent>[];
    container.room.events.on<RoomDisconnectedEvent>(disconnected.add);

    final stale = container.room.connect(exampleUri, token).then<Object?>((_) => null, onError: (Object e) => e);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await container.room.disconnect();
    container.wsConnector.connectGate = null;
    await container.connectRoom();
    final rejoined = container.wsConnector.sockets.last;

    // the first connect's socket opens only now
    gate.complete();
    final staleError = await stale.timeout(const Duration(seconds: 2));
    await _settle();
    final staleSocket = container.wsConnector.sockets.last;

    expect(staleError, isA<SignalConnectSupersededException>());
    expect(staleSocket, isNot(same(rejoined)));
    expect(staleSocket.isDisposed, isTrue, reason: 'a socket nobody wants any more is closed');
    expect(container.room.connectionState, ConnectionState.connected);
    expect(disconnected, hasLength(1), reason: 'only the disconnect() the app asked for');

    final before = rejoined.sent.length;
    await container.client.sendLeave();
    expect(rejoined.sent, hasLength(before + 1), reason: 'requests go out on the rejoined session');
    expect(staleSocket.sent, isEmpty);
  });

  test('a cleanUp still closing the old socket leaves the next connection alone', () async {
    // a dart:io close waits for the server to answer the close frame
    final connector = MockWebSocketConnector()..disposeLatency = const Duration(milliseconds: 100);
    final client = SignalClient(connector.connect);
    Future<void> connect() =>
        client.connect(exampleUri, token, connectOptions: const ConnectOptions(), roomOptions: const RoomOptions());
    try {
      await connect();
      final closing = client.cleanUp();
      await connect();
      final current = connector.sockets.last;
      await closing;

      final before = current.sent.length;
      await client.sendLeave();
      expect(current.sent, hasLength(before + 1), reason: 'the first cleanUp() must not detach the new socket');
    } finally {
      await client.dispose();
    }
  });

  test('simulating a signal drop with no signal socket does nothing', () async {
    final events = <RoomEvent>[];
    container.room.events.on<RoomAttemptReconnectEvent>(events.add);
    container.room.events.on<RoomReconnectingEvent>(events.add);

    await container.room.sendSimulateScenario(signalReconnect: true);
    await _settle();

    expect(events, isEmpty);
    expect(container.wsConnector.sockets, isEmpty);
  });

  test('the signalReconnect debug scenario still drops the signal and starts a reconnect', () async {
    await container.connectRoom();
    final events = <RoomEvent>[];
    container.room.events.on<RoomAttemptReconnectEvent>(events.add);

    await container.room.sendSimulateScenario(signalReconnect: true);

    expect(
      await _resumeStarted(container),
      isTrue,
      reason: 'the engine must re-open the signal connection as a resume',
    );
    expect(events, isNotEmpty);
  });

  test('the disconnectSignalOnResume debug action still starts a resume', () async {
    container.wsConnector.closeLatency = const Duration(milliseconds: 50);
    await container.connectRoom();

    await container.room.sendSimulateScenario(disconnectSignalOnResume: true);

    expect(await _resumeStarted(container), isTrue, reason: 'the server only acts on the next resume');
  });

  test('the connection checker reconnect check succeeds once the room resumes', () async {
    container.wsConnector.closeLatency = const Duration(milliseconds: 50);
    await container.connectRoom();
    final replaced = container.wsConnector.handlers;

    final check = ReconnectCheck(exampleUri, token, room: container.room);
    final running = check.run();
    await _waitForNewSocket(container, replaced);
    container.wsConnector.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());
    final info = await running;

    expect(info.status, CheckStatus.success, reason: info.logs.map((l) => l.message).join(', '));
  });
}

List<int> _leave(lk_rtc.LeaveRequest_Action action, lk_models.DisconnectReason reason) => lk_rtc.SignalResponse(
  leave: lk_rtc.LeaveRequest(action: action, reason: reason),
).writeToBuffer();

/// Lets the events of something that just happened run their course.
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 100));

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
