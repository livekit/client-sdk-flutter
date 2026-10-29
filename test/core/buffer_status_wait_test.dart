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

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/internal/events.dart';
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';

const _full = 10 * 1024 * 1024;

void main() {
  late E2EContainer container;

  setUp(() async {
    resetMockDataChannels();
    container = E2EContainer();
    await container.connectRoom();
  });

  tearDown(() async {
    await container.dispose();
  });

  void setBufferedAmount(int? amount) {
    for (final dc in mockDataChannels) {
      dc.fakeBufferedAmount = amount;
    }
  }

  /// Fills the reliable channel and sends once, so the engine's cached status also says it is full.
  Future<void> fillReliableChannel() async {
    // The mock loops published data back into this room as if a remote sent it, which the room
    // rejects. These tests only need the send to refresh the engine's cached status.
    for (final dc in mockDataChannels) {
      dc.onMessageSend = null;
    }
    setBufferedAmount(_full);
    await container.room.localParticipant!.publishData([1], reliable: true);
    expect(container.engine.isBufferStatusLow(Reliability.reliable), isFalse);
  }

  test('a wait ends once the channel is empty, even without a low-buffer event', () async {
    await fillReliableChannel();
    final wait = container.engine.waitForBufferStatusLow(Reliability.reliable);

    // An empty channel that never reports the drain, as when a full reconnect replaces the
    // channel the wait started on.
    setBufferedAmount(null);

    await wait.timeout(const Duration(seconds: 1));
  });

  test('a wait does not leave its closing listener behind', () async {
    final before = container.engine.events.listeners.length;
    await fillReliableChannel();
    final wait = container.engine.waitForBufferStatusLow(Reliability.reliable);

    setBufferedAmount(null);
    for (final dc in mockDataChannels) {
      dc.onBufferedAmountLow?.call(0);
    }
    await wait.timeout(const Duration(seconds: 1));

    expect(container.engine.events.listeners.length, before);
  });

  test('a wait still fails when the engine closes', () async {
    await fillReliableChannel();
    final wait = container.engine.waitForBufferStatusLow(Reliability.reliable);
    final outcome = wait.then<Object?>((_) => 'resolved', onError: (Object e) => e);

    container.engine.events.emit(EngineClosingEvent());

    expect(await outcome.timeout(const Duration(seconds: 2)), isNot('resolved'));
  });
}
