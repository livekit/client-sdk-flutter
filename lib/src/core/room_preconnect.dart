// Copyright 2025 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

import '../logger.dart';
import '../preconnect/pre_connect_audio_buffer.dart';
import 'room.dart';

extension RoomPreConnect on Room {
  /// Runs an async [operation] while a pre-connect audio buffer records.
  ///
  /// This is primarily used for voice agent experiences to reduce perceived
  /// latency: the microphone starts recording before [Room.connect] completes,
  /// and the buffered audio is sent to the agent once it becomes active.
  ///
  /// If [operation] throws, recording is stopped and the buffer is reset
  /// (discarding any buffered audio).
  ///
  /// Example:
  /// ```dart
  /// await room.withPreConnectAudio(
  ///   () async {
  ///     final creds = await tokenService.fetch();
  ///     await room.connect(creds.serverUrl, creds.participantToken);
  ///     return true;
  ///   },
  ///   timeout: const Duration(seconds: 20),
  ///   onError: (error) => logger.warning('Preconnect failed: $error'),
  /// );
  /// ```
  ///
  /// - Note: Requires microphone permission. On iOS/macOS the SDK requests it
  ///   when recording starts, but only while the app is active, so call this
  ///   once the app has become active and the system prompt can appear. At app
  ///   launch the app may not be active yet, so when calling this early,
  ///   request permission up front (for example with the permission_handler
  ///   package). Otherwise it throws a [TrackCreateException].
  /// - SeeAlso: [PreConnectAudioBuffer]
  Future<T> withPreConnectAudio<T>(
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 10),
    PreConnectOnError? onError,
  }) async {
    preConnectAudioBuffer.setErrorHandler(onError);
    await preConnectAudioBuffer.startRecording(timeout: timeout);
    try {
      final result = await operation();
      unawaited(() async {
        try {
          await preConnectAudioBuffer.agentReadyFuture;
        } catch (error, stackTrace) {
          logger.warning('[Preconnect] agent readiness wait failed: $error', error, stackTrace);
        } finally {
          await preConnectAudioBuffer.reset();
        }
      }());
      return result;
    } catch (error) {
      await preConnectAudioBuffer.stopRecording(withError: error);
      await preConnectAudioBuffer.reset();
      logger.warning('[Preconnect] operation failed with error: $error');
      rethrow;
    }
  }
}
