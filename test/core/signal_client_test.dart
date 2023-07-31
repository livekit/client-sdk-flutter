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
import 'package:protobuf/protobuf.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/core/signal_client.dart';
import 'package:livekit_client/src/internal/events.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import '../mock/test_data.dart';
import '../mock/websocket_mock.dart';

void main() {
  const connectOptions = ConnectOptions();
  const roomOptions = RoomOptions();

  late SignalClient client;
  late MockWebSocketConnector connector;
  setUp(() async {
    connector = MockWebSocketConnector();
    client = SignalClient(connector.connect);
  });

  group('connection', () {
    test('connect', () async {
      expect(
          client.events.streamCtrl.stream,
          emitsInOrder(<Matcher>[
            predicate<SignalConnectionStateUpdatedEvent>(
                (event) => event.newState == ConnectionState.connecting),
            predicate<SignalConnectionStateUpdatedEvent>(
                (event) => event.newState == ConnectionState.connected),
          ]));
      await client.connect(
        exampleUri,
        token,
        connectOptions: connectOptions,
        roomOptions: roomOptions,
      );
    });
    test('reconnect', () async {
      expect(
          client.events.streamCtrl.stream,
          emitsInOrder(<Matcher>[
            predicate<SignalConnectionStateUpdatedEvent>(
                (event) => event.newState == ConnectionState.reconnecting),
            predicate<SignalConnectionStateUpdatedEvent>((event) =>
                event.newState == ConnectionState.connected &&
                event.didReconnect == true),
          ]));
      await client.connect(
        exampleUri,
        token,
        connectOptions: connectOptions,
        roomOptions: roomOptions,
        reconnect: true,
      );
    });
  });

  group('messaging', () {
    test('join', () async {
      await client.connect(
        exampleUri,
        token,
        connectOptions: connectOptions,
        roomOptions: roomOptions,
      );
      expect(client.events.streamCtrl.stream,
          emits(isA<SignalJoinResponseEvent>()));
      connector.handlers?.onData!(joinResponse.writeToBuffer());
    });
  });
}

final lk_rtc.SignalResponse joinResponse = lk_rtc.SignalResponse(
  join: lk_rtc.JoinResponse(
    room: lk_models.Room(
      name: 'room_name',
      sid: 'room_sid',
    ),
    participant: localParticipantData,
    subscriberPrimary: true,
    serverVersion: '99.999',
  ),
);

final lk_rtc.SignalResponse offerResponse = lk_rtc.SignalResponse(
    offer: lk_rtc.SessionDescription(
  sdp: 'remote_offer',
  type: 'offer',
));

final lk_rtc.SignalResponse participantJoinResponse = lk_rtc.SignalResponse(
  update: lk_rtc.ParticipantUpdate(
    participants: [remoteParticipantData],
  ),
);

final lk_rtc.SignalResponse participantDisconnectResponse =
    lk_rtc.SignalResponse(
  update: lk_rtc.ParticipantUpdate(
    participants: [
      remoteParticipantData.deepCopy()
        ..state = lk_models.ParticipantInfo_State.DISCONNECTED,
    ],
  ),
);
final lk_rtc.SignalResponse participantMetadataChangedResponse =
    lk_rtc.SignalResponse(
  update: lk_rtc.ParticipantUpdate(
    participants: [
      remoteParticipantData.deepCopy()..metadata = 'metadata_changed',
    ],
  ),
);

final lk_rtc.SignalResponse roomUpdateResponse = lk_rtc.SignalResponse(
  roomUpdate: lk_rtc.RoomUpdate(
    room: lk_models.Room(
      metadata: 'changed_metadata',
    ),
  ),
);

final lk_rtc.SignalResponse connectionQualityResponse = lk_rtc.SignalResponse(
  connectionQuality: lk_rtc.ConnectionQualityUpdate(updates: [
    lk_rtc.ConnectionQualityInfo(
      participantSid: localParticipantData.sid,
      quality: lk_models.ConnectionQuality.EXCELLENT,
    )
  ]),
);

final lk_rtc.SignalResponse activeSpeakerResponse = lk_rtc.SignalResponse(
  speakersChanged: lk_rtc.SpeakersChanged(
    speakers: [remoteSpeakerInfo],
  ),
);
final lk_rtc.SignalResponse leaveResponse =
    lk_rtc.SignalResponse(leave: lk_rtc.LeaveRequest());
const exampleUri = 'ws://www.example.com';
const token = 'token';
