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
import '../support/platform.dart';
import 'android_audio_session_adapter.dart';
import 'audio_processing_state.dart';
import 'audio_session.dart';
import 'audio_session_policy.dart';

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

  AudioSessionOptions _options = const AudioSessionOptions.communication();
  AudioSessionManagementMode _managementMode = AudioSessionManagementMode.automatic;
  bool _preferSpeakerOutput = true;
  bool _forceSpeakerOutput = false;
  bool _isPlayoutEnabled = false;
  bool _isRecordingEnabled = false;
  final StreamController<AudioEngineState> _audioEngineStateController = StreamController<AudioEngineState>.broadcast();

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

  bool get _isAutomaticConfigurationEnabled => _managementMode == AudioSessionManagementMode.automatic;

  @visibleForTesting
  void resetForTest() {
    _options = const AudioSessionOptions.communication();
    _managementMode = AudioSessionManagementMode.automatic;
    _preferSpeakerOutput = true;
    _forceSpeakerOutput = false;
    _isPlayoutEnabled = false;
    _isRecordingEnabled = false;
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

  /// Seeds the initial session intent without taking over the session lifecycle.
  ///
  /// `LiveKitClient.initialize(initialAudioSessionOptions: ...)` uses this so the
  /// WebRTC initialization-time Android audio attributes and LiveKit's automatic
  /// runtime session policy start from the same intent. Unlike
  /// [setAudioSessionOptions], this keeps automatic management enabled and does
  /// not apply native session changes immediately.
  @internal
  void setInitialAudioSessionOptions(AudioSessionOptions options) {
    if (_managementMode != AudioSessionManagementMode.automatic) {
      return;
    }
    _options = options;
  }

  /// Applies an explicit audio session configuration and switches to manual mode.
  ///
  /// Calling this puts [AudioManager] in [AudioSessionManagementMode.manual]:
  /// LiveKit stops managing the session from room, connect, and engine
  /// lifecycle, and the app owns it from here. Hand control back to LiveKit with
  /// [setAudioSessionManagementMode] and [AudioSessionManagementMode.automatic].
  ///
  /// The speaker preference and force flag are owned by setSpeakerOutputPreferred
  /// and are preserved across this call.
  Future<void> setAudioSessionOptions(AudioSessionOptions options) async {
    await _enterManualMode();
    _options = options;
    await _applyCurrentAudioSessionPolicy();
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
  /// Switching back to automatic mode reapplies LiveKit's managed policy.
  Future<void> setAudioSessionManagementMode(AudioSessionManagementMode mode) async {
    final previousMode = _managementMode;
    _managementMode = mode;
    await _syncAppleAudioSessionManagementMode();
    if (previousMode != AudioSessionManagementMode.automatic && mode == AudioSessionManagementMode.automatic) {
      await _applyCurrentAudioSessionPolicy();
    }
  }

  /// Switches to manual mode if not already, syncing the native side once.
  Future<void> _enterManualMode() async {
    if (_managementMode == AudioSessionManagementMode.manual) return;
    _managementMode = AudioSessionManagementMode.manual;
    await _syncAppleAudioSessionManagementMode();
  }

  /// Deactivates the current platform audio session and switches to manual mode.
  ///
  /// Like [setAudioSessionOptions], calling this puts [AudioManager] in
  /// [AudioSessionManagementMode.manual] so LiveKit does not re-activate the
  /// session on its own. Re-apply a configuration with [setAudioSessionOptions],
  /// or hand control back with [setAudioSessionManagementMode].
  Future<void> deactivateAudioSession() async {
    await _enterManualMode();
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

    if (lkPlatformIs(PlatformType.iOS)) {
      if (_isAutomaticConfigurationEnabled) {
        final policy = _resolvedAudioSessionPolicy(_options);
        // Automatic mode: the native audio-engine delegate owns activation
        // timing, so this caches the policy and applies now only if the engine
        // is already running. Category is resolved natively from engine state.
        await Native.configureAudio(
          policy.appleConfiguration,
          automatic: true,
          selectCategoryByEngineState: true,
          forceSpeakerOutput: policy.forceSpeakerOutput,
        );
      } else {
        // Manual mode: re-apply the fixed Apple config. Non-forced receiver vs
        // speaker behavior comes from that config. Force is carried separately
        // to native for playAndRecord sessions.
        await _configureAppleAudioSession(_options);
      }
    } else if (lkPlatformIs(PlatformType.android)) {
      await Native.setAndroidSpeakerphoneOn(preferred, force: _forceSpeakerOutput);
    }
  }

  Future<void> _applyCurrentAudioSessionPolicy() async {
    if (lkPlatformIs(PlatformType.iOS)) {
      await _configureAppleAudioSession(_options);
    } else if (lkPlatformIs(PlatformType.android)) {
      await _configureAndroidAudioSession(_options);
    }
  }

  @internal
  Future<void> applyOptionsForConnect() async {
    await _syncAppleAudioSessionManagementMode();
    if (_isAutomaticConfigurationEnabled) {
      await _applyCurrentAudioSessionPolicy();
    }
  }

  Future<void> _syncAppleAudioSessionManagementMode() async {
    if (lkPlatformIs(PlatformType.iOS)) {
      await Native.setAppleAudioSessionAutomaticManagementEnabled(_isAutomaticConfigurationEnabled);
    }
  }

  Future<void> _configureAppleAudioSession(AudioSessionOptions options) async {
    final policy = _resolvedAudioSessionPolicy(options);
    final config = policy.appleConfiguration;
    logger.fine('configuring Apple audio session using $config...');
    // In automatic mode the native audio-engine delegate owns activation timing,
    // so this caches the policy and applies now only if the engine is already
    // running. Automatic mode resolves the category from engine state. Manual
    // mode applies the resolved config immediately and verbatim.
    await Native.configureAudio(
      config,
      automatic: _isAutomaticConfigurationEnabled,
      selectCategoryByEngineState: _isAutomaticConfigurationEnabled,
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

  ResolvedAudioSessionPolicy _resolvedAudioSessionPolicy(AudioSessionOptions options) => ResolvedAudioSessionPolicy(
        options: options,
        preferSpeakerOutput: _preferSpeakerOutput,
        forceSpeakerOutput: _forceSpeakerOutput && _preferSpeakerOutput,
        automatic: _isAutomaticConfigurationEnabled,
      );

  /// Diagnostic snapshot of the resolved audio processing state.
  ///
  /// The audio processing module is owned by the native peer connection factory
  /// and shared engine-wide, so this reflects what is actually applied across
  /// the engine rather than any single track. Use it to verify native state
  /// after a `LocalAudioTrack.setAudioProcessingOptions` request. Returns
  /// `null` when the native side cannot provide it.
  Future<AudioProcessingState?> getAudioProcessingState() async {
    final response = await Native.getAudioProcessingState();
    if (response == null) return null;
    return AudioProcessingState.fromMap(response);
  }
}
