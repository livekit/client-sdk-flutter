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

import 'package:livekit_client/src/track/local/audio.dart';

void main() {
  test('stops native recording only after the last holder releases it', () {
    final holders = NativeRecordingHolders();
    const preJoinMic = 'pre-join';
    const roomMic = 'room';

    holders.add(preJoinMic);
    holders.add(roomMic);

    expect(holders.remove(preJoinMic), isFalse);
    expect(holders.length, 1);

    expect(holders.remove(roomMic), isTrue);
    expect(holders.length, 0);
  });

  test('a second release of the same holder does not stop recording again', () {
    final holders = NativeRecordingHolders();
    const mic = 'mic';

    holders.add(mic);

    expect(holders.remove(mic), isTrue);
    expect(holders.remove(mic), isFalse);
  });
}
