import 'room.dart';
import 'signal_client.dart';

class LiveKitClient {
  static Future<Room> connect(String url, String token,
      [JoinOptions? options]) {
    final room = Room();
    return room.connect(url, token, options);
  }
}
