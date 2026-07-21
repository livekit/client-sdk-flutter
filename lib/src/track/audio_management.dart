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

import '../audio/audio_manager.dart';
import '../audio/audio_session.dart';
import '../support/native.dart';
import '../support/platform.dart';
import 'local/local.dart';
import 'remote/remote.dart';

@Deprecated('Audio session lifecycle is managed by AudioManager instead')
mixin LocalAudioManagementMixin on LocalTrack, AudioTrack {}

@Deprecated('Audio session lifecycle is managed by AudioManager instead')
mixin RemoteAudioManagementMixin on RemoteTrack, AudioTrack {}

class NativeAudioManagement {
  static Future<void> start() async {
    await AudioManager.instance.applyOptionsForConnect();
  }

  static Future<void> stop() async {
    // Release mirrors acquire: applyOptionsForConnect starts the Android
    // audio session in every mode except manual, including externalCallSystem,
    // which behaves like automatic on Android until Telecom integration owns
    // focus and routing for registered calls.
    if (lkPlatformIs(PlatformType.android) &&
        AudioManager.instance.managementMode != AudioSessionManagementMode.manual) {
      await Native.stopAndroidAudioSession();
    }
  }
}
