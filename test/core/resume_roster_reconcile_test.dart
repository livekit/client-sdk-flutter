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

// Ported from rust-sdks' `test_resume_synthesizes_disconnect_for_participant_that_left`
// (livekit/tests/reconnection_test.rs). That test needs a live SFU plus a
// fault-injection switch that drops DISCONNECTED updates; here the mock signal
// transport gives the same setup for free — we simply never deliver the
// leaver's disconnect, then answer the resume with a roster snapshot that omits
// them. The observer/leaver/witness shape is kept: the witness proves the
// reconciliation only removes participants that actually left.

@Timeout(Duration(seconds: 10))
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';
import '../mock/test_data.dart';
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
    await container.simulateRemoteParticipantJoin('leaver');
    await container.simulateRemoteParticipantJoin('witness');
    expect(room.remoteParticipants.keys, containsAll(<String>['leaver', 'witness']));
  });

  tearDown(() async {
    await container.dispose();
  });

  /// Drop the signal socket, which the engine recovers with a resume, and wait
  /// until it has re-opened the connection.
  Future<void> resumeSignalConnection() async {
    final previousHandlers = ws.handlers;
    ws.onDispose();
    for (var i = 0; i < 200 && identical(ws.handlers, previousHandlers); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(identical(ws.handlers, previousHandlers), isFalse, reason: 'SDK never re-opened the signal connection');
    expect(ws.uri?.queryParameters['reconnect'], '1', reason: 'expected a resume, not a re-join');
    ws.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());
  }

  lk_models.ParticipantInfo info(String identity) => lk_models.ParticipantInfo(
    sid: '${identity}_sid',
    identity: identity,
    state: lk_models.ParticipantInfo_State.ACTIVE,
  );

  /// The roster snapshot the server sends right after the `ReconnectResponse`.
  /// It always carries the local participant — the server includes it so
  /// metadata changes propagate — which is what marks it as a full roster
  /// rather than an ordinary partial update.
  void sendRosterSnapshot(List<String> identities) {
    ws.onData(
      lk_rtc.SignalResponse(
        update: lk_rtc.ParticipantUpdate(
          participants: [
            localParticipantData,
            ...identities.map(info),
          ],
        ),
      ).writeToBuffer(),
    );
  }

  /// An ordinary update: only the participants that changed, no local entry.
  void sendPartialUpdate(List<String> identities) {
    ws.onData(
      lk_rtc.SignalResponse(
        update: lk_rtc.ParticipantUpdate(participants: identities.map(info).toList()),
      ).writeToBuffer(),
    );
  }

  test('resume synthesizes a disconnect for a participant that left', () async {
    final disconnected = <String>[];
    final cancel = room.events.listen((event) {
      if (event is ParticipantDisconnectedEvent) {
        disconnected.add(event.participant.identity);
      }
    });

    await resumeSignalConnection();
    // The leaver left while we were away; its DISCONNECTED update went to the
    // socket we no longer had, so the snapshot is the only evidence.
    sendRosterSnapshot(['witness']);
    await room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await cancel();

    expect(disconnected, ['leaver']);
    expect(room.remoteParticipants.keys, ['witness']);
  });

  test('resume keeps every participant still present in the snapshot', () async {
    final disconnected = <String>[];
    final cancel = room.events.listen((event) {
      if (event is ParticipantDisconnectedEvent) {
        disconnected.add(event.participant.identity);
      }
    });

    await resumeSignalConnection();
    sendRosterSnapshot(['leaver', 'witness']);
    await room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await cancel();

    expect(disconnected, isEmpty);
    expect(room.remoteParticipants.keys, containsAll(<String>['leaver', 'witness']));
  });

  test('resume without a roster snapshot leaves the roster untouched', () async {
    // Safety property: reconciliation is armed by the signal reconnect but only
    // fires on a snapshot. If the server never sends one, we must not conclude
    // that everyone left.
    final disconnected = <String>[];
    final cancel = room.events.listen((event) {
      if (event is ParticipantDisconnectedEvent) {
        disconnected.add(event.participant.identity);
      }
    });

    await resumeSignalConnection();
    await room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await cancel();

    expect(disconnected, isEmpty);
    expect(room.remoteParticipants.keys, containsAll(<String>['leaver', 'witness']));
  });

  test('a partial update is not mistaken for the roster snapshot', () async {
    // An ordinary update lists only the participants that changed. Treating one
    // as a full roster would evict everybody else, so it must not disarm or
    // trigger the reconciliation.
    final disconnected = <String>[];
    final cancel = room.events.listen((event) {
      if (event is ParticipantDisconnectedEvent) {
        disconnected.add(event.participant.identity);
      }
    });

    await resumeSignalConnection();
    sendPartialUpdate(['newcomer']);
    await room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await cancel();

    expect(disconnected, isEmpty, reason: 'a partial update must not evict participants');
    expect(room.remoteParticipants.keys, containsAll(<String>['leaver', 'witness', 'newcomer']));
  });

  test('the arming expires so a much later update cannot trigger it', () async {
    final disconnected = <String>[];
    final cancel = room.events.listen((event) {
      if (event is ParticipantDisconnectedEvent) {
        disconnected.add(event.participant.identity);
      }
    });

    await resumeSignalConnection();
    await room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
    // No snapshot ever arrives. Once the window closes, a later snapshot-shaped
    // update is just a normal update and must not reconcile against it.
    await Future<void>.delayed(const Duration(seconds: 6));
    sendRosterSnapshot(['newcomer']);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await cancel();

    expect(disconnected, isEmpty);
    expect(room.remoteParticipants.keys, containsAll(<String>['leaver', 'witness', 'newcomer']));
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('a full reconnect does not run the resume reconciliation', () async {
    // The full-restart path unwinds the roster itself and rebuilds it from the
    // JoinResponse; the armed snapshot must not double-fire on top of that.
    final disconnected = <String>[];
    final cancel = room.events.listen((event) {
      if (event is ParticipantDisconnectedEvent) {
        disconnected.add(event.participant.identity);
      }
    });

    // Arm the reconciliation first, then escalate: a resume that reaches the
    // ReconnectResponse and then fails takes exactly this path, and the
    // arming must not survive into the restart.
    await resumeSignalConnection();

    final previousHandlers = ws.handlers;
    container.engine.fullReconnectOnNext = true;
    ws.onDispose();
    for (var i = 0; i < 200 && identical(ws.handlers, previousHandlers); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await cancel();

    // exactly one disconnect each, from the restart unwind — not doubled
    expect(disconnected..sort(), ['leaver', 'witness']);
  });
}
