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
import 'package:livekit_client/src/connection_check/checks/websocket.dart';
import 'package:livekit_client/src/support/websocket.dart';
import '../core/signal_client_test.dart';
import '../mock/websocket_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebSocketCheck', () {
    test('succeeds when the server answers with a join response', () async {
      final connector = MockWebSocketConnector();
      final check = WebSocketCheck(exampleUri, token);
      check.wsConnector = connector.connect;

      final resultFuture = check.run();
      // wait for the check to open its (mock) socket, then reply with a join
      while (connector.handlers == null) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      connector.onData(joinResponse.writeToBuffer());

      final info = await resultFuture;
      expect(info.status, CheckStatus.success);
      expect(
        info.logs.map((log) => log.message),
        contains(contains('Connected to server, version 99.999')),
      );
      // ws:// scheme should produce an insecure-server warning
      expect(
        info.logs.where((log) => log.level == CheckLogLevel.warning),
        isNotEmpty,
      );
      await check.dispose();
    });

    test('fails when the socket cannot be opened', () async {
      final connector = MockWebSocketConnector();
      connector.connectError = WebSocketException('Failed to connect');
      final check = WebSocketCheck(exampleUri, token);
      check.wsConnector = connector.connect;

      final info = await check.run();
      expect(info.status, CheckStatus.failed);
      expect(
        info.logs.map((log) => log.message),
        contains(contains('Websocket connection could not be established')),
      );
      await check.dispose();
    });
  });
}
