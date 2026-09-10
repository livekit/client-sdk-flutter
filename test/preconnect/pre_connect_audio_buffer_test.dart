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

import '../mock/e2e_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreConnectAudioBuffer.startRecording', () {
    late E2EContainer container;

    setUp(() {
      container = E2EContainer();
    });

    tearDown(() async {
      await container.dispose();
    });

    // In the test environment LocalAudioTrack.create() always fails (no
    // platform channels), which stands in for a real create failure such as
    // a denied microphone permission.
    test('stays reusable after track creation fails', () async {
      final buffer = container.room.preConnectAudioBuffer;
      final errors = <Object>[];
      buffer.setErrorHandler(errors.add);

      await expectLater(
        buffer.startRecording(timeout: const Duration(milliseconds: 50)),
        throwsA(anything),
      );

      // The buffer must return to an idle state, not stay latched on
      // _isRecording so that retries are silently ignored.
      expect(buffer.isRecording, isFalse);
      expect(errors, hasLength(1));

      // A retry reaches track creation again and reports its own failure
      // instead of returning early as "already recording".
      await expectLater(
        buffer.startRecording(timeout: const Duration(milliseconds: 50)),
        throwsA(anything),
      );
      expect(buffer.isRecording, isFalse);
      expect(errors, hasLength(2));

      // The agent-ready timeout was cancelled by the cleanup. If it were
      // still armed, it would complete the unobserved agentReadyFuture with
      // a TimeoutException and fail this test as an unhandled error.
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    test('cleans up even when the error handler throws', () async {
      final buffer = container.room.preConnectAudioBuffer;
      var callbackCalls = 0;
      buffer.setErrorHandler((error) {
        callbackCalls++;
        throw StateError('app callback bug');
      });

      // The original track creation failure must reach the caller, not the
      // callback's own error, and cleanup must still run.
      await expectLater(
        buffer.startRecording(timeout: const Duration(milliseconds: 50)),
        throwsA(isNot(isA<StateError>())),
      );

      expect(callbackCalls, 1);
      expect(buffer.isRecording, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
  });
}
