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

import 'package:livekit_client/src/options.dart';
import 'package:livekit_client/src/types/other.dart';

void main() {
  group('getDefaultDegradationPreference', () {
    test('camera prefers framerate', () {
      expect(
        getDefaultDegradationPreference(TrackSource.camera),
        DegradationPreference.maintainFramerate,
      );
    });

    test('screen share prefers resolution', () {
      expect(
        getDefaultDegradationPreference(TrackSource.screenShareVideo),
        DegradationPreference.maintainResolution,
      );
    });

    test('other sources fall back to balanced', () {
      // the application declined to declare a motion-vs-detail intent
      expect(
        getDefaultDegradationPreference(TrackSource.unknown),
        DegradationPreference.balanced,
      );
    });
  });
}
