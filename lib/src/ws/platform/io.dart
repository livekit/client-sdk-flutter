import 'dart:async';
import 'dart:io' as io;

import 'package:livekit_client/src/logger.dart';

import '../interface.dart';

Future<LKWebSocketIO> lkWebSocketConnect(
  Uri uri, [
  LKWebSocketOptions? options,
]) =>
    LKWebSocketIO.connect(uri, options);

class LKWebSocketIO implements LKWebSocket {
  final io.WebSocket _ws;
  final LKWebSocketOptions? options;
  late final StreamSubscription _subscription;

  LKWebSocketIO._(
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
  void send(List<int> data) => _ws.add(data);

  static Future<LKWebSocketIO> connect(
    Uri uri, [
    LKWebSocketOptions? options,
  ]) async {
    logger.info('LKWebSocketIO connect (uri: ${uri.toString()})');
    try {
      final ws = await io.WebSocket.connect(uri.toString());
      logger.fine('LKWebSocketIO connected');
      return LKWebSocketIO._(ws, options);
    } catch (_) {
      logger.severe('LKWebSocketIO error ${_}');
      throw LKWebSocketError.connect();
    }
  }
}
