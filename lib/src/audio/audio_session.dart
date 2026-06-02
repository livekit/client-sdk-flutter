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

export '../support/native_audio.dart' show AppleAudioCategory, AppleAudioCategoryOption, AppleAudioMode;

import 'package:meta/meta.dart';

import '../support/native_audio.dart' show AppleAudioCategory, AppleAudioCategoryOption, AppleAudioMode;

enum AudioSessionManagementMode {
  /// LiveKit updates the platform audio session based on room/track lifecycle.
  automatic,

  /// LiveKit does not update the platform audio session automatically.
  ///
  /// The app must call AudioManager APIs when it wants to apply a session
  /// configuration.
  manual,
}

enum _AudioSessionPreset { communication, media }

class AudioSessionOptions {
  final _AudioSessionPreset _preset;

  /// Whether communication sessions should prefer speaker output.
  final bool preferSpeakerOutput;

  /// Optional exact iOS session override.
  final AppleAudioSessionConfiguration? apple;

  /// Optional exact Android session override.
  final AndroidAudioSessionConfiguration? android;

  const AudioSessionOptions._({
    required _AudioSessionPreset preset,
    this.preferSpeakerOutput = true,
    this.apple,
    this.android,
  }) : _preset = preset;

  const AudioSessionOptions.communication({
    bool preferSpeakerOutput = true,
    AppleAudioSessionConfiguration? apple,
    AndroidAudioSessionConfiguration? android,
  }) : this._(
          preset: _AudioSessionPreset.communication,
          preferSpeakerOutput: preferSpeakerOutput,
          apple: apple,
          android: android,
        );

  const AudioSessionOptions.media({
    AppleAudioSessionConfiguration? apple,
    AndroidAudioSessionConfiguration? android,
  }) : this._(
          preset: _AudioSessionPreset.media,
          preferSpeakerOutput: true,
          apple: apple,
          android: android,
        );

  AudioSessionOptions copyWith({
    bool? preferSpeakerOutput,
    AppleAudioSessionConfiguration? apple,
    AndroidAudioSessionConfiguration? android,
  }) =>
      AudioSessionOptions._(
        preset: _preset,
        preferSpeakerOutput: preferSpeakerOutput ?? this.preferSpeakerOutput,
        apple: apple ?? this.apple,
        android: android ?? this.android,
      );

  @internal
  bool get isCommunication => _preset == _AudioSessionPreset.communication;

  @internal
  bool get isMedia => _preset == _AudioSessionPreset.media;
}

class AppleAudioSessionConfiguration {
  /// AVAudioSession category.
  final AppleAudioCategory? category;

  /// AVAudioSession category options.
  final Set<AppleAudioCategoryOption>? categoryOptions;

  /// AVAudioSession mode.
  final AppleAudioMode? mode;

  /// Whether AVAudioSession should prefer speaker output when supported.
  final bool? preferSpeakerOutput;

  const AppleAudioSessionConfiguration({
    this.category,
    this.categoryOptions,
    this.mode,
    this.preferSpeakerOutput,
  });

  AppleAudioSessionConfiguration copyWith({
    AppleAudioCategory? category,
    Set<AppleAudioCategoryOption>? categoryOptions,
    AppleAudioMode? mode,
    bool? preferSpeakerOutput,
  }) =>
      AppleAudioSessionConfiguration(
        category: category ?? this.category,
        categoryOptions: categoryOptions ?? this.categoryOptions,
        mode: mode ?? this.mode,
        preferSpeakerOutput: preferSpeakerOutput ?? this.preferSpeakerOutput,
      );
}

enum AndroidAudioMode {
  normal,
  callScreening,
  inCall,
  inCommunication,
  ringtone,
}

enum AndroidAudioFocusMode {
  gain,
  gainTransient,
  gainTransientExclusive,
  gainTransientMayDuck,
}

enum AndroidAudioStreamType {
  accessibility,
  alarm,
  dtmf,
  music,
  notification,
  ring,
  system,
  voiceCall,
}

enum AndroidAudioAttributesUsageType {
  alarm,
  assistanceAccessibility,
  assistanceNavigationGuidance,
  assistanceSonification,
  assistant,
  game,
  media,
  notification,
  notificationEvent,
  notificationRingtone,
  unknown,
  voiceCommunication,
  voiceCommunicationSignalling,
}

enum AndroidAudioAttributesContentType {
  movie,
  music,
  sonification,
  speech,
  unknown,
}

class AndroidAudioSessionConfiguration {
  /// Android AudioManager mode.
  final AndroidAudioMode? audioMode;

  /// Whether LiveKit should manage Android audio focus.
  final bool? manageAudioFocus;

  /// Requested Android audio focus gain type.
  final AndroidAudioFocusMode? focusMode;

  /// Legacy Android stream type.
  final AndroidAudioStreamType? streamType;

  /// Android AudioAttributes usage.
  final AndroidAudioAttributesUsageType? usageType;

  /// Android AudioAttributes content type.
  final AndroidAudioAttributesContentType? contentType;

  /// Forces LiveKit audio routing even outside communication/call modes.
  final bool? forceAudioRouting;

  const AndroidAudioSessionConfiguration({
    this.audioMode,
    this.manageAudioFocus,
    this.focusMode,
    this.streamType,
    this.usageType,
    this.contentType,
    this.forceAudioRouting,
  });

  static const communication = AndroidAudioSessionConfiguration(
    audioMode: AndroidAudioMode.inCommunication,
    manageAudioFocus: true,
    focusMode: AndroidAudioFocusMode.gain,
    streamType: AndroidAudioStreamType.voiceCall,
    usageType: AndroidAudioAttributesUsageType.voiceCommunication,
    contentType: AndroidAudioAttributesContentType.speech,
  );

  static const media = AndroidAudioSessionConfiguration(
    audioMode: AndroidAudioMode.normal,
    manageAudioFocus: true,
    focusMode: AndroidAudioFocusMode.gain,
    streamType: AndroidAudioStreamType.music,
    usageType: AndroidAudioAttributesUsageType.media,
    contentType: AndroidAudioAttributesContentType.unknown,
  );

  AndroidAudioSessionConfiguration copyWith({
    AndroidAudioMode? audioMode,
    bool? manageAudioFocus,
    AndroidAudioFocusMode? focusMode,
    AndroidAudioStreamType? streamType,
    AndroidAudioAttributesUsageType? usageType,
    AndroidAudioAttributesContentType? contentType,
    bool? forceAudioRouting,
  }) =>
      AndroidAudioSessionConfiguration(
        audioMode: audioMode ?? this.audioMode,
        manageAudioFocus: manageAudioFocus ?? this.manageAudioFocus,
        focusMode: focusMode ?? this.focusMode,
        streamType: streamType ?? this.streamType,
        usageType: usageType ?? this.usageType,
        contentType: contentType ?? this.contentType,
        forceAudioRouting: forceAudioRouting ?? this.forceAudioRouting,
      );
}
