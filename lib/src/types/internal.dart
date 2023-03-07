import 'package:meta/meta.dart';

@internal
enum ClientDisconnectReason {
  user,
  peerConnectionClosed,
  negotiationFailed,
  signal,
  reconnect,
  leaveReconnect,
}
