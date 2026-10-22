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

@Timeout(Duration(seconds: 5))
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import '../mock/e2e_container.dart';

lk_models.ParticipantInfo _info(int version, List<String> trackSids) => lk_models.ParticipantInfo(
  sid: 'PA_remote',
  identity: 'remote',
  version: version,
  state: lk_models.ParticipantInfo_State.ACTIVE,
  tracks: trackSids.map(
    (sid) => lk_models.TrackInfo(
      sid: sid,
      name: sid,
      type: lk_models.TrackType.AUDIO,
      source: lk_models.TrackSource.MICROPHONE,
    ),
  ),
);

List<int> _update(int version, List<String> trackSids) => lk_rtc.SignalResponse(
  update: lk_rtc.ParticipantUpdate(participants: [_info(version, trackSids)]),
).writeToBuffer();

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late E2EContainer container;
  late Room room;

  setUp(() {
    container = E2EContainer();
    room = container.room;
  });

  tearDown(() async {
    await container.dispose();
  });

  test('an older snapshot does not remove tracks from a newer one', () async {
    await container.connectRoom();
    final unpublished = <String>[];
    room.events.on<TrackUnpublishedEvent>((event) => unpublished.add(event.publication.sid));

    container.wsConnector.onData(_update(3, ['TR_A', 'TR_B']));
    await _settle();
    container.wsConnector.onData(_update(2, ['TR_A']));
    await _settle();

    final participant = room.remoteParticipants['remote']!;
    expect(participant.trackPublications.keys, unorderedEquals(['TR_A', 'TR_B']));
    expect(unpublished, isEmpty);
  });
}
