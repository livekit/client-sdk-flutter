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
import 'package:livekit_client/src/core/engine.dart';
import 'package:livekit_client/src/internal/events.dart';
import 'package:livekit_client/src/types/internal.dart';
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late E2EContainer container;
  late List<EngineEvent> events;

  setUp(() async {
    resetMockDataChannels();
    container = E2EContainer();
    await container.connectRoom();
    events = [];
    container.engine.events.listen(events.add);
  });

  tearDown(() async {
    await container.dispose();
  });

  test('disposing the room announces engine closure', () async {
    await container.room.dispose();

    expect(events.whereType<EngineClosingEvent>(), hasLength(1));
    expect(container.engine.isClosed, isTrue);
  });

  test('an unrecoverable reconnect announces closure before disconnection', () async {
    container.wsConnector.connectError = CertificatePinningException(
      'Certificate pin mismatch',
      host: 'www.example.com',
    );
    final disconnected = container.engine.events.waitFor<EngineDisconnectedEvent>(
      duration: const Duration(seconds: 1),
    );

    await container.engine.attemptReconnect(ClientDisconnectReason.reconnectRetry);
    expect((await disconnected).reason, DisconnectReason.signalingConnectionFailure);

    expect(container.engine.isClosed, isTrue);
    expect(events.whereType<EngineClosingEvent>(), hasLength(1));
    expect(
      events.indexWhere((event) => event is EngineClosingEvent),
      lessThan(events.indexWhere((event) => event is EngineDisconnectedEvent)),
    );
  });

  test('exhausting reconnect attempts announces engine closure', () async {
    // A generic resume failure stays recoverable without escalating to a full reconnect.
    container.wsConnector.connectError = Exception('temporary connection failure');
    final disconnected = container.engine.events.waitFor<EngineDisconnectedEvent>(
      duration: const Duration(seconds: 1),
    );

    // Drive the attempts directly rather than waiting through the retry delays.
    for (var i = 0; i < defaultRetryDelaysInMs.length; i++) {
      await container.engine.attemptReconnect(ClientDisconnectReason.reconnectRetry);
    }
    expect((await disconnected).reason, DisconnectReason.reconnectAttemptsExceeded);

    expect(container.engine.isClosed, isTrue);
    expect(events.whereType<EngineClosingEvent>(), hasLength(1));
    expect(
      events.indexWhere((event) => event is EngineClosingEvent),
      lessThan(events.indexWhere((event) => event is EngineDisconnectedEvent)),
    );
  });

  test('a recoverable reconnect does not announce engine closure', () async {
    container.wsConnector.connectError = Exception('temporary connection failure');

    await container.engine.attemptReconnect(ClientDisconnectReason.reconnectRetry);

    expect(container.engine.isClosed, isFalse);
    expect(events.whereType<EngineClosingEvent>(), isEmpty);
    expect(events.whereType<EngineDisconnectedEvent>(), isEmpty);
  });

  test('a buffer wait started after disposal rejects even when the channel reports low', () async {
    await container.room.dispose();

    await expectLater(container.engine.waitForBufferStatusLow(Reliability.reliable), throwsA('Engine disconnected'));
  });

  test('disconnect followed by disposal announces closure only once', () async {
    await container.engine.disconnect();
    await expectLater(container.engine.waitForBufferStatusLow(Reliability.reliable), throwsA('Engine disconnected'));
    await container.room.dispose();

    expect(events.whereType<EngineClosingEvent>(), hasLength(1));
  });
}
