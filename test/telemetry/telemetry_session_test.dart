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

/// What a Room's session hands the core, against a spy session: stats polling under track churn
/// and a stuck peer connection, room updates, and SDK warnings whatever the console level.
@TestOn('vm')
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import 'package:livekit_client/src/telemetry/telemetry_io.dart' show telemetryScopeFactory;
import 'package:livekit_client/src/uniffi/uniffi_io.dart' as ffi;
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';

void main() {
  late _SpyScope spy;
  late E2EContainer container;

  setUp(() async {
    spy = _SpyScope();
    final real = telemetryScopeFactory;
    addTearDown(() => telemetryScopeFactory = real);
    telemetryScopeFactory = () => real() == null ? null : spy;
    resetMockDataChannels();
    container = E2EContainer();
    if (container.room.telemetry == null) {
      markTestSkipped('no native library');
      return;
    }
    await container.connectRoom(
      otherParticipants: [
        lk_models.ParticipantInfo(
          sid: 'PA_other',
          identity: 'other',
          state: lk_models.ParticipantInfo_State.ACTIVE,
          tracks: [lk_models.TrackInfo(sid: 'TR_other', type: lk_models.TrackType.AUDIO)],
        ),
      ],
    );
    addTearDown(() {
      MockPeerConnection.onGetStats = null;
      return container.dispose();
    });
  });

  /// Track signals (a subscribe intent) every 100 ms for [duration].
  Future<void> churn(Duration duration) async {
    final publication = container.room.remoteParticipants.values.first.trackPublications.values.first;
    for (final end = DateTime.now().add(duration); DateTime.now().isBefore(end);) {
      container.room.telemetry?.subscribeStarted(publication);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  test('track signals every 100 ms never postpone a 1 s poll', () async {
    if (container.room.telemetry == null) return;
    final before = spy.submissions;
    await churn(const Duration(seconds: 4));
    expect(spy.submissions - before, greaterThanOrEqualTo(4), reason: 'one poll per second, two peer connections');
  });

  test('one read at a time, whatever signals arrive meanwhile', () async {
    if (container.room.telemetry == null) return;
    var inFlight = 0, most = 0;
    MockPeerConnection.onGetStats = () async {
      most = ++inFlight > most ? inFlight : most;
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      inFlight--;
    };
    await churn(const Duration(seconds: 4));
    expect(most, 1);
  });

  test('a peer connection that never answers holds no poll', () async {
    if (container.room.telemetry == null) return;
    MockPeerConnection.onGetStats = () {
      MockPeerConnection.onGetStats = null;
      return Completer<void>().future; // never answers
    };
    await Future<void>.delayed(const Duration(seconds: 2));
    final stuck = spy.submissions;
    await Future<void>.delayed(const Duration(seconds: 6)); // past the 5 s bound
    expect(spy.submissions, greaterThan(stuck), reason: 'the next reads go on');
  });

  test('a room update refreshes the identity', () async {
    if (container.room.telemetry == null) return;
    container.wsConnector.onData(
      lk_rtc.SignalResponse(
        roomUpdate: lk_rtc.RoomUpdate(room: lk_models.Room(name: 'renamed_room')),
      ).writeToBuffer(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(spy.room?.name, 'renamed_room');
    expect(spy.room?.sid, isNotNull, reason: 'an update without a sid keeps the one from the join');
    expect(spy.room?.participantIdentity, isNotNull);
  });

  test('SDK warnings reach telemetry whatever the console level', () async {
    if (container.room.telemetry == null) return;
    hierarchicalLoggingEnabled = true;
    final level = logger.level;
    addTearDown(() => logger.level = level);
    disableLogging();
    final console = <LogRecord>[];
    final listening = logger.onRecord.listen(console.add);
    addTearDown(listening.cancel);
    // A warning from one of the Room's handlers: filed under its session.
    container.wsConnector.onData(
      lk_rtc.SignalResponse(
        streamStateUpdate: lk_rtc.StreamStateUpdate(
          streamStates: [lk_rtc.StreamStateInfo(participantSid: 'nobody', trackSid: 'TR_nobody')],
        ),
      ).writeToBuffer(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(spy.logs.map((r) => r.body), contains('Participant not found for sid nobody'));
    expect(console, isEmpty, reason: 'the console stays silent');
  });
}

/// Records what the session hands the core and asks for a poll every second; everything else is
/// accepted and ignored (a span it cannot start is skipped).
class _SpyScope implements ffi.TelemetryScope {
  var submissions = 0;
  ffi.RoomIdentity? room;
  final logs = <ffi.LogRecord>[];

  @override
  int statsPollIntervalMs() => 1000;

  @override
  void recordPeerStats({
    required List<ffi.RtcStat> report,
    required Map<String, String> tracks,
    required int? timestampNs,
  }) => submissions++;

  @override
  void setRoom({required ffi.RoomIdentity room}) => this.room = room;

  @override
  void log({required ffi.LogRecord record}) => logs.add(record);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
