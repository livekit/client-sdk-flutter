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

import 'package:livekit_client/livekit_client.dart';

void main() {
  late List<LogRecord> records;

  setUp(() {
    // What an app has before it touches any logging setting.
    hierarchicalLoggingEnabled = false;
    Logger.root.level = Level.INFO;
    records = [];
    final subscription = Logger.root.onRecord.listen(records.add);
    addTearDown(() async {
      await subscription.cancel();
      hierarchicalLoggingEnabled = true;
      logger.level = null;
      hierarchicalLoggingEnabled = false;
      Logger.root.level = Level.INFO;
    });
  });

  List<String> messagesFrom(String loggerName) => [
    for (final record in records)
      if (record.loggerName == loggerName) record.message,
  ];

  test('setLoggingLevel works in an app that has not set up logging', () {
    expect(() => setLoggingLevel(LoggerLevel.kFINE), returnsNormally);
  });

  test('disableLogging works in an app that has not set up logging', () {
    expect(disableLogging, returnsNormally);
  });

  test('setLoggingLevel lets SDK records below the root level through to the root listener', () {
    logger.fine('before');
    setLoggingLevel(LoggerLevel.kFINE);
    logger.fine('after');
    logger.finest('too detailed');

    expect(messagesFrom('livekit'), ['after']);
  });

  test('setLoggingLevel leaves other loggers on the root level', () {
    final other = Logger('app');
    setLoggingLevel(LoggerLevel.kALL);
    other.fine('detail');
    other.info('headline');

    expect(messagesFrom('app'), ['headline']);
  });

  test('disableLogging silences the SDK and nothing else', () {
    final other = Logger('app');
    disableLogging();
    logger.severe('from the sdk');
    other.info('from the app');

    expect(messagesFrom('livekit'), isEmpty);
    expect(messagesFrom('app'), ['from the app']);
  });

  test('a level can be raised again after logging was disabled', () {
    disableLogging();
    setLoggingLevel(LoggerLevel.kWARNING);
    logger.info('quiet');
    logger.warning('loud');

    expect(messagesFrom('livekit'), ['loud']);
  });
}
