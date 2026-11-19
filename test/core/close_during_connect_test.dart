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

// A full reconnect that is opening its new signal connection when the room is disposed or
// disconnected. The room's teardown ran before that connection existed, so the reconnect has to
// close what it opened instead of joining the room again as a ghost.

@Timeout(Duration(seconds: 10))
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/core/engine.dart';
import 'package:livekit_client/src/core/signal_client.dart';
import 'package:livekit_client/src/support/websocket.dart';
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';
import '../mock/websocket_mock.dart';

/// Holds every socket open until [gate] completes, and reports when one is waiting.
class GatedConnector extends MockWebSocketConnector {
  Completer<void>? gate;
  Completer<void>? reached;

  @override
  Future<LiveKitWebSocket> connect(
    Uri uri, {
    WebSocketEventHandlers? options,
    Map<String, String>? headers,
    NetworkOptions? networkOptions = const NetworkOptions(),
  }) async {
    final g = gate;
    if (g != null) {
      reached?.complete();
      await g.future;
    }
    return super.connect(uri, options: options, headers: headers, networkOptions: networkOptions);
  }
}

class GatedContainer extends E2EContainer {
  GatedContainer() {
    wsConnector = GatedConnector();
    client = SignalClient(wsConnector.connect);
    engine = Engine(
      connectOptions: const ConnectOptions(),
      roomOptions: const RoomOptions(),
      signalClient: client,
      peerConnectionCreate: MockPeerConnection.create,
    );
    room = Room(engine: engine);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final how in ['dispose', 'disconnect']) {
    test('$how while the full reconnect is opening its signal connection leaves nothing connected', () async {
      resetMockDataChannels();
      final container = GatedContainer();
      await container.connectRoom();
      final ws = container.wsConnector as GatedConnector;

      ws.gate = Completer<void>();
      ws.reached = Completer<void>();
      container.engine.fullReconnectOnNext = true;
      ws.onDispose();
      await ws.reached!.future;

      final closing = how == 'dispose' ? container.room.dispose() : container.room.disconnect();
      // The room's teardown runs while the socket is still opening.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      ws.gate!.complete();
      ws.gate = null;
      // The server answers the join the reopened socket carries.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      try {
        await container.answerJoin();
      } catch (_) {
        // The reconnect may have closed the socket before the answer, which is the point.
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await closing;

      expect(
        container.client.connectionState,
        isNot(ConnectionState.connected),
        reason: 'the signal socket stayed open',
      );
      expect(container.engine.publisher, isNull, reason: 'a publisher transport survived');
      expect(container.engine.subscriber, isNull, reason: 'a subscriber transport survived');
      if (how == 'disconnect') await container.room.dispose();
    });
  }
}
