import 'dart:async';
import 'dart:io' as io;

import '../../logger.dart';
import '../websocket.dart';
import '../../extensions.dart';

Future<LiveKitWebSocketIO> lkWebSocketConnect(
  Uri uri, [
  WebSocketEventHandlers? options,
]) =>
    LiveKitWebSocketIO.connect(uri, options);

class LiveKitWebSocketIO implements LiveKitWebSocket {
  final io.WebSocket _ws;
  final WebSocketEventHandlers? options;
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
  Future<void> dispose() async {
    await _subscription.cancel();
    await _ws.close();
    options?.onDispose?.call();
  }

  @override
  void send(List<int> data) {
    // 0 CONNECTING, 1 OPEN, 2 CLOSING, 3 CLOSED
    if (_ws.readyState != 1) {
      logger.fine(
          '[$objectId] Tried to send data (readyState: ${_ws.readyState})');
      return;
    }

    try {
      _ws.add(data);
    } catch (_) {
      logger.fine('[$objectId] send did throw ${_}');
    }
  }

  static Future<LiveKitWebSocketIO> connect(
    Uri uri, [
    WebSocketEventHandlers? options,
  ]) async {
    logger.fine('[WebSocketIO] Connecting(uri: ${uri.toString()})...');
    try {
      final ws = await io.WebSocket.connect(uri.toString());
      logger.fine('[WebSocketIO] Connected');
      return LiveKitWebSocketIO._(ws, options);
    } catch (_) {
      logger.severe('[WebSocketIO] did throw ${_}');
      throw WebSocketException.connect();
    }
  }
}
