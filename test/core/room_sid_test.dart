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
import '../mock/test_data.dart';
import 'signal_client_test.dart';

/// Room sids are assigned asynchronously by the server: the JoinResponse can
/// carry an empty `room.sid`, with the real sid following in a RoomUpdate.
/// `getSid()` must resolve when that update arrives — it used to wait for
/// `SignalRoomUpdateEvent` on the Room's own emitter, where that (signal)
/// event is never emitted, so the returned future never completed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final lk_rtc.SignalResponse emptySidJoinResponse = lk_rtc.SignalResponse(
    join: lk_rtc.JoinResponse(
      room: lk_models.Room(
        name: 'room_name',
        // sid deliberately unset — issued later via RoomUpdate.
      ),
      participant: localParticipantData,
      subscriberPrimary: true,
      serverVersion: '99.999',
      serverInfo: lk_models.ServerInfo(
        version: '1.8.0',
      ),
    ),
  );

  final lk_rtc.SignalResponse sidRoomUpdateResponse = lk_rtc.SignalResponse(
    roomUpdate: lk_rtc.RoomUpdate(
      room: lk_models.Room(
        name: 'room_name',
        sid: 'RM_issued_later',
      ),
    ),
  );

  /// Connects the container's room, answering with [joinResp] instead of the
  /// default join response.
  Future<void> connectWith(E2EContainer container, lk_rtc.SignalResponse joinResp) async {
    final connectFuture = container.room.connect(exampleUri, token);
    Future.delayed(const Duration(milliseconds: 1), () {
      container.wsConnector.onData(joinResp.writeToBuffer());
      container.wsConnector.onData(offerResponse.writeToBuffer());
    });
    await connectFuture;
  }

  late E2EContainer container;

  setUp(() async {
    container = E2EContainer();
  });

  tearDown(() async {
    await container.dispose();
  });

  group('Room.getSid', () {
    test('returns immediately when the join response carried the sid', () async {
      await connectWith(container, joinResponse);

      expect(await container.room.getSid(), 'room_sid');
    });

    test('resolves when the sid arrives via a later RoomUpdate', () async {
      await connectWith(container, emptySidJoinResponse);

      final sidFuture = container.room.getSid();
      container.wsConnector.onData(sidRoomUpdateResponse.writeToBuffer());

      expect(await sidFuture, 'RM_issued_later');
    });

    test('completes with an empty sid when the room is disposed while waiting', () async {
      await connectWith(container, emptySidJoinResponse);

      final sidFuture = container.room.getSid();
      await container.room.dispose();

      expect(await sidFuture, '');
    });

    test('resolves with the join-response sid for callers waiting during connect', () async {
      final connectFuture = container.room.connect(exampleUri, token);
      Future.delayed(const Duration(milliseconds: 5), () {
        container.wsConnector.onData(joinResponse.writeToBuffer());
        container.wsConnector.onData(offerResponse.writeToBuffer());
      });
      // Ask while the signal connection is still being established.
      await Future<void>.delayed(const Duration(milliseconds: 1));
      final sidFuture = container.room.getSid();

      await connectFuture;
      expect(await sidFuture, 'room_sid');
    });

    test('repeated calls do not accumulate dispose hooks', () async {
      await connectWith(container, emptySidJoinResponse);
      final hooksBefore = container.room.disposeFuncCount;

      for (var i = 0; i < 3; i++) {
        final sidFuture = container.room.getSid();
        container.wsConnector.onData(sidRoomUpdateResponse.writeToBuffer());
        await sidFuture;
      }

      expect(container.room.disposeFuncCount, hooksBefore);
    });

    test('resolves for a caller arriving after the RoomUpdate landed', () async {
      await connectWith(container, emptySidJoinResponse);

      container.wsConnector.onData(sidRoomUpdateResponse.writeToBuffer());
      // Let the signal event propagate to _applyRoomUpdate.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(await container.room.getSid(), 'RM_issued_later');
    });
  });
}
