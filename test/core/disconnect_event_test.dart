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

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/internal/events.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
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
    container.wsConnector.connectError = CertificatePinningException(
      'Certificate pin mismatch',
      host: 'www.example.com',
    );

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

    container.wsConnector.connectError = CertificatePinningException(
      'Certificate pin mismatch',
      host: 'www.example.com',
    );
    container.engine.fullReconnectOnNext = true;
    await container.engine.attemptReconnect(ClientDisconnectReason.reconnectRetry);

    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(engineDisconnectedEvents, hasLength(1));
    expect(engineDisconnectedEvents.single.reason, DisconnectReason.signalingConnectionFailure);
    expect(roomDisconnectedEvents, hasLength(1));
    expect(roomDisconnectedEvents.single.reason, DisconnectReason.signalingConnectionFailure);
  });

  test('disconnect completes when the server closes the socket without echoing the leave', () async {
    await container.connectRoom();
    final disconnectedEvents = <RoomDisconnectedEvent>[];
    container.room.events.on<RoomDisconnectedEvent>(disconnectedEvents.add);

    final disconnecting = container.room.disconnect();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    // media nodes drop queued leave messages on close, so only the close arrives
    container.wsConnector.onDispose();

    await disconnecting.timeout(const Duration(seconds: 2));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(container.room.connectionState, ConnectionState.disconnected);
    expect(disconnectedEvents.map((e) => e.reason), [DisconnectReason.clientInitiated]);
    expect(_leavesSent(container), 1);
  });

  test('disconnect with a leave echo followed by the socket close emits exactly one disconnected event', () async {
    await container.connectRoom();
    final disconnectedEvents = <RoomDisconnectedEvent>[];
    container.room.events.on<RoomDisconnectedEvent>(disconnectedEvents.add);
    final engineDisconnects = <EngineDisconnectedEvent>[];
    final engineListener = container.engine.createListener()..on<EngineDisconnectedEvent>(engineDisconnects.add);

    final disconnecting = container.room.disconnect();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    container.wsConnector.onData(_leave(lk_rtc.LeaveRequest_Action.DISCONNECT));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    // the real socket reports its close after the SDK disposed it
    container.wsConnector.onDispose();

    await disconnecting.timeout(const Duration(seconds: 2));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await engineListener.dispose();

    expect(container.room.connectionState, ConnectionState.disconnected);
    expect(disconnectedEvents, hasLength(1));
    expect(engineDisconnects, hasLength(1));
    expect(_leavesSent(container), 1);
  });

  test('disconnect returns with the room torn down, without waiting on the server', () async {
    await container.connectRoom();
    final disconnectedEvents = <RoomDisconnectedEvent>[];
    container.room.events.on<RoomDisconnectedEvent>(disconnectedEvents.add);

    // no leave echo, no socket close from the server, nothing at all
    await container.room.disconnect().timeout(const Duration(seconds: 2));

    expect(container.room.connectionState, ConnectionState.disconnected);
    expect(container.engine.publisher, isNull);
    expect(container.engine.subscriber, isNull);
    expect(container.room.localParticipant, isNull);
    expect(_leavesSent(container), 1);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(disconnectedEvents.map((e) => e.reason), [DisconnectReason.clientInitiated]);
  });

  test('overlapping disconnect calls send one Leave and report one disconnect', () async {
    await container.connectRoom();
    final disconnectedEvents = <RoomDisconnectedEvent>[];
    container.room.events.on<RoomDisconnectedEvent>(disconnectedEvents.add);

    final first = container.room.disconnect();
    // the second call finds the first one tearing down and returns at once
    await container.room.disconnect().timeout(const Duration(seconds: 2));
    await first.timeout(const Duration(seconds: 2));

    expect(container.room.localParticipant, isNull);
    expect(container.room.connectionState, ConnectionState.disconnected);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(disconnectedEvents, hasLength(1));
    expect(_leavesSent(container), 1);
  });

  test('connect again to the same room right after disconnect returns', () async {
    // the case behind issue 553: cleanup from the first session racing the second connect
    await container.connectRoom();
    await container.room.disconnect();

    final events = <RoomEvent>[];
    container.room.events.on<RoomConnectedEvent>(events.add);
    container.room.events.on<RoomDisconnectedEvent>(events.add);
    await container.connectRoom();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(container.room.connectionState, ConnectionState.connected);
    expect(container.room.localParticipant, isNotNull);
    expect(events.whereType<RoomDisconnectedEvent>(), isEmpty, reason: 'no stale disconnect from the first session');
    expect(events.whereType<RoomConnectedEvent>(), hasLength(1));

    await container.room.disconnect().timeout(const Duration(seconds: 2));
    expect(container.room.connectionState, ConnectionState.disconnected);
  });

  test('a connect started from the disconnected event survives the old teardown', () async {
    // an app that rejoins as soon as it hears it was disconnected
    await container.connectRoom();
    var tornDownWhenReported = false;
    final rejoin = Completer<Object?>();
    final listener = container.room.createListener();
    listener.once<RoomDisconnectedEvent>((_) {
      // the event comes after the teardown, never in the middle of it
      tornDownWhenReported = container.room.localParticipant == null && container.engine.publisher == null;
      rejoin.complete(container.connectRoom().then<Object?>((_) => null, onError: (Object e) => e));
    });

    await container.room.disconnect();
    final rejoinError = await rejoin.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () => fail('the disconnected event must reach the app'),
    );
    expect(tornDownWhenReported, isTrue);
    expect(rejoinError, isNull, reason: 'the rejoin must not fail');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(container.room.connectionState, ConnectionState.connected);
    expect(container.room.localParticipant, isNotNull);

    // and the rejoined session tears down on its own disconnect
    await container.room.disconnect().timeout(const Duration(seconds: 2));
    expect(container.room.connectionState, ConnectionState.disconnected);
    expect(container.room.localParticipant, isNull);
    await listener.dispose();
  });

  test('a disconnect() from a callback the teardown runs returns at once', () async {
    await container.connectRoom();
    final disconnectedEvents = <RoomDisconnectedEvent>[];
    container.room.events.on<RoomDisconnectedEvent>(disconnectedEvents.add);
    // an app that leaves the room when its local participant goes away
    var hookFinished = false;
    container.room.localParticipant!.onDispose(() async {
      await container.room.disconnect();
      hookFinished = true;
    });

    await container.room.disconnect().timeout(const Duration(seconds: 2));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(hookFinished, isTrue);
    expect(container.room.connectionState, ConnectionState.disconnected);
    expect(disconnectedEvents, hasLength(1));
    expect(_leavesSent(container), 1);
  });
}

List<int> _leave(lk_rtc.LeaveRequest_Action action) => lk_rtc.SignalResponse(
  leave: lk_rtc.LeaveRequest(action: action, reason: lk_models.DisconnectReason.CLIENT_INITIATED),
).writeToBuffer();

/// How many Leave requests the SDK sent over any socket.
int _leavesSent(E2EContainer container) =>
    container.wsConnector.sentData.where((data) => lk_rtc.SignalRequest.fromBuffer(data).hasLeave()).length;
