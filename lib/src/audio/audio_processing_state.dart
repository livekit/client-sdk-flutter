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

import '../track/options.dart';

/// The implementation in effect for an audio processing component.
enum AudioProcessingImplementation {
  unknown('unknown'),
  disabled('disabled'),
  software('software'),
  platform('platform'),
  softwareAndPlatform('softwareAndPlatform');

  const AudioProcessingImplementation(this.value);

  final String value;

  static AudioProcessingImplementation fromValue(String? value) => AudioProcessingImplementation.values.firstWhere(
        (e) => e.value == value,
        orElse: () => AudioProcessingImplementation.unknown,
      );
}

AudioProcessingMode _modeFromValue(String? value) {
  for (final mode in AudioProcessingMode.values) {
    if (mode.constraintValue == value) return mode;
  }
  return AudioProcessingMode.automatic;
}

/// The caller's request for one audio processing component: enabled flag plus
/// implementation mode.
class AudioProcessingComponentRequest {
  const AudioProcessingComponentRequest({
    required this.enabled,
    required this.mode,
  });

  factory AudioProcessingComponentRequest.fromMap(Map<dynamic, dynamic> map) => AudioProcessingComponentRequest(
        enabled: (map['enabled'] as bool?) ?? false,
        mode: _modeFromValue(map['mode'] as String?),
      );

  final bool enabled;
  final AudioProcessingMode mode;
}

/// Diagnostic state of one audio processing component (echo cancellation,
/// noise suppression, auto gain control or high-pass filter), observed at
/// three stages of one pipeline: requested (caller intent) -> resolved (the
/// engine's per-path decision) -> active (live truth), with [effective] as
/// the merged verdict.
class AudioProcessingComponentState {
  const AudioProcessingComponentState({
    this.requested,
    required this.isSoftwareResolved,
    required this.isSoftwareActive,
    required this.isPlatformAvailable,
    required this.isPlatformResolved,
    required this.isPlatformActive,
    required this.effective,
  });

  factory AudioProcessingComponentState.fromMap(Map<dynamic, dynamic> map) => AudioProcessingComponentState(
        requested: map['requested'] is Map
            ? AudioProcessingComponentRequest.fromMap(Map<dynamic, dynamic>.from(map['requested'] as Map))
            : null,
        isSoftwareResolved: (map['isSoftwareResolved'] as bool?) ?? false,
        isSoftwareActive: (map['isSoftwareActive'] as bool?) ?? false,
        isPlatformAvailable: (map['isPlatformAvailable'] as bool?) ?? false,
        isPlatformResolved: (map['isPlatformResolved'] as bool?) ?? false,
        isPlatformActive: (map['isPlatformActive'] as bool?) ?? false,
        effective: AudioProcessingImplementation.fromValue(map['effective'] as String?),
      );

  /// What the caller most recently requested for this component. Null when no
  /// audio processing options have ever been applied — "nobody asked".
  final AudioProcessingComponentRequest? requested;

  /// Whether the resolver decided the WebRTC software (APM) implementation
  /// should run, after weighing the requested mode against platform
  /// availability, coupling, and policy.
  final bool isSoftwareResolved;

  /// Whether APM's live configuration currently has this component enabled.
  final bool isSoftwareActive;

  /// Whether this device/OS offers a built-in implementation at all.
  final bool isPlatformAvailable;

  /// Whether the engine asked the OS to run the platform implementation. The
  /// OS owns the outcome: it can decline, defer, or couple components.
  final bool isPlatformResolved;

  /// Whether the device reports the platform implementation actually running.
  final bool isPlatformActive;

  /// The verdict: which implementation is in effect right now.
  final AudioProcessingImplementation effective;
}

/// Diagnostic snapshot of the resolved audio processing state for the shared
/// audio processing module.
///
/// The module is owned by the native peer connection factory and shared
/// engine-wide, so this reflects what is actually applied (per-component
/// [AudioProcessingComponentState.effective]) versus what was requested — for
/// the whole engine, not a single track.
class AudioProcessingState {
  const AudioProcessingState({
    required this.hasAudioProcessingModule,
    required this.echoCancellation,
    required this.noiseSuppression,
    required this.autoGainControl,
    required this.highPassFilter,
  });

  factory AudioProcessingState.fromMap(Map<dynamic, dynamic> map) => AudioProcessingState(
        hasAudioProcessingModule: (map['hasAudioProcessingModule'] as bool?) ?? false,
        echoCancellation:
            AudioProcessingComponentState.fromMap(Map<dynamic, dynamic>.from(map['echoCancellation'] as Map)),
        noiseSuppression:
            AudioProcessingComponentState.fromMap(Map<dynamic, dynamic>.from(map['noiseSuppression'] as Map)),
        autoGainControl:
            AudioProcessingComponentState.fromMap(Map<dynamic, dynamic>.from(map['autoGainControl'] as Map)),
        highPassFilter: AudioProcessingComponentState.fromMap(Map<dynamic, dynamic>.from(map['highPassFilter'] as Map)),
      );

  final bool hasAudioProcessingModule;
  final AudioProcessingComponentState echoCancellation;
  final AudioProcessingComponentState noiseSuppression;
  final AudioProcessingComponentState autoGainControl;
  final AudioProcessingComponentState highPassFilter;
}
