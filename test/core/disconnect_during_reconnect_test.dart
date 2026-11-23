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

// disconnect() and Room.dispose() close the engine for good, even when a full
// reconnect is already tearing down the old connection and is about to connect
// again, and the room can connect again after disconnect().

@Timeout(Duration(seconds: 10))
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
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

  test('disconnect() during a full reconnect does not connect again', () async {
    final disconnected = Completer<void>();
    final listener = room.createListener();
    // RoomReconnectingEvent comes from the full reconnect, before it disposes
    // the old connection and connects again.
    listener.on<RoomReconnectingEvent>((_) {
      if (!disconnected.isCompleted) {
        unawaited(room.disconnect().then(disconnected.complete));
      }
    });

    container.engine.fullReconnectOnNext = true;
    final droppedHandlers = ws.handlers;
    ws.onDispose();
    await disconnected.future;

    // Give a reconnect that was not stopped time to open its socket.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await listener.dispose();

    expect(identical(ws.handlers, droppedHandlers), isTrue, reason: 'the full reconnect opened a new signal socket');
    expect(container.engine.isClosed, isTrue);
    expect(room.connectionState, ConnectionState.disconnected);

    await container.connectRoom();
    expect(room.connectionState, ConnectionState.connected);
  });

  test('the room connects again after disconnect() during a reconnect delay', () async {
    final disconnected = Completer<void>();
    final listener = room.createListener();
    // Emitted before the retry timer fires, so the reconnect is still pending.
    listener.on<RoomAttemptReconnectEvent>((_) {
      if (!disconnected.isCompleted) {
        unawaited(room.disconnect().then(disconnected.complete));
      }
    });

    ws.onDispose();
    await disconnected.future;
    await listener.dispose();
    expect(room.connectionState, ConnectionState.disconnected);

    await container.connectRoom();
    expect(room.connectionState, ConnectionState.connected);
  });

  test('disposing the room during a full reconnect does not connect again', () async {
    final restartPaused = Completer<void>();
    final resumeRestart = Completer<void>();
    container.engine.publisher!.onDispose(() async {
      restartPaused.complete();
      await resumeRestart.future;
    });
    final disposePaused = Completer<void>();
    final resumeDispose = Completer<void>();
    container.engine.subscriber!.onDispose(() async {
      disposePaused.complete();
      await resumeDispose.future;
    });

    container.engine.fullReconnectOnNext = true;
    final droppedHandlers = ws.handlers;
    ws.onDispose();
    await restartPaused.future;

    // The room's teardown reaches the subscriber while the full reconnect still holds the publisher.
    final disposing = room.dispose();
    await disposePaused.future;
    resumeRestart.complete();
    // Give a reconnect that was not stopped time to open its socket.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    resumeDispose.complete();
    await disposing;

    expect(identical(ws.handlers, droppedHandlers), isTrue, reason: 'the full reconnect opened a new signal socket');
  });

  test('a full reconnect still tearing down does not disturb an immediate connect', () async {
    final teardownStarted = Completer<void>();
    final releaseTeardown = Completer<void>();
    container.engine.publisher!.onDispose(() async {
      if (!teardownStarted.isCompleted) teardownStarted.complete();
      await releaseTeardown.future;
    });

    container.engine.fullReconnectOnNext = true;
    ws.onDispose();
    await teardownStarted.future;

    await room.disconnect();
    await container.connectRoom();
    final publisher = container.engine.publisher;
    final subscriber = container.engine.subscriber;
    expect(room.connectionState, ConnectionState.connected);

    releaseTeardown.complete();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    expect(identical(container.engine.publisher, publisher), isTrue, reason: 'publisher replaced or dropped');
    expect(identical(container.engine.subscriber, subscriber), isTrue, reason: 'subscriber replaced or dropped');
    expect(room.connectionState, ConnectionState.connected);
    await container.simulateRemoteParticipantJoin('late');
    expect(room.remoteParticipants.values.map((p) => p.identity), contains('late'));
  });
}
