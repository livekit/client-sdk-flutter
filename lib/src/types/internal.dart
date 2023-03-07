import 'package:meta/meta.dart';

@internal
enum InternalDisconnectReason {
  user,
  peerConnectionClosed,
  negotiationFailed,
  signal,
  reconnect,
  leaveReconnect,
}
