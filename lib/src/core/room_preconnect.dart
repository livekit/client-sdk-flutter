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
      await preConnectAudioBuffer.agentReadyFuture;
      return result;
    } catch (error) {
      await preConnectAudioBuffer.stopRecording(withError: error);
      logger.warning('[Preconnect] operation failed with error: $error');
      rethrow;
    } finally {
      await preConnectAudioBuffer.reset();
    }
  }
}
