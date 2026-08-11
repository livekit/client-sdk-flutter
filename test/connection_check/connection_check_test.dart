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

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import '../mock/fake_checker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectionCheck', () {
    test('aggregates results of multiple checks', () async {
      final connectionCheck = ConnectionCheck('ws://www.example.com', 'token');

      final ok = await connectionCheck.runCheck(FakeChecker(onPerform: (checker) async {
        checker.addMessage('fine');
      }));
      expect(ok.status, CheckStatus.success);
      expect(connectionCheck.isSuccess, true);

      final failed = await connectionCheck.runCheck(FakeChecker(onPerform: (checker) async {
        throw const CheckException('nope');
      }));
      expect(failed.status, CheckStatus.failed);
      expect(connectionCheck.isSuccess, false);

      final results = connectionCheck.getResults();
      expect(results, hasLength(2));
      expect(results[0].status, CheckStatus.success);
      expect(results[1].status, CheckStatus.failed);

      await connectionCheck.dispose();
    });

    test('emits update events with unique check ids', () async {
      final connectionCheck = ConnectionCheck('ws://www.example.com', 'token');
      final listener = connectionCheck.createListener();
      final seenIds = <int>{};
      final updates = <ConnectionCheckUpdateEvent>[];
      listener.on<ConnectionCheckUpdateEvent>((event) {
        seenIds.add(event.checkId);
        updates.add(event);
      });

      await connectionCheck.runCheck(FakeChecker());
      await connectionCheck.runCheck(FakeChecker());
      // wait for pending events to be delivered
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(seenIds, {0, 1});
      expect(updates.last.info.status, CheckStatus.success);

      await listener.dispose();
      await connectionCheck.dispose();
    });

    test('skipped checks do not fail the run', () async {
      final connectionCheck = ConnectionCheck('ws://www.example.com', 'token');
      final skipped = await connectionCheck.runCheck(FakeChecker(onPerform: (checker) async {
        checker.doSkip();
      }));
      expect(skipped.status, CheckStatus.skipped);
      expect(connectionCheck.isSuccess, true);
      await connectionCheck.dispose();
    });
  });
}
