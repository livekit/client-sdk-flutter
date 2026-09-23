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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late E2EContainer container;

  setUp(() {
    container = E2EContainer();
    // After a failed socket connect the SDK validates the token over HTTP. A
    // 403 there is how LiveKit Cloud signals that the project is not served
    // from that region, and it is the case that fails over to another region.
    sdkHttpClientFactoryForTesting = (_) =>
        MockClient((request) async => http.Response('project not allowed in this region.', 403));
  });

  tearDown(() async {
    sdkHttpClientFactoryForTesting = null;
    await container.dispose();
  });

  test('pre-connect audio buffer survives a region failover on the first attempt', () async {
    final room = container.room;

    // Known regions, so a failed first attempt retries another region instead
    // of failing the connect.
    room.regionUrlProviderForTesting = RegionUrlProvider(url: cloudUri, token: token)
      ..setServerReportedRegions(
        lk_rtc.RegionSettings()
          ..regions.add(
            lk_rtc.RegionInfo()
              ..region = 'other'
              ..url = 'wss://other.livekit.cloud',
          ),
      );
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
