import 'platform/io.dart' if (dart.library.html) 'platform/web.dart';

class LKWebSocketError implements Exception {
  final int code;
  const LKWebSocketError._(this.code);

  static LKWebSocketError unknown() => const LKWebSocketError._(0);
  static LKWebSocketError connect() => const LKWebSocketError._(1);

  @override
  String toString() => {
        LKWebSocketError.unknown(): 'Unknown error',
        LKWebSocketError.connect(): 'Failed to connect',
      }[this]!;
}

typedef LKWebSocketOnData = Function(dynamic data);
typedef LKWebSocketOnError = Function(dynamic error);
typedef LKWebSocketOnDispose = Function();

class LKWebSocketOptions {
  final LKWebSocketOnData? onData;
  final LKWebSocketOnError? onError;
  final LKWebSocketOnDispose? onDispose;
  const LKWebSocketOptions({
    this.onData,
    this.onError,
    this.onDispose,
  });
}

abstract class LKWebSocket {
  void send(List<int> data);
  void dispose();

  static Future<LKWebSocket> connect(
    Uri uri, [
    LKWebSocketOptions? options,
  ]) =>
      lkWebSocketConnect(uri, options);
}
