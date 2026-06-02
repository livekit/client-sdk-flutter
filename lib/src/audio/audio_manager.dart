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

import 'package:meta/meta.dart';

import '../logger.dart';
import '../support/native.dart';
import '../support/native_audio.dart';
import '../support/platform.dart';
import 'android_audio_session_adapter.dart';
import 'audio_processing_state.dart';
import 'audio_session.dart';

/// Controls LiveKit's process-wide platform audio behavior.
///
/// Platform audio sessions and the audio processing module are global to the
/// app process, so session options and engine-scoped audio state live here
/// rather than on a `Room` or an individual track.
class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  AudioSessionOptions _defaultOptions = const AudioSessionOptions.communication();
  AudioSessionOptions _options = const AudioSessionOptions.communication();
  AudioSessionManagementMode _managementMode = AudioSessionManagementMode.automatic;
  bool _hasLocalAudio = false;
  bool _hasRemoteAudio = false;
  bool _hasExplicitRuntimeOptions = false;
  bool _preferSpeakerOutput = true;
  bool _forceSpeakerOutput = false;

  AudioSessionOptions get defaultOptions => _defaultOptions;
  AudioSessionOptions get options => _options;
  AudioSessionManagementMode get managementMode => _managementMode;

  /// Whether the speakerphone is the preferred audio output.
  bool get speakerphoneOn => _preferSpeakerOutput;
  bool get preferSpeakerOutput => _preferSpeakerOutput;

  /// Whether speaker output is forced even when a headset/Bluetooth device is
  /// connected (iOS only).
  bool get forceSpeakerOutput => _forceSpeakerOutput && _preferSpeakerOutput;

  /// Whether the platform supports switching the speakerphone (iOS/Android).
  bool get canSwitchSpeakerphone => lkPlatformIsMobile();

  // Derived from [managementMode]; kept internal so the public surface exposes
  // a single way to read the mode.
  @internal
  bool get isAutomaticConfigurationEnabled => _managementMode == AudioSessionManagementMode.automatic;

  @internal
  void configureDefaults({
    required bool bypassVoiceProcessing,
  }) {
    _defaultOptions =
        bypassVoiceProcessing ? const AudioSessionOptions.media() : const AudioSessionOptions.communication();
    _options = _defaultOptions;
    _hasExplicitRuntimeOptions = false;
  }

  @internal
  void updateAudioTrackState({
    required bool hasLocalAudio,
    required bool hasRemoteAudio,
  }) {
    _hasLocalAudio = hasLocalAudio;
    _hasRemoteAudio = hasRemoteAudio;
  }

  /// Applies a new audio session configuration immediately.
  ///
  /// Use [AudioSessionOptions.communication] to enter VoIP/call mode and
  /// [AudioSessionOptions.media] to leave communication mode for
  /// media/live-streaming capture. This explicit apply path works in both
  /// automatic and manual management modes.
  Future<void> setAudioSessionOptions(AudioSessionOptions options) async {
    _hasExplicitRuntimeOptions = true;
    _options = options;
    await applyCurrentAudioSessionOptions();
  }

  /// Selects whether LiveKit manages the platform audio session automatically.
  ///
  /// In [AudioSessionManagementMode.manual], LiveKit does not update the audio
  /// session from room, connect, or track lifecycle. The app can still apply a
  /// configuration explicitly with [setAudioSessionOptions].
  ///
  /// Prefer choosing the mode via `LiveKitClient.initialize`. flutter_webrtc's
  /// own native audio management is always disabled (LiveKit owns the session);
  /// changing the mode at runtime only affects LiveKit's own automatic
  /// configuration.
  void setAudioSessionManagementMode(AudioSessionManagementMode mode) {
    _managementMode = mode;
  }

  /// Routes audio output to/from the speakerphone.
  ///
  /// By default a connected wired/Bluetooth headset still takes priority even
  /// when [enable] is true. Set [forceSpeakerOutput] to force the speaker even
  /// when a headset is connected (iOS only).
  ///
  /// LiveKit owns this routing on both platforms — Android via its own
  /// audioswitch handler and iOS via its audio session — so it does not depend
  /// on flutter_webrtc.
  Future<void> setSpeakerphoneOn(bool enable, {bool forceSpeakerOutput = false}) async {
    if (!canSwitchSpeakerphone) {
      logger.warning('setSpeakerphoneOn is only supported on iOS/Android');
      return;
    }
    _preferSpeakerOutput = enable;
    _forceSpeakerOutput = forceSpeakerOutput;

    if (lkPlatformIs(PlatformType.iOS)) {
      if (isAutomaticConfigurationEnabled) {
        var config = _resolveAppleConfiguration(_options);
        if (_preferSpeakerOutput && _forceSpeakerOutput) {
          config = config.copyWith(
            appleAudioCategoryOptions: {
              ...?config.appleAudioCategoryOptions,
              AppleAudioCategoryOption.defaultToSpeaker,
            },
          );
        }
        await Native.configureAudio(config);
      } else {
        // Manual mode: route without re-applying category/mode the app owns.
        await Native.setAppleSpeakerphoneOn(enable);
      }
    } else if (lkPlatformIs(PlatformType.android)) {
      await Native.setAndroidSpeakerphoneOn(enable);
    }
  }

  /// Re-applies the current audio session options.
  ///
  /// This is useful after platform interruptions or app lifecycle changes when
  /// the app wants LiveKit to restore its currently selected session mode.
  Future<void> applyCurrentAudioSessionOptions() async {
    if (lkPlatformIs(PlatformType.iOS)) {
      await _configureAppleAudioSession(_options);
    } else if (lkPlatformIs(PlatformType.android)) {
      await _configureAndroidAudioSession(_options);
    }
  }

  @internal
  Map<String, dynamic>? androidAudioConfigurationForInitialize() {
    if (!lkPlatformIs(PlatformType.android)) {
      return null;
    }

    // Preserve today's implicit initialize behavior; only send Android audio
    // attributes when the bypassVoiceProcessing path needs media attributes.
    if (!isAutomaticConfigurationEnabled || !Native.bypassVoiceProcessing) {
      return null;
    }

    return androidAudioSessionConfigurationToMap(_resolveAndroidConfiguration(_defaultOptions));
  }

  @internal
  Future<void> applyOptionsForConnect() async {
    if (isAutomaticConfigurationEnabled) {
      await applyCurrentAudioSessionOptions();
    }
  }

  @internal
  bool get shouldUseLegacyAutomaticAppleConfiguration =>
      isAutomaticConfigurationEnabled &&
      !_hasExplicitRuntimeOptions &&
      _options.isCommunication &&
      _options.preferSpeakerOutput &&
      _options.apple == null;

  @internal
  NativeAudioConfiguration automaticAppleAudioConfiguration() => _resolveAppleConfiguration(_options);

  Future<void> _configureAppleAudioSession(AudioSessionOptions options) async {
    final config = _resolveAppleConfiguration(options);
    logger.fine('configuring Apple audio session using $config...');
    await Native.configureAudio(config);
  }

  Future<void> _configureAndroidAudioSession(AudioSessionOptions options) async {
    final config = _resolveAndroidConfiguration(options);
    logger.fine('configuring Android audio session using ${androidAudioSessionConfigurationToMap(config)}...');
    await setAndroidAudioSessionConfiguration(config);
  }

  NativeAudioConfiguration _resolveAppleConfiguration(AudioSessionOptions options) {
    final apple = options.apple;
    if (apple != null) {
      return NativeAudioConfiguration(
        appleAudioCategory: apple.category,
        appleAudioCategoryOptions: apple.categoryOptions,
        appleAudioMode: apple.mode,
        preferSpeakerOutput: apple.preferSpeakerOutput,
      );
    }

    if (options.isCommunication) {
      return NativeAudioConfiguration(
        appleAudioCategory: AppleAudioCategory.playAndRecord,
        appleAudioCategoryOptions: {
          AppleAudioCategoryOption.allowBluetooth,
          AppleAudioCategoryOption.allowBluetoothA2DP,
          AppleAudioCategoryOption.allowAirPlay,
        },
        appleAudioMode: options.preferSpeakerOutput ? AppleAudioMode.videoChat : AppleAudioMode.voiceChat,
        preferSpeakerOutput: options.preferSpeakerOutput,
      );
    }

    if (isAutomaticConfigurationEnabled && !_hasLocalAudio) {
      return _hasRemoteAudio ? NativeAudioConfiguration.playback : NativeAudioConfiguration.soloAmbient;
    }
    return NativeAudioConfiguration(
      appleAudioCategory: AppleAudioCategory.playAndRecord,
      appleAudioCategoryOptions: {
        AppleAudioCategoryOption.mixWithOthers,
        AppleAudioCategoryOption.allowBluetooth,
        AppleAudioCategoryOption.allowBluetoothA2DP,
        AppleAudioCategoryOption.allowAirPlay,
      },
      appleAudioMode: AppleAudioMode.default_,
      preferSpeakerOutput: true,
    );
  }

  AndroidAudioSessionConfiguration _resolveAndroidConfiguration(AudioSessionOptions options) {
    final android = options.android;
    if (android != null) {
      return android;
    }

    if (options.isCommunication) {
      return AndroidAudioSessionConfiguration.communication;
    }
    return AndroidAudioSessionConfiguration.media;
  }

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
