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

@Timeout(Duration(seconds: 5))
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/core/signal_client.dart';
import 'package:livekit_client/src/internal/events.dart';
import '../mock/websocket_mock.dart';

const exampleUri = 'ws://www.example.com';
const token = 'token';

void main() {
  const connectOptions = ConnectOptions();
  const networkOptions = NetworkOptions(
    certificatePinning: CertificatePinningOptions(
      rules: [
        CertificatePinningRule(
          hosts: ['www.example.com'],
          primaryPins: ['sha256/primary-pin'],
          backupPins: ['sha256/backup-pin'],
        ),
      ],
    ),
  );
  const roomOptions = RoomOptions(networkOptions: networkOptions);

  late SignalClient client;
  late MockWebSocketConnector connector;

  setUp(() {
    connector = MockWebSocketConnector();
    client = SignalClient(connector.connect);
  });

  test('passes configured network options to signaling websocket connector', () async {
    await client.connect(
      exampleUri,
      token,
      connectOptions: connectOptions,
      roomOptions: roomOptions,
    );

    // avoid exact URI equality so unrelated query parameters added to
    // Utils.buildUri do not break this test
    expect(connector.uri?.scheme, 'ws');
    expect(connector.uri?.host, 'www.example.com');
    expect(connector.uri?.path, '/rtc');
    expect(connector.uri?.queryParameters, containsPair('sdk', 'flutter'));
    expect(connector.headers, {'Authorization': 'Bearer $token'});
    expect(connector.networkOptions, same(roomOptions.networkOptions));
  });

  test('fails fast on certificate pinning failures', () async {
    connector.connectError = CertificatePinningException('Certificate pin mismatch', host: 'www.example.com');

    expect(
      client.events.streamCtrl.stream,
      emitsInOrder(<Matcher>[
        isA<SignalConnectingEvent>(),
        isA<SignalDisconnectedEvent>(),
      ]),
    );

    await expectLater(
      client.connect(
        exampleUri,
        token,
        connectOptions: connectOptions,
        roomOptions: roomOptions,
      ),
      throwsA(isA<CertificatePinningException>()),
    );
    expect(client.connectionState, ConnectionState.disconnected);
  });

  test('does not emit disconnected event on certificate pinning failures while reconnecting', () async {
    connector.connectError = CertificatePinningException('Certificate pin mismatch', host: 'www.example.com');

    final emitted = <SignalEvent>[];
    client.events.streamCtrl.stream.listen(emitted.add);

    await expectLater(
      client.connect(
        exampleUri,
        token,
        connectOptions: connectOptions,
        roomOptions: roomOptions,
        reconnect: true,
      ),
      throwsA(isA<CertificatePinningException>()),
    );

    await Future<void>.delayed(Duration.zero);
    expect(emitted.whereType<SignalDisconnectedEvent>(), isEmpty);
  });
}
