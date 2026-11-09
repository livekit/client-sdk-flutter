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

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'package:livekit_client/src/track/local/video.dart';
import 'package:livekit_client/src/track/options.dart';
import 'package:livekit_client/src/types/other.dart';
import '../mock/mediastream_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  LocalVideoTrack createTrack() {
    final mediaTrack = FakeMediaStreamTrack(id: 'video-1', kind: 'video');
    final stream = FakeMediaStream('stream-1');
    return LocalVideoTrack(
      TrackSource.camera,
      stream,
      mediaTrack,
      const CameraCaptureOptions(),
    );
  }

  group('clearSimulcastState', () {
    test('allows re-adding a backup codec after clearing', () {
      final track = createTrack();

      track.addSimulcastTrack('vp8', []);
      // simulates the server requesting the same backup codec again after a
      // reconnect, which previously threw because the map was never cleared
      expect(() => track.addSimulcastTrack('vp8', []), throwsException);

      track.clearSimulcastState();
      expect(track.simulcastCodecs, isEmpty);
      expect(() => track.addSimulcastTrack('vp8', []), returnsNormally);
    });

    test('clears encoding backups as well', () {
      final track = createTrack();
      track.encodingBackups[('sender-1', 0)] = rtc.RTCRtpEncoding();

      track.clearSimulcastState();

      expect(track.encodingBackups, isEmpty);
    });
  });
}
