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

  group('Checker', () {
    test('reports success when perform completes without errors', () async {
      final checker = FakeChecker(onPerform: (checker) async {
        checker.addMessage('all good');
      });
      final info = await checker.run();
      expect(info.status, CheckStatus.success);
      expect(info.name, 'FakeChecker');
      expect(info.description, 'Fake check for testing');
      expect(info.logs, hasLength(1));
      expect(info.logs.first.level, CheckLogLevel.info);
      expect(info.logs.first.message, 'all good');
      await checker.dispose();
    });

    test('reports failure when perform throws', () async {
      final checker = FakeChecker(onPerform: (checker) async {
        throw const CheckException('something went wrong');
      });
      final info = await checker.run();
      expect(info.status, CheckStatus.failed);
      expect(info.logs, hasLength(1));
      expect(info.logs.first.level, CheckLogLevel.error);
      expect(info.logs.first.message, 'something went wrong');
      await checker.dispose();
    });

    test('reports failure when an error is appended', () async {
      final checker = FakeChecker(onPerform: (checker) async {
        checker.addError('bad');
        checker.addMessage('but continued');
      });
      final info = await checker.run();
      expect(info.status, CheckStatus.failed);
      expect(info.logs, hasLength(2));
      await checker.dispose();
    });

    test('warnings do not fail the check', () async {
      final checker = FakeChecker(onPerform: (checker) async {
        checker.addWarning('be careful');
      });
      final info = await checker.run();
      expect(info.status, CheckStatus.success);
      expect(info.logs.first.level, CheckLogLevel.warning);
      await checker.dispose();
    });

    test('errorsAsWarnings turns a thrown error into a warning', () async {
      final checker = FakeChecker(
        onPerform: (checker) async {
          throw const CheckException('not fatal here');
        },
        options: CheckerOptions(errorsAsWarnings: true),
      );
      final info = await checker.run();
      expect(info.status, CheckStatus.success);
      expect(info.logs, hasLength(1));
      expect(info.logs.first.level, CheckLogLevel.warning);
      expect(info.logs.first.message, 'not fatal here');
      await checker.dispose();
    });

    test('skip marks the check as skipped', () async {
      final checker = FakeChecker(onPerform: (checker) async {
        checker.doSkip();
      });
      final info = await checker.run();
      expect(info.status, CheckStatus.skipped);
      await checker.dispose();
    });

    test('emits an update event for every log entry and status change', () async {
      final checker = FakeChecker(onPerform: (checker) async {
        checker.addMessage('one');
        checker.addMessage('two');
      });
      final listener = checker.createListener();
      final updates = <CheckInfo>[];
      listener.on<CheckerUpdateEvent>((event) => updates.add(event.info));
      final info = await checker.run();
      // wait for pending events to be delivered
      await Future<void>.delayed(const Duration(milliseconds: 10));
      // running + 2 logs + final status
      expect(updates, hasLength(4));
      expect(updates.first.status, CheckStatus.running);
      expect(updates.last.status, CheckStatus.success);
      expect(info.logs, hasLength(2));
      await listener.dispose();
      await checker.dispose();
    });

    test('cannot be run twice', () async {
      final checker = FakeChecker();
      await checker.run();
      expect(() => checker.run(), throwsStateError);
      await checker.dispose();
    });
  });
}
