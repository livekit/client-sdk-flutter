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
import 'package:logging/logging.dart';

import 'package:livekit_client/src/support/sdk_logger.dart';

void main() {
  late SdkLogger logger;
  late List<LogRecord> emitted, captured;

  setUp(() {
    logger = SdkLogger(Logger.detached('sdk_logger_test'));
    emitted = [];
    captured = [];
    final listening = logger.onRecord.listen(emitted.add);
    sdkFilteredWarningCapture = captured.add; // as with telemetry installed
    addTearDown(() {
      sdkFilteredWarningCapture = null;
      return listening.cancel();
    });
  });

  test('an emitted record is the logger\'s own, message converted and evaluated once', () {
    logger.level = Level.ALL;
    final message = _Counting();
    var evaluations = 0;
    var inner = 0;
    logger
      ..warning(message)
      ..severe(() => ++evaluations)
      ..warning(
        () =>
            () => ++inner,
      ); // a lazy message whose value is a Function: not called again
    expect(message.conversions, 1);
    expect(evaluations, 1);
    expect(inner, 0);
    expect(emitted.map((r) => r.message).take(2), ['counted', '1']);
    expect(captured, isEmpty, reason: 'telemetry takes emitted records from onRecord');
  });

  test('a filtered warning goes to telemetry only, evaluated once', () {
    logger.level = Level.OFF;
    var evaluations = 0;
    logger
      ..warning(() => ++evaluations)
      ..info(() => ++evaluations); // below WARNING: never evaluated, as before
    expect(evaluations, 1);
    expect(captured.single.message, '1');
    expect(emitted, isEmpty);
  });

  test('a filtered message that throws never reaches the caller', () {
    logger.level = Level.OFF;
    expect(() => logger.warning(() => throw StateError('message')), returnsNormally);
    expect(captured, isEmpty);
  });

  test('without telemetry a filtered message is never evaluated', () {
    sdkFilteredWarningCapture = null;
    logger.level = Level.OFF;
    expect(() => logger.warning(() => throw StateError('message')), returnsNormally);
  });
}

class _Counting {
  var conversions = 0;

  @override
  String toString() {
    conversions++;
    return 'counted';
  }
}
