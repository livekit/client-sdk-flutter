import 'dart:async';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import '../websocket.dart';

Future<LiveKitWebSocketWeb> lkWebSocketConnect(
  Uri uri, [
  WebSocketEventHandlers? options,
]) =>
    LiveKitWebSocketWeb.connect(uri, options);

class LiveKitWebSocketWeb implements LiveKitWebSocket {
  final html.WebSocket _ws;
  final WebSocketEventHandlers? options;
  late final StreamSubscription _messageSubscription;
  late final StreamSubscription _closeSubscription;

  LiveKitWebSocketWeb._(
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
  Future<void> dispose() async {
    options?.onDispose?.call();
    await _messageSubscription.cancel();
    await _closeSubscription.cancel();
    _ws.close();
  }

  static Future<LiveKitWebSocketWeb> connect(
    Uri uri, [
    WebSocketEventHandlers? options,
  ]) async {
    final completer = Completer<LiveKitWebSocketWeb>();
    final ws = html.WebSocket(uri.toString());
    ws.onOpen.listen((_) => completer.complete(LiveKitWebSocketWeb._(ws, options)));
    ws.onError.listen((_) => completer.completeError(WebSocketException.connect()));
    return completer.future;
  }
}
