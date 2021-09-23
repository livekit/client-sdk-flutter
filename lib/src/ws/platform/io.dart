import 'dart:async';
import 'dart:io' as io;

import '../../logger.dart';
import '../interface.dart';

Future<LiveKitWebSocketIO> lkWebSocketConnect(
  Uri uri, [
  WebSocketOptions? options,
]) =>
    LiveKitWebSocketIO.connect(uri, options);

class LiveKitWebSocketIO implements LiveKitWebSocket {
  final io.WebSocket _ws;
  final WebSocketOptions? options;
  late final StreamSubscription _subscription;

  LiveKitWebSocketIO._(
    this._ws, [
    this.options,
  ]) {
    _subscription = _ws.listen(
      (dynamic data) => options?.onData?.call(data),
      onDone: () => dispose(),
    );
  }

  @override
  void dispose() {
    options?.onDispose?.call();
    _subscription.cancel();
    _ws.close();
  }

  @override
  void send(List<int> data) {
    // 0 CONNECTING
    // 1 OPEN
    // 2 CLOSING
    // 3 CLOSED
    if (_ws.readyState == 1) {
      try {
        _ws.add(data);
      } catch (e) {
        //
      }
    }
  }

  static Future<LiveKitWebSocketIO> connect(
    Uri uri, [
    WebSocketOptions? options,
  ]) async {
    logger.fine('WebSocketIO connect (uri: ${uri.toString()})');
    try {
      final ws = await io.WebSocket.connect(uri.toString());
      logger.fine('WebSocketIO connected');
      return LiveKitWebSocketIO._(ws, options);
    } catch (_) {
      logger.severe('WebSocketIO error ${_}');
      throw WebSocketException.connect();
    }
  }
}
