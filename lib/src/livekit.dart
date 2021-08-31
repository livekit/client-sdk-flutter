import 'room.dart';
import 'options.dart';

/// Main entry point to connect to a room.
/// {@category Room}
class LiveKitClient {
  /// Connects to a LiveKit room
  static Future<Room> connect(String url, String token,
      [JoinOptions? options]) {
    final room = Room();
    return room.connect(url, token, options);
  }
}
