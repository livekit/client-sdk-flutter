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
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'package:livekit_client/src/extensions.dart';
import 'package:livekit_client/src/options.dart';

void main() {
  group('DegradationPreference.toRTCType', () {
    test('converts every value without throwing', () {
      for (final preference in DegradationPreference.values) {
        expect(() => preference.toRTCType(), returnsNormally);
      }
    });

    test('deprecated disabled maps to maintain framerate and resolution', () {
      // WebRTC defines DISABLED as an alias for MAINTAIN_FRAMERATE_AND_RESOLUTION
      expect(
        // ignore: deprecated_member_use_from_same_package
        DegradationPreference.disabled.toRTCType(),
        rtc.RTCDegradationPreference.MAINTAIN_FRAMERATE_AND_RESOLUTION,
      );
    });
  });
}
