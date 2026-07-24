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

import '../audio/audio_session.dart' show AppleAudioCategory, AppleAudioCategoryOption, AppleAudioMode;
import 'value_or_absent.dart';

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
        AppleAudioCategoryOption.interruptSpokenAudioAndMixWithOthers: 'interruptSpokenAudioAndMixWithOthers',
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

  NativeAudioConfiguration(
      {
      // for iOS / Mac
      this.appleAudioCategory,
      this.appleAudioCategoryOptions,
      this.appleAudioMode
      // Android options
      // ...
      });

  Map<String, dynamic> toMap() => <String, dynamic>{
        if (appleAudioCategory != null) 'appleAudioCategory': appleAudioCategory!.toStringValue(),
        if (appleAudioCategoryOptions != null)
          'appleAudioCategoryOptions': appleAudioCategoryOptions!.map((e) => e.toStringValue()).toList(),
        if (appleAudioMode != null) 'appleAudioMode': appleAudioMode!.toStringValue(),
      };

  NativeAudioConfiguration copyWith({
    ValueOrAbsent<AppleAudioCategory?> appleAudioCategory = const ValueOrAbsent.absent(),
    ValueOrAbsent<Set<AppleAudioCategoryOption>?> appleAudioCategoryOptions = const ValueOrAbsent.absent(),
    ValueOrAbsent<AppleAudioMode?> appleAudioMode = const ValueOrAbsent.absent(),
  }) =>
      NativeAudioConfiguration(
        appleAudioCategory: appleAudioCategory.valueOr(this.appleAudioCategory),
        appleAudioCategoryOptions: appleAudioCategoryOptions.valueOr(this.appleAudioCategoryOptions),
        appleAudioMode: appleAudioMode.valueOr(this.appleAudioMode),
      );
}
