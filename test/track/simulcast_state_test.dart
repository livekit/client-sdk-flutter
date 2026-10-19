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

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'package:livekit_client/src/track/local/video.dart';
import 'package:livekit_client/src/track/options.dart';
import 'package:livekit_client/src/types/other.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  LocalVideoTrack createTrack() {
    final mediaTrack = _FakeMediaStreamTrack(id: 'video-1', kind: 'video');
    final stream = _FakeMediaStream('stream-1');
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

class _FakeMediaStream extends rtc.MediaStream {
  final List<rtc.MediaStreamTrack> _tracks = [];

  _FakeMediaStream(String id) : super(id, 'fake-owner');

  @override
  bool? get active => true;

  @override
  Future<void> addTrack(rtc.MediaStreamTrack track, {bool addToNative = true}) async {
    _tracks.add(track);
  }

  @override
  Future<rtc.MediaStream> clone() async => _FakeMediaStream('${id}_clone');

  @override
  List<rtc.MediaStreamTrack> getAudioTracks() => _tracks.where((t) => t.kind == 'audio').toList();

  @override
  Future<void> getMediaTracks() async {}

  @override
  List<rtc.MediaStreamTrack> getTracks() => List<rtc.MediaStreamTrack>.from(_tracks);

  @override
  List<rtc.MediaStreamTrack> getVideoTracks() => _tracks.where((t) => t.kind == 'video').toList();

  @override
  Future<void> removeTrack(rtc.MediaStreamTrack track, {bool removeFromNative = true}) async {
    _tracks.remove(track);
  }
}

class _FakeMediaStreamTrack implements rtc.MediaStreamTrack {
  @override
  rtc.StreamTrackCallback? onEnded;

  @override
  rtc.StreamTrackCallback? onMute;

  @override
  rtc.StreamTrackCallback? onUnMute;

  @override
  bool enabled;

  @override
  final String id;

  @override
  final String kind;

  @override
  String? get label => '$kind-track';

  @override
  bool? get muted => false;

  _FakeMediaStreamTrack({
    required this.id,
    required this.kind,
    this.enabled = true,
  });

  @override
  Future<void> adaptRes(int width, int height) async {}

  @override
  Future<void> applyConstraints([Map<String, dynamic>? constraints]) async {}

  @override
  Future<ByteBuffer> captureFrame() {
    throw UnimplementedError();
  }

  @override
  Future<rtc.MediaStreamTrack> clone() async => _FakeMediaStreamTrack(id: id, kind: kind, enabled: enabled);

  @override
  Future<void> dispose() async {}

  @override
  Map<String, dynamic> getConstraints() => const {};

  @override
  Map<String, dynamic> getSettings() => const {};

  @override
  Future<bool> hasTorch() async => false;

  @override
  void enableSpeakerphone(bool enable) {}

  @override
  Future<void> setTorch(bool torch) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<bool> switchCamera() async => false;
}
