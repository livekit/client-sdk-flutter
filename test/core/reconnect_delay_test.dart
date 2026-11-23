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

import 'package:livekit_client/src/core/engine.dart';

void main() {
  group('reconnect delay', () {
    test('spreads out clients that disconnect at the same moment', () {
      // The first retry's base delay is 0, so without jitter every client
      // disconnected by the same event reconnects at the same instant.
      final observed = List.generate(100, (_) => reconnectDelayInMs(0)).toSet();

      expect(
        observed.length,
        greaterThan(1),
        reason: 'every caller got the same first retry delay: $observed',
      );
    });

    test('keeps the first retry inside a bounded window', () {
      for (var i = 0; i < 1000; i++) {
        final delay = reconnectDelayInMs(0);

        expect(delay, greaterThanOrEqualTo(0));
        // Inclusive: the window is rounded to whole milliseconds, so the top of
        // the range rounds up to the bound itself.
        expect(delay, lessThanOrEqualTo(maxFirstRetryJitterInMs));
      }
    });

    test('scales jitter with the base delay', () {
      for (var retryCount = 1; retryCount < defaultRetryDelaysInMs.length; retryCount++) {
        final base = defaultRetryDelaysInMs[retryCount];

        for (var i = 0; i < 100; i++) {
          final delay = reconnectDelayInMs(retryCount);

          expect(
            delay,
            greaterThanOrEqualTo((base * 0.5).round()),
            reason: 'retry $retryCount fell below half of $base',
          );
          expect(
            delay,
            lessThanOrEqualTo((base * 1.5).round()),
            reason: 'retry $retryCount exceeded 1.5x of $base',
          );
        }
      }
    });

    test('later retries also vary between callers', () {
      final observed = List.generate(100, (_) => reconnectDelayInMs(1)).toSet();

      expect(observed.length, greaterThan(1));
    });
  });
}
