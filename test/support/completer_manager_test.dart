// Copyright 2025 LiveKit, Inc.
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

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/src/support/completer_manager.dart';

void main() {
  group('CompleterManager', () {
    late CompleterManager<String> manager;

    setUp(() {
      manager = CompleterManager<String>();
    });

    tearDown(() {
      // Only dispose if not already completed or disposed
      try {
        if (manager.isActive) {
          manager.complete('teardown');
        }
        manager.dispose();
      } catch (_) {
        // Already disposed, ignore
      }
    });

    group('Basic Functionality', () {
      test('should provide a future when accessed', () async {
        final future = manager.future;
        expect(future, isA<Future<String>>());
        expect(manager.isActive, isTrue);
        expect(manager.isCompleted, isFalse);

        // Complete it to avoid tearDown issues
        manager.complete('test');
        await expectLater(future, completion('test'));
      });

      test('should complete successfully with value', () async {
        final future = manager.future;
        final result = manager.complete('success');

        expect(result, isTrue);
        expect(manager.isCompleted, isTrue);
        expect(manager.isActive, isFalse);
        await expectLater(future, completion('success'));
      });

      test('should complete successfully without value', () async {
        final manager = CompleterManager<String?>();
        final future = manager.future;
        final result = manager.complete();

        expect(result, isTrue);
        expect(manager.isCompleted, isTrue);
        await expectLater(future, completion(isNull));
        manager.dispose();
      });

      test('should complete with error', () async {
        final future = manager.future;
        final testError = Exception('test error');
        final result = manager.completeError(testError);

        expect(result, isTrue);
        expect(manager.isCompleted, isTrue);
        expect(manager.isActive, isFalse);
        await expectLater(future, throwsA(testError));
      });

      test('should complete with error and stack trace', () async {
        final future = manager.future;
        final testError = Exception('test error');
        final stackTrace = StackTrace.current;
        final result = manager.completeError(testError, stackTrace);

        expect(result, isTrue);
        expect(manager.isCompleted, isTrue);

        try {
          await future;
          fail('Should have thrown an error');
        } catch (error, trace) {
          expect(error, equals(testError));
          expect(trace, equals(stackTrace));
        }
      });

      test('should return false when completing already completed manager', () {
        manager.complete('first');
        final result1 = manager.complete('second');
        final result2 = manager.completeError(Exception('error'));

        expect(result1, isFalse);
        expect(result2, isFalse);
      });
    });

    group('State Properties', () {
      test('initial state should be inactive and not completed', () {
        expect(manager.isActive, isFalse);
        expect(manager.isCompleted, isFalse);
      });

      test('should be active after accessing future', () async {
        final future = manager.future;
        expect(manager.isActive, isTrue);
        expect(manager.isCompleted, isFalse);

        // Complete it to avoid tearDown issues
        manager.complete('test');
        await expectLater(future, completion('test'));
      });

      test('should be completed after completion', () async {
        final future = manager.future;
        manager.complete('done');

        expect(manager.isActive, isFalse);
        expect(manager.isCompleted, isTrue);
        await expectLater(future, completion('done'));
      });

      test('should be completed after error completion', () async {
        final future = manager.future;
        final testError = Exception('error');
        manager.completeError(testError);

        expect(manager.isActive, isFalse);
        expect(manager.isCompleted, isTrue);
        await expectLater(future, throwsA(testError));
      });
    });

    group('Reusability', () {
      test('should create new future after previous completion', () async {
        // First use
        final future1 = manager.future;
        manager.complete('first');
        await expectLater(future1, completion('first'));

        // Second use - should get new future
        final future2 = manager.future;
        expect(future2, isNot(same(future1)));
        expect(manager.isActive, isTrue);
        expect(manager.isCompleted, isFalse);

        manager.complete('second');
        await expectLater(future2, completion('second'));
      });

      test('should reset and be reusable', () async {
        // First use
        final future1 = manager.future;
        manager.complete('first');
        await expectLater(future1, completion('first'));

        // Reset - note that reset creates a new completer, so it's not active until future is accessed
        manager.reset();
        expect(manager.isCompleted, isFalse);
        // After reset, manager is ready but not active until future is accessed

        // Second use after reset
        final future2 = manager.future;
        expect(manager.isActive, isTrue);
        manager.complete('second');
        await expectLater(future2, completion('second'));
      });

      test('should reset even when active', () async {
        final future1 = manager.future;
        expect(manager.isActive, isTrue);

        manager.reset();
        expect(manager.isCompleted, isFalse);
        // After reset, manager is ready but not active until future is accessed

        final future2 = manager.future;
        expect(manager.isActive, isTrue);
        expect(future2, isNot(same(future1)));

        // Complete it to avoid tearDown issues
        manager.complete('test');
        await expectLater(future2, completion('test'));
      });
    });

    group('Timeout Functionality', () {
      test('should timeout with default message', () async {
        final future = manager.future;
        manager.setTimer(Duration(milliseconds: 10));

        await expectLater(
          future,
          throwsA(isA<TimeoutException>()),
        );
        expect(manager.isCompleted, isTrue);
      });

      test('should timeout with custom message', () async {
        final future = manager.future;
        const customMessage = 'Custom timeout message';
        manager.setTimer(Duration(milliseconds: 10), timeoutReason: customMessage);

        try {
          await future;
          fail('Should have thrown TimeoutException');
        } catch (error) {
          expect(error, isA<TimeoutException>());
          expect((error as TimeoutException).message, contains(customMessage));
        }
      });

      test('should cancel timeout on manual completion', () async {
        final future = manager.future;
        manager.setTimer(Duration(milliseconds: 100));

        // Complete before timeout
        manager.complete('completed');
        await expectLater(future, completion('completed'));

        // Wait longer than timeout to ensure it was cancelled
        await Future.delayed(Duration(milliseconds: 150));
        // If we get here without additional errors, timeout was cancelled
      });

      test('should cancel timeout on error completion', () async {
        final future = manager.future;
        manager.setTimer(Duration(milliseconds: 100));

        // Complete with error before timeout
        final testError = Exception('test error');
        manager.completeError(testError);
        await expectLater(future, throwsA(testError));

        // Wait longer than timeout to ensure it was cancelled
        await Future.delayed(Duration(milliseconds: 150));
        // If we get here without additional errors, timeout was cancelled
      });

      test('should replace previous timeout when setting new one', () async {
        final future = manager.future;
        manager.setTimer(Duration(milliseconds: 200));
        manager.setTimer(Duration(milliseconds: 10)); // This should replace the previous one

        await expectLater(
          future,
          throwsA(isA<TimeoutException>()),
        );
      });

      test('should not set timeout on completed manager', () async {
        final future = manager.future;
        manager.complete('done');
        await expectLater(future, completion('done'));

        // This should not throw or affect anything
        manager.setTimer(Duration(milliseconds: 10));

        // Verify still completed
        expect(manager.isCompleted, isTrue);
      });

      test('should not set timeout when no active completer', () {
        // Should not throw
        manager.setTimer(Duration(milliseconds: 10));
        expect(manager.isActive, isFalse);
      });
    });

    group('Disposal', () {
      test('should complete with error when disposed while active', () async {
        final future = manager.future;
        expect(manager.isActive, isTrue);

        manager.dispose();

        await expectLater(
          future,
          throwsA(isA<StateError>()),
        );
        expect(manager.isCompleted, isTrue);
      });

      test('should not affect already completed manager', () async {
        final future = manager.future;
        manager.complete('done');
        await expectLater(future, completion('done'));

        // Dispose should not throw or change state
        manager.dispose();
        expect(manager.isCompleted, isTrue);
      });

      test('should cancel timeout on dispose', () async {
        final future = manager.future;
        manager.setTimer(Duration(milliseconds: 10));

        manager.dispose();

        // Should complete with StateError, not TimeoutException
        await expectLater(
          future,
          throwsA(isA<StateError>()),
        );
      });

      test('should not allow operations after dispose', () {
        manager.dispose();

        final result1 = manager.complete('test');
        final result2 = manager.completeError(Exception('error'));

        expect(result1, isFalse);
        expect(result2, isFalse);
        expect(manager.isCompleted, isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle multiple future accesses for same completer', () async {
        final future1 = manager.future;
        final future2 = manager.future;

        expect(identical(future1, future2), isTrue);
        expect(manager.isActive, isTrue);

        // Complete it to avoid tearDown issues
        manager.complete('test');
        await expectLater(future1, completion('test'));
      });

      test('should handle rapid complete/reset cycles', () async {
        for (int i = 0; i < 5; i++) {
          final future = manager.future;
          manager.complete('value_$i');
          await expectLater(future, completion('value_$i'));
          if (i < 4) { // Don't reset on the last iteration
            manager.reset();
          }
        }
      });

      test('should work with different generic types', () async {
        final intManager = CompleterManager<int>();
        final intFuture = intManager.future;
        intManager.complete(42);
        await expectLater(intFuture, completion(42));
        intManager.dispose();

        final boolManager = CompleterManager<bool>();
        final boolFuture = boolManager.future;
        boolManager.complete(true);
        await expectLater(boolFuture, completion(isTrue));
        boolManager.dispose();
      });

      test('should handle Future<T> values in complete', () async {
        final future = manager.future;
        final futureValue = Future.value('async_result');
        manager.complete(futureValue);

        await expectLater(future, completion('async_result'));
      });
    });

    group('Thread Safety', () {
      test('should handle concurrent operations safely', () async {
        final futures = <Future>[];

        // Start multiple concurrent operations
        for (int i = 0; i < 10; i++) {
          futures.add(Future(() async {
            final future = manager.future;
            if (i == 0) {
              // Only the first one should succeed in completing
              await Future.delayed(Duration(milliseconds: 1));
              manager.complete('winner');
            }
            return future;
          }));
        }

        final results = await Future.wait(futures, eagerError: false);

        // All should complete with the same value
        for (final result in results) {
          expect(result, equals('winner'));
        }
      });
    });
  });
}
