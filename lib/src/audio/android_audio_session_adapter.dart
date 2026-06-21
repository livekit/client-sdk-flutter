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

import '../support/native.dart';
import 'audio_session.dart';

/// Serializes an [AndroidAudioSessionConfiguration] into the map consumed by
/// LiveKit's native Android audio session manager. Unset fields are omitted so
/// the native side keeps its current value.
@internal
Map<String, dynamic> androidAudioSessionConfigurationToMap(AndroidAudioSessionConfiguration config) =>
    <String, dynamic>{
      if (config.manageAudioFocus != null) 'manageAudioFocus': config.manageAudioFocus!,
      if (config.audioMode != null) 'androidAudioMode': config.audioMode!.name,
      if (config.focusMode != null) 'androidAudioFocusMode': config.focusMode!.name,
      if (config.streamType != null) 'androidAudioStreamType': config.streamType!.name,
      if (config.usageType != null) 'androidAudioAttributesUsageType': config.usageType!.name,
      if (config.contentType != null) 'androidAudioAttributesContentType': config.contentType!.name,
      if (config.forceAudioRouting != null) 'forceHandleAudioRouting': config.forceAudioRouting!,
    };

@internal
Future<void> setAndroidAudioSessionConfiguration(AndroidAudioSessionConfiguration config) async {
  await Native.configureAndroidAudioSession(androidAudioSessionConfigurationToMap(config));
}
