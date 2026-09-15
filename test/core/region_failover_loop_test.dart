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
import 'package:flutter_webrtc/flutter_webrtc.dart' show RTCPeerConnection;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:livekit_client/src/constants.dart';
import 'package:livekit_client/src/events.dart';
import 'package:livekit_client/src/exceptions.dart';
import 'package:livekit_client/src/options.dart';
import 'package:livekit_client/src/support/http_client.dart';
import 'package:livekit_client/src/support/websocket.dart' show WebSocketException;
import 'package:livekit_client/src/types/other.dart';
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';

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
  Duration? regionsDelay;

  setUp(() {
    validatedHosts.clear();
    validateStatus = 503;
    validateThrows = false;
    onValidate = null;
    regionsDelay = null;
    container = E2EContainer();
    sdkHttpClientOverride = (_) => MockClient((request) async {
      if (request.method == 'HEAD') {
        return http.Response('', 200);
      }
      if (request.url.path == '/settings/regions') {
        if (regionsDelay != null) await Future<void>.delayed(regionsDelay!);
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

  test('a later connect on the same room has every region available again', () async {
    container.wsConnector.connectError = const WebSocketException('Failed to connect');

    await expectLater(container.room.connect(cloudUrl, token), throwsA(isA<ConnectException>()));
    expect(validatedHosts, [cloudHost, ...regionHosts]);

    validatedHosts.clear();
    await expectLater(container.room.connect(cloudUrl, token), throwsA(isA<ConnectException>()));
    expect(validatedHosts, [cloudHost, ...regionHosts]);
  });

  test('disconnect while the join is stalled completes the teardown', () async {
    // the socket opens but the server never answers the join
    const shortTimeouts = Timeouts(
      connection: Duration(milliseconds: 200),
      debounce: Duration(milliseconds: 1),
      publish: Duration(milliseconds: 200),
      subscribe: Duration(milliseconds: 200),
      peerConnection: Duration(milliseconds: 200),
      iceRestart: Duration(milliseconds: 200),
    );
    final disconnectedEvents = <RoomDisconnectedEvent>[];
    container.room.events.on<RoomDisconnectedEvent>(disconnectedEvents.add);

    // capture the outcome now, the failure lands while disconnect() is awaited
    final connectOutcome = container.room
        .connect(cloudUrl, token, connectOptions: const ConnectOptions(timeouts: shortTimeouts))
        .then<Object?>((_) => null, onError: (Object e) => e);
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (container.room.connectionState != ConnectionState.connected) {
      if (DateTime.now().isAfter(deadline)) fail('signal socket never opened');
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }

    await container.room.disconnect().timeout(const Duration(seconds: 3));
    expect(await connectOutcome, isA<ConnectException>());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(container.room.connectionState, ConnectionState.disconnected);
    expect(disconnectedEvents, hasLength(1));
  });

  test('a prepared region is used once and is not picked again as the next region', () async {
    container.wsConnector.connectError = const WebSocketException('Failed to connect');
    await container.room.prepareConnection(cloudUrl, token);

    await expectLater(container.room.connect(cloudUrl, token), throwsA(isA<ConnectException>()));
    // the prepared region is the first attempt, the others follow once each
    expect(validatedHosts, regionHosts);

    validatedHosts.clear();
    await expectLater(container.room.connect(cloudUrl, token), throwsA(isA<ConnectException>()));
    expect(validatedHosts, [cloudHost, ...regionHosts]);
  });

  test('peer connections built by a late join response are disposed before the next region', () async {
    // The first attempt's join response lands after the connect deadline, so
    // transports get created for an attempt that has already been given up on.
    // A slow region lookup keeps the loop parked while that happens.
    regionsDelay = const Duration(milliseconds: 300);
    var creates = 0;
    final counting = E2EContainer(
      peerConnectionCreate: (Map<String, dynamic> configuration, [Map<String, dynamic>? constraints]) async {
        creates++;
        return MockPeerConnection();
      },
    );
    addTearDown(counting.dispose);
    const shortTimeouts = Timeouts(
      connection: Duration(milliseconds: 200),
      debounce: Duration(milliseconds: 1),
      publish: Duration(milliseconds: 200),
      subscribe: Duration(milliseconds: 200),
      peerConnection: Duration(milliseconds: 200),
      iceRestart: Duration(milliseconds: 200),
    );

    Future<void> waitForSocket(String host) async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (counting.wsConnector.uri?.host != host || counting.wsConnector.handlers == null) {
        if (DateTime.now().isAfter(deadline)) fail('socket to $host was never opened');
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
    }

    // capture the outcome now, a failure would otherwise surface as an unhandled error while polling
    final connectOutcome = counting.room
        .connect(cloudUrl, token, connectOptions: const ConnectOptions(timeouts: shortTimeouts))
        .then<Object?>((_) => null, onError: (Object e) => e);

    await waitForSocket(cloudHost);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await counting.answerJoin();
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (counting.engine.publisher == null) {
      if (DateTime.now().isAfter(deadline)) fail('late join never created the first publisher');
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    final firstPublisher = counting.engine.publisher;
    expect(creates, 2);

    await waitForSocket(regionHosts[0]);
    expect(counting.engine.publisher, isNull, reason: 'transports from the failed attempt must be disposed');
    await counting.answerJoin();
    expect(await connectOutcome, isNull);

    expect(counting.room.connectionState, ConnectionState.connected);
    expect(counting.engine.publisher, isNot(same(firstPublisher)));
    expect(counting.engine.subscriber, isNotNull);
    expect(creates, 4);
  });

  test('a failed validate request keeps the socket error and still fails over', () async {
    container.wsConnector.connectError = const WebSocketException('Failed to connect');
    validateThrows = true;

    await expectLater(container.room.connect(cloudUrl, token), throwsA(isA<WebSocketException>()));

    expect(validatedHosts, [cloudHost, ...regionHosts]);
  });
}
