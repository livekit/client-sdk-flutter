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
import 'package:livekit_client/src/support/websocket.dart';
import 'package:livekit_client/src/types/internal.dart';
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';
import '../mock/websocket_mock.dart';

// A resume restarts ICE on a publisher that was negotiated before. The publisher keeps reporting
// connected over its old candidate pair, after a migration to the old media node, so the resume
// must not count as done before the answer to the restart offer is applied and the selected
// candidate pair has moved off the old one.

lk_models.DataPacket _marker() => lk_models.DataPacket(
  kind: lk_models.DataPacket_Kind.RELIABLE,
  user: lk_models.UserPacket(payload: [42]),
);

bool _isMarker(lk_models.DataPacket packet) =>
    packet.hasUser() && packet.user.payload.length == 1 && packet.user.payload.first == 42;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late E2EContainer container;
  late Room room;
  late MockWebSocketConnector ws;
  late List<EngineEvent> engineEvents;
  late List<RoomEvent> roomEvents;
  late List<lk_models.DataPacket> sent;

  Future<void> connect({ConnectOptions? connectOptions}) async {
    await container.connectRoom(connectOptions: connectOptions);
    // Record what is sent instead of looping it back into this room.
    for (final dc in mockDataChannels) {
      dc.onMessageSend = (message) => sent.add(lk_models.DataPacket.fromBuffer(message.binary));
    }
    container.engine.events.listen(engineEvents.add);
    room.events.listen(roomEvents.add);
  }

  setUp(() {
    resetMockDataChannels();
    container = E2EContainer();
    room = container.room;
    ws = container.wsConnector;
    engineEvents = [];
    roomEvents = [];
    sent = [];
  });

  tearDown(() async {
    await container.dispose();
  });

  List<int> sentOfferIds() => ws.sentData
      .map(lk_rtc.SignalRequest.fromBuffer)
      .where((request) => request.hasOffer())
      .map((request) => request.offer.id)
      .toList();

  Future<int> waitForOffer({required int after}) async {
    for (var i = 0; i < 300; i++) {
      final ids = sentOfferIds().where((id) => id > after);
      if (ids.isNotEmpty) return ids.last;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('the SDK sent no publisher offer after offer $after');
  }

  void answerOffer(int offerId) => ws.onData(
    lk_rtc.SignalResponse(
      answer: lk_rtc.SessionDescription(type: 'answer', sdp: 'v=0', id: offerId),
    ).writeToBuffer(),
  );

  /// Negotiates the publisher and brings it to connected, as a publish does. Returns the offer id.
  Future<int> negotiatePublisher() async {
    await container.engine.negotiate();
    final offerId = await waitForOffer(after: 0);
    answerOffer(offerId);
    for (var i = 0; i < 100; i++) {
      if (container.engine.publisher!.pc.connectionState == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        return offerId;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('the publisher never connected');
  }

  Future<void> waitForNewSignalConnection(WebSocketEventHandlers? previous) async {
    for (var i = 0; i < 200 && identical(ws.handlers, previous); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(identical(ws.handlers, previous), isFalse, reason: 'the SDK never re-opened the signal connection');
  }

  /// Answers a resume the way the receiving node does.
  Future<void> answerResume(WebSocketEventHandlers? previous) async {
    await waitForNewSignalConnection(previous);
    expect(ws.uri?.queryParameters['reconnect'], '1', reason: 'expected a resume');
    ws.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());
  }

  /// What a node migration does: the server asks the client to resume.
  void sendResumeLeave() => ws.onData(
    lk_rtc.SignalResponse(
      leave: lk_rtc.LeaveRequest(
        action: lk_rtc.LeaveRequest_Action.RESUME,
        reason: lk_models.DisconnectReason.MIGRATION,
      ),
    ).writeToBuffer(),
  );

  test('a resume is not done, and reliable data stays held, until the publisher ICE restart finished', () async {
    await connect();
    final firstOffer = await negotiatePublisher();
    final publisherPc = container.engine.publisher!.pc as MockPeerConnection;
    publisherPc.selectedCandidatePairId = 'old-pair';

    final previous = ws.handlers;
    sendResumeLeave();
    await answerResume(previous);
    final restartOffer = await waitForOffer(after: firstOffer);

    // The old candidate pair still reports connected.
    publisherPc.onConnectionState?.call(RTCPeerConnectionState.RTCPeerConnectionStateConnected);

    var sendDone = false;
    final send = container.engine
        .sendDataPacket(_marker(), reliability: Reliability.reliable)
        .whenComplete(() => sendDone = true);

    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(engineEvents.whereType<EngineResumedEvent>(), isEmpty, reason: 'resumed before the restart was answered');
    expect(sendDone, isFalse, reason: 'a reliable send went out before the restart was answered');

    // The answer is applied and the publisher is connected, still over the old pair.
    answerOffer(restartOffer);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(engineEvents.whereType<EngineResumedEvent>(), isEmpty, reason: 'resumed while still on the old pair');
    expect(roomEvents.whereType<RoomReconnectedEvent>(), isEmpty);
    expect(sendDone, isFalse, reason: 'a reliable send went out while the publisher was still on the old pair');
    expect(sent.where(_isMarker), isEmpty);

    final reconnected = room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 2));
    // The new ICE generation takes over. On one node this changes no connection state at all.
    publisherPc.selectedCandidatePairId = 'new-pair';
    await reconnected;
    await send.timeout(const Duration(seconds: 2));

    expect(engineEvents.whereType<EngineResumedEvent>(), hasLength(1));
    expect(engineEvents.whereType<EngineFullRestartingEvent>(), isEmpty);
    expect(sent.where(_isMarker), hasLength(1));
  });

  test(
    'a publisher that does not finish its ICE restart in time fails the resume, then a full reconnect runs',
    () async {
      await connect(
        connectOptions: const ConnectOptions(
          timeouts: Timeouts(
            connection: Duration(seconds: 10),
            debounce: Duration(milliseconds: 20),
            publish: Duration(seconds: 10),
            subscribe: Duration(seconds: 10),
            peerConnection: Duration(milliseconds: 500),
            iceRestart: Duration(seconds: 10),
          ),
        ),
      );
      final firstOffer = await negotiatePublisher();
      (container.engine.publisher!.pc as MockPeerConnection).selectedCandidatePairId = 'old-pair';

      final previous = ws.handlers;
      sendResumeLeave();
      await answerResume(previous);
      final restartOffer = await waitForOffer(after: firstOffer);
      final resumeHandlers = ws.handlers;

      // The restart is answered and the publisher reports connected, but it never leaves its old
      // pair, as when it cannot reach the server any more. After the timeout the next attempt
      // re-joins.
      answerOffer(restartOffer);
      await waitForNewSignalConnection(resumeHandlers);
      expect(ws.uri?.queryParameters.containsKey('reconnect'), isFalse, reason: 'the next attempt must re-join');
      expect(engineEvents.whereType<EngineResumedEvent>(), isEmpty, reason: 'the failed resume was reported done');

      final reconnected = room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
      await container.answerJoin();
      await reconnected;

      expect(engineEvents.whereType<EngineFullRestartingEvent>(), hasLength(1));
      expect(engineEvents.whereType<EngineRestartedEvent>(), hasLength(1));
      expect(engineEvents.whereType<EngineResumedEvent>(), isEmpty);
    },
  );

  test('without a selected pair in the stats, the applied answer and the connected state end the wait', () async {
    await connect();
    final firstOffer = await negotiatePublisher();

    final previous = ws.handlers;
    sendResumeLeave();
    await answerResume(previous);
    final restartOffer = await waitForOffer(after: firstOffer);

    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(engineEvents.whereType<EngineResumedEvent>(), isEmpty, reason: 'resumed before the restart was answered');

    final reconnected = room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 2));
    answerOffer(restartOffer);
    await reconnected;
    expect(engineEvents.whereType<EngineFullRestartingEvent>(), isEmpty);
  });

  test('a client that never published resumes without waiting for the publisher', () async {
    await connect();

    final previous = ws.handlers;
    sendResumeLeave();
    await waitForNewSignalConnection(previous);
    final reconnected = room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 2));
    final answered = Stopwatch()..start();
    ws.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());
    await reconnected;

    expect(answered.elapsed, lessThan(const Duration(milliseconds: 500)));
    expect(sentOfferIds(), isEmpty, reason: 'a publisher that was never negotiated got an offer');
    expect(engineEvents.whereType<EngineResumedEvent>(), hasLength(1));
  });

  test('a disconnect while the resume waits for the publisher ends the attempt without a resumed event', () async {
    await connect();
    final firstOffer = await negotiatePublisher();

    final previous = ws.handlers;
    final attempt = container.engine.attemptReconnect(ClientDisconnectReason.leaveReconnect);
    await answerResume(previous);
    await waitForOffer(after: firstOffer);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final resumeHandlers = ws.handlers;

    await room.disconnect();
    // The attempt ends right away, not when the publisher wait times out.
    await attempt.timeout(const Duration(seconds: 1));
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(engineEvents.whereType<EngineResumedEvent>(), isEmpty);
    expect(roomEvents.whereType<RoomReconnectedEvent>(), isEmpty);
    expect(roomEvents.whereType<RoomDisconnectedEvent>(), hasLength(1));
    expect(identical(ws.handlers, resumeHandlers), isTrue, reason: 'the SDK reconnected after the disconnect');
    expect(container.engine.isClosed, isTrue);
  });
}
