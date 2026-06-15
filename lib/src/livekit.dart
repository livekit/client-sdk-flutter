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

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'audio/audio_manager.dart';
import 'support/native.dart';
import 'support/platform.dart' show lkPlatformIsMobile;

/// Main entry point to connect to a room.
/// {@category Room}
class LiveKitClient {
  static const version = '2.8.0';

  /// Initialize the WebRTC plugin.
  ///
  /// Optional: call once at startup to enable [bypassVoiceProcessing] before
  /// connecting. Otherwise WebRTC initializes lazily with defaults.
  ///
  /// LiveKit owns the platform audio session, and flutter_webrtc's own native
  /// audio management is disabled automatically when the LiveKit plugin loads
  /// (done natively at registration), so that does not depend on this call.
  ///
  /// Configure audio-session behavior through [AudioManager] before connecting,
  /// e.g. `await AudioManager.instance.setAudioSessionManagementMode(...)` and
  /// `await AudioManager.instance.setAudioSessionOptions(...)`.
  static Future<void> initialize({
    bool bypassVoiceProcessing = false,
  }) async {
    if (lkPlatformIsMobile()) {
      Native.bypassVoiceProcessing = bypassVoiceProcessing;
      AudioManager.instance.configureDefaults(
        bypassVoiceProcessing: bypassVoiceProcessing,
      );
      final androidAudioConfiguration = AudioManager.instance.androidAudioConfigurationForInitialize();

      await rtc.WebRTC.initialize(options: {
        if (bypassVoiceProcessing) 'bypassVoiceProcessing': bypassVoiceProcessing,
        if (androidAudioConfiguration != null) 'androidAudioConfiguration': androidAudioConfiguration,
      });
    }
  }
}
