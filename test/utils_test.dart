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

      expect(encodings![0].rid, 'q');
      expect(encodings[0].maxFramerate, 20);
      expect(encodings[0].maxBitrate, 450000);
      expect(encodings[0].scaleResolutionDownBy, 2);

      expect(encodings[1].rid, 'h');
      expect(encodings[1].maxFramerate, 24);
      expect(encodings[1].maxBitrate, 1500000);
      expect(encodings[1].scaleResolutionDownBy, 1);

      expect(encodings[2].rid, 'f');
      expect(encodings[2].maxFramerate, 24);
      expect(encodings[2].maxBitrate, 1500000);
      expect(encodings[2].scaleResolutionDownBy, 1);
    });

    test('lower-resolution layer clamps framerate but preserves preset bitrate', () {
      final encodings = Utils.computeVideoEncodings(
        isScreenShare: false,
        dimensions: const VideoDimensions(1280, 720),
        options: const VideoPublishOptions(
          videoEncoding: VideoEncoding(maxBitrate: 500000, maxFramerate: 15),
        ),
      );

      expect(encodings, hasLength(3));
      expect(encodings![1].rid, 'h');
      expect(encodings[1].maxFramerate, 15);
      expect(encodings[1].maxBitrate, 450000);
      expect(encodings[1].scaleResolutionDownBy, 2);
    });
  });
}
