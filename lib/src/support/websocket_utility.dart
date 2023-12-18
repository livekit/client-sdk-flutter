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

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../logger.dart';
import 'websocket.dart';

enum SocketStatus {
  kSocketStatusNone,
  kSocketStatusConnecting,
  kSocketStatusConnected,
  kSocketStatusReconnecting,
  kSocketStatusFailed,
  kSocketStatusClosed,
}

const maxRetryDelay = 7000;

const defaultRetryDelaysInMs = [
  0,
  300,
  2 * 2 * 300,
  3 * 3 * 300,
  4 * 4 * 300,
  maxRetryDelay,
  maxRetryDelay,
  maxRetryDelay,
  maxRetryDelay,
  maxRetryDelay,
];

class WebSocketUtility {
  WebSocketUtility(this._wsConnector);
  LiveKitWebSocket? _webSocket;
  final WebSocketConnector _wsConnector;
  SocketStatus _socketStatus = SocketStatus.kSocketStatusNone;
  final int _reconnectCount = defaultRetryDelaysInMs.length;
  int _reconnectTimes = 0;
  Function? onError;
  Function? onMessage;
  Function? onClose;
  Function? onSocketStatusChange;
  late Uri _url;
  Uri? _reconnectUrl;
  SocketStatus get socketStatus => _socketStatus;
  bool _isClosed = false;
  ConnectivityResult _connectivity = ConnectivityResult.none;
  StreamSubscription<dynamic>? _connectivitySubscription;

  Future<void> initWebSocket(
      {Function? onMessage,
      Function? onError,
      Function? onClose,
      Function? onSocketStatusChange}) async {
    this.onMessage = onMessage;
    this.onError = onError;
    this.onClose = onClose;
    this.onSocketStatusChange = onSocketStatusChange;

    _isClosed = false;
    _socketStatus = SocketStatus.kSocketStatusNone;
    onSocketStatusChange?.call(_socketStatus);

    if (_connectivitySubscription != null) {
      await _connectivitySubscription?.cancel();
      _connectivitySubscription = null;
    }

    _connectivity = await Connectivity().checkConnectivity();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      logger.fine('network changed ${result.name}, reconnecting...');
      if ((result != ConnectivityResult.none && _connectivity != result) &&
          !_isClosed) {
        if (_socketStatus != SocketStatus.kSocketStatusNone) {
          reconnect();
        }
      }
      _connectivity = result;
    });
  }

  void setReconnSid(String sid) {
    try {
      var queryParameters = Map<String, String>.from(_url.queryParameters);
      queryParameters['sid'] = sid;
      queryParameters['reconnect'] = '1';
      _reconnectUrl = _url.replace(queryParameters: queryParameters);
    } catch (e) {
      logger.warning(e);
    }
  }

  void _changeSocketStatus(SocketStatus status) {
    _socketStatus = status;
    onSocketStatusChange?.call(_socketStatus);
  }

  Future<void> openSocket(Uri url, {Duration? connectTimeout}) async {
    _url = url;
    if (_socketStatus == SocketStatus.kSocketStatusConnecting ||
        _socketStatus == SocketStatus.kSocketStatusConnected) {
      return;
    }
    _cleanUp();
    _changeSocketStatus(SocketStatus.kSocketStatusConnecting);

    try {
      var future = _wsConnector.call(
        url,
        WebSocketEventHandlers(
          onData: webSocketOnMessage,
          onDispose: webSocketOnDone,
          onError: webSocketOnError,
        ),
      );
      if (connectTimeout != null) {
        future = future.timeout(connectTimeout);
      }
      _webSocket = await future;
    } catch (e) {
      if (!_isClosed && !await reconnect()) {
        logger.warning(e);
      }
      logger.warning('WebSocket failed to connect to $url, retrying...');
      return;
    }
    _reconnectTimes = 0;
    logger.fine('WebSocket successfully connected to $url');
    _changeSocketStatus(SocketStatus.kSocketStatusConnected);
  }

  webSocketOnMessage(data) {
    onMessage?.call(data);
  }

  webSocketOnDone() {
    logger.fine('closed');
    if (_socketStatus == SocketStatus.kSocketStatusConnected) {
      _webSocket?.dispose();
      _webSocket = null;
      _changeSocketStatus(SocketStatus.kSocketStatusClosed);
      onClose?.call();
    }
    if (!_isClosed) {
      reconnect();
    }
  }

  webSocketOnError(e) {
    WebSocketException ex = e;
    onError?.call(ex);
  }

  void _cleanUp() {
    if (_webSocket != null) {
      logger.fine('WebSocket closed');
      _webSocket?.dispose();
      _webSocket = null;
    }
    _socketStatus = SocketStatus.kSocketStatusNone;
  }

  void closeSocket() {
    if (_socketStatus == SocketStatus.kSocketStatusConnected) {
      _changeSocketStatus(SocketStatus.kSocketStatusClosed);
      onClose?.call();
    }
    _reconnectTimes = 0;
    _isClosed = true;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _cleanUp();
  }

  void sendMessage(message) {
    if (_socketStatus != SocketStatus.kSocketStatusConnected) {
      logger.warning('WebSocket not connected');
      return;
    }
    _webSocket?.send(message);
  }

  Future<bool> reconnect() async {
    if (_reconnectUrl == null) {
      logger.warning('WebSocket reconnect failed, no reconnect url');
      return false;
    }
    if (_reconnectTimes < _reconnectCount) {
      if (_socketStatus != SocketStatus.kSocketStatusReconnecting) {
        _changeSocketStatus(SocketStatus.kSocketStatusReconnecting);
      }
      var delay = defaultRetryDelaysInMs[_reconnectTimes];
      logger.fine(
          'WebSocket reconnecting in $delay ms, retry times $_reconnectTimes');
      _reconnectTimes++;
      Future.delayed(Duration(milliseconds: delay), () async {
        await openSocket(_reconnectUrl!,
            connectTimeout: const Duration(milliseconds: 1000));
      });
      return true;
    } else {
      logger
          .warning('WebSocket reconnect failed, retry times $_reconnectTimes');
      _socketStatus = SocketStatus.kSocketStatusFailed;
      onSocketStatusChange?.call(_socketStatus);
      return false;
    }
  }
}
