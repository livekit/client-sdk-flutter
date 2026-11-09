// Copyright 2026 LiveKit, Inc.
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

/// Strategy used to mute microphone input on iOS/macOS.
///
/// Applies to the AVAudioEngine-based audio device module, which is engine-wide
/// (process-global) state. Set via `AudioManager.setMicrophoneMuteMode`.
enum MicrophoneMuteMode {
  /// Mute using Voice Processing I/O's input mute.
  ///
  /// Fast, and the OS keeps observing the input so muted-talker detection
  /// remains possible, but the platform plays its mute/unmute sound effect.
  voiceProcessing,

  /// Mute by restarting the audio engine without microphone input.
  ///
  /// Slower, but silent and stops microphone input entirely while muted.
  restart,

  /// Mute by muting the engine's input mixer node.
  ///
  /// Fast and silent; the engine and audio session keep running.
  inputMixer,

  /// The mode could not be determined (e.g. unsupported platform).
  unknown,
}
