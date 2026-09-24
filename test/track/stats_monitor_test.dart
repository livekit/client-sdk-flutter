// Copyright 2024 LiveKit, Inc.
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

import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:mockito/mockito.dart';

import 'package:livekit_client/src/track/track.dart';
import 'package:livekit_client/src/types/other.dart';

class _Stream extends Mock implements rtc.MediaStream {}

class _MediaTrack extends Mock implements rtc.MediaStreamTrack {}

class _SlowTrack extends Track {
  _SlowTrack() : super(TrackType.VIDEO, TrackSource.camera, _Stream(), _MediaTrack());
  final pending = <Completer<bool>>[];
  int active = 0;
  int maximumActive = 0;

  @override
  Future<bool> monitorStats() async {
    active++;
    if (active > maximumActive) maximumActive = active;
    final result = Completer<bool>();
    pending.add(result);
    try {
      return await result.future;
    } finally {
      active--;
    }
  }
}

void main() {
  testWidgets('a slow stats request does not overlap, and monitoring resumes and stops', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final track = _SlowTrack();
    track.startMonitor();
    await tester.pump(const Duration(seconds: 2));
    expect(track.pending.length, 1);
    await tester.pump(const Duration(seconds: 6));
    expect(track.maximumActive, 1);
    expect(track.pending.length, 1);

    track.pending.single.complete(true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(track.pending.length, 2);
    track.stopMonitor();
    track.startMonitor();
    track.pending.last.complete(false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(track.pending.length, 3, reason: 'an old monitor must not cancel a restarted timer');
    track.stopMonitor();
    track.pending.last.complete(true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(track.pending.length, 3);
  });
}
