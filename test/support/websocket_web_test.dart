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

@TestOn('browser')
@Timeout(Duration(seconds: 10))
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/src/support/websocket.dart';
import 'package:livekit_client/src/support/websocket/web.dart';

void main() {
  test('an open connection that fails is disposed without an uncaught error', () async {
    final server = spawnHybridUri('websocket_web_error_server.dart');
    final port = await server.stream.first as int;
    final errors = <Object>[];
    final disposed = Completer<void>();

    await runZonedGuarded(() async {
      await LiveKitWebSocketWeb.connect(
        Uri.parse('ws://127.0.0.1:$port/rtc'),
        options: WebSocketEventHandlers(onDispose: disposed.complete),
      );
      await disposed.future;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }, (error, _) => errors.add(error));

    expect(errors, isEmpty);
  });
}
