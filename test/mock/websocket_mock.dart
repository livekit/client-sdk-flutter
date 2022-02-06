import 'package:livekit_client/src/support/websocket.dart';

class MockWebSocket extends LiveKitWebSocket {
  @override
  void send(List<int> data) {}
}

class MockWebSocketConnector {
  WebSocketEventHandlers? handlers;

  WebSocketOnData get onData => handlers!.onData!;

  WebSocketOnDispose get onDispose => handlers!.onDispose!;

  WebSocketOnError get onError => handlers!.onError!;

  Future<LiveKitWebSocket> connect(Uri uri,
      [WebSocketEventHandlers? options]) async {
    handlers = options;
    return MockWebSocket();
  }
}
