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

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/support/native.dart';

class _FakeProcessor implements TrackProcessor<AudioProcessorOptions> {
  final List<String> initTrackIds = [];
  int destroyCount = 0;

  @override
  String get name => 'fake';

  @override
  Future<void> init(AudioProcessorOptions options) async => initTrackIds.add(options.track.id!);

  @override
  Future<void> restart(AudioProcessorOptions options) async {}

  @override
  Future<void> destroy() async => destroyCount++;

  @override
  Future<void> onPublish(Room room) async {}

  @override
  Future<void> onUnpublish() async {}

  @override
  rtc.MediaStreamTrack? get processedTrack => null;
}

class _FakeSender implements rtc.RTCRtpSender {
  final List<String?> replacedTrackIds = [];

  @override
  Future<void> replaceTrack(rtc.MediaStreamTrack? track) async => replacedTrackIds.add(track?.id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTransceiver implements rtc.RTCRtpTransceiver {
  _FakeTransceiver(this.sender);

  @override
  final rtc.RTCRtpSender sender;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const webrtcChannel = MethodChannel('FlutterWebRTC.Method');

  var trackCounter = 0;

  setUp(() {
    trackCounter = 0;
    messenger.setMockMethodCallHandler(webrtcChannel, (call) async {
      if (call.method == 'getUserMedia') {
        trackCounter++;
        return <String, dynamic>{
          'streamId': 'stream-$trackCounter',
          'audioTracks': [
            <String, dynamic>{'id': 'mic-$trackCounter', 'label': 'mic', 'kind': 'audio', 'enabled': true},
          ],
          'videoTracks': <dynamic>[],
        };
      }
      return null;
    });
    messenger.setMockMethodCallHandler(Native.channel, (call) async => true);
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(webrtcChannel, null);
    messenger.setMockMethodCallHandler(Native.channel, null);
  });

  Future<(LocalAudioTrack, _FakeProcessor, _FakeSender)> createPublishedTrack() async {
    final processor = _FakeProcessor();
    final track = await LocalAudioTrack.create(AudioCaptureOptions(processor: processor));
    await track.start();
    final sender = _FakeSender();
    track.transceiver = _FakeTransceiver(sender);
    return (track, processor, sender);
  }

  test('mute and unmute keep the processor on the restarted track', () async {
    final (track, processor, sender) = await createPublishedTrack();
    expect(processor.initTrackIds, ['mic-1']);

    await track.mute();
    await track.unmute();

    expect(sender.replacedTrackIds, ['mic-2']);
    expect(track.processor, same(processor));
    expect(processor.initTrackIds, ['mic-1', 'mic-2']);
  });

  test('restartTrack keeps the processor on the new track', () async {
    final (track, processor, sender) = await createPublishedTrack();

    await track.restartTrack();

    expect(sender.replacedTrackIds, ['mic-2']);
    expect(track.processor, same(processor));
    expect(processor.initTrackIds, ['mic-1', 'mic-2']);
  });

  test('stop releases the processor, also after a mute already stopped capture', () async {
    final (track, processor, _) = await createPublishedTrack();

    await track.mute();
    await track.stop();

    expect(track.processor, isNull);
    expect(processor.destroyCount, 1);
  });
}
