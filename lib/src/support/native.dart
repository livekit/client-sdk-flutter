import 'package:flutter/services.dart';

import 'package:meta/meta.dart';

import '../logger.dart';
import 'native_audio.dart';

// Method channel methods to call native code.
class Native {
  @internal
  static const channel = MethodChannel('livekit_client');

  @internal
  static Future<bool> configureAudio(
      NativeAudioConfiguration configuration) async {
    try {
      final result = await channel.invokeMethod<bool>(
        'configureNativeAudio',
        configuration.toMap(),
      );
      return result == true;
    } catch (error) {
      logger.warning('configureNativeAudio did throw $error');
      return false;
    }
  }

  /// Returns OS's version as a string
  /// Currently only for iOS, macOS
  @internal
  static Future<String?> osVersionString() async {
    try {
      return await channel.invokeMethod<String>(
        'osVersionString',
        <String, dynamic>{},
      );
    } catch (error) {
      logger.warning('appleOSVersionString did throw error: ${error}');
    }
    return null;
  }
}
