// Copyright 2023 LiveKit, Inc.
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

@Timeout(Duration(seconds: 5))

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import '../core/signal_client_test.dart';
import '../mock/e2e_container.dart';

void main() {
  late E2EContainer container;
  late Room room;
  setUp(() async {
    container = E2EContainer();
    room = container.room;
  });

  tearDown(() async {
    await container.dispose();
  });

  test('connect', () async {
    await container.connectRoom();
    expect(room.connectionState, ConnectionState.connected);
    expect(room.localParticipant?.sid, joinResponse.join.participant.sid);
  });
}
