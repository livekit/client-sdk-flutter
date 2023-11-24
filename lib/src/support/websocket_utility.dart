import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../logger.dart';

enum SocketStatus {
  kSocketStatusNone,
  kSocketStatusConnecting,
  kSocketStatusConnected,
  kSocketStatusReconnecting,
  kSocketStatusFailed,
  kSocketStatusClosed,
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
  WebSocketUtility();
  WebSocketChannel? _webSocket;
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
  StreamSubscription<dynamic>? _streamSubscription;
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
    WebSocketChannel? channel;
    try {
      channel = WebSocketChannel.connect(url);
      var future = channel.ready;
      if (connectTimeout != null) {
        future = future.timeout(connectTimeout);
      }
      await future;
    } catch (e) {
      if (!_isClosed && !await reconnect()) {
        logger.warning(e);
      }
      logger.warning('WebSocket failed to connect to $url, retrying...');
      return;
    }
    _reconnectTimes = 0;
    _streamSubscription = channel.stream.listen(
        (data) => webSocketOnMessage(data),
        onError: webSocketOnError,
        onDone: webSocketOnDone);

    logger.fine('WebSocket successfully connected to $url');
    _changeSocketStatus(SocketStatus.kSocketStatusConnected);
    _webSocket = channel;
  }

  webSocketOnMessage(data) {
    onMessage?.call(data);
  }

  webSocketOnDone() {
    logger.fine('closed');
    if (_socketStatus == SocketStatus.kSocketStatusConnected) {
      _streamSubscription?.cancel();
      _streamSubscription = null;
      _webSocket?.sink.close();
      _webSocket = null;
      _changeSocketStatus(SocketStatus.kSocketStatusClosed);
      onClose?.call();
    }
    if (!_isClosed) {
      reconnect();
    }
  }

  webSocketOnError(e) {
    WebSocketChannelException ex = e;
    onError?.call(ex.message);
  }

  void _cleanUp() {
    if (_webSocket != null) {
      logger.fine('WebSocket closed');
      _streamSubscription?.cancel();
      _streamSubscription = null;
      _webSocket?.sink.close();
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
    _webSocket?.sink.add(message);
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
