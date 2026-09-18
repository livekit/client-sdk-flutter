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
  @override
  void send(List<int> data) {}
}

class MockWebSocketConnector {
  WebSocketEventHandlers? handlers;
  MockWebSocket? socket;
  Uri? uri;
  Map<String, String>? headers;
  NetworkOptions? networkOptions;
  Object? connectError;

  /// When true, [connectError] is thrown once and then cleared, so the next
  /// connect succeeds. Models a first attempt that fails and a retry that gets
  /// through.
  bool connectErrorOnce = false;

  /// Per-attempt failure. Takes precedence over [connectError] when it returns non-null.
  Object? Function(Uri uri)? connectErrorFor;

  /// Delivers data as the server would. A socket the SDK has disposed drops
  /// it, matching the real socket implementations.
  WebSocketOnData get onData => (dynamic data) {
    if (socket?.isDisposed ?? true) return;
    handlers!.onData!(data);
  };

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

    final error = connectErrorFor?.call(uri) ?? connectError;
    if (error != null) {
      if (connectErrorOnce) {
        connectError = null;
      }
      throw error;
    }

    handlers = options;
    return socket = MockWebSocket();
  }
}
