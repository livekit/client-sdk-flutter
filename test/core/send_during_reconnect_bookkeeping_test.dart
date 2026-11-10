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

// A send's post-send bookkeeping reads the channel's buffered amount after the packet went out.
// When a full reconnect replaces the channel in between, that read belongs to the old channel:
// it must neither fail the send nor overwrite the new channel's buffer status.

@Timeout(Duration(seconds: 10))
library;

import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import '../mock/datachannel_mock.dart';
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';

const _full = 10 * 1024 * 1024;

final _channelGone = PlatformException(
  code: 'dataChannelGetBufferedAmountFailed',
  message: 'Error: dataChannel not found or not opened!',
);

lk_models.DataPacket _packet() => lk_models.DataPacket(
  kind: lk_models.DataPacket_Kind.RELIABLE,
  user: lk_models.UserPacket(payload: [1]),
);

void main() {
  late E2EContainer container;

  setUp(() async {
    resetMockDataChannels();
    container = E2EContainer();
    await container.connectRoom();
    for (final dc in mockDataChannels) {
      dc.onMessageSend = null;
    }
  });

  tearDown(() async {
    await container.dispose();
  });

  test('a send on the old channel that finishes after a full reconnect leaves the new status alone', () async {
    final gate = Completer<void>();
    for (final dc in mockDataChannels) {
      dc.fakeBufferedAmount = _full;
      dc.getBufferedAmountGate = gate.future;
    }
    final newChannels = <MockDataChannel>[];
    onMockReliableChannelCreated = newChannels.add;

    final send = container.engine.sendDataPacket(_packet(), reliability: Reliability.reliable);
    await pumpEventQueue();

    // The full reconnect runs to the end while the old channel's buffered amount read is still pending.
    final ws = container.wsConnector;
    final previous = ws.handlers;
    container.engine.fullReconnectOnNext = true;
    final reconnected = container.room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
    ws.onDispose();
    for (var i = 0; i < 200 && identical(ws.handlers, previous); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await container.answerJoin();
    await reconnected;
    expect(newChannels, isNotEmpty);

    // The new channel is empty, which only the cached status knows once its live reading is high.
    for (final dc in newChannels) {
      dc.fakeBufferedAmount = _full;
    }
    gate.complete();
    await send;

    await container.engine
        .waitForBufferStatusLow(Reliability.reliable)
        .timeout(const Duration(milliseconds: 500), onTimeout: () => fail('the old channel marked the new one full'));
  });

  {
    const reliability = Reliability.reliable;
    test('a send whose bookkeeping fails while a full reconnect tears down completes', () async {
      final gate = Completer<void>();
      for (final dc in mockDataChannels) {
        dc.getBufferedAmountGate = gate.future;
      }
      final outcome = container.engine
          .sendDataPacket(_packet(), reliability: reliability)
          .then<Object?>((_) => null, onError: (Object e) => e);
      await pumpEventQueue();

      // Hold the full reconnect inside the publisher teardown.
      final paused = Completer<void>();
      final resume = Completer<void>();
      container.engine.publisher!.onDispose(() async {
        paused.complete();
        await resume.future;
      });
      container.engine.fullReconnectOnNext = true;
      container.wsConnector.onDispose();
      await paused.future.timeout(const Duration(seconds: 2));

      // The publisher's native connection is gone, so its channels are too.
      for (final dc in mockDataChannels) {
        dc.getBufferedAmountError = _channelGone;
      }
      gate.complete();
      final result = await outcome.timeout(const Duration(seconds: 2));
      resume.complete();

      expect(result, isNull, reason: 'the send surfaced $result');
    });
  }
}
