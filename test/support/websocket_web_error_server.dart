// Copyright 2026 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Serves one WebSocket that opens and then breaks the protocol, so the browser fails the open connection.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

// [channel] is the StreamChannel that spawnHybridUri passes in.
Future<void> hybridMain(dynamic channel) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  channel.sink.add(server.port);
  server.listen((request) async {
    final key = request.headers.value('sec-websocket-key')!;
    final accept = base64.encode(sha1.convert(utf8.encode('${key}258EAFA5-E914-47DA-95CA-C5AB0DC85B11')).bytes);
    final socket = await request.response.detachSocket(writeHeaders: false);
    socket.add(
      utf8.encode(
        'HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n'
        'Sec-WebSocket-Accept: $accept\r\n\r\n',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // A frame with the reserved bits set is a protocol error.
    socket.add([0xF1, 0x00]);
  });
  channel.stream.listen(null, onDone: () => server.close(force: true));
}
