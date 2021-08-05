import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<WebSocketChannel> connectToWebSocket(Uri uri) {
  var ws = WebSocket(uri.toString());
  ws.binaryType = 'arraybuffer';
  var completer = Completer<WebSocketChannel>();
  ws.onOpen.first.then((_) {
    completer.complete(HtmlWebSocketChannel(ws));
  });
  ws.onError.first.then((e) {
    completer.completeError('could not connect');
  });
  return completer.future;
}
