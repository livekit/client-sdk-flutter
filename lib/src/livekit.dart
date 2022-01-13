import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import 'core/room.dart';
import 'options.dart';

/// Main entry point to connect to a room.
/// {@category Room}
class LiveKitClient {
  static const version = '0.5.6';

  @internal
  static const channel = MethodChannel('livekit_client');

  /// Convenience method for connecting to a LiveKit server.
  /// Returns a [Room] upon a successful connect or throws when it fails.
  /// Alternatively, it is possible to instantiate [Room] and call [Room.connect] directly.
  static Future<Room> connect(
    String url,
    String token, {
    ConnectOptions? connectOptions,
    RoomOptions? roomOptions,
  }) async {
    final room = Room();
    try {
      await room.connect(
        url,
        token,
        connectOptions: connectOptions,
        roomOptions: roomOptions,
      );
      return room;
    } catch (error) {
      await room.dispose();
      rethrow;
    }
  }
}
