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

export '../support/value_or_absent.dart';

import 'package:meta/meta.dart';

import '../support/value_or_absent.dart';

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
  ///
  /// This is used by the communication preset and by Apple `playAndRecord`
  /// policies. Media/playback policies leave routing to the platform unless an
  /// exact platform override says otherwise.
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

  /// Two-way audio preset for calls, rooms, and microphone capture.
  ///
  /// LiveKit resolves this to communication-oriented platform policies. Use
  /// [preferSpeakerOutput] for the default speaker preference unless [apple] or
  /// [android] provides a more exact platform policy.
  ///
  /// On Apple platforms in automatic mode, listen-only playout uses playback
  /// until recording starts. Receiver routing from [preferSpeakerOutput] only
  /// applies while the effective category is `playAndRecord`.
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

  /// One-way media playback preset.
  ///
  /// This intentionally does not expose an initial [preferSpeakerOutput] value:
  /// Apple playback policy leaves routing to the platform, while Android
  /// speaker routing remains a runtime preference. Use [apple] or [android] for
  /// exact platform behavior, or switch at runtime with
  /// `AudioManager.setSpeakerOutputPreferred`.
  const AudioSessionOptions.media({
    AppleAudioSessionConfiguration? apple,
    AndroidAudioSessionConfiguration? android,
  }) : this._(
          preset: _AudioSessionPreset.media,
          preferSpeakerOutput: true,
          apple: apple,
          android: android,
        );

  /// Returns a copy with selected fields replaced.
  ///
  /// The preset chosen by [AudioSessionOptions.communication] or
  /// [AudioSessionOptions.media] is intentionally retained. Create a new
  /// options object with the other constructor to switch presets.
  AudioSessionOptions copyWith({
    ValueOrAbsent<bool> preferSpeakerOutput = const Absent(),
    ValueOrAbsent<AppleAudioSessionConfiguration?> apple = const Absent(),
    ValueOrAbsent<AndroidAudioSessionConfiguration?> android = const Absent(),
  }) =>
      AudioSessionOptions._(
        preset: _preset,
        preferSpeakerOutput: preferSpeakerOutput.valueOr(this.preferSpeakerOutput),
        apple: apple.valueOr(this.apple),
        android: android.valueOr(this.android),
      );

  @internal
  bool get isCommunication => _preset == _AudioSessionPreset.communication;

  @internal
  bool get isMedia => _preset == _AudioSessionPreset.media;
}

// https://developer.apple.com/documentation/avfaudio/avaudiosession/category
enum AppleAudioCategory {
  soloAmbient,
  playback,
  record,
  playAndRecord,
  multiRoute,
}

// https://developer.apple.com/documentation/avfaudio/avaudiosession/categoryoptions
enum AppleAudioCategoryOption {
  mixWithOthers, // Only playAndRecord, playback, or multiRoute.
  duckOthers, // Only playAndRecord, playback, or multiRoute.
  interruptSpokenAudioAndMixWithOthers,
  allowBluetooth, // Only playAndRecord or record.
  allowBluetoothA2DP,
  allowAirPlay,
  defaultToSpeaker,
}

// https://developer.apple.com/documentation/avfaudio/avaudiosession/mode
enum AppleAudioMode {
  default_,
  gameChat,
  measurement,
  moviePlayback,
  spokenAudio,
  videoChat,
  videoRecording,
  voiceChat,
  voicePrompt,
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
    ValueOrAbsent<AppleAudioCategory?> category = const Absent(),
    ValueOrAbsent<Set<AppleAudioCategoryOption>?> categoryOptions = const Absent(),
    ValueOrAbsent<AppleAudioMode?> mode = const Absent(),
    ValueOrAbsent<bool?> preferSpeakerOutput = const Absent(),
  }) =>
      AppleAudioSessionConfiguration(
        category: category.valueOr(this.category),
        categoryOptions: categoryOptions.valueOr(this.categoryOptions),
        mode: mode.valueOr(this.mode),
        preferSpeakerOutput: preferSpeakerOutput.valueOr(this.preferSpeakerOutput),
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
    ValueOrAbsent<AndroidAudioMode?> audioMode = const Absent(),
    ValueOrAbsent<bool?> manageAudioFocus = const Absent(),
    ValueOrAbsent<AndroidAudioFocusMode?> focusMode = const Absent(),
    ValueOrAbsent<AndroidAudioStreamType?> streamType = const Absent(),
    ValueOrAbsent<AndroidAudioAttributesUsageType?> usageType = const Absent(),
    ValueOrAbsent<AndroidAudioAttributesContentType?> contentType = const Absent(),
    ValueOrAbsent<bool?> forceAudioRouting = const Absent(),
  }) =>
      AndroidAudioSessionConfiguration(
        audioMode: audioMode.valueOr(this.audioMode),
        manageAudioFocus: manageAudioFocus.valueOr(this.manageAudioFocus),
        focusMode: focusMode.valueOr(this.focusMode),
        streamType: streamType.valueOr(this.streamType),
        usageType: usageType.valueOr(this.usageType),
        contentType: contentType.valueOr(this.contentType),
        forceAudioRouting: forceAudioRouting.valueOr(this.forceAudioRouting),
      );
}
