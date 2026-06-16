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

import 'dart:async';

import 'package:meta/meta.dart';

import '../logger.dart';
import '../support/native.dart';
import '../support/native_audio.dart';
import '../support/platform.dart';
import 'android_audio_session_adapter.dart';
import 'audio_processing_state.dart';
import 'audio_session.dart';

/// Snapshot of the WebRTC audio engine's playout/recording state.
///
/// Surfaced by [AudioManager] from real audio-engine lifecycle events on the
/// native side (iOS and macOS). This is the source of truth for audio activity,
/// replacing the legacy track-counting state.
class AudioEngineState {
  /// Whether the engine has playout (output / remote audio) enabled.
  final bool isPlayoutEnabled;

  /// Whether the engine has recording (input / local mic) enabled.
  final bool isRecordingEnabled;

  const AudioEngineState({
    required this.isPlayoutEnabled,
    required this.isRecordingEnabled,
  });

  /// Whether the engine is neither playing out nor recording.
  bool get isIdle => !isPlayoutEnabled && !isRecordingEnabled;

  @override
  bool operator ==(Object other) =>
      other is AudioEngineState &&
      other.isPlayoutEnabled == isPlayoutEnabled &&
      other.isRecordingEnabled == isRecordingEnabled;

  @override
  int get hashCode => Object.hash(isPlayoutEnabled, isRecordingEnabled);

  @override
  String toString() => 'AudioEngineState(isPlayoutEnabled: $isPlayoutEnabled, isRecordingEnabled: $isRecordingEnabled)';
}

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
  bool _hasExplicitRuntimeOptions = false;
  bool _preferSpeakerOutput = true;
  bool _forceSpeakerOutput = false;
  bool _isPlayoutEnabled = false;
  bool _isRecordingEnabled = false;
  final StreamController<AudioEngineState> _audioEngineStateController = StreamController<AudioEngineState>.broadcast();

  AudioSessionOptions get defaultOptions => _defaultOptions;
  AudioSessionOptions get options => _options;
  AudioSessionManagementMode get managementMode => _managementMode;

  /// Whether the speaker is the preferred audio output.
  bool get isSpeakerOutputPreferred => _preferSpeakerOutput;

  /// Whether speaker output is forced even when a headset/Bluetooth device is
  /// connected.
  bool get isSpeakerOutputForced => _forceSpeakerOutput && _preferSpeakerOutput;

  /// Whether the platform supports switching the speaker output (iOS/Android).
  bool get canSwitchSpeakerphone => lkPlatformIsMobile();

  /// The current audio engine state, derived from native engine lifecycle
  /// events (iOS/macOS). On platforms without engine events this stays idle.
  AudioEngineState get audioEngineState =>
      AudioEngineState(isPlayoutEnabled: _isPlayoutEnabled, isRecordingEnabled: _isRecordingEnabled);

  /// A broadcast stream of audio engine state changes (native engine lifecycle).
  Stream<AudioEngineState> get audioEngineStateStream => _audioEngineStateController.stream;

  // Derived from [managementMode]. Kept internal so the public surface exposes
  // a single way to read the mode.
  @internal
  bool get isAutomaticConfigurationEnabled => _managementMode == AudioSessionManagementMode.automatic;

  @visibleForTesting
  void resetForTest() {
    _defaultOptions = const AudioSessionOptions.communication();
    _options = const AudioSessionOptions.communication();
    _managementMode = AudioSessionManagementMode.automatic;
    _hasExplicitRuntimeOptions = false;
    _preferSpeakerOutput = true;
    _forceSpeakerOutput = false;
    _isPlayoutEnabled = false;
    _isRecordingEnabled = false;
  }

  @internal
  void configureDefaults({
    required bool bypassVoiceProcessing,
  }) {
    _defaultOptions =
        bypassVoiceProcessing ? const AudioSessionOptions.media() : const AudioSessionOptions.communication();
    if (!_hasExplicitRuntimeOptions) {
      _options = _defaultOptions;
    }
  }

  /// Invoked from native when the WebRTC audio engine's playout/recording state
  /// changes. Audio-engine lifecycle events are the single source of truth for
  /// audio activity. This replaces the legacy track-counting path, which had
  /// timing races and could miss session deactivation.
  ///
  /// On iOS the native engine delegate also owns audio-session activation
  /// timing (configure + activate on enable, deactivate on disable). This Dart
  /// hop is non-blocking and only keeps the observable state in sync. macOS
  /// emits the same events (no `AVAudioSession` to configure) so engine state
  /// stays authoritative there too.
  @internal
  void handleAudioEngineState({
    required bool isPlayoutEnabled,
    required bool isRecordingEnabled,
  }) {
    final nextState = AudioEngineState(
      isPlayoutEnabled: isPlayoutEnabled,
      isRecordingEnabled: isRecordingEnabled,
    );
    if (nextState == audioEngineState) {
      return;
    }

    _isPlayoutEnabled = isPlayoutEnabled;
    _isRecordingEnabled = isRecordingEnabled;
    _audioEngineStateController.add(nextState);
  }

  /// Applies a new audio session configuration immediately.
  ///
  /// Use [AudioSessionOptions.communication] to enter VoIP/call mode and
  /// [AudioSessionOptions.media] to leave communication mode for
  /// media/live-streaming capture. This explicit apply path works in both
  /// automatic and manual management modes.
  Future<void> setAudioSessionOptions(AudioSessionOptions options) async {
    _hasExplicitRuntimeOptions = true;
    _syncSpeakerPreferenceFromOptions(options);
    _forceSpeakerOutput = false;
    _options = options;
    await applyCurrentAudioSessionOptions();
  }

  /// Selects whether LiveKit manages the platform audio session automatically.
  ///
  /// In [AudioSessionManagementMode.manual], LiveKit does not update the audio
  /// session from room, connect, or track lifecycle. The app can still apply a
  /// configuration explicitly with [setAudioSessionOptions] and release it with
  /// [deactivateAudioSession].
  ///
  /// Prefer setting this before connecting to a room. flutter_webrtc's own
  /// native audio management is always disabled (LiveKit owns the session).
  /// Changing the mode at runtime only affects LiveKit's own automatic
  /// configuration.
  Future<void> setAudioSessionManagementMode(AudioSessionManagementMode mode) async {
    _managementMode = mode;
    await _syncAppleAudioSessionManagementMode();
  }

  /// Deactivates the current platform audio session.
  ///
  /// In manual mode this is the explicit release counterpart to
  /// [setAudioSessionOptions] or [applyCurrentAudioSessionOptions]. In automatic
  /// mode, LiveKit normally releases the session from room/engine lifecycle, so
  /// apps rarely need to call this directly.
  Future<void> deactivateAudioSession() async {
    if (lkPlatformIs(PlatformType.iOS)) {
      await Native.deactivateAppleAudioSession();
    } else if (lkPlatformIs(PlatformType.android)) {
      await Native.stopAndroidAudioSession();
    }
  }

  /// Prefers routing audio output to/from the speaker.
  ///
  /// By default a connected wired/Bluetooth headset still takes priority even
  /// when [preferred] is true. Set [force] to force the speaker even when a
  /// headset is connected.
  ///
  /// LiveKit owns this routing on both platforms (Android via its own
  /// audioswitch handler and iOS via its audio session), so it does not depend
  /// on flutter_webrtc.
  Future<void> setSpeakerOutputPreferred(bool preferred, {bool force = false}) async {
    if (!canSwitchSpeakerphone) {
      logger.warning('setSpeakerOutputPreferred is only supported on iOS/Android');
      return;
    }
    _preferSpeakerOutput = preferred;
    _forceSpeakerOutput = preferred && force;
    _options = _optionsWithSpeakerPreference(_options, preferred);

    if (lkPlatformIs(PlatformType.iOS)) {
      if (isAutomaticConfigurationEnabled) {
        final policy = _resolvedAudioSessionPolicy(_options);
        // Automatic mode: the native audio-engine delegate owns activation
        // timing, so this caches the policy and applies now only if the engine
        // is already running. Category is resolved natively from engine state
        // unless the app supplied an explicit Apple override.
        await Native.configureAudio(
          policy.appleConfiguration,
          automatic: true,
          selectCategoryByEngineState: policy.usesDynamicAppleCategory,
          forceSpeakerOutput: policy.forceSpeakerOutput,
        );
      } else {
        // Manual mode: this is an explicit routing request, so re-apply the
        // resolved session policy immediately. Plain speaker preference is
        // expressed by category/mode; force is carried separately to native.
        await _configureAppleAudioSession(_options);
      }
    } else if (lkPlatformIs(PlatformType.android)) {
      await Native.setAndroidSpeakerphoneOn(preferred, force: _forceSpeakerOutput);
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
  Map<String, dynamic>? androidAudioConfigurationForInitialize({
    @visibleForTesting bool assumeAndroid = false,
  }) {
    if (!assumeAndroid && !lkPlatformIs(PlatformType.android)) {
      return null;
    }

    // Preserve today's implicit initialize behavior. Only send Android audio
    // attributes when the bypassVoiceProcessing path needs media attributes.
    if (!isAutomaticConfigurationEnabled || !Native.bypassVoiceProcessing) {
      return null;
    }

    return androidAudioSessionConfigurationToMap(_resolvedAudioSessionPolicy(_options).androidConfiguration);
  }

  @internal
  Future<void> applyOptionsForConnect() async {
    await _syncAppleAudioSessionManagementMode();
    if (isAutomaticConfigurationEnabled) {
      await applyCurrentAudioSessionOptions();
    }
  }

  Future<void> _syncAppleAudioSessionManagementMode() async {
    if (lkPlatformIs(PlatformType.iOS)) {
      await Native.setAppleAudioSessionAutomaticManagementEnabled(isAutomaticConfigurationEnabled);
    }
  }

  Future<void> _configureAppleAudioSession(AudioSessionOptions options) async {
    final policy = _resolvedAudioSessionPolicy(options);
    final config = policy.appleConfiguration;
    logger.fine('configuring Apple audio session using $config...');
    // In automatic mode the native audio-engine delegate owns activation timing,
    // so this caches the policy and applies now only if the engine is already
    // running. Automatic mode can resolve the category from engine state unless
    // the app gave an explicit Apple override. Manual mode applies the resolved
    // config immediately and verbatim.
    await Native.configureAudio(
      config,
      automatic: isAutomaticConfigurationEnabled,
      selectCategoryByEngineState: isAutomaticConfigurationEnabled && policy.usesDynamicAppleCategory,
      forceSpeakerOutput: policy.forceSpeakerOutput,
    );
  }

  Future<void> _configureAndroidAudioSession(AudioSessionOptions options) async {
    final policy = _resolvedAudioSessionPolicy(options);
    final config = policy.androidConfiguration;
    logger.fine(
      'configuring Android audio session using ${androidAudioSessionConfigurationToMap(config)}...',
    );
    await setAndroidAudioSessionConfiguration(config);
    await Native.setAndroidSpeakerphoneOn(policy.preferSpeakerOutput, force: policy.forceSpeakerOutput);
  }

  _ResolvedAudioSessionPolicy _resolvedAudioSessionPolicy(AudioSessionOptions options) {
    final preferSpeakerOutput = _speakerPreferenceForOptions(options);
    return _ResolvedAudioSessionPolicy(
      options: options,
      preferSpeakerOutput: preferSpeakerOutput,
      forceSpeakerOutput: _forceSpeakerOutput && preferSpeakerOutput,
    );
  }

  @visibleForTesting
  NativeAudioConfiguration resolveAppleAudioConfigurationForTest(
    AudioSessionOptions options, {
    bool forceSpeakerOutput = false,
  }) {
    final preferSpeakerOutput = _speakerPreferenceForOptions(options);
    return _ResolvedAudioSessionPolicy(
      options: options,
      preferSpeakerOutput: preferSpeakerOutput,
      forceSpeakerOutput: forceSpeakerOutput && preferSpeakerOutput,
    ).appleConfiguration;
  }

  @visibleForTesting
  AndroidAudioSessionConfiguration resolveAndroidAudioConfigurationForTest(AudioSessionOptions options) =>
      _resolvedAudioSessionPolicy(options).androidConfiguration;

  bool _speakerPreferenceForOptions(AudioSessionOptions options) =>
      options.apple?.preferSpeakerOutput ?? options.preferSpeakerOutput;

  void _syncSpeakerPreferenceFromOptions(AudioSessionOptions options) {
    _preferSpeakerOutput = _speakerPreferenceForOptions(options);
    if (!_preferSpeakerOutput) {
      _forceSpeakerOutput = false;
    }
  }

  AudioSessionOptions _optionsWithSpeakerPreference(AudioSessionOptions options, bool preferSpeakerOutput) {
    final apple = options.apple;
    return options.copyWith(
      preferSpeakerOutput: Value(preferSpeakerOutput),
      apple: apple == null
          ? const Absent<AppleAudioSessionConfiguration?>()
          : Value(
              apple.copyWith(
                preferSpeakerOutput: Value(preferSpeakerOutput),
              ),
            ),
    );
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

class _ResolvedAudioSessionPolicy {
  const _ResolvedAudioSessionPolicy({
    required this.options,
    required this.preferSpeakerOutput,
    required this.forceSpeakerOutput,
  });

  final AudioSessionOptions options;
  final bool preferSpeakerOutput;
  final bool forceSpeakerOutput;

  bool get usesDynamicAppleCategory => options.apple == null;

  NativeAudioConfiguration get appleConfiguration {
    final apple = options.apple;
    if (apple != null) {
      return NativeAudioConfiguration(
        appleAudioCategory: apple.category,
        appleAudioCategoryOptions: apple.categoryOptions,
        appleAudioMode: apple.mode,
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
        appleAudioMode: preferSpeakerOutput ? AppleAudioMode.videoChat : AppleAudioMode.voiceChat,
      );
    }

    // Media (non-communication) base policy. The category here is a base. In
    // automatic mode the native engine delegate overrides it from the live
    // engine state (playAndRecord while recording, playback for playout-only),
    // so it no longer depends on stale track/engine flags resolved at connect.
    return NativeAudioConfiguration(
      appleAudioCategory: AppleAudioCategory.playAndRecord,
      appleAudioCategoryOptions: {
        AppleAudioCategoryOption.mixWithOthers,
        AppleAudioCategoryOption.allowBluetooth,
        AppleAudioCategoryOption.allowBluetoothA2DP,
        AppleAudioCategoryOption.allowAirPlay,
      },
      appleAudioMode: AppleAudioMode.default_,
    );
  }

  AndroidAudioSessionConfiguration get androidConfiguration {
    final android = options.android;
    if (android != null) {
      return android;
    }

    if (options.isCommunication) {
      return AndroidAudioSessionConfiguration.communication;
    }
    return AndroidAudioSessionConfiguration.media;
  }
}
