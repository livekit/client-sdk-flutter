// Copyright 2024 LiveKit, Inc.
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

import 'package:livekit_client/src/options.dart';
import 'package:livekit_client/src/support/websocket.dart';

class MockWebSocket extends LiveKitWebSocket {
  MockWebSocket([this.onSend]);

  final void Function(List<int> data)? onSend;

  @override
  void send(List<int> data) => onSend?.call(data);
}

class MockWebSocketConnector {
  WebSocketEventHandlers? handlers;
  Uri? uri;
  Map<String, String>? headers;
  NetworkOptions? networkOptions;
  Object? connectError;

  /// When true, [connectError] is thrown once and then cleared, so the next
  /// connect succeeds. Models a first attempt that fails and a retry that gets
  /// through.
  bool connectErrorOnce = false;

  /// When set, a connect waits for it before it answers. Models a socket
  /// handshake that is still in flight.
  Future<void>? connectGate;

  /// Every message the SDK sent over any socket this connector opened.
  final List<List<int>> sentData = [];

  WebSocketOnData get onData => handlers!.onData!;

  WebSocketOnDispose get onDispose => handlers!.onDispose!;

  WebSocketOnError get onError => handlers!.onError!;

  Future<LiveKitWebSocket> connect(
    Uri uri, {
    WebSocketEventHandlers? options,
    Map<String, String>? headers,
    NetworkOptions? networkOptions = const NetworkOptions(),
  }) async {
    this.uri = uri;
    this.headers = headers;
    this.networkOptions = networkOptions;

    await connectGate;

    final error = connectError;
    if (error != null) {
      if (connectErrorOnce) {
        connectError = null;
      }
      throw error;
    }

    handlers = options;
    return MockWebSocket(sentData.add);
  }
}
