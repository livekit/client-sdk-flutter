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
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';
import '../mock/websocket_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late E2EContainer container;
  late MockWebSocketConnector ws;

  setUp(() async {
    resetMockDataChannels();
    container = E2EContainer();
    ws = container.wsConnector;
    await container.connectRoom();
  });

  tearDown(() async {
    await container.dispose();
  });

  Future<void> until(bool Function() condition) async {
    for (var i = 0; i < 200 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(condition(), isTrue);
  }

  test('restartIce() resumes to switch candidates, restarting publisher ICE', () async {
    final publisher = container.engine.publisher!;
    await container.engine.negotiate();
    await until(() => publisher.pc.signalingState == rtc.RTCSignalingState.RTCSignalingStateHaveLocalOffer);
    ws.onData(
      lk_rtc.SignalResponse(
        answer: lk_rtc.SessionDescription(type: 'answer', sdp: 'remote_answer'),
      ).writeToBuffer(),
    );
    await until(() => publisher.pc.connectionState == rtc.RTCPeerConnectionState.RTCPeerConnectionStateConnected);

    final previousHandlers = ws.handlers;
    await container.room.restartIce();
    await until(() => !identical(ws.handlers, previousHandlers));

    expect(ws.uri!.queryParameters['reconnect'], '1');
    expect(ws.uri!.queryParameters['reconnect_reason'], '${lk_models.ReconnectReason.RR_SWITCH_CANDIDATE.value}');

    ws.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());
    await container.room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
    expect(publisher.restartingIce, isTrue);
  });
}
