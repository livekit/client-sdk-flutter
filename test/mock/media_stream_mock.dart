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

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

/// A media stream with no native counterpart, for tracks built in unit tests.
class FakeMediaStream extends rtc.MediaStream {
  final List<rtc.MediaStreamTrack> _tracks = [];

  FakeMediaStream(String id) : super(id, 'fake-owner');

  @override
  bool? get active => true;

  @override
  Future<void> addTrack(rtc.MediaStreamTrack track, {bool addToNative = true}) async {
    _tracks.add(track);
  }

  @override
  Future<rtc.MediaStream> clone() async => FakeMediaStream('${id}_clone');

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

class FakeMediaStreamTrack implements rtc.MediaStreamTrack {
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

  FakeMediaStreamTrack({required this.id, required this.kind, this.enabled = true});

  @override
  Future<void> applyConstraints([Map<String, dynamic>? constraints]) async {}

  @override
  Future<rtc.MediaStreamTrack> clone() async => FakeMediaStreamTrack(id: id, kind: kind, enabled: enabled);

  @override
  Future<void> dispose() async {}

  @override
  Future<void> adaptRes(int width, int height) async {}

  @override
  Map<String, dynamic> getConstraints() => const {};

  @override
  Map<String, dynamic> getSettings() => const {};

  @override
  Future<void> stop() async {}

  @override
  void enableSpeakerphone(bool enable) {}

  @override
  Future<ByteBuffer> captureFrame() => throw UnimplementedError();

  @override
  Future<bool> hasTorch() async => false;

  @override
  Future<void> setTorch(bool torch) async {}

  @override
  Future<bool> switchCamera() async => false;

  @override
  String toString() => 'FakeMediaStreamTrack(id: $id, kind: $kind, enabled: $enabled)';
}
