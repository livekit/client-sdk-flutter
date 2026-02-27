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

@Timeout(Duration(seconds: 5))
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/src/support/serial_runner.dart';

void main() {
  group('SerialRunner', () {
    test('executes a single operation', () async {
      final runner = SerialRunner<int>();
      final result = await runner.run(() async => 42);
      expect(result, 42);
    });

    test('serializes concurrent operations', () async {
      final runner = SerialRunner<int>();
      final order = <int>[];

      final completer1 = Completer<void>();
      final future1 = runner.run(() async {
        order.add(1);
        await completer1.future;
        order.add(2);
        return 1;
      });

      // Second call while first is pending
      final future2 = runner.run(() async {
        order.add(3);
        return 2;
      });

      // Only the first operation should have started
      expect(order, [1]);
      expect(runner.isRunning, isTrue);

      // Complete the first operation
      completer1.complete();
      final results = await Future.wait([future1, future2]);

      expect(results, [1, 2]);
      expect(order, [1, 2, 3]);
      expect(runner.isRunning, isFalse);
    });

    test('second call runs after first even if first throws', () async {
      final runner = SerialRunner<int>();

      final future1 = runner.run(() async {
        throw StateError('fail');
      });

      final future2 = runner.run(() async => 42);

      await expectLater(future1, throwsStateError);
      expect(await future2, 42);
    });

    test('propagates errors to caller', () async {
      final runner = SerialRunner<int>();
      await expectLater(
        runner.run(() async => throw FormatException('bad')),
        throwsFormatException,
      );
      // Runner is reusable after error
      expect(runner.isRunning, isFalse);
      expect(await runner.run(() async => 1), 1);
    });

    test('serializes three operations in order', () async {
      final runner = SerialRunner<int>();
      final order = <int>[];

      final c1 = Completer<void>();
      final c2 = Completer<void>();

      final f1 = runner.run(() async {
        order.add(1);
        await c1.future;
        return 1;
      });

      final f2 = runner.run(() async {
        order.add(2);
        await c2.future;
        return 2;
      });

      final f3 = runner.run(() async {
        order.add(3);
        return 3;
      });

      expect(order, [1]);

      c1.complete();
      await f1;
      // After f1 completes, f2 should start
      await Future.delayed(Duration.zero);
      expect(order, [1, 2]);

      c2.complete();
      await Future.wait([f2, f3]);
      expect(order, [1, 2, 3]);
    });
  });
}
