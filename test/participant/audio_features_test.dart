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
import 'package:livekit_client/src/track/local/audio.dart' show audioProcessingFeatures;
import '../mock/e2e_container.dart';

const _ec = lk_models.AudioTrackFeature.TF_ECHO_CANCELLATION;
const _ns = lk_models.AudioTrackFeature.TF_NOISE_SUPPRESSION;
const _agc = lk_models.AudioTrackFeature.TF_AUTO_GAIN_CONTROL;
const _stereo = lk_models.AudioTrackFeature.TF_STEREO;
const _noDtx = lk_models.AudioTrackFeature.TF_NO_DTX;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const webrtcChannel = MethodChannel('FlutterWebRTC.Method');

  group('audioProcessingFeatures', () {
    test('reports each enabled effect whatever its mode', () {
      expect(
        audioProcessingFeatures(
          const AudioProcessingOptions(
            echoCancellation: true,
            noiseSuppression: true,
            autoGainControl: false,
            highPassFilter: true,
            echoCancellationMode: AudioProcessingMode.software,
            noiseSuppressionMode: AudioProcessingMode.platform,
          ),
        ),
        {_ec, _ns},
      );
      expect(audioProcessingFeatures(const AudioProcessingOptions.communication()), {_ec, _ns, _agc});
      expect(audioProcessingFeatures(const AudioProcessingOptions.noProcessing()), isEmpty);
    });

    test('browser settings override the requested options and report stereo', () {
      expect(
        audioProcessingFeatures(
          const AudioProcessingOptions.noProcessing(),
          sourceSettings: {'echoCancellation': true, 'autoGainControl': true, 'channelCount': 2},
        ),
        {_ec, _agc, _stereo},
      );
      expect(
        audioProcessingFeatures(
          const AudioProcessingOptions.communication(),
          sourceSettings: {'noiseSuppression': false, 'channelCount': 1},
        ),
        {_ec, _agc},
      );
    });
  });

  group('published audio features', () {
    late E2EContainer container;
    late List<MethodCall> nativeCalls;
    Map<String, dynamic> processingResponse = {};

    setUp(() {
      nativeCalls = [];
      processingResponse = {'result': true, 'code': 'applied', 'message': ''};
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
      messenger.setMockMethodCallHandler(Native.channel, (call) async {
        nativeCalls.add(call);
        if (call.method == 'setAudioProcessingOptions') return processingResponse;
        return true;
      });
      container = E2EContainer();
    });

    tearDown(() async {
      Native.bypassVoiceProcessing = false;
      await container.dispose();
      messenger.setMockMethodCallHandler(webrtcChannel, null);
      messenger.setMockMethodCallHandler(Native.channel, null);
    });

    Iterable<lk_rtc.SignalRequest> sentRequests() =>
        container.wsConnector.sentData.map(lk_rtc.SignalRequest.fromBuffer);

    Iterable<lk_rtc.UpdateLocalAudioTrack> sentAudioTrackUpdates() =>
        sentRequests().where((r) => r.hasUpdateAudioTrack()).map((r) => r.updateAudioTrack);

    /// Publishes a microphone track and returns it with the AddTrackRequest the SDK sent.
    Future<(LocalAudioTrack, lk_rtc.AddTrackRequest)> publish({
      AudioCaptureOptions? captureOptions,
      AudioPublishOptions? publishOptions,
    }) async {
      await container.connectRoom();
      final track = await LocalAudioTrack.create(captureOptions);
      final publish = container.room.localParticipant!.publishAudioTrack(track, publishOptions: publishOptions);

      lk_rtc.AddTrackRequest? request;
      for (var i = 0; i < 100 && request == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        request = sentRequests().where((r) => r.hasAddTrack()).map((r) => r.addTrack).firstOrNull;
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
      return (track, request);
    }

    Future<lk_rtc.UpdateLocalAudioTrack?> waitForAudioTrackUpdate() async {
      for (var i = 0; i < 40; i++) {
        final update = sentAudioTrackUpdates().firstOrNull;
        if (update != null) return update;
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      return null;
    }

    test('default capture options report echo cancellation, noise suppression and auto gain control', () async {
      final (_, request) = await publish();
      expect(request.audioFeatures.toSet(), {_ec, _ns, _agc});
    });

    test('disabled processing is not reported, publish features still are', () async {
      final (_, request) = await publish(
        captureOptions: const AudioCaptureOptions(
          echoCancellation: false,
          noiseSuppression: false,
          autoGainControl: false,
        ),
        publishOptions: const AudioPublishOptions(dtx: false),
      );
      expect(request.audioFeatures.toSet(), {_noDtx});
    });

    test('bypassVoiceProcessing reports no processing', () async {
      Native.bypassVoiceProcessing = true;
      final (_, request) = await publish();
      expect(request.audioFeatures.toSet(), isEmpty);
    });

    test('a runtime change sends the new features to the server', () async {
      final (track, _) = await publish(publishOptions: const AudioPublishOptions(dtx: false));

      await track.setAudioProcessingOptions(
        const AudioProcessingOptions(
          echoCancellation: true,
          noiseSuppression: false,
          autoGainControl: false,
          highPassFilter: false,
        ),
      );

      final update = await waitForAudioTrackUpdate();
      expect(update, isNotNull, reason: 'the SDK never sent an UpdateLocalAudioTrack');
      expect(update!.trackSid, 'TR_audio');
      expect(update.features.toSet(), {_ec, _noDtx});
    });

    test('a rejected runtime change reports nothing', () async {
      final (track, _) = await publish();
      processingResponse = {'result': false, 'code': 'rejectedInvalidCombination', 'message': 'no'};

      await expectLater(
        track.setAudioProcessingOptions(const AudioProcessingOptions.noProcessing()),
        throwsA(isA<AudioProcessingException>()),
      );

      expect(await waitForAudioTrackUpdate(), isNull);
      expect(track.currentOptions.echoCancellation, isTrue);
    });

    test('a mode-only runtime change does not resend unchanged features', () async {
      final (track, _) = await publish();

      await track.setAudioProcessingOptions(
        const AudioProcessingOptions(
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
          highPassFilter: false,
          echoCancellationMode: AudioProcessingMode.software,
        ),
      );

      expect(nativeCalls.where((c) => c.method == 'setAudioProcessingOptions'), hasLength(1));
      expect(await waitForAudioTrackUpdate(), isNull);
    });
  });
}
