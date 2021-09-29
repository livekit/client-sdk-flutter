import 'package:flutter/services.dart';

import 'logger.dart';
import 'options.dart';
import 'room.dart';
import 'support/native_audio.dart';

/// Main entry point to connect to a room.
/// {@category Room}
class LiveKitClient {
  static const version = '0.4.0';
  static const _channel = MethodChannel('livekit_client');

  /// Connects to a LiveKit room
  static Future<Room> connect(
    String url,
    String token, {
    ConnectOptions? options,
  }) =>
      Room.connect(
        url,
        token,
        options: options,
      );

  static Future<bool> configureAudioSession(NativeAudioConfiguration configuration) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'configureAudioSession',
        configuration.toMap(),
      );
      return result == true;
    } catch (_) {
      logger.warning('configureAudioSession did throw $_');
      return false;
    }
  }
}
