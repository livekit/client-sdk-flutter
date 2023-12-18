// Copyright 2023 LiveKit, Inc.
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

import '../support/disposable.dart';
import 'websocket/io.dart' if (dart.library.html) 'websocket/web.dart';

class WebSocketException implements Exception {
  final int code;
  const WebSocketException._(this.code);

  static WebSocketException unknown() => const WebSocketException._(0);
  static WebSocketException connect() => const WebSocketException._(1);

  @override
  String toString() => {
        WebSocketException.unknown(): 'Unknown error',
        WebSocketException.connect(): 'Failed to connect',
      }[this]!;
}

typedef WebSocketOnData = Function(dynamic data);
typedef WebSocketOnError = Function(dynamic error);
typedef WebSocketOnDispose = Function();

class WebSocketEventHandlers {
  final WebSocketOnData? onData;
  final WebSocketOnError? onError;
  final WebSocketOnDispose? onDispose;

  const WebSocketEventHandlers({
    this.onData,
    this.onError,
    this.onDispose,
  });
}

typedef WebSocketConnector = Future<LiveKitWebSocket> Function(Uri uri,
    [WebSocketEventHandlers? options]);

abstract class LiveKitWebSocket extends Disposable {
  void send(List<int> data);

  static Future<LiveKitWebSocket> connect(Uri uri,
          [WebSocketEventHandlers? options]) =>
      lkWebSocketConnect(uri, options);
}
