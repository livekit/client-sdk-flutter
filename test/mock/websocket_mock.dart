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

import 'dart:async';

import 'package:livekit_client/src/options.dart';
import 'package:livekit_client/src/support/websocket.dart';

class MockWebSocket extends LiveKitWebSocket {
  /// Like the real sockets, the close is reported to the SDK after dispose()
  /// has returned, see [MockWebSocketConnector.closeLatency] and
  /// [MockWebSocketConnector.holdCloses].
  MockWebSocket(this._connector, this.handlers) {
    onDispose(() async {
      final connector = _connector;
      if (connector.disposeLatency > Duration.zero) await Future<void>.delayed(connector.disposeLatency);
      await connector.disposeGate;
      void reportClose() => handlers?.onDispose?.call();
      if (connector.holdCloses) {
        connector._heldCloses.add(reportClose);
      } else {
        unawaited(Future<void>.delayed(connector.closeLatency, reportClose));
      }
    });
  }

  final MockWebSocketConnector _connector;

  /// The callbacks the SDK gave this socket.
  final WebSocketEventHandlers? handlers;

  /// Every message the SDK sent over this socket.
  final List<List<int>> sent = [];

  @override
  void send(List<int> data) {
    sent.add(data);
    _connector.sentData.add(data);
  }
}

class MockWebSocketConnector {
  WebSocketEventHandlers? handlers;
  Uri? uri;
  Map<String, String>? headers;
  NetworkOptions? networkOptions;
  Object? connectError;

  /// Delay between the SDK disposing a socket and that socket reporting its close.
  Duration closeLatency = Duration.zero;

  /// How long dispose() takes, like a dart:io close that waits on the server.
  Duration disposeLatency = Duration.zero;

  /// When set, dispose() waits for it, so a test decides when a close finishes.
  Future<void>? disposeGate;

  /// While true, the closes of disposed sockets are held until [releaseCloses],
  /// so a test decides exactly when an old socket reports its close.
  bool holdCloses = false;
  final _heldCloses = <void Function()>[];

  /// Reports every close held by [holdCloses].
  void releaseCloses() {
    final held = [..._heldCloses];
    _heldCloses.clear();
    for (final reportClose in held) {
      reportClose();
    }
  }

  /// Every socket this connector opened, oldest first.
  final List<MockWebSocket> sockets = [];

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
    final socket = MockWebSocket(this, options);
    sockets.add(socket);
    return socket;
  }
}
