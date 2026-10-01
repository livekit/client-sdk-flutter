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

@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/src/uniffi/uniffi.dart';

void main() {
  // Exercises the whole delivery chain rather than any particular API: the
  // build hook resolved a cdylib for this target, Native Assets bundled it,
  // `@Native` bound the symbol, and a value crossed back from Rust. If the
  // bindgen or the hook regresses, this is what fails first.
  group('livekit_uniffi', () {
    test('is available on native platforms', () {
      expect(LiveKitUniffi.isAvailable, isTrue);
    });

    test('buildVersion returns the Rust core version', () {
      final version = LiveKitUniffi.buildVersion;
      expect(version, isNotEmpty);
      // The crate stamps its own semver, so assert the shape rather than a
      // literal that would need bumping on every livekit-uniffi release.
      expect(version, matches(RegExp(r'^\d+\.\d+\.\d+')));
    });
  });
}
