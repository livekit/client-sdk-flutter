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
        signalClient: client, peerConnectionCreate: MockPeerConnection.create);
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
