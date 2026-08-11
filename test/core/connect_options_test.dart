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

@Timeout(Duration(seconds: 10))
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';

void main() {
  setUp(resetMockDataChannels);

  group('Room.connect options', () {
    // Regression: the deprecated `roomOptions` parameter was shadowed by a local of the same name
    // in the first line of `connect`, which Dart permits silently. Everything passed here was
    // discarded, so callers saw the Room's own options with no indication anything was wrong.
    test('honors the roomOptions passed to connect', () async {
      final container = E2EContainer(
        roomOptions: const RoomOptions(dynacast: false, adaptiveStream: false),
      );
      addTearDown(container.dispose);

      await container.connectRoom(
        // ignore: deprecated_member_use_from_same_package
        roomOptions: const RoomOptions(dynacast: true, adaptiveStream: true),
      );

      expect(container.room.roomOptions.dynacast, isTrue);
      expect(container.room.roomOptions.adaptiveStream, isTrue);
    });

    test('falls back to the Room\'s options when connect is given none', () async {
      final container = E2EContainer(
        roomOptions: const RoomOptions(dynacast: true, adaptiveStream: true),
      );
      addTearDown(container.dispose);

      await container.connectRoom();

      expect(container.room.roomOptions.dynacast, isTrue);
      expect(container.room.roomOptions.adaptiveStream, isTrue);
    });
  });
}
