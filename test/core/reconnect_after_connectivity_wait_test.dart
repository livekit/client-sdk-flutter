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

// `attemptReconnect` can park for up to ten connection timeouts waiting for
// connectivity to come back. The mode it runs in has to be decided after that
// wait, because the state it depends on is exactly the state being waited on.
//
// The server drops a participant a few seconds after its transport fails
// (`disconnectCleanupDuration`), so a resume chosen before the wait is sent for
// a session that no longer exists and can only be rejected. A signalling-only
// failure is the opposite case: the peer connection is still up, the
// participant is still resumable, and a resume is the correct cheaper answer —
// so the escalation is gated on the transport, not on the wait alone.

@Timeout(Duration(seconds: 10))
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'package:livekit_client/src/core/signal_client.dart';
import 'package:livekit_client/src/internal/events.dart';
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';
import '../mock/websocket_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late E2EContainer container;
  late SignalClient client;
  late MockWebSocketConnector ws;

  setUp(() async {
    resetMockDataChannels();
    container = E2EContainer();
    client = container.client;
    ws = container.wsConnector;
    await container.connectRoom();
  });

  tearDown(() async {
    await container.dispose();
  });

  /// Spin until the SDK opens a new signal socket, returning its URI.
  Future<Uri> awaitNewSocket(Object? previousHandlers, {int maxWaitMs = 4000}) async {
    for (var i = 0; i < maxWaitMs ~/ 10 && identical(ws.handlers, previousHandlers); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(identical(ws.handlers, previousHandlers), isFalse, reason: 'SDK never re-opened the signal connection');
    return ws.uri!;
  }

  MockPeerConnection primaryPc() {
    final pc = container.engine.primary?.pc as MockPeerConnection?;
    expect(pc, isNotNull, reason: 'no primary transport');
    return pc!;
  }

  /// Drops the connection with no network available, runs [whileOffline] once the
  /// engine is parked in the wait, then restores connectivity and returns the URI
  /// of the socket the engine opens.
  Future<Uri> reconnectAcrossAnOutage({void Function()? whileOffline}) async {
    final offline = Completer<void>();
    client.debugNetworkIsAvailable = () async {
      if (!offline.isCompleted) offline.complete();
      return false;
    };

    final previousHandlers = ws.handlers;
    ws.onDispose();

    // The engine is now inside the wait, with the mode decision still ahead of it.
    await offline.future;
    await Future<void>.delayed(const Duration(milliseconds: 50));

    whileOffline?.call();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Network is back.
    client.debugNetworkIsAvailable = () async => true;
    client.events.emit(
      const SignalConnectivityChangedEvent(
        oldState: [ConnectivityResult.none],
        state: [ConnectivityResult.wifi],
      ),
    );

    return awaitNewSocket(previousHandlers);
  }

  test('an escalation raised during the connectivity wait is honored by that attempt', () async {
    // The production sequence: the socket dies first and the attempt parks waiting
    // for a network, and only then does ICE give up. That raises a full-reconnect
    // request — which a mode captured before the wait cannot act on, so the engine
    // used to send one doomed resume before honoring it.
    final uri = await reconnectAcrossAnOutage(
      whileOffline: () {
        primaryPc().connectionState = rtc.RTCPeerConnectionState.RTCPeerConnectionStateFailed;
      },
    );

    expect(
      uri.queryParameters['reconnect'],
      isNot('1'),
      reason: 'a full reconnect requested during the wait must be honored by the attempt that follows it',
    );
  });

  test('a transport that is merely disconnected across the wait still resumes', () async {
    // A peer that went away with the network is not a lost session: `resumeConnection`
    // sends an ICE restart and waits for the peer to come back, and `peerConnectionClosed`
    // is deliberately not escalated. Escalating here would trade a recoverable session
    // for a certain loss, because a full reconnect resets `_reliableDataSequence` and
    // clears `_reliableMessageBuffer` — discarding exactly the packets a resume replays
    // from `lastMessageSeq`.
    final uri = await reconnectAcrossAnOutage(
      whileOffline: () {
        primaryPc().connectionState = rtc.RTCPeerConnectionState.RTCPeerConnectionStateDisconnected;
      },
    );

    expect(
      uri.queryParameters['reconnect'],
      '1',
      reason: 'a disconnected peer is recoverable by ICE restart and must not lose the reliable buffer',
    );
  });

  test('a surviving transport after the connectivity wait still resumes', () async {
    // Signalling-only failure: the participant is still resumable, so the cheap path
    // must stay available. This is the graceful migration case, where the server
    // severs signalling precisely so the client resumes.
    expect(primaryPc().connectionState, rtc.RTCPeerConnectionState.RTCPeerConnectionStateConnected);

    final uri = await reconnectAcrossAnOutage();

    expect(uri.queryParameters['reconnect'], '1', reason: 'a live transport must still take the resume path');
  });
}
