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

import 'package:livekit_client/src/exceptions.dart';
import 'package:livekit_client/src/support/region_url_provider.dart';
import 'package:livekit_client/src/support/websocket.dart' show WebSocketException;

void main() {
  group('canFailOverToAnotherRegion', () {
    test('allows failover on 403, which LiveKit Cloud uses to signal region pinning', () {
      // The RTC paths 403 when the project is not allowed in the region the client
      // geo-routed to. /settings/regions stays reachable so the client can discover
      // where it is allowed to connect.
      expect(
        canFailOverToAnotherRegion(
          ConnectException(
            'project not allowed in this region.',
            reason: ConnectionErrorReason.NotAllowed,
            statusCode: 403,
          ),
        ),
        isTrue,
      );
    });

    test('does not allow failover on 401 — no other region will accept the same token', () {
      expect(
        canFailOverToAnotherRegion(
          ConnectException(
            'unauthorized',
            reason: ConnectionErrorReason.NotAllowed,
            statusCode: 401,
          ),
        ),
        isFalse,
      );
    });

    test('allows failover on a websocket error', () {
      expect(canFailOverToAnotherRegion(const WebSocketException('failed')), isTrue);
    });

    test('allows failover on non-NotAllowed connect errors', () {
      for (final reason in [ConnectionErrorReason.InternalError, ConnectionErrorReason.Timeout]) {
        expect(
          canFailOverToAnotherRegion(ConnectException('failed', reason: reason)),
          isTrue,
          reason: 'expected failover for $reason',
        );
      }
    });

    test('does not allow failover on unrelated errors', () {
      expect(canFailOverToAnotherRegion(StateError('boom')), isFalse);
    });
  });
}
