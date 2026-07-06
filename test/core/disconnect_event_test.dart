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

@Timeout(Duration(seconds: 5))
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/internal/events.dart';
import 'package:livekit_client/src/support/websocket.dart';
import 'package:livekit_client/src/types/internal.dart';
import '../mock/e2e_container.dart';

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

  test('emits exactly one disconnected event when pinning fails on initial connect', () async {
    container.wsConnector.connectError =
        CertificatePinningException('Certificate pin mismatch', host: 'www.example.com');

    final disconnectedEvents = <RoomDisconnectedEvent>[];
    container.room.events.listen((event) {
      if (event is RoomDisconnectedEvent) {
        disconnectedEvents.add(event);
      }
    });

    await expectLater(
      container.room.connect(exampleUri, token),
      throwsA(isA<CertificatePinningException>()),
    );

    // allow all pending event deliveries to complete
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(disconnectedEvents, hasLength(1));
    expect(disconnectedEvents.single.reason, DisconnectReason.signalingConnectionFailure);
  });

  test('emits exactly one disconnected event when initial connect fails', () async {
    container.wsConnector.connectError = WebSocketException('Failed to connect');

    final disconnectedEvents = <RoomDisconnectedEvent>[];
    container.room.events.listen((event) {
      if (event is RoomDisconnectedEvent) {
        disconnectedEvents.add(event);
      }
    });

    await expectLater(
      container.room.connect(exampleUri, token),
      throwsA(isA<Exception>()),
    );

    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(disconnectedEvents, hasLength(1));
    expect(disconnectedEvents.single.reason, DisconnectReason.joinFailure);
  });

  test('emits exactly one disconnected event when pinning fails during a full reconnect', () async {
    await container.connectRoom();

    final engineDisconnectedEvents = <EngineDisconnectedEvent>[];
    container.engine.events.listen((event) {
      if (event is EngineDisconnectedEvent) {
        engineDisconnectedEvents.add(event);
      }
    });
    final roomDisconnectedEvents = <RoomDisconnectedEvent>[];
    container.room.events.listen((event) {
      if (event is RoomDisconnectedEvent) {
        roomDisconnectedEvents.add(event);
      }
    });

    container.wsConnector.connectError =
        CertificatePinningException('Certificate pin mismatch', host: 'www.example.com');
    container.engine.fullReconnectOnNext = true;
    await container.engine.attemptReconnect(ClientDisconnectReason.reconnectRetry);

    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(engineDisconnectedEvents, hasLength(1));
    expect(engineDisconnectedEvents.single.reason, DisconnectReason.signalingConnectionFailure);
    expect(roomDisconnectedEvents, hasLength(1));
    expect(roomDisconnectedEvents.single.reason, DisconnectReason.signalingConnectionFailure);
  });
}
