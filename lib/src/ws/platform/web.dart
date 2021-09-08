import 'dart:async';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import '../interface.dart';

Future<LKWebSocketWeb> lkWebSocketConnect(
  Uri uri, [
  LKWebSocketOptions? options,
]) =>
    LKWebSocketWeb.connect(uri, options);

class LKWebSocketWeb implements LKWebSocket {
  final html.WebSocket _ws;
  final LKWebSocketOptions? options;
  late final StreamSubscription _messageSubscription;
  late final StreamSubscription _closeSubscription;

  LKWebSocketWeb._(
    this._ws, [
    this.options,
  ]) {
    _ws.binaryType = 'arraybuffer';
    _messageSubscription = _ws.onMessage.listen((_) {
      dynamic _data = _.data is ByteBuffer ? _.data.asUint8List() : _.data;
      options?.onData?.call(_data);
    });
    _closeSubscription = _ws.onClose.listen((_) => dispose());
  }

  @override
  void send(List<int> data) => _ws.send(data);

  @override
  void dispose() {
    options?.onDispose?.call();
    _messageSubscription.cancel();
    _closeSubscription.cancel();
    _ws.close();
  }

  static Future<LKWebSocketWeb> connect(
    Uri uri, [
    LKWebSocketOptions? options,
  ]) async {
    final completer = Completer<LKWebSocketWeb>();
    final ws = html.WebSocket(uri.toString());
    ws.onOpen.listen((_) => completer.complete(LKWebSocketWeb._(ws, options)));
    ws.onError.listen((_) => completer.completeError(LKWebSocketError.connect()));
    return completer.future;
  }
}
