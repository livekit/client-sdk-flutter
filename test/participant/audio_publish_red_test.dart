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

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import 'package:livekit_client/src/support/native.dart';
import '../mock/e2e_container.dart';
import '../mock/e2ee_fake_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const webrtcChannel = MethodChannel('FlutterWebRTC.Method');

  late E2EContainer container;

  setUp(() {
    messenger.setMockMethodCallHandler(webrtcChannel, (call) async {
      if (call.method == 'getUserMedia') {
        return <String, dynamic>{
          'streamId': 'stream-1',
          'audioTracks': [
            <String, dynamic>{'id': 'mic-1', 'label': 'mic', 'kind': 'audio', 'enabled': true},
          ],
          'videoTracks': <dynamic>[],
        };
      }
      return null;
    });
    messenger.setMockMethodCallHandler(Native.channel, (call) async => true);
    container = E2EContainer();
  });

  tearDown(() async {
    await container.dispose();
    messenger.setMockMethodCallHandler(webrtcChannel, null);
    messenger.setMockMethodCallHandler(Native.channel, null);
  });

  /// Publishes a microphone track and returns the AddTrackRequest the SDK sent.
  Future<lk_rtc.AddTrackRequest> publishAndCaptureAddTrack({AudioPublishOptions? publishOptions}) async {
    await container.connectRoom();
    final track = await LocalAudioTrack.create();
    final publish = container.room.localParticipant!.publishAudioTrack(track, publishOptions: publishOptions);

    lk_rtc.AddTrackRequest? request;
    for (var i = 0; i < 100 && request == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      request = container.wsConnector.sentData
          .map(lk_rtc.SignalRequest.fromBuffer)
          .where((r) => r.hasAddTrack())
          .map((r) => r.addTrack)
          .firstOrNull;
    }
    expect(request, isNotNull, reason: 'the SDK never sent an AddTrackRequest');

    container.wsConnector.onData(
      lk_rtc.SignalResponse(
        trackPublished: lk_rtc.TrackPublishedResponse(
          cid: request!.cid,
          track: lk_models.TrackInfo(sid: 'TR_audio', type: lk_models.TrackType.AUDIO),
        ),
      ).writeToBuffer(),
    );
    await publish;
    return request;
  }

  test('RED is requested by default', () async {
    final request = await publishAndCaptureAddTrack();
    expect(request.disableRed, isFalse);
  });

  test('red: false disables RED', () async {
    final request = await publishAndCaptureAddTrack(publishOptions: const AudioPublishOptions(red: false));
    expect(request.disableRed, isTrue);
  });

  test('E2EE disables RED even when red is true', () async {
    container.engine.setE2eeManager(TestE2EEManager());
    final request = await publishAndCaptureAddTrack(publishOptions: const AudioPublishOptions(red: true));
    expect(request.disableRed, isTrue);
  });
}
