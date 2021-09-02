import 'dart:async';
import 'dart:io' as io;

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<WebSocketChannel> connectToWebSocket(Uri uri) async {
  try {
    // ignore: close_sinks
    final ws = await io.WebSocket.connect(uri.toString());
    return IOWebSocketChannel(ws);
  } catch (e) {
    return Future.error(e);
  }
}
