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
    // the real sockets report their close a few milliseconds after dispose()
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
}
