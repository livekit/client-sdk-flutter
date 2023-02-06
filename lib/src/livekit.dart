import 'core/room.dart';
import 'options.dart';
import 'types/other.dart';

/// Main entry point to connect to a room.
/// {@category Room}
class LiveKitClient {
  static const version = '1.1.9';

  /// Convenience method for connecting to a LiveKit server.
  /// Returns a [Room] upon a successful connect or throws when it fails.
  /// Alternatively, it is possible to instantiate [Room] and call [Room.connect] directly.
  @Deprecated(
      'Use `Room.connect` instead, This method is deprecated above Protocol v8.')
  static Future<Room> connect(
    String url,
    String token, {
    ConnectOptions? connectOptions,
    RoomOptions? roomOptions,
  }) async {
    final room = Room();
    ConnectOptions copyOptions = ConnectOptions(
      autoSubscribe:
          connectOptions != null ? connectOptions.autoSubscribe : true,
      rtcConfiguration: connectOptions != null
          ? connectOptions.rtcConfiguration
          : const RTCConfiguration(),
      protocolVersion: ProtocolVersion.v7,
    );
    try {
      await room.connect(
        url,
        token,
        connectOptions: copyOptions,
        roomOptions: roomOptions,
      );
      return room;
    } catch (error) {
      await room.dispose();
      rethrow;
    }
  }
}
