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

import 'package:livekit_client/src/support/reusable_completer.dart';

void main() {
  group('ReusableCompleter', () {
    late ReusableCompleter<String> completer;

    setUp(() {
      completer = ReusableCompleter<String>();
    });

    tearDown(() {
      if (!completer.isDisposed) {
        completer.dispose();
      }
    });

    group('Basic Functionality', () {
      test('should provide a future when accessed', () async {
        final future = completer.future;
        expect(future, isA<Future<String>>());
        expect(completer.isActive, isTrue);
        expect(completer.isCompleted, isFalse);

        completer.complete('test');
        await expectLater(future, completion('test'));
      });

      test('should complete successfully with value', () async {
        final future = completer.future;
        final result = completer.complete('success');

        expect(result, isTrue);
        expect(completer.isCompleted, isTrue);
        expect(completer.isActive, isFalse);
        await expectLater(future, completion('success'));
      });

      test('should complete successfully without value', () async {
        final completer = ReusableCompleter<String?>();
        final future = completer.future;
        final result = completer.complete();

        expect(result, isTrue);
        expect(completer.isCompleted, isTrue);
        await expectLater(future, completion(isNull));
        completer.dispose();
      });

      test('should complete with error', () async {
        final future = completer.future;
        final testError = Exception('test error');
        final result = completer.completeError(testError);

        expect(result, isTrue);
        expect(completer.isCompleted, isTrue);
        expect(completer.isActive, isFalse);
        await expectLater(future, throwsA(testError));
      });

      test('should complete with error and stack trace', () async {
        final future = completer.future;
        final testError = Exception('test error');
        final stackTrace = StackTrace.current;
        final result = completer.completeError(testError, stackTrace);

        expect(result, isTrue);
        expect(completer.isCompleted, isTrue);

        try {
          await future;
          fail('Should have thrown an error');
        } catch (error, trace) {
          expect(error, equals(testError));
          expect(trace, equals(stackTrace));
        }
      });

      test('should return false when completing already completed completer', () {
        completer.complete('first');
        final result1 = completer.complete('second');
        final result2 = completer.completeError(Exception('error'));

        expect(result1, isFalse);
        expect(result2, isFalse);
      });
    });

    group('State Properties', () {
      test('initial state should be active and not completed', () {
        expect(completer.isActive, isTrue);
        expect(completer.isCompleted, isFalse);
        expect(completer.isDisposed, isFalse);
      });

      test('should remain active after accessing future', () async {
        final future = completer.future;
        expect(completer.isActive, isTrue);
        expect(completer.isCompleted, isFalse);

        completer.complete('test');
        await expectLater(future, completion('test'));
      });

      test('should create new future after previous completion', () async {
        final future1 = completer.future;
        completer.complete('first');
        await expectLater(future1, completion('first'));

        final future2 = completer.future;
        expect(future2, isNot(same(future1)));
        expect(completer.isActive, isTrue);
        expect(completer.isCompleted, isFalse);

        completer.complete('second');
        await expectLater(future2, completion('second'));
      });

      test('should reset and be reusable', () async {
        final future1 = completer.future;
        completer.complete('first');
        await expectLater(future1, completion('first'));

        completer.reset();
        expect(completer.isCompleted, isFalse);

        final future2 = completer.future;
        expect(completer.isActive, isTrue);
        completer.complete('second');
        await expectLater(future2, completion('second'));
      });

      test('should reset even when active and deliver error to pending future', () async {
        final future1 = completer.future;
        expect(completer.isActive, isTrue);

        completer.reset();
        expect(completer.isCompleted, isFalse);

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

        final future2 = completer.future;
        expect(completer.isActive, isTrue);
        expect(future2, isNot(same(future1)));

        completer.complete('test');
        await expectLater(future2, completion('test'));
      });
    });

    group('Timeout Functionality', () {
      test('should timeout with default message', () async {
        final future = completer.future;
        completer.setTimer(Duration(milliseconds: 10));

        await expectLater(
          future,
          throwsA(isA<TimeoutException>()),
        );
        expect(completer.isCompleted, isTrue);
      });

      test('should timeout with custom message', () async {
        final future = completer.future;
        const customMessage = 'Custom timeout message';
        completer.setTimer(Duration(milliseconds: 10), timeoutReason: customMessage);

        try {
          await future;
          fail('Expected TimeoutException');
        } catch (error) {
          expect(error, isA<TimeoutException>());
          expect((error as TimeoutException).message, contains(customMessage));
        }
      });

      test('should ignore timer after completion', () async {
        final future = completer.future;
        completer.setTimer(Duration(milliseconds: 10));
        completer.complete('done');

        await expectLater(future, completion('done'));
        await Future<void>.delayed(Duration(milliseconds: 20));
        expect(completer.isCompleted, isTrue);
      });
    });

    group('Reset Behavior', () {
      test('should complete pending future with custom error on reset', () async {
        final future = completer.future;
        final customError = Exception('custom reset');
        completer.reset(error: customError);

        await expectLater(future, throwsA(customError));
      });

      test('should allow reset after completion without affecting last result', () async {
        final future = completer.future;
        completer.complete('done');
        await expectLater(future, completion('done'));

        completer.reset();
        final nextFuture = completer.future;

        completer.complete('next');
        await expectLater(nextFuture, completion('next'));
      });
    });

    group('Dispose', () {
      test('should complete pending future with error on dispose', () async {
        final future = completer.future;
        completer.dispose();

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
        expect(completer.isCompleted, isTrue);
        expect(completer.isDisposed, isTrue);
      });

      test('should use custom error on dispose', () async {
        final future = completer.future;
        final customError = Exception('disposed error');
        completer.dispose(error: customError);

        await expectLater(future, throwsA(customError));
      });

      test('should return false for operations after dispose', () {
        completer.dispose();

        final result1 = completer.complete('test');
        final result2 = completer.completeError(Exception('error'));
        completer.setTimer(Duration(seconds: 1));

        expect(result1, isFalse);
        expect(result2, isFalse);
        expect(completer.isActive, isFalse);
      });

      test('should throw when requesting future after dispose', () {
        completer.dispose();

        expect(
          () => completer.future,
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
        completer.dispose();
        expect(completer.isDisposed, isTrue);

        completer.dispose();
        expect(completer.isDisposed, isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle multiple future accesses for same completer', () async {
        final future1 = completer.future;
        final future2 = completer.future;

        expect(identical(future1, future2), isTrue);
        expect(completer.isActive, isTrue);

        completer.complete('test');
        await expectLater(future1, completion('test'));
      });

      test('should handle rapid complete/reset cycles', () async {
        for (int i = 0; i < 5; i++) {
          final future = completer.future;
          completer.complete('value_$i');
          await expectLater(future, completion('value_$i'));
          if (i < 4) {
            completer.reset();
          }
        }
      });

      test('should work with different generic types', () async {
        final intCompleter = ReusableCompleter<int>();
        final intFuture = intCompleter.future;
        intCompleter.complete(42);
        await expectLater(intFuture, completion(42));
        intCompleter.dispose();

        final boolCompleter = ReusableCompleter<bool>();
        final boolFuture = boolCompleter.future;
        boolCompleter.complete(true);
        await expectLater(boolFuture, completion(isTrue));
        boolCompleter.dispose();
      });

      test('should handle Future<T> values in complete', () async {
        final future = completer.future;
        final futureValue = Future.value('async_result');
        completer.complete(futureValue);

        await expectLater(future, completion('async_result'));
      });
    });

    group('Concurrency', () {
      test('should handle concurrent operations safely enough for single isolate', () async {
        final futures = <Future>[];

        for (int i = 0; i < 10; i++) {
          futures.add(Future(() async {
            final future = completer.future;
            if (i == 0) {
              await Future.delayed(Duration(milliseconds: 1));
              completer.complete('winner');
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
