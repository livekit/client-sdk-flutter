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

// A resume that fails because the publisher cannot negotiate must be followed by a full
// reconnect: the publisher stays in have-local-offer, so resuming again fails the same way.

@Timeout(Duration(seconds: 10))
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';
import '../mock/websocket_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final connections = <StaleAnswerPeerConnection>[];
  late E2EContainer container;
  late MockWebSocketConnector ws;

  setUp(() async {
    resetMockDataChannels();
    connections.clear();
    container = E2EContainer(
      peerConnectionCreate: (Map<String, dynamic> configuration, [Map<String, dynamic>? constraints]) async {
        final pc = StaleAnswerPeerConnection();
        connections.add(pc);
        return pc;
      },
    );
    ws = container.wsConnector;
    await container.connectRoom();
  });

  tearDown(() async {
    await container.dispose();
  });

  test('a resume that fails with a NegotiationError is retried as a full reconnect', () async {
    // Negotiating marks the publisher as having published.
    await container.engine.negotiate();
    // Let the debounced negotiation finish before the publisher is made stale.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    for (final pc in connections) {
      pc.stale = true;
    }

    var resumeHandlers = ws.handlers;
    ws.onDispose();
    for (var i = 0; i < 200 && identical(ws.handlers, resumeHandlers); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(
      ws.uri?.queryParameters['reconnect'],
      '1',
      reason: 'the first attempt must be a resume',
    );

    resumeHandlers = ws.handlers;
    ws.onData(
      lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer(),
    );

    for (var i = 0; i < 200 && identical(ws.handlers, resumeHandlers); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(
      identical(ws.handlers, resumeHandlers),
      isFalse,
      reason: 'no attempt followed the failed resume',
    );
    expect(
      ws.uri?.queryParameters['reconnect'],
      isNull,
      reason: 'the next attempt must re-join, not resume',
    );
  });
}
