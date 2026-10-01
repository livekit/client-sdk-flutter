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

/// The opt-out stops what Dart collects for a Room that stays connected. Its own process: the
/// opt-out is process-wide.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';

void main() {
  test('a connected Room collects no stats after the opt-out', () async {
    final container = E2EContainer();
    if (container.room.telemetry == null) {
      markTestSkipped('no native library');
      return;
    }
    // A track already in the room waits for media: the core asks for a poll every second.
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
    for (var i = 0; i < 50 && MockPeerConnection.statsCalls == 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(MockPeerConnection.statsCalls, greaterThan(0), reason: 'polling before the opt-out');

    // The app opts out while a poll reads one peer connection, and that read fails: the poll
    // must not go on to read the other one.
    late Future<void> purged;
    var before = -1;
    MockPeerConnection.onGetStats = () async {
      MockPeerConnection.onGetStats = null;
      purged = LiveKitClient.disableTelemetry();
      before = MockPeerConnection.statsCalls;
      throw StateError('peer connection closing');
    };
    for (var i = 0; i < 50 && before < 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    await purged;
    await Future<void>.delayed(const Duration(seconds: 3));
    expect(container.room.connectionState, ConnectionState.connected, reason: 'the Room is retained');
    expect(MockPeerConnection.statsCalls, before, reason: 'no stats collected after the opt-out');
    await container.dispose();
  });
}
