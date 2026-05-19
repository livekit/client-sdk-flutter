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

import 'package:livekit_client/livekit_client.dart' as lk;
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

  group('screen share simulcast encodings', () {
    test('default lower layer follows top layer fps and priorities', () {
      final encodings = Utils.computeVideoEncodings(
        isScreenShare: true,
        dimensions: const lk.VideoDimensions(1920, 1080),
        options: const lk.VideoPublishOptions(
          screenShareEncoding: lk.VideoEncoding(
            maxBitrate: 2500000,
            maxFramerate: 15,
            bitratePriority: lk.Priority.high,
            networkPriority: lk.Priority.high,
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
  });
}
