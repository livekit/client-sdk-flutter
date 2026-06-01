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

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/utils.dart';

void main() {
  group('retry', () {
    // test if List of errors are thrown
    test(
      'throw all and throw error list',
      () => expect(
        Utils.retry<void>(
          (triesLeft, _) => throw 'error-${triesLeft}',
          tries: 3,
          delay: Duration.zero,
        ),
        throwsA([
          'error-2',
          'error-1',
          'error-0',
        ]),
      ),
    );
    test(
      'throw once and return result',
      () => expectLater(
        Utils.retry<String>(
          (triesLeft, _) async {
            expect(
              triesLeft,
              isNot(0),
              reason: 'should be never 0 because returning on 1',
            );
            if (triesLeft == 1) return 'result-${triesLeft}';
            throw 'error${triesLeft}';
          },
          tries: 3,
          delay: Duration.zero,
        ),
        completion('result-1'),
      ),
    );
  });

  group('simulcast encodings', () {
    test('same-resolution lower layer is clamped to top encoding', () {
      final presets = Utils.computeSimulcastPresets(
        dimensions: const VideoDimensions(1280, 720),
        original: const VideoParameters(
          dimensions: VideoDimensions(1280, 720),
          encoding: VideoEncoding(maxBitrate: 1500000, maxFramerate: 24),
        ),
        requestedPresets: const [
          VideoParametersPresets.h720_169,
          VideoParametersPresets.h360_169,
        ],
        isScreenShare: false,
      );

      expect(presets, hasLength(3));

      expect(presets[0], VideoParametersPresets.h360_169);

      expect(presets[1].dimensions, VideoDimensionsPresets.h720_169);
      expect(presets[1].encoding?.maxFramerate, 24);
      expect(presets[1].encoding?.maxBitrate, 1500000);

      expect(presets[2].dimensions, const VideoDimensions(1280, 720));
      expect(presets[2].encoding?.maxFramerate, 24);
      expect(presets[2].encoding?.maxBitrate, 1500000);
    });

    test('lower-resolution layer clamps framerate but preserves preset bitrate', () {
      final presets = Utils.computeSimulcastPresets(
        dimensions: const VideoDimensions(1280, 720),
        original: const VideoParameters(
          dimensions: VideoDimensions(1280, 720),
          encoding: VideoEncoding(maxBitrate: 500000, maxFramerate: 15),
        ),
        requestedPresets: const [],
        isScreenShare: false,
      );

      expect(presets, hasLength(3));
      expect(presets[1].dimensions, VideoDimensionsPresets.h360_169);
      expect(presets[1].encoding?.maxFramerate, 15);
      expect(presets[1].encoding?.maxBitrate, 450000);
    });

    test('same-resolution full clamp', () {
      final presets = Utils.computeSimulcastPresets(
        dimensions: const VideoDimensions(854, 480),
        original: const VideoParameters(
          dimensions: VideoDimensions(854, 480),
          encoding: VideoEncoding(maxBitrate: 600000, maxFramerate: 15),
        ),
        requestedPresets: const [
          VideoParameters(
            dimensions: VideoDimensions(854, 480),
            encoding: VideoEncoding(maxBitrate: 2000000, maxFramerate: 30),
          ),
        ],
        isScreenShare: false,
      );

      expect(presets, hasLength(2));
      expect(presets[0].encoding?.maxFramerate, 15);
      expect(presets[0].encoding?.maxBitrate, 600000);
      expect(presets[1].dimensions, const VideoDimensions(854, 480));
      expect(presets[1].encoding?.maxFramerate, 15);
      expect(presets[1].encoding?.maxBitrate, 600000);
    });

    test('ladder length follows the larger output dimension', () {
      const cases = [
        (VideoDimensions(320, 240), 1),
        (VideoDimensions(640, 480), 2),
        (VideoDimensions(1280, 720), 3),
      ];

      for (final (dimensions, expectedCount) in cases) {
        final presets = Utils.computeSimulcastPresets(
          dimensions: dimensions,
          original: VideoParameters(
            dimensions: dimensions,
            encoding: const VideoEncoding(maxBitrate: 1000000, maxFramerate: 30),
          ),
          requestedPresets: const [],
          isScreenShare: false,
        );

        expect(presets, hasLength(expectedCount), reason: 'dimensions=$dimensions');
      }
    });

    test("presets that don't overshoot are passed through unchanged", () {
      const original = VideoParameters(
        dimensions: VideoDimensions(1920, 1080),
        encoding: VideoEncoding(maxBitrate: 5000000, maxFramerate: 30),
      );

      final presets = Utils.computeSimulcastPresets(
        dimensions: const VideoDimensions(1920, 1080),
        original: original,
        requestedPresets: const [
          VideoParametersPresets.h360_169,
          VideoParametersPresets.h720_169,
        ],
        isScreenShare: false,
      );

      expect(presets, hasLength(3));
      expect(presets[0], VideoParametersPresets.h360_169);
      expect(presets[1], VideoParametersPresets.h720_169);
      expect(presets[2], original);
    });

    test('clamped layer carries forward per-layer priorities', () {
      const prioritized = VideoParameters(
        dimensions: VideoDimensions(1280, 720),
        encoding: VideoEncoding(
          maxBitrate: 1700000,
          maxFramerate: 30,
          bitratePriority: Priority.high,
          networkPriority: Priority.high,
        ),
      );

      final presets = Utils.computeSimulcastPresets(
        dimensions: const VideoDimensions(1280, 720),
        original: const VideoParameters(
          dimensions: VideoDimensions(1280, 720),
          encoding: VideoEncoding(maxBitrate: 1500000, maxFramerate: 24),
        ),
        requestedPresets: const [
          VideoParametersPresets.h360_169,
          prioritized,
        ],
        isScreenShare: false,
      );

      expect(presets, hasLength(3));
      expect(presets[1].encoding?.maxFramerate, 24);
      expect(presets[1].encoding?.maxBitrate, 1500000);
      expect(presets[1].encoding?.bitratePriority, Priority.high);
      expect(presets[1].encoding?.networkPriority, Priority.high);
    });

    test('computed encodings use clamped presets', () {
      final encodings = Utils.computeVideoEncodings(
        isScreenShare: false,
        dimensions: const VideoDimensions(1280, 720),
        options: const VideoPublishOptions(
          videoEncoding: VideoEncoding(maxBitrate: 1500000, maxFramerate: 24),
          videoSimulcastLayers: [
            VideoParametersPresets.h720_169,
            VideoParametersPresets.h360_169,
          ],
        ),
      );

      expect(encodings, hasLength(3));
      expect(encodings![1].rid, 'h');
      expect(encodings[1].maxFramerate, 24);
      expect(encodings[1].maxBitrate, 1500000);
      expect(encodings[1].scaleResolutionDownBy, 1);
    });
  });

  group('screen share simulcast encodings', () {
    test('screen share preset bitrates match common SDK presets', () {
      expect(VideoParametersPresets.screenShareH720FPS5.encoding?.maxBitrate, 800000);
      expect(VideoParametersPresets.screenShareH1080FPS30.encoding?.maxBitrate, 5000000);
    });

    test('default lower layer follows top layer fps and priorities', () {
      final encodings = Utils.computeVideoEncodings(
        isScreenShare: true,
        dimensions: const VideoDimensions(1920, 1080),
        options: const VideoPublishOptions(
          screenShareEncoding: VideoEncoding(
            maxBitrate: 2500000,
            maxFramerate: 15,
            bitratePriority: Priority.high,
            networkPriority: Priority.high,
          ),
        ),
      );

      expect(encodings, hasLength(2));

      final lowLayer = encodings![0];
      expect(lowLayer.rid, 'q');
      expect(lowLayer.scaleResolutionDownBy, 2);
      expect(lowLayer.maxFramerate, 15);
      expect(lowLayer.maxBitrate, 625000);
      expect(lowLayer.priority, rtc.RTCPriorityType.high);
      expect(lowLayer.networkPriority, rtc.RTCPriorityType.high);
    });

    test('default lower layer follows selected screen share preset', () {
      final encodings = Utils.computeVideoEncodings(
        isScreenShare: true,
        dimensions: const VideoDimensions(1920, 1080),
      );

      expect(encodings, hasLength(2));

      final lowLayer = encodings![0];
      expect(lowLayer.rid, 'q');
      expect(lowLayer.scaleResolutionDownBy, 2);
      expect(lowLayer.maxFramerate, 15);
      expect(lowLayer.maxBitrate, 625000);

      final topLayer = encodings[1];
      expect(topLayer.rid, 'h');
      expect(topLayer.scaleResolutionDownBy, 1);
      expect(topLayer.maxFramerate, 15);
      expect(topLayer.maxBitrate, 2500000);
    });
  });
}
