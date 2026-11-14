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

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';
import 'signal_client_test.dart' show joinResponse, offerResponse;

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

  /// Starts a full reconnect and answers its join, leaving it to wait for the subscriber offer.
  /// The new, empty publisher channels exist from here on, but the reconnect has not finished.
  Future<void> startFullReconnect() async {
    final ws = container.wsConnector;
    final previousHandlers = ws.handlers;
    container.engine.fullReconnectOnNext = true;
    ws.onDispose();
    for (var i = 0; i < 200 && identical(ws.handlers, previousHandlers); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
    ws.onData(joinResponse.writeToBuffer());
  }

  void finishFullReconnect() => container.wsConnector.onData(offerResponse.writeToBuffer());

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

  test('a wait ends when a full reconnect replaces the full channel', () async {
    await fillReliableChannel();
    final wait = container.engine.waitForBufferStatusLow(Reliability.reliable);

    // The replaced channel never reports a drain, only the new one is empty.
    await startFullReconnect();
    finishFullReconnect();

    await wait.timeout(const Duration(seconds: 1));
  });

  test('a wait wakes as soon as the channel reports a drain', () async {
    await fillReliableChannel();
    var done = false;
    final wait = container.engine.waitForBufferStatusLow(Reliability.reliable).whenComplete(() => done = true);
    await pumpEventQueue();
    expect(done, isFalse);

    setBufferedAmount(null);
    for (final dc in mockDataChannels) {
      dc.onBufferedAmountLow?.call(0);
    }

    // Only zero-length timers run here, so a wait that polls on a timer would not have woken yet.
    await pumpEventQueue();
    expect(done, isTrue);
    await wait;
  });

  test('a wait does not leave an engine listener behind', () async {
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

    container.engine.markClosed();

    expect(await outcome.timeout(const Duration(seconds: 2)), isNot('resolved'));
  });

  test('a wait holds until a full reconnect finishes', () async {
    final engine = container.engine;
    await fillReliableChannel();

    final marker = lk_models.DataPacket(
      kind: lk_models.DataPacket_Kind.RELIABLE,
      user: lk_models.UserPacket(payload: [42]),
    );
    var markerSent = false;
    onMockReliableChannelCreated = (dc) => dc.onMessageSend = (message) {
      final packet = lk_models.DataPacket.fromBuffer(message.binary);
      if (packet.hasUser() && packet.user.payload.length == 1 && packet.user.payload.first == 42) {
        markerSent = true;
      }
    };

    // What a stream writer does with each chunk.
    final write = engine
        .waitForBufferStatusLow(Reliability.reliable)
        .then((_) => engine.sendDataPacket(marker, reliability: Reliability.reliable));

    // The new channel exists and is empty, but the reconnect waits for the subscriber transport.
    await startFullReconnect();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(markerSent, isFalse, reason: 'the write went out before the reconnect finished');

    finishFullReconnect();
    await write.timeout(const Duration(seconds: 2));
    expect(markerSent, isTrue, reason: 'the write never reached the new channel');
  });

  test('a wait does not carry over to the next connection', () async {
    await fillReliableChannel();
    final wait = container.engine.waitForBufferStatusLow(Reliability.reliable);
    final outcome = wait.then<Object?>((_) => 'resolved', onError: (Object e) => e);

    // A disconnect and a new connect between two checks of the wait. The new connection's
    // channels start out empty, so a wait that followed it would resolve.
    container.engine.markClosed();
    final connecting = container.engine.connect('ws://www.example.com', 'token');
    unawaited(container.answerJoin());

    expect(await outcome.timeout(const Duration(seconds: 2)), isNot('resolved'));
    await connecting;
  });
}
