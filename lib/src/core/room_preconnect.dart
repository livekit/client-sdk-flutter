import 'dart:async';

import '../logger.dart';
import '../preconnect/pre_connect_audio_buffer.dart';
import 'room.dart';

extension RoomPreConnect on Room {
  /// Wrap an async operation while a pre-connect audio buffer records.
  /// Stops and flushes on error.
  Future<T> withPreConnectAudio<T>(
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 10),
    PreConnectOnError? onError,
  }) async {
    await preConnectAudioBuffer.startRecording(timeout: timeout);
    try {
      final result = await operation();
      return result;
    } catch (error) {
      logger.warning('[Preconnect] operation failed with error: $error');
      rethrow;
    } finally {
      await preConnectAudioBuffer.reset();
    }
  }
}
