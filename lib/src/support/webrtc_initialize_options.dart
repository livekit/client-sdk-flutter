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

import 'package:meta/meta.dart';

import '../audio/android_audio_session_adapter.dart';
import '../audio/audio_session.dart';

@internal
Map<String, dynamic> liveKitWebRTCInitializeOptions({
  required bool bypassVoiceProcessing,
  required AudioSessionOptions? initialAudioSessionOptions,
  required bool includeAndroidAudioConfiguration,
}) =>
    {
      if (bypassVoiceProcessing) 'bypassVoiceProcessing': bypassVoiceProcessing,
      if (includeAndroidAudioConfiguration && initialAudioSessionOptions != null)
        'androidAudioConfiguration': androidAudioSessionConfigurationToMap(initialAudioSessionOptions.android),
    };
