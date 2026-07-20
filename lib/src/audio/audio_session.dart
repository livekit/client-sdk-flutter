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

@immutable
class AudioSessionOptions {
  /// Exact Apple session configuration for manual mode.
  final AppleAudioSessionConfiguration apple;

  /// Exact Android session configuration for manual mode.
  final AndroidAudioSessionConfiguration android;

  const AudioSessionOptions._({
    required this.apple,
    required this.android,
  });

  /// Two-way audio preset for calls, rooms, and microphone capture.
  ///
  /// This pre-fills communication-oriented platform policies. Speaker
  /// routing is a runtime preference set with
  /// `AudioManager.setSpeakerOutputPreferred`. Override [apple] or [android]
  /// for exact platform behavior.
  const AudioSessionOptions.communication({
    AppleAudioSessionConfiguration apple = AppleAudioSessionConfiguration.communication,
    AndroidAudioSessionConfiguration android = AndroidAudioSessionConfiguration.communication,
  }) : this._(apple: apple, android: android);

  /// One-way media playback preset.
  ///
  /// This pre-fills playback-oriented platform policies. Apple and Android
  /// media routing are platform-owned. On Android, pass this to
  /// `LiveKitClient.initialize` before WebRTC initializes when WebRTC playout
  /// should use media `AudioAttributes`; the same value seeds LiveKit's initial
  /// automatic runtime media session policy.
  const AudioSessionOptions.mediaPlayback({
    AppleAudioSessionConfiguration apple = AppleAudioSessionConfiguration.media,
    AndroidAudioSessionConfiguration android = AndroidAudioSessionConfiguration.media,
  }) : this._(apple: apple, android: android);

  /// Returns a copy with selected fields replaced.
  AudioSessionOptions copyWith({
    ValueOrAbsent<AppleAudioSessionConfiguration> apple = const ValueOrAbsent.absent(),
    ValueOrAbsent<AndroidAudioSessionConfiguration> android = const ValueOrAbsent.absent(),
  }) =>
      AudioSessionOptions._(
        apple: apple.valueOr(this.apple),
        android: android.valueOr(this.android),
      );
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

@immutable
class AppleAudioSessionConfiguration {
  /// AVAudioSession category.
  final AppleAudioCategory? category;

  /// AVAudioSession category options.
  final Set<AppleAudioCategoryOption>? categoryOptions;

  /// AVAudioSession mode.
  final AppleAudioMode? mode;

  const AppleAudioSessionConfiguration({
    this.category,
    this.categoryOptions,
    this.mode,
  });

  static const communication = AppleAudioSessionConfiguration(
    category: AppleAudioCategory.playAndRecord,
    categoryOptions: {
      AppleAudioCategoryOption.allowBluetooth,
      AppleAudioCategoryOption.allowBluetoothA2DP,
      AppleAudioCategoryOption.allowAirPlay,
    },
    mode: AppleAudioMode.videoChat,
  );

  static const media = AppleAudioSessionConfiguration(
    category: AppleAudioCategory.playback,
    categoryOptions: {AppleAudioCategoryOption.mixWithOthers},
    mode: AppleAudioMode.spokenAudio,
  );

  AppleAudioSessionConfiguration copyWith({
    ValueOrAbsent<AppleAudioCategory?> category = const ValueOrAbsent.absent(),
    ValueOrAbsent<Set<AppleAudioCategoryOption>?> categoryOptions = const ValueOrAbsent.absent(),
    ValueOrAbsent<AppleAudioMode?> mode = const ValueOrAbsent.absent(),
  }) =>
      AppleAudioSessionConfiguration(
        category: category.valueOr(this.category),
        categoryOptions: categoryOptions.valueOr(this.categoryOptions),
        mode: mode.valueOr(this.mode),
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

@immutable
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
    ValueOrAbsent<AndroidAudioMode?> audioMode = const ValueOrAbsent.absent(),
    ValueOrAbsent<bool?> manageAudioFocus = const ValueOrAbsent.absent(),
    ValueOrAbsent<AndroidAudioFocusMode?> focusMode = const ValueOrAbsent.absent(),
    ValueOrAbsent<AndroidAudioStreamType?> streamType = const ValueOrAbsent.absent(),
    ValueOrAbsent<AndroidAudioAttributesUsageType?> usageType = const ValueOrAbsent.absent(),
    ValueOrAbsent<AndroidAudioAttributesContentType?> contentType = const ValueOrAbsent.absent(),
    ValueOrAbsent<bool?> forceAudioRouting = const ValueOrAbsent.absent(),
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
