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

import 'package:livekit_client/src/extensions.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/types/other.dart';

void main() {
  group('DisconnectReason.toSDKType', () {
    test('maps every proto value to a distinct SDK value', () {
      final mapped = <DisconnectReason>{};
      for (final reason in lk_models.DisconnectReason.values) {
        final sdkReason = reason.toSDKType();
        expect(
          mapped.contains(sdkReason),
          isFalse,
          reason: '$reason maps to $sdkReason which is already used by another proto value',
        );
        mapped.add(sdkReason);
      }
    });

    test('maps newer server reasons to their own members', () {
      expect(lk_models.DisconnectReason.ROOM_CLOSED.toSDKType(), DisconnectReason.roomClosed);
      expect(lk_models.DisconnectReason.MIGRATION.toSDKType(), DisconnectReason.migration);
      expect(lk_models.DisconnectReason.SIGNAL_CLOSE.toSDKType(), DisconnectReason.signalClose);
      expect(lk_models.DisconnectReason.USER_UNAVAILABLE.toSDKType(), DisconnectReason.userUnavailable);
      expect(lk_models.DisconnectReason.USER_REJECTED.toSDKType(), DisconnectReason.userRejected);
      expect(lk_models.DisconnectReason.SIP_TRUNK_FAILURE.toSDKType(), DisconnectReason.sipTrunkFailure);
      expect(lk_models.DisconnectReason.CONNECTION_TIMEOUT.toSDKType(), DisconnectReason.connectionTimeout);
      expect(lk_models.DisconnectReason.MEDIA_FAILURE.toSDKType(), DisconnectReason.mediaFailure);
      expect(lk_models.DisconnectReason.AGENT_ERROR.toSDKType(), DisconnectReason.agentError);
    });
  });
}
