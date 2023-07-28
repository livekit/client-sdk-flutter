// Copyright 2023 LiveKit, Inc.
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

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/core/engine.dart';
import 'package:livekit_client/src/core/signal_client.dart';
import '../core/signal_client_test.dart';
import 'peerconnection_mock.dart';
import 'websocket_mock.dart';

class E2EContainer {
  late MockWebSocketConnector wsConnector;
  late SignalClient client;
  late Room room;
  late Engine engine;

  E2EContainer() {
    wsConnector = MockWebSocketConnector();
    client = SignalClient(wsConnector.connect);
    engine = Engine(
      signalClient: client,
      peerConnectionCreate: MockPeerConnection.create,
      connectOptions: const ConnectOptions(),
      roomOptions: const RoomOptions(),
    );
    room = Room(engine: engine);
  }

  Future<void> dispose() async {
    await room.dispose();
  }

  Future<void> connectRoom() async {
    final connectFuture = room.connect(exampleUri, token);
    Future.delayed(const Duration(milliseconds: 1), () {
      wsConnector.onData(joinResponse.writeToBuffer());
      wsConnector.onData(offerResponse.writeToBuffer());
    });
    await connectFuture;
  }
}
