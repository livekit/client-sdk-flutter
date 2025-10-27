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
      if (!manager.isDisposed) {
        manager.dispose();
      }
    });

    group('Basic Functionality', () {
      test('should provide a future when accessed', () async {
        final future = manager.future;
        expect(future, isA<Future<String>>());
        expect(manager.isActive, isTrue);
        expect(manager.isCompleted, isFalse);

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
      test('initial state should be active and not completed', () {
        expect(manager.isActive, isTrue);
        expect(manager.isCompleted, isFalse);
        expect(manager.isDisposed, isFalse);
      });

      test('should remain active after accessing future', () async {
        final future = manager.future;
        expect(manager.isActive, isTrue);
        expect(manager.isCompleted, isFalse);

        manager.complete('test');
        await expectLater(future, completion('test'));
      });

      test('should create new future after previous completion', () async {
        final future1 = manager.future;
        manager.complete('first');
        await expectLater(future1, completion('first'));

        final future2 = manager.future;
        expect(future2, isNot(same(future1)));
        expect(manager.isActive, isTrue);
        expect(manager.isCompleted, isFalse);

        manager.complete('second');
        await expectLater(future2, completion('second'));
      });

      test('should reset and be reusable', () async {
        final future1 = manager.future;
        manager.complete('first');
        await expectLater(future1, completion('first'));

        manager.reset();
        expect(manager.isCompleted, isFalse);

        final future2 = manager.future;
        expect(manager.isActive, isTrue);
        manager.complete('second');
        await expectLater(future2, completion('second'));
      });

      test('should reset even when active and deliver error to pending future', () async {
        final future1 = manager.future;
        expect(manager.isActive, isTrue);

        manager.reset();
        expect(manager.isCompleted, isFalse);

        await expectLater(
          future1,
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('reset'),
            ),
          ),
        );

        final future2 = manager.future;
        expect(manager.isActive, isTrue);
        expect(future2, isNot(same(future1)));

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
          fail('Expected TimeoutException');
        } catch (error) {
          expect(error, isA<TimeoutException>());
          expect((error as TimeoutException).message, contains(customMessage));
        }
      });

      test('should ignore timer after completion', () async {
        final future = manager.future;
        manager.setTimer(Duration(milliseconds: 10));
        manager.complete('done');

        await expectLater(future, completion('done'));
        await Future<void>.delayed(Duration(milliseconds: 20));
        expect(manager.isCompleted, isTrue);
      });
    });

    group('Reset Behavior', () {
      test('should complete pending future with custom error on reset', () async {
        final future = manager.future;
        final customError = Exception('custom reset');
        manager.reset(error: customError);

        await expectLater(future, throwsA(customError));
      });

      test('should allow reset after completion without affecting last result', () async {
        final future = manager.future;
        manager.complete('done');
        await expectLater(future, completion('done'));

        manager.reset();
        final nextFuture = manager.future;

        manager.complete('next');
        await expectLater(nextFuture, completion('next'));
      });
    });

    group('Dispose', () {
      test('should complete pending future with error on dispose', () async {
        final future = manager.future;
        manager.dispose();

        await expectLater(
          future,
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('disposed'),
            ),
          ),
        );
        expect(manager.isCompleted, isTrue);
        expect(manager.isDisposed, isTrue);
      });

      test('should use custom error on dispose', () async {
        final future = manager.future;
        final customError = Exception('disposed error');
        manager.dispose(error: customError);

        await expectLater(future, throwsA(customError));
      });

      test('should return false for operations after dispose', () {
        manager.dispose();

        final result1 = manager.complete('test');
        final result2 = manager.completeError(Exception('error'));
        manager.setTimer(Duration(seconds: 1));

        expect(result1, isFalse);
        expect(result2, isFalse);
        expect(manager.isActive, isFalse);
      });

      test('should throw when requesting future after dispose', () {
        manager.dispose();

        expect(
          () => manager.future,
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('disposed'),
            ),
          ),
        );
      });

      test('should ignore duplicate dispose calls', () {
        manager.dispose();
        expect(manager.isDisposed, isTrue);

        manager.dispose();
        expect(manager.isDisposed, isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle multiple future accesses for same completer', () async {
        final future1 = manager.future;
        final future2 = manager.future;

        expect(identical(future1, future2), isTrue);
        expect(manager.isActive, isTrue);

        manager.complete('test');
        await expectLater(future1, completion('test'));
      });

      test('should handle rapid complete/reset cycles', () async {
        for (int i = 0; i < 5; i++) {
          final future = manager.future;
          manager.complete('value_$i');
          await expectLater(future, completion('value_$i'));
          if (i < 4) {
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

    group('Concurrency', () {
      test('should handle concurrent operations safely enough for single isolate', () async {
        final futures = <Future>[];

        for (int i = 0; i < 10; i++) {
          futures.add(Future(() async {
            final future = manager.future;
            if (i == 0) {
              await Future.delayed(Duration(milliseconds: 1));
              manager.complete('winner');
            }
            return future;
          }));
        }

        final results = await Future.wait(futures, eagerError: false);

        for (final result in results) {
          expect(result, equals('winner'));
        }
      });
    });
  });
}
