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

/// A stats read that succeeds after another isolate opted the process out is never submitted, and
/// nothing more is read (telemetry_opt_out_test.dart covers an opt-out in the reading isolate,
/// during a read that fails). Its own process: the opt-out is process-wide.
@TestOn('vm')
library;

import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/src/telemetry/telemetry_io.dart' show telemetryScopeFactory;
import 'package:livekit_client/src/uniffi/uniffi_io.dart' as ffi;
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';

void main() {
  test('a read that completes after another isolate opted out is not submitted', () async {
    final spy = _SpyScope();
    final real = telemetryScopeFactory;
    addTearDown(() => telemetryScopeFactory = real);
    telemetryScopeFactory = () => real() == null ? null : spy;

    final container = E2EContainer();
    if (container.room.telemetry == null) {
      markTestSkipped('no native library');
      return;
    }
    expect(ffi.telemetryIsDisabled(), isFalse);
    await container.connectRoom();
    for (var i = 0; i < 50 && spy.submissions == 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(spy.submissions, greaterThan(0), reason: 'submitting before the opt-out');

    // Another isolate (another Flutter engine) opts out while this one's poll waits for a read that
    // then succeeds. This isolate's own state never hears of it; only the core does.
    var reads = -1, submissions = -1;
    MockPeerConnection.onGetStats = () async {
      MockPeerConnection.onGetStats = null;
      await Isolate.run(ffi.telemetryDisable);
      (reads, submissions) = (MockPeerConnection.statsCalls, spy.submissions);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    };
    for (var i = 0; i < 50 && reads < 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    await Future<void>.delayed(const Duration(seconds: 3));
    expect(spy.submissions, submissions, reason: 'the late answer is not submitted');
    expect(MockPeerConnection.statsCalls, reads, reason: 'and nothing more is read');
    await container.dispose();
  });
}

/// Counts stats submissions and asks for a poll every second; everything else is accepted and
/// ignored (a span it cannot start is skipped).
class _SpyScope implements ffi.TelemetryScope {
  var submissions = 0;

  @override
  int statsPollIntervalMs() => 1000;

  @override
  void recordPeerStats({
    required List<ffi.RtcStat> report,
    required Map<String, String> tracks,
    required int? timestampNs,
  }) => submissions++;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
