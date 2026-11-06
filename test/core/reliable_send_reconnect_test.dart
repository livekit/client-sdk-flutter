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
import 'package:flutter_webrtc/flutter_webrtc.dart' show RTCPeerConnectionState;

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/internal/events.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';
import '../mock/websocket_mock.dart';
import 'signal_client_test.dart' show joinResponse, offerResponse;

lk_models.DataPacket _marker() => lk_models.DataPacket(
  kind: lk_models.DataPacket_Kind.RELIABLE,
  user: lk_models.UserPacket(payload: [42]),
);

bool _isMarker(lk_models.DataPacket packet) =>
    packet.hasUser() && packet.user.payload.length == 1 && packet.user.payload.first == 42;

void main() {
  late E2EContainer container;
  late MockWebSocketConnector ws;

  setUp(() async {
    resetMockDataChannels();
    container = E2EContainer();
    ws = container.wsConnector;
    await container.connectRoom();
    // The mock loops published data back into this room as if a remote sent it, which the room
    // rejects. These tests record what is sent instead.
    for (final dc in mockDataChannels) {
      dc.onMessageSend = null;
    }
  });

  tearDown(() async {
    await container.dispose();
  });

  /// Records every packet sent on the reliable channels a full reconnect creates.
  List<lk_models.DataPacket> recordNewChannels() {
    final sent = <lk_models.DataPacket>[];
    onMockReliableChannelCreated = (dc) => dc.onMessageSend = (message) {
      sent.add(lk_models.DataPacket.fromBuffer(message.binary));
    };
    return sent;
  }

  /// Starts a full reconnect and answers its join, leaving it to wait for the subscriber offer.
  /// The new publisher channels exist from here on, but the reconnect has not finished.
  Future<void> startFullReconnect() async {
    final previousHandlers = ws.handlers;
    container.engine.fullReconnectOnNext = true;
    ws.onDispose();
    for (var i = 0; i < 200 && identical(ws.handlers, previousHandlers); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(identical(ws.handlers, previousHandlers), isFalse, reason: 'the SDK never re-opened the signal connection');
    await Future<void>.delayed(const Duration(milliseconds: 1));
    ws.onData(joinResponse.writeToBuffer());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.engine.isFullReconnectInProgress, isTrue);
  }

  Future<void> finishFullReconnect() async {
    final reconnected = container.room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
    ws.onData(offerResponse.writeToBuffer());
    await reconnected;
  }

  test('a reliable send during a full reconnect goes out on the new channel once it finishes', () async {
    final sent = recordNewChannels();
    await startFullReconnect();

    var completed = false;
    final send = container.engine
        .sendDataPacket(_marker(), reliability: Reliability.reliable)
        .whenComplete(() => completed = true);

    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(completed, isFalse, reason: 'the send finished while the reconnect was still running');

    await finishFullReconnect();
    await send.timeout(const Duration(seconds: 2));
    expect(sent.where(_isMarker), hasLength(1), reason: 'the packet never reached the new channel');
  });

  test('a full reconnect restarts reliable sequence numbers', () async {
    for (var i = 0; i < 3; i++) {
      await container.room.localParticipant!.publishData([i], reliable: true);
    }

    final sent = recordNewChannels();
    await startFullReconnect();
    await finishFullReconnect();

    await container.engine.sendDataPacket(_marker(), reliability: Reliability.reliable);
    final marker = sent.singleWhere(_isMarker);
    expect(marker.sequence, 1, reason: 'the new session carried on the old session\'s sequence numbers');
  });

  test('a send waiting out a reconnect fails when the engine closes', () async {
    await startFullReconnect();

    final send = container.engine.sendDataPacket(_marker(), reliability: Reliability.reliable);
    final failed = expectLater(send, throwsA(isA<UnexpectedConnectionState>()));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await container.engine.disconnect();

    await failed.timeout(const Duration(seconds: 2));
  });

  test('a reliable send during a resume goes out once', () async {
    final sent = <lk_models.DataPacket>[];
    for (final dc in mockDataChannels) {
      dc.onMessageSend = (message) => sent.add(lk_models.DataPacket.fromBuffer(message.binary));
    }
    // The server acknowledges this one in its reconnect response.
    await container.room.localParticipant!.publishData([1], reliable: true);
    final acknowledged = sent.last.sequence;

    final previousHandlers = ws.handlers;
    ws.onDispose();
    for (var i = 0; i < 200 && identical(ws.handlers, previousHandlers); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(ws.uri?.queryParameters['reconnect'], '1', reason: 'this test needs a resume');

    final send = container.engine.sendDataPacket(_marker(), reliability: Reliability.reliable);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final reconnected = container.room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
    ws.onData(
      lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse(lastMessageSeq: acknowledged)).writeToBuffer(),
    );
    await reconnected;
    await send.timeout(const Duration(seconds: 2));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(sent.where(_isMarker), hasLength(1));
  });

  test('a reliable send after the reconnect response but before the resume ends goes out', () async {
    final sent = <lk_models.DataPacket>[];
    for (final dc in mockDataChannels) {
      dc.onMessageSend = (message) => sent.add(lk_models.DataPacket.fromBuffer(message.binary));
    }
    await container.room.localParticipant!.publishData([1], reliable: true);
    final acknowledged = sent.last.sequence;
    // The first send negotiates the publisher after a debounce. Let that finish before the resume
    // starts, the mock cannot run two offers at once.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Hold the primary connection in connecting so the resume is still running after its reconnect
    // response has replayed the buffer.
    final primary = container.engine.subscriber!.pc as MockPeerConnection;
    primary.connectionState = RTCPeerConnectionState.RTCPeerConnectionStateConnecting;

    final previousHandlers = ws.handlers;
    ws.onDispose();
    for (var i = 0; i < 200 && identical(ws.handlers, previousHandlers); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(ws.uri?.queryParameters['reconnect'], '1', reason: 'this test needs a resume');

    final responded = container.engine.events.waitFor<SignalReconnectedEvent>(duration: const Duration(seconds: 2));
    ws.onData(
      lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse(lastMessageSeq: acknowledged)).writeToBuffer(),
    );
    await responded;
    // The resume sets restartingIce right before it waits for the primary connection.
    for (var i = 0; i < 200 && container.engine.subscriber?.restartingIce != true; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(container.engine.subscriber?.restartingIce, isTrue, reason: 'the resume never waited for the primary');

    // The replay is over and the resume is waiting for the primary. A send here used to be parked
    // in the resend buffer, which nothing replayed again.
    final send = container.engine.sendDataPacket(_marker(), reliability: Reliability.reliable);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final reconnected = container.room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
    primary.connectionState = RTCPeerConnectionState.RTCPeerConnectionStateConnected;
    await reconnected;
    await send.timeout(const Duration(seconds: 2));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(sent.where(_isMarker), hasLength(1), reason: 'the packet was buffered after the replay and never sent');
  });
}
