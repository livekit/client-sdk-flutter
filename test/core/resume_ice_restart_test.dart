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

// A resume restarts ICE with a new publisher offer. When the previous offer is
// still waiting for its answer, the transport first re-applies the last answer
// to get back to `stable`. If that offer added media sections (a published
// track, or in single PC mode a receive section the server asked for), the old
// answer no longer matches it and is rejected, and every further resume would
// fail the same way. The next attempt has to rebuild the peer connection.

@Timeout(Duration(seconds: 10))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/core/transport.dart' show Transport;
import 'package:livekit_client/src/internal/types.dart' show RTCOfferOptions;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';
import '../mock/websocket_mock.dart';

/// Once [offerPending] is set, behaves like a peer connection whose latest offer
/// added media sections the last answer does not have: it is in
/// `have-local-offer`, and re-applying that answer is rejected as libwebrtc does.
class _GrownOfferPeerConnection extends MockPeerConnection {
  bool offerPending = false;
  int rejectedAnswers = 0;

  static final _lastAnswer = rtc.RTCSessionDescription('v=0\r\nlast-answer', 'answer');

  @override
  rtc.RTCSignalingState? get signalingState =>
      offerPending ? rtc.RTCSignalingState.RTCSignalingStateHaveLocalOffer : super.signalingState;

  @override
  Future<rtc.RTCSignalingState?> getSignalingState() async => signalingState;

  @override
  Future<rtc.RTCSessionDescription?> getRemoteDescription() async =>
      offerPending ? _lastAnswer : super.getRemoteDescription();

  @override
  Future<void> setRemoteDescription(rtc.RTCSessionDescription description) async {
    if (offerPending && description.type == 'answer') {
      rejectedAnswers++;
      throw Exception("Failed to set remote answer sdp: The number of m-lines in answer doesn't match the offer.");
    }
    await super.setRemoteDescription(description);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Transport reports a rejected answer re-apply on ICE restart as a media failure', () async {
    final pc = _GrownOfferPeerConnection();
    final transport = await Transport.create(
      (Map<String, dynamic> configuration, [Map<String, dynamic>? constraints]) async => pc,
      connectOptions: const ConnectOptions(),
    );
    addTearDown(transport.dispose);
    var offers = 0;
    transport.onOffer = (_, _) => offers++;

    pc.offerPending = true;
    await expectLater(
      transport.createAndSendOffer(const RTCOfferOptions(iceRestart: true)),
      throwsA(isA<MediaConnectException>()),
    );
    expect(pc.rejectedAnswers, 1);
    expect(offers, 0, reason: 'no ICE restart offer can be sent while the old one is pending');
  });

  group('resume with a pending publisher offer', () {
    late E2EContainer container;
    late MockWebSocketConnector ws;
    final pcs = <_GrownOfferPeerConnection>[];

    setUp(() async {
      resetMockDataChannels();
      pcs.clear();
      container = E2EContainer(
        peerConnectionCreate: (Map<String, dynamic> configuration, [Map<String, dynamic>? constraints]) async {
          final pc = _GrownOfferPeerConnection();
          pcs.add(pc);
          return pc;
        },
      );
      ws = container.wsConnector;
      await container.connectRoom();
    });

    tearDown(() async {
      await container.dispose();
    });

    Future<Uri> awaitNewSocket(Object? previousHandlers) async {
      for (var i = 0; i < 200 && identical(ws.handlers, previousHandlers); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(identical(ws.handlers, previousHandlers), isFalse, reason: 'SDK never re-opened the signal connection');
      return ws.uri!;
    }

    test('falls back to a full reconnect when the last answer no longer applies', () async {
      final roomEvents = <RoomEvent>[];
      final cancel = container.room.events.listen(roomEvents.add);

      // Publishing makes the publisher required, so the resume restarts ICE on it.
      await container.engine.negotiate();
      final publisherPc = container.engine.publisher!.pc as _GrownOfferPeerConnection;
      // A new offer went out (here: grown by a published track) and the signal
      // connection drops before its answer arrives.
      publisherPc.offerPending = true;

      final firstHandlers = ws.handlers;
      ws.onDispose();
      final resumeUri = await awaitNewSocket(firstHandlers);
      expect(resumeUri.queryParameters['reconnect'], '1', reason: 'the first attempt must be a resume');

      final resumeHandlers = ws.handlers;
      ws.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());

      // Retrying the resume would hit the same rejected answer, so the next
      // attempt must re-join with a new peer connection.
      final retryUri = await awaitNewSocket(resumeHandlers);
      await cancel();

      expect(publisherPc.rejectedAnswers, 1);
      expect(retryUri.queryParameters['reconnect'], isNull, reason: 'the retry must re-join, not resume again');
      expect(roomEvents.whereType<RoomResumingEvent>(), isNotEmpty);
      expect(roomEvents.whereType<RoomReconnectingEvent>(), isNotEmpty);
    });
  });
}
