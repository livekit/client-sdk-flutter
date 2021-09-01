// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:web_socket_channel/html.dart';

import 'imports.dart';

Future<WebSocketChannel> connectToWebSocket(Uri uri) {
  final ws = html.WebSocket(uri.toString());
  ws.binaryType = 'arraybuffer';
  final completer = Completer<WebSocketChannel>();
  ws.onOpen.first.then((_) {
    completer.complete(HtmlWebSocketChannel(ws));
  });
  ws.onError.first.then((e) {
    completer.completeError('could not connect');
  });
  return completer.future;
}
