enum IosAudioCategory {
  soloAmbient,
  playback,
  record,
  playAndRecord,
  multiRoute,
}

enum IosAudioMode {
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

enum IosAudioCategoryOption {
  mixWithOthers, // Only playAndRecord, playback, or multiRoute.
  duckOthers, // Only playAndRecord, playback, or multiRoute.
  interruptSpokenAudioAndMixWithOthers,
  allowBluetooth, // Only playAndRecord or record.
  allowBluetoothA2DP,
  allowAirPlay,
  defaultToSpeaker,
}

extension IOSAudioCategoryExt on IosAudioCategory {
  String toStringValue() => <IosAudioCategory, String>{
        IosAudioCategory.soloAmbient: 'soloAmbient',
        IosAudioCategory.playback: 'playback',
        IosAudioCategory.record: 'record',
        IosAudioCategory.playAndRecord: 'playAndRecord',
        IosAudioCategory.multiRoute: 'multiRoute',
      }[this]!;
}

extension IosAudioModeExt on IosAudioMode {
  String toStringValue() => <IosAudioMode, String>{
        IosAudioMode.default_: 'default',
        IosAudioMode.gameChat: 'gameChat',
        IosAudioMode.measurement: 'measurement',
        IosAudioMode.moviePlayback: 'moviePlayback',
        IosAudioMode.spokenAudio: 'spokenAudio',
        IosAudioMode.videoChat: 'videoChat',
        IosAudioMode.videoRecording: 'videoRecording',
        IosAudioMode.voiceChat: 'voiceChat',
        IosAudioMode.voicePrompt: 'voicePrompt',
      }[this]!;
}

extension IosAudioCategoryOptionExt on IosAudioCategoryOption {
  String toStringValue() => <IosAudioCategoryOption, String>{
        IosAudioCategoryOption.mixWithOthers: 'mixWithOthers',
        IosAudioCategoryOption.duckOthers: 'duckOthers',
        IosAudioCategoryOption.interruptSpokenAudioAndMixWithOthers:
            'interruptSpokenAudioAndMixWithOthers',
        IosAudioCategoryOption.allowBluetooth: 'allowBluetooth',
        IosAudioCategoryOption.allowBluetoothA2DP: 'allowBluetoothA2DP',
        IosAudioCategoryOption.allowAirPlay: 'allowAirPlay',
        IosAudioCategoryOption.defaultToSpeaker: 'defaultToSpeaker',
      }[this]!;
}

class NativeAudioConfiguration {
  final IosAudioCategory? iosCategory;
  final IosAudioMode? iosMode;
  final Set<IosAudioCategoryOption>? iosCategoryOptions;

  NativeAudioConfiguration({
    this.iosCategory,
    this.iosMode,
    this.iosCategoryOptions,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
        if (iosCategory != null) 'iosCategory': iosCategory!.toStringValue(),
        if (iosCategoryOptions != null)
          'iosCategoryOptions': iosCategoryOptions!.map((e) => e.toStringValue()).toList(),
        if (iosMode != null) 'iosMode': iosMode!.toStringValue(),
      };
}
