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

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import 'package:livekit_client/src/support/http_client.dart';
import 'package:livekit_client/src/support/region_url_provider.dart';
import 'package:livekit_client/src/support/websocket.dart';
import '../mock/e2e_container.dart';

const cloudUri = 'wss://test.livekit.cloud';
const token = 'token';

/// A provider that already knows its regions, so a failover never has to
/// fetch them. With no [regions] there is nowhere left to fail over to.
RegionUrlProvider providerWith(List<String> regions) =>
    RegionUrlProvider(url: cloudUri, token: token)..setServerReportedRegions(
      lk_rtc.RegionSettings()
        ..regions.addAll([
          for (final region in regions)
            lk_rtc.RegionInfo()
              ..region = region
              ..url = 'wss://$region.livekit.cloud',
        ]),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late E2EContainer container;

  // What the validate request answers after a failed socket connect. A 403 is
  // one of the answers that makes connect() fail over to another region.
  late int validateStatus;

  setUp(() {
    container = E2EContainer();
    validateStatus = 403;
    sdkHttpClientFactoryForTesting = (_) => MockClient(
      (request) async => validateStatus == 200
          ? http.Response('success', 200)
          : http.Response('project not allowed in this region.', validateStatus),
    );
  });

  tearDown(() async {
    sdkHttpClientFactoryForTesting = null;
    await container.dispose();
  });

  test('pre-connect audio buffer survives a region failover on the first attempt', () async {
    final room = container.room;

    // Known regions, so a failed first attempt retries another region instead
    // of failing the connect.
    room.regionUrlProviderForTesting = providerWith(['other']);
    room.preConnectAudioBuffer.markRecordingForTesting();

    // The first socket connect fails, the retry gets through.
    container.wsConnector.connectError = WebSocketException('first region down');
    container.wsConnector.connectErrorOnce = true;
    final connecting = room.connect(cloudUri, token);
    await container.answerJoin();
    await connecting;

    expect(room.connectionState, ConnectionState.connected);
    expect(container.wsConnector.uri.toString(), startsWith('wss://other.livekit.cloud'));
    // The buffered microphone track is published from the join response, so
    // the cleanup that runs for the failed attempt must leave the buffer alone.
    expect(room.preConnectAudioBuffer.isRecording, isTrue);
  });

  test('pre-connect audio buffer survives a failover when only the socket is rejected', () async {
    final room = container.room;
    room.regionUrlProviderForTesting = providerWith(['other']);
    room.preConnectAudioBuffer.markRecordingForTesting();

    // The socket is refused while the validate request succeeds, so connect()
    // fails over on the socket error itself.
    validateStatus = 200;
    container.wsConnector.connectError = WebSocketException('rejected');
    container.wsConnector.connectErrorOnce = true;
    final connecting = room.connect(cloudUri, token);
    await container.answerJoin();
    await connecting;

    expect(room.connectionState, ConnectionState.connected);
    expect(container.wsConnector.uri.toString(), startsWith('wss://other.livekit.cloud'));
    expect(room.preConnectAudioBuffer.isRecording, isTrue);
  });

  test('pre-connect audio buffer is reset when connect fails with no failover', () async {
    final room = container.room;
    room.preConnectAudioBuffer.markRecordingForTesting();

    // Not a LiveKit Cloud url, so there is no other region to try.
    validateStatus = 401;
    container.wsConnector.connectError = WebSocketException('down');
    await expectLater(room.connect('wss://self.hosted.example', token), throwsA(isA<ConnectException>()));
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(room.preConnectAudioBuffer.isRecording, isFalse);
  });

  test('pre-connect audio buffer is reset when the failover has no region left', () async {
    final room = container.room;
    room.regionUrlProviderForTesting = providerWith([]);
    room.preConnectAudioBuffer.markRecordingForTesting();
    // Stopped with the connect error, which is what also stops the native
    // recorder, rather than with a plain reset.
    final agentReady = expectLater(room.preConnectAudioBuffer.agentReadyFuture, throwsA(isA<ConnectException>()));

    container.wsConnector.connectError = WebSocketException('down');
    await expectLater(room.connect(cloudUri, token), throwsA(isA<ConnectException>()));
    await agentReady;

    expect(room.preConnectAudioBuffer.isRecording, isFalse);
  });

  test('pre-connect audio buffer is reset when the failover attempt fails too', () async {
    final room = container.room;
    room.regionUrlProviderForTesting = providerWith(['other']);
    room.preConnectAudioBuffer.markRecordingForTesting();
    final agentReady = expectLater(room.preConnectAudioBuffer.agentReadyFuture, throwsA(isA<ConnectException>()));

    container.wsConnector.connectError = WebSocketException('down');
    await expectLater(room.connect(cloudUri, token), throwsA(isA<ConnectException>()));
    await agentReady;

    expect(room.preConnectAudioBuffer.isRecording, isFalse);
  });

  test('pre-connect audio buffer is reset when disconnect() is called during connect', () async {
    final room = container.room;
    room.preConnectAudioBuffer.markRecordingForTesting();

    // The socket handshake is still in flight when the app gives up. A buffer
    // left recording here would publish the microphone if that connect went
    // on to complete.
    final handshake = Completer<void>();
    container.wsConnector.connectGate = handshake.future;
    unawaited(room.connect(cloudUri, token).then((_) {}, onError: (_) {}));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    unawaited(room.disconnect().then((_) {}, onError: (_) {}));
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(room.preConnectAudioBuffer.isRecording, isFalse);
    handshake.complete();
  });

  test('pre-connect audio buffer is still reset when the connection drops', () async {
    final room = container.room;
    await container.connectRoom();
    room.preConnectAudioBuffer.markRecordingForTesting();

    // The server asks the participant to leave, outside of any connect attempt.
    container.wsConnector.onData(
      lk_rtc.SignalResponse(
        leave: lk_rtc.LeaveRequest(
          action: lk_rtc.LeaveRequest_Action.DISCONNECT,
          reason: lk_models.DisconnectReason.ROOM_DELETED,
        ),
      ).writeToBuffer(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(room.preConnectAudioBuffer.isRecording, isFalse);
  });
}
