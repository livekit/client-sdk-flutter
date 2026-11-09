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

// A data packet in flight when the room is disposed. The native data channel is gone by the time
// the send's bookkeeping asks it for its buffered amount, and the platform call fails with a
// PlatformException. That used to surface from publishData and stream writes as is.

@Timeout(Duration(seconds: 10))
library;

import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';

lk_models.DataPacket _packet() => lk_models.DataPacket(
  kind: lk_models.DataPacket_Kind.RELIABLE,
  user: lk_models.UserPacket(payload: [1]),
);

final _channelGone = PlatformException(
  code: 'dataChannelGetBufferedAmountFailed',
  message: 'Error: dataChannel not found or not opened!',
);

void main() {
  late E2EContainer container;

  setUp(() async {
    resetMockDataChannels();
    container = E2EContainer();
    await container.connectRoom();
    for (final dc in mockDataChannels) {
      dc.onMessageSend = null;
    }
  });

  tearDown(() async {
    await container.dispose();
  });

  test('a packet sent right before the room is disposed completes without an error', () async {
    // The send reaches the channel, and the room is disposed before the bookkeeping reads the buffer.
    for (final dc in mockDataChannels) {
      dc.onMessageSend = (_) {
        dc.getBufferedAmountError = _channelGone;
        unawaited(container.room.dispose());
      };
    }

    await container.engine.sendDataPacket(_packet(), reliability: Reliability.reliable);
  });

  test('a packet the channel refused because the room was disposed fails with UnexpectedConnectionState', () async {
    for (final dc in mockDataChannels) {
      dc.onMessageSend = (_) {
        unawaited(container.room.dispose());
        throw PlatformException(code: 'dataChannelSendFailed', message: 'Error: dataChannel not found or not opened!');
      };
    }

    await expectLater(
      container.engine.sendDataPacket(_packet(), reliability: Reliability.reliable),
      throwsA(isA<UnexpectedConnectionState>()),
    );
  });

  test('a bookkeeping failure on a live channel still surfaces', () async {
    for (final dc in mockDataChannels) {
      dc.getBufferedAmountError = _channelGone;
    }

    await expectLater(
      container.engine.sendDataPacket(_packet(), reliability: Reliability.reliable),
      throwsA(isA<PlatformException>()),
    );
  });
}
