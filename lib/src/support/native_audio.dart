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

extension AppleAudioCategoryExt on AppleAudioCategory {
  String toStringValue() => <AppleAudioCategory, String>{
        AppleAudioCategory.soloAmbient: 'soloAmbient',
        AppleAudioCategory.playback: 'playback',
        AppleAudioCategory.record: 'record',
        AppleAudioCategory.playAndRecord: 'playAndRecord',
        AppleAudioCategory.multiRoute: 'multiRoute',
      }[this]!;
}

extension AppleAudioCategoryOptionExt on AppleAudioCategoryOption {
  String toStringValue() => <AppleAudioCategoryOption, String>{
        AppleAudioCategoryOption.mixWithOthers: 'mixWithOthers',
        AppleAudioCategoryOption.duckOthers: 'duckOthers',
        AppleAudioCategoryOption.interruptSpokenAudioAndMixWithOthers:
            'interruptSpokenAudioAndMixWithOthers',
        AppleAudioCategoryOption.allowBluetooth: 'allowBluetooth',
        AppleAudioCategoryOption.allowBluetoothA2DP: 'allowBluetoothA2DP',
        AppleAudioCategoryOption.allowAirPlay: 'allowAirPlay',
        AppleAudioCategoryOption.defaultToSpeaker: 'defaultToSpeaker',
      }[this]!;
}

extension AppleAudioModeExt on AppleAudioMode {
  String toStringValue() => <AppleAudioMode, String>{
        AppleAudioMode.default_: 'default',
        AppleAudioMode.gameChat: 'gameChat',
        AppleAudioMode.measurement: 'measurement',
        AppleAudioMode.moviePlayback: 'moviePlayback',
        AppleAudioMode.spokenAudio: 'spokenAudio',
        AppleAudioMode.videoChat: 'videoChat',
        AppleAudioMode.videoRecording: 'videoRecording',
        AppleAudioMode.voiceChat: 'voiceChat',
        AppleAudioMode.voicePrompt: 'voicePrompt',
      }[this]!;
}

class NativeAudioConfiguration {
  final AppleAudioCategory? appleAudioCategory;
  final Set<AppleAudioCategoryOption>? appleAudioCategoryOptions;
  final AppleAudioMode? appleAudioMode;

  NativeAudioConfiguration({
    // for iOS / Mac
    this.appleAudioCategory,
    this.appleAudioCategoryOptions,
    this.appleAudioMode,
    // Android options
    // ...
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
        if (appleAudioCategory != null)
          'appleAudioCategory': appleAudioCategory!.toStringValue(),
        if (appleAudioCategoryOptions != null)
          'appleAudioCategoryOptions':
              appleAudioCategoryOptions!.map((e) => e.toStringValue()).toList(),
        if (appleAudioMode != null)
          'appleAudioMode': appleAudioMode!.toStringValue(),
      };

  NativeAudioConfiguration copyWith({
    AppleAudioCategory? appleAudioCategory,
    Set<AppleAudioCategoryOption>? appleAudioCategoryOptions,
    AppleAudioMode? appleAudioMode,
  }) =>
      NativeAudioConfiguration(
        appleAudioCategory: appleAudioCategory ?? this.appleAudioCategory,
        appleAudioCategoryOptions:
            appleAudioCategoryOptions ?? this.appleAudioCategoryOptions,
        appleAudioMode: appleAudioMode ?? this.appleAudioMode,
      );
}
