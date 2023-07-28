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
import '../mock/e2e_container.dart';
import '../mock/test_data.dart';
import '../mock/websocket_mock.dart';
import 'signal_client_test.dart';

void main() {
  late E2EContainer container;
  late Room room;
  late MockWebSocketConnector ws;
  setUp(() async {
    container = E2EContainer();
    room = container.room;
    ws = container.wsConnector;
    await container.connectRoom();
  });

  tearDown(() async {
    await container.dispose();
  });

  group('connection', () {
    test('disconnect and connect', () async {
      await room.disconnect();
      await container.connectRoom();
      expect(room.connectionState, ConnectionState.connected);
      expect(room.localParticipant?.sid, joinResponse.join.participant.sid);
    }, skip: 'todo');
  });

  group('room updates', () {
    test('participant join', () async {
      expect(
        room.events.streamCtrl.stream,
        emitsInOrder(<Matcher>[
          predicate<TrackPublishedEvent>(
            (event) => event.participant.sid == remoteParticipantData.sid,
          ),
          predicate<ParticipantConnectedEvent>(
            (event) => event.participant.sid == remoteParticipantData.sid,
          )
        ]),
      );

      ws.onData(participantJoinResponse.writeToBuffer());

      await room.events.waitFor<ParticipantConnectedEvent>(
          duration: const Duration(seconds: 1));
      expect(room.participants.length, 1);
    });

    test('participant disconnect', () async {
      ws.onData(participantJoinResponse.writeToBuffer());
      await room.events.waitFor<ParticipantConnectedEvent>(
          duration: const Duration(seconds: 1));

      ws.onData(participantDisconnectResponse.writeToBuffer());
      expect(
        room.events.streamCtrl.stream,
        emitsInOrder(<Matcher>[
          predicate<TrackUnpublishedEvent>(
              (event) => event.participant.sid == remoteParticipantData.sid),
          predicate<ParticipantDisconnectedEvent>(
              (event) => event.participant.sid == remoteParticipantData.sid),
        ]),
      );

      await room.events.waitFor<ParticipantDisconnectedEvent>(
          duration: const Duration(seconds: 1));
      expect(room.participants.length, 0);
    });

    test('participant metadata changed', () async {
      ws.onData(participantJoinResponse.writeToBuffer());
      await room.events.waitFor<ParticipantConnectedEvent>(
          duration: const Duration(seconds: 1));

      ws.onData(participantMetadataChangedResponse.writeToBuffer());
      expect(
        room.events.streamCtrl.stream,
        emits(
          predicate<ParticipantMetadataUpdatedEvent>((event) =>
              event.participant.metadata ==
              participantMetadataChangedResponse
                  .update.participants[0].metadata),
        ),
      );
    });

    test('room metadata update', () async {
      expect(
        room.events.streamCtrl.stream,
        emits(predicate<RoomMetadataChangedEvent>((event) =>
            event.metadata == roomUpdateResponse.roomUpdate.room.metadata &&
            room.metadata == event.metadata)),
      );
      ws.onData(roomUpdateResponse.writeToBuffer());
    });

    test('connection quality', () async {
      expect(
        room.events.streamCtrl.stream,
        emits(predicate<ParticipantConnectionQualityUpdatedEvent>((event) =>
            event.participant.sid == localParticipantData.sid &&
            event.connectionQuality == ConnectionQuality.excellent)),
      );
      ws.onData(connectionQualityResponse.writeToBuffer());
    });

    test('active speakers changed', () async {
      ws.onData(participantJoinResponse.writeToBuffer());
      await room.events.waitFor<ParticipantConnectedEvent>(
          duration: const Duration(seconds: 1));

      expect(
        room.events.streamCtrl.stream,
        emits(
          predicate<ActiveSpeakersChangedEvent>(
              (event) => event.speakers[0].sid == remoteParticipantData.sid),
        ),
      );
      ws.onData(activeSpeakerResponse.writeToBuffer());
    });

    test('leave', () async {
      expect(
          room.events.streamCtrl.stream,
          emits(predicate<RoomDisconnectedEvent>((event) =>
              room.connectionState == ConnectionState.disconnected)));
      ws.onData(leaveResponse.writeToBuffer());
    });
  });
}
