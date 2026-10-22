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
import 'package:livekit_client/src/internal/events.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import '../mock/e2e_container.dart';
import '../mock/mediastream_mock.dart';
import 'signal_client_test.dart' show exampleUri, joinResponse, offerResponse, token;

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

/// Connects with [otherParticipants] in the JoinResponse and delivers
/// [updates] right behind it, the way the server flushes the updates it
/// queued while the participant was joining.
Future<void> _connectWithQueuedUpdates(
  E2EContainer container, {
  List<lk_models.ParticipantInfo> otherParticipants = const [],
  required List<List<int>> updates,
}) async {
  final join = joinResponse.deepCopy();
  join.join.otherParticipants
    ..clear()
    ..addAll(otherParticipants);

  final connectFuture = container.room.connect(exampleUri, token);
  await Future<void>.delayed(const Duration(milliseconds: 1));
  container.wsConnector.onData(join.writeToBuffer());
  updates.forEach(container.wsConnector.onData);
  container.wsConnector.onData(offerResponse.writeToBuffer());
  await connectFuture;
}

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

  test('updates queued during join are applied in order', () async {
    final events = <String>[];
    room.events.on<TrackPublishedEvent>((event) => events.add('published ${event.publication.sid}'));
    room.events.on<TrackUnpublishedEvent>((event) => events.add('unpublished ${event.publication.sid}'));

    await _connectWithQueuedUpdates(
      container,
      otherParticipants: [_info(2, [])],
      updates: [
        _update(3, ['TR_A']),
        _update(4, ['TR_A']),
        _update(5, ['TR_A', 'TR_B']),
      ],
    );
    await _settle();

    final participant = room.remoteParticipants['remote']!;
    expect(participant.trackPublications.keys, unorderedEquals(['TR_A', 'TR_B']));
    expect(events, ['published TR_A', 'published TR_B']);
  });

  test('queued updates for a new participant create a single instance', () async {
    final connected = <RemoteParticipant>[];
    room.events.on<ParticipantConnectedEvent>((event) => connected.add(event.participant));

    await _connectWithQueuedUpdates(
      container,
      updates: [
        _update(1, ['TR_A']),
        _update(2, ['TR_A', 'TR_B']),
      ],
    );
    await _settle();

    final participant = room.remoteParticipants['remote']!;
    expect(connected, hasLength(1));
    expect(connected.single, same(participant));
    expect(participant.trackPublications.keys, unorderedEquals(['TR_A', 'TR_B']));
  });

  test('a pending track waiting for its publication does not block later updates', () async {
    await container.connectRoom();

    // Media for TR_B arrives before the participant is known, so it is queued.
    container.engine.events.emit(
      EngineTrackAddedEvent(
        track: FakeMediaStreamTrack(id: 'TR_B', kind: 'audio'),
        stream: FakeMediaStream('PA_remote|stream'),
        receiver: null,
      ),
    );
    final subscribed = room.events.waitFor<TrackSubscribedEvent>(
      filter: (event) => event.publication.sid == 'TR_B',
      duration: const Duration(seconds: 1),
    );

    // The first update creates the participant without TR_B, so flushing the
    // queued media waits for a later update to publish it.
    container.wsConnector.onData(_update(1, ['TR_A']));
    await _settle();
    container.wsConnector.onData(_update(2, ['TR_A', 'TR_B']));

    expect((await subscribed).participant.identity, 'remote');
  });
}
