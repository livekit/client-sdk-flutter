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
import 'audio/audio_session.dart';
import 'support/native.dart';
import 'support/platform.dart' show PlatformType, lkPlatformIs, lkPlatformIsMobile;
import 'support/webrtc_initialize_options.dart';

/// Main entry point to connect to a room.
/// {@category Room}
class LiveKitClient {
  static const version = '2.9.0-dev.0';

  /// Initialize the WebRTC plugin.
  ///
  /// Optional: call once at startup to enable [bypassVoiceProcessing] before
  /// connecting, or to apply Android [initialAudioSessionOptions] before WebRTC
  /// creates its audio device module. Otherwise WebRTC initializes lazily with
  /// defaults.
  ///
  /// LiveKit owns the platform audio session, and flutter_webrtc's own native
  /// audio management is disabled automatically when the LiveKit plugin loads
  /// (done natively at registration), so that does not depend on this call.
  ///
  /// Configure explicit runtime audio-session behavior through [AudioManager]
  /// before connecting, e.g.
  /// `await AudioManager.instance.setAudioSessionManagementMode(...)` and
  /// `await AudioManager.instance.setAudioSessionOptions(...)`.
  ///
  /// [initialAudioSessionOptions] currently affects Android's WebRTC
  /// initialization-time playout attributes, such as media vs voice
  /// communication usage. It also seeds [AudioManager]'s initial automatic
  /// runtime session policy until the app explicitly replaces it with
  /// [AudioManager.setAudioSessionOptions]. A future SDK/WebRTC integration may
  /// make those Android playout attributes runtime-updatable; for now, pass them
  /// here before WebRTC initializes.
  static Future<void> initialize({
    bool bypassVoiceProcessing = false,
    AudioSessionOptions? initialAudioSessionOptions,
  }) async {
    if (lkPlatformIsMobile()) {
      // bypassVoiceProcessing controls only WebRTC voice processing. Android
      // playout attributes are passed here because WebRTC reads them when it
      // creates the audio device module.
      Native.bypassVoiceProcessing = bypassVoiceProcessing;
      await rtc.WebRTC.initialize(
        options: liveKitWebRTCInitializeOptions(
          bypassVoiceProcessing: bypassVoiceProcessing,
          initialAudioSessionOptions: initialAudioSessionOptions,
          includeAndroidAudioConfiguration: lkPlatformIs(PlatformType.android),
        ),
      );
      if (lkPlatformIs(PlatformType.android) && initialAudioSessionOptions != null) {
        AudioManager.instance.setInitialAudioSessionOptions(initialAudioSessionOptions);
      }
    }
  }
}
