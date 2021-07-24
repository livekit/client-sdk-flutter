import 'room.dart';

class LiveKitClient {
  // TODO: take in connect options
  static Future<Room> connect(String url, String token) {
    var room = Room();
    return room.connect(url, token);
  }
}
