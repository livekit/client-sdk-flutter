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

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/src/audio/android_audio_session_adapter.dart';
import 'package:livekit_client/src/audio/audio_manager.dart';
import 'package:livekit_client/src/audio/audio_session.dart';

void main() {
  group('AudioSessionManagementMode', () {
    test('supports automatic and manual management', () {
      expect(
        AudioSessionManagementMode.values,
        [
          AudioSessionManagementMode.automatic,
          AudioSessionManagementMode.manual,
        ],
      );
    });
  });

  group('AudioSessionOptions', () {
    test('defaults to communication', () {
      final options = AudioSessionOptions.communication();

      expect(options.isCommunication, isTrue);
      expect(options.isMedia, isFalse);
    });

    test('communication and media constructors describe session intent', () {
      final communication = AudioSessionOptions.communication();
      final media = AudioSessionOptions.media();

      expect(communication.isCommunication, isTrue);
      expect(communication.isMedia, isFalse);
      expect(media.isCommunication, isFalse);
      expect(media.isMedia, isTrue);
    });
  });

  group('AudioManager', () {
    test('management mode can be set independently from options', () {
      final manager = AudioManager.instance;

      manager.setAudioSessionManagementMode(AudioSessionManagementMode.manual);

      expect(manager.managementMode, AudioSessionManagementMode.manual);
      expect(manager.isAutomaticConfigurationEnabled, isFalse);
      expect(manager.options.isCommunication, isTrue);

      manager.setAudioSessionManagementMode(AudioSessionManagementMode.automatic);
    });
  });

  group('AndroidAudioSessionConfiguration', () {
    test('communication preset uses voice communication values', () {
      final config = AndroidAudioSessionConfiguration.communication;

      expect(config.manageAudioFocus, isTrue);
      expect(config.audioMode, AndroidAudioMode.inCommunication);
      expect(config.focusMode, AndroidAudioFocusMode.gain);
      expect(config.streamType, AndroidAudioStreamType.voiceCall);
      expect(config.usageType, AndroidAudioAttributesUsageType.voiceCommunication);
      expect(config.contentType, AndroidAudioAttributesContentType.speech);
    });

    test('media preset uses non-communication media values', () {
      final config = AndroidAudioSessionConfiguration.media;

      expect(config.manageAudioFocus, isTrue);
      expect(config.audioMode, AndroidAudioMode.normal);
      expect(config.focusMode, AndroidAudioFocusMode.gain);
      expect(config.streamType, AndroidAudioStreamType.music);
      expect(config.usageType, AndroidAudioAttributesUsageType.media);
      expect(config.contentType, AndroidAudioAttributesContentType.unknown);
    });
  });

  group('androidAudioSessionConfigurationToMap', () {
    test('serializes communication preset for WebRTC initialization', () {
      expect(
        androidAudioSessionConfigurationToMap(AndroidAudioSessionConfiguration.communication),
        {
          'manageAudioFocus': true,
          'androidAudioMode': 'inCommunication',
          'androidAudioFocusMode': 'gain',
          'androidAudioStreamType': 'voiceCall',
          'androidAudioAttributesUsageType': 'voiceCommunication',
          'androidAudioAttributesContentType': 'speech',
        },
      );
    });

    test('omits unset Android fields', () {
      final config = AndroidAudioSessionConfiguration(
        audioMode: AndroidAudioMode.normal,
        forceAudioRouting: true,
      );

      expect(
        androidAudioSessionConfigurationToMap(config),
        {
          'androidAudioMode': 'normal',
          'forceHandleAudioRouting': true,
        },
      );
    });
  });
}
