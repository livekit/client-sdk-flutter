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

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:livekit_client/src/events.dart';
import 'package:livekit_client/src/exceptions.dart';
import 'package:livekit_client/src/support/http_client.dart';
import 'package:livekit_client/src/support/websocket.dart' show WebSocketException;
import 'package:livekit_client/src/types/other.dart';
import '../mock/e2e_container.dart';

const token = 'token';
const cloudHost = 'project.livekit.cloud';
const cloudUrl = 'wss://$cloudHost';
const regionHosts = [
  'project.region-a.production.livekit.cloud',
  'project.region-b.production.livekit.cloud',
  'project.region-c.production.livekit.cloud',
];

String regionsJson() => jsonEncode({
  'regions': [
    for (final (i, host) in regionHosts.indexed)
      {'region': 'region-${i + 1}', 'url': 'https://$host', 'distance': '${i + 1}'},
  ],
});

/// Hosts that answered a `/rtc/validate` request. Each failed socket attempt
/// produces exactly one, so this is the list of regions the SDK tried.
final validatedHosts = <String>[];

void main() {
  late E2EContainer container;
  late int validateStatus;
  bool validateThrows = false;
  void Function()? onValidate;

  setUp(() {
    validatedHosts.clear();
    validateStatus = 503;
    validateThrows = false;
    onValidate = null;
    container = E2EContainer();
    sdkHttpClientOverride = (_) => MockClient((request) async {
      if (request.url.path == '/settings/regions') {
        return http.Response(regionsJson(), 200);
      }
      if (request.url.path.endsWith('/validate')) {
        validatedHosts.add(request.url.host);
        onValidate?.call();
        if (validateThrows) throw http.ClientException('connection refused', request.url);
        return http.Response('node error', validateStatus);
      }
      return http.Response('not found', 404);
    });
  });

  tearDown(() async {
    sdkHttpClientOverride = null;
    await container.dispose();
  });

  Future<void> answerJoinOnceConnectedTo(String host) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (container.wsConnector.uri?.host != host || container.wsConnector.handlers == null) {
      if (DateTime.now().isAfter(deadline)) {
        fail('socket to $host was never opened, last attempt: ${container.wsConnector.uri}');
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    await container.answerJoin();
  }

  test('tries every region the server lists before giving up', () async {
    container.wsConnector.connectError = const WebSocketException('Failed to connect');

    await expectLater(
      container.room.connect(cloudUrl, token),
      throwsA(isA<ConnectException>().having((e) => e.statusCode, 'statusCode', 503)),
    );

    expect(validatedHosts, [cloudHost, ...regionHosts]);
  });

  test('connects to the first region that accepts the socket', () async {
    container.wsConnector.connectErrorFor = (uri) =>
        uri.host == regionHosts[1] ? null : const WebSocketException('Failed to connect');

    final disconnectedEvents = <RoomDisconnectedEvent>[];
    container.room.events.on<RoomDisconnectedEvent>(disconnectedEvents.add);

    final connectFuture = container.room.connect(cloudUrl, token);
    await answerJoinOnceConnectedTo(regionHosts[1]);
    await connectFuture;
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(container.room.connectionState, ConnectionState.connected);
    expect(validatedHosts, [cloudHost, regionHosts[0]]);
    // the attempts that were retried must not surface as disconnects
    expect(disconnectedEvents, isEmpty);
  });

  test('a 4xx from validate ends the connect without trying other regions', () async {
    container.wsConnector.connectError = const WebSocketException('Failed to connect');
    validateStatus = 429;

    await expectLater(
      container.room.connect(cloudUrl, token),
      throwsA(
        isA<ConnectException>()
            .having((e) => e.reason, 'reason', ConnectionErrorReason.NotAllowed)
            .having((e) => e.statusCode, 'statusCode', 429),
      ),
    );

    expect(validatedHosts, [cloudHost]);
  });

  test('disconnect during failover stops the region loop', () async {
    container.wsConnector.connectError = const WebSocketException('Failed to connect');
    final disconnectedEvents = <RoomDisconnectedEvent>[];
    container.room.events.on<RoomDisconnectedEvent>(disconnectedEvents.add);
    // the app gives up while the first attempt is being validated
    onValidate = () => unawaited(container.room.disconnect());

    await expectLater(container.room.connect(cloudUrl, token), throwsA(isA<Exception>()));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(validatedHosts, [cloudHost]);
    expect(disconnectedEvents.map((e) => e.reason), [DisconnectReason.clientInitiated]);
  });

  test('a failed validate request keeps the socket error and still fails over', () async {
    container.wsConnector.connectError = const WebSocketException('Failed to connect');
    validateThrows = true;

    await expectLater(container.room.connect(cloudUrl, token), throwsA(isA<WebSocketException>()));

    expect(validatedHosts, [cloudHost, ...regionHosts]);
  });
}
