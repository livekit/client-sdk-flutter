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

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import '../mock/e2e_container.dart';

void main() {
  late E2EContainer container;
  late Room room;

  setUpAll(() async {
    container = E2EContainer();
    room = container.room;
    await container.connectRoom();
    await container.simulateRemoteParticipantJoin('remote-a');
  });

  tearDownAll(() async {
    await container.dispose();
  });

  Future<DataReceivedEvent> deliverFrom(String identity) async {
    final completer = Completer<DataReceivedEvent>();
    final cancel = room.events.on<DataReceivedEvent>(completer.complete);

    container.deliverInboundDataPacket(
      lk_models.DataPacket(
        kind: lk_models.DataPacket_Kind.RELIABLE,
        participantIdentity: identity,
        user: lk_models.UserPacket(
          payload: utf8.encode('hello'),
          participantIdentity: identity,
        ),
      ),
    );

    final event = await completer.future.timeout(const Duration(seconds: 3));
    await cancel();
    return event;
  }

  test('reports the sender identity when the participant is not in the room', () async {
    // Data sent by the Server API, or by a participant that has already left,
    // has no RemoteParticipant to attach to. Without the identity the receiver
    // cannot tell who sent it at all.
    final event = await deliverFrom('server-api-sender');

    expect(event.participant, isNull);
    expect(event.participantIdentity, 'server-api-sender');
  });

  test('reports the sender identity for a known participant too', () async {
    final event = await deliverFrom('remote-a');

    expect(event.participant?.identity, 'remote-a');
    expect(event.participantIdentity, 'remote-a');
  });
}
