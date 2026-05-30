// Copyright 2025 LiveKit, Inc.
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

import 'package:livekit_client/src/types/other.dart';

void main() {
  group('AdaptiveStreamPixelDensity.resolve', () {
    test('fixed densities ignore the device pixel ratio', () {
      expect(const AdaptiveStreamPixelDensity.fixed(1.0).resolve(3.0), 1.0);
      expect(const AdaptiveStreamPixelDensity.fixed(2.0).resolve(1.0), 2.0);
    });

    test('fractional fixed densities are supported', () {
      expect(const AdaptiveStreamPixelDensity.fixed(1.5).resolve(3.0), 1.5);
      expect(const AdaptiveStreamPixelDensity.fixed(2.75).resolve(1.0), 2.75);
    });

    test('auto falls back to the supplied device pixel ratio', () {
      expect(AdaptiveStreamPixelDensity.auto.resolve(1.0), 1.0);
      expect(AdaptiveStreamPixelDensity.auto.resolve(2.0), 2.0);
      expect(AdaptiveStreamPixelDensity.auto.resolve(2.625), 2.625);
    });

    test('caps at 3x for both fixed and auto', () {
      expect(const AdaptiveStreamPixelDensity.fixed(4.0).resolve(1.0), 3.0);
      expect(AdaptiveStreamPixelDensity.auto.resolve(4.0), 3.0);
      expect(AdaptiveStreamPixelDensity.maxDensity, 3.0);
    });

    test('falls back for invalid auto device pixel ratios', () {
      expect(AdaptiveStreamPixelDensity.auto.resolve(0), 1.0);
      expect(AdaptiveStreamPixelDensity.auto.resolve(-2.0), 1.0);
      expect(AdaptiveStreamPixelDensity.auto.resolve(double.nan), 1.0);
    });

    test('fixed densities must be positive', () {
      expect(
        () => AdaptiveStreamPixelDensity.fixed(0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => AdaptiveStreamPixelDensity.fixed(-1.0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('value is null only for auto', () {
      expect(AdaptiveStreamPixelDensity.auto.value, isNull);
      expect(const AdaptiveStreamPixelDensity.fixed(1.5).value, 1.5);
    });

    test('equality is by value', () {
      expect(
        const AdaptiveStreamPixelDensity.fixed(2.0),
        const AdaptiveStreamPixelDensity.fixed(2.0),
      );
      expect(
        const AdaptiveStreamPixelDensity.fixed(2.0) == AdaptiveStreamPixelDensity.auto,
        isFalse,
      );
    });
  });
}
