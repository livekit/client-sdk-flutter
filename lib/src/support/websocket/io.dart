import 'dart:async';
import 'dart:io' as io;

import '../../extensions.dart';
import '../../logger.dart';
import '../websocket.dart';

Future<LiveKitWebSocketIO> lkWebSocketConnect(
  Uri uri, [
  WebSocketEventHandlers? options,
]) =>
    LiveKitWebSocketIO.connect(uri, options);

class LiveKitWebSocketIO extends LiveKitWebSocket {
  final io.WebSocket _ws;
  final WebSocketEventHandlers? options;
  late final StreamSubscription _subscription;

  LiveKitWebSocketIO._(
    this._ws, [
    this.options,
  ]) {
    _subscription = _ws.listen(
      (dynamic data) {
        if (isDisposed) {
          logger.warning('$objectId already disposed, ignoring received data.');
          return;
        }
        options?.onData?.call(data);
      },
      onDone: () async {
        await _subscription.cancel();
        options?.onDispose?.call();
      },
    );

    onDispose(() async {
      if (_ws.readyState != io.WebSocket.closed) {
        await _ws.close();
      }
    });
  }

  @override
  void send(List<int> data) {
    if (_ws.readyState != io.WebSocket.open) {
      logger.fine('[$objectId] Socket not open (state: ${_ws.readyState})');
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
