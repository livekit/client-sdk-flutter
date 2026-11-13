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

import 'package:livekit_client/src/events.dart';
import 'package:livekit_client/src/internal/events.dart';
import 'package:livekit_client/src/managers/event.dart';

void main() {
  test('a refreshed token is not written to the log when its event is emitted', () async {
    const token = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyIn0.c2lnbmF0dXJl';
    final messages = <String>[];
    final previous = Logger.root.level;
    Logger.root.level = Level.ALL;
    final subscription = Logger.root.onRecord.listen((record) => messages.add(record.message));
    addTearDown(() async {
      await subscription.cancel();
      Logger.root.level = previous;
    });

    final emitter = EventsEmitter<SignalEvent>();
    addTearDown(emitter.dispose);
    emitter.emit(const SignalTokenUpdatedEvent(token: token));
    await pumpEventQueue();

    expect(
      messages.where((m) => m.contains('SignalTokenUpdatedEvent')),
      isNotEmpty,
      reason: 'the emit is logged, otherwise this checks nothing',
    );
    expect(messages.where((m) => m.contains(token)), isEmpty);
  });
}
