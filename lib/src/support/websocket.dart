import 'platforms/io.dart' if (dart.library.html) 'platforms/web.dart';

class WebSocketException implements Exception {
  final int code;
  const WebSocketException._(this.code);

  static WebSocketException unknown() => const WebSocketException._(0);
  static WebSocketException connect() => const WebSocketException._(1);

  @override
  String toString() => {
        WebSocketException.unknown(): 'Unknown error',
        WebSocketException.connect(): 'Failed to connect',
      }[this]!;
}

typedef WebSocketOnData = Function(dynamic data);
typedef WebSocketOnError = Function(dynamic error);
typedef WebSocketOnDispose = Function();

class WebSocketEventHandlers {
  final WebSocketOnData? onData;
  final WebSocketOnError? onError;
  final WebSocketOnDispose? onDispose;
  const WebSocketEventHandlers({
    this.onData,
    this.onError,
    this.onDispose,
  });
}

abstract class LiveKitWebSocket {
  void send(List<int> data);
  Future<void> dispose();

  static Future<LiveKitWebSocket> connect(
    Uri uri, [
    WebSocketEventHandlers? options,
  ]) =>
      lkWebSocketConnect(uri, options);
}
