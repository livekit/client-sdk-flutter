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

// disconnect() closes the engine for good, even when a full reconnect is
// already tearing down the old connection and is about to connect again, and
// the room can connect again afterwards.

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
}
