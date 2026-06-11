// Copyright 2024 LiveKit, Inc.
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

import '../support/native.dart';
import 'audio_processing_state.dart';

/// Controls LiveKit's process-wide platform audio behavior.
///
/// The platform audio engine and its audio processing module are global to the
/// app process, so engine-scoped audio state lives here rather than on a `Room`
/// or an individual track.
class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  /// Diagnostic snapshot of the resolved audio processing state.
  ///
  /// The audio processing module is owned by the native peer connection factory
  /// and shared engine-wide, so this reflects what is actually applied across
  /// the engine rather than any single track — use it to verify what a
  /// `LocalAudioTrack.setAudioProcessingOptions` request resolved to. Returns
  /// `null` when the native side cannot provide it.
  Future<AudioProcessingState?> getAudioProcessingState() async {
    final response = await Native.getAudioProcessingState();
    if (response == null) return null;
    return AudioProcessingState.fromMap(response);
  }
}
