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

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/src/audio/android_audio_session_adapter.dart';
import 'package:livekit_client/src/audio/audio_manager.dart';
import 'package:livekit_client/src/audio/audio_session.dart';
import 'package:livekit_client/src/support/native.dart';
import 'package:livekit_client/src/support/native_audio.dart' as native_audio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AudioManager.instance.resetForTest();
    Native.bypassVoiceProcessing = false;
  });

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

    test('copyWith updates and clears platform overrides', () {
      const options = AudioSessionOptions.communication(
        preferSpeakerOutput: true,
        apple: AppleAudioSessionConfiguration(
          category: AppleAudioCategory.playAndRecord,
        ),
        android: AndroidAudioSessionConfiguration(
          audioMode: AndroidAudioMode.inCommunication,
        ),
      );

      final updated = options.copyWith(
        preferSpeakerOutput: const Value(false),
        apple: const Value(
          AppleAudioSessionConfiguration(
            mode: AppleAudioMode.voiceChat,
          ),
        ),
      );

      expect(updated.preferSpeakerOutput, isFalse);
      expect(updated.apple?.category, isNull);
      expect(updated.apple?.mode, AppleAudioMode.voiceChat);
      expect(updated.android?.audioMode, AndroidAudioMode.inCommunication);

      final cleared = updated.copyWith(
        apple: const Value(null),
        android: const Value(null),
      );

      expect(cleared.apple, isNull);
      expect(cleared.android, isNull);
    });

    test('Apple configuration copyWith updates and clears nullable fields', () {
      const config = AppleAudioSessionConfiguration(
        category: AppleAudioCategory.playAndRecord,
        categoryOptions: {AppleAudioCategoryOption.allowBluetooth},
        mode: AppleAudioMode.voiceChat,
        preferSpeakerOutput: false,
      );

      final updated = config.copyWith(
        category: const Value(AppleAudioCategory.playback),
        categoryOptions: const Value({AppleAudioCategoryOption.mixWithOthers}),
        mode: const Value(AppleAudioMode.spokenAudio),
        preferSpeakerOutput: const Value(true),
      );

      expect(updated.category, AppleAudioCategory.playback);
      expect(updated.categoryOptions, {AppleAudioCategoryOption.mixWithOthers});
      expect(updated.mode, AppleAudioMode.spokenAudio);
      expect(updated.preferSpeakerOutput, isTrue);

      final cleared = updated.copyWith(
        category: const Value(null),
        categoryOptions: const Value(null),
        mode: const Value(null),
        preferSpeakerOutput: const Value(null),
      );

      expect(cleared.category, isNull);
      expect(cleared.categoryOptions, isNull);
      expect(cleared.mode, isNull);
      expect(cleared.preferSpeakerOutput, isNull);
    });

    test('Android configuration copyWith updates and clears nullable fields', () {
      const config = AndroidAudioSessionConfiguration(
        audioMode: AndroidAudioMode.inCommunication,
        manageAudioFocus: true,
        focusMode: AndroidAudioFocusMode.gain,
        streamType: AndroidAudioStreamType.voiceCall,
        usageType: AndroidAudioAttributesUsageType.voiceCommunication,
        contentType: AndroidAudioAttributesContentType.speech,
        forceAudioRouting: true,
      );

      final updated = config.copyWith(
        audioMode: const Value(AndroidAudioMode.normal),
        manageAudioFocus: const Value(false),
        focusMode: const Value(AndroidAudioFocusMode.gainTransient),
        streamType: const Value(AndroidAudioStreamType.music),
        usageType: const Value(AndroidAudioAttributesUsageType.media),
        contentType: const Value(AndroidAudioAttributesContentType.unknown),
        forceAudioRouting: const Value(false),
      );

      expect(updated.audioMode, AndroidAudioMode.normal);
      expect(updated.manageAudioFocus, isFalse);
      expect(updated.focusMode, AndroidAudioFocusMode.gainTransient);
      expect(updated.streamType, AndroidAudioStreamType.music);
      expect(updated.usageType, AndroidAudioAttributesUsageType.media);
      expect(updated.contentType, AndroidAudioAttributesContentType.unknown);
      expect(updated.forceAudioRouting, isFalse);

      final cleared = updated.copyWith(
        audioMode: const Value(null),
        manageAudioFocus: const Value(null),
        focusMode: const Value(null),
        streamType: const Value(null),
        usageType: const Value(null),
        contentType: const Value(null),
        forceAudioRouting: const Value(null),
      );

      expect(cleared.audioMode, isNull);
      expect(cleared.manageAudioFocus, isNull);
      expect(cleared.focusMode, isNull);
      expect(cleared.streamType, isNull);
      expect(cleared.usageType, isNull);
      expect(cleared.contentType, isNull);
      expect(cleared.forceAudioRouting, isNull);
    });
  });

  group('AudioManager', () {
    test('management mode can be set independently from options', () async {
      final manager = AudioManager.instance;

      await manager.setAudioSessionManagementMode(AudioSessionManagementMode.manual);

      expect(manager.managementMode, AudioSessionManagementMode.manual);
      expect(manager.isAutomaticConfigurationEnabled, isFalse);
      expect(manager.options.isCommunication, isTrue);

      await manager.setAudioSessionManagementMode(AudioSessionManagementMode.automatic);
    });

    test('setAudioSessionOptions syncs communication speaker preference', () async {
      final manager = AudioManager.instance;

      await manager.setAudioSessionOptions(
        const AudioSessionOptions.communication(preferSpeakerOutput: false),
      );

      expect(manager.isSpeakerOutputPreferred, isFalse);
      expect(manager.options.preferSpeakerOutput, isFalse);

      await manager.setAudioSessionOptions(
        const AudioSessionOptions.communication(preferSpeakerOutput: true),
      );

      expect(manager.isSpeakerOutputPreferred, isTrue);
      expect(manager.options.preferSpeakerOutput, isTrue);
    });

    test('setAudioSessionOptions syncs explicit Apple speaker preference', () async {
      final manager = AudioManager.instance;

      await manager.setAudioSessionOptions(
        const AudioSessionOptions.communication(
          apple: AppleAudioSessionConfiguration(
            preferSpeakerOutput: false,
          ),
        ),
      );

      expect(manager.isSpeakerOutputPreferred, isFalse);

      await manager.setAudioSessionOptions(
        const AudioSessionOptions.communication(
          apple: AppleAudioSessionConfiguration(
            preferSpeakerOutput: true,
          ),
        ),
      );

      expect(manager.isSpeakerOutputPreferred, isTrue);
    });

    test('resolves communication Apple session policy from speaker preference', () {
      final manager = AudioManager.instance;

      final speaker = manager.resolveAppleAudioConfigurationForTest(
        const AudioSessionOptions.communication(preferSpeakerOutput: true),
      );

      expect(speaker.appleAudioCategory, AppleAudioCategory.playAndRecord);
      expect(speaker.appleAudioMode, AppleAudioMode.videoChat);
      expect(
        speaker.appleAudioCategoryOptions,
        {
          AppleAudioCategoryOption.allowBluetooth,
          AppleAudioCategoryOption.allowBluetoothA2DP,
          AppleAudioCategoryOption.allowAirPlay,
        },
      );

      final receiver = manager.resolveAppleAudioConfigurationForTest(
        const AudioSessionOptions.communication(preferSpeakerOutput: false),
      );

      expect(receiver.appleAudioCategory, AppleAudioCategory.playAndRecord);
      expect(receiver.appleAudioMode, AppleAudioMode.voiceChat);
    });

    test('resolves media Apple session policy as dynamic playAndRecord base', () {
      final config = AudioManager.instance.resolveAppleAudioConfigurationForTest(
        const AudioSessionOptions.media(),
      );

      expect(config.appleAudioCategory, AppleAudioCategory.playAndRecord);
      expect(config.appleAudioMode, AppleAudioMode.default_);
      expect(
        config.appleAudioCategoryOptions,
        {
          AppleAudioCategoryOption.mixWithOthers,
          AppleAudioCategoryOption.allowBluetooth,
          AppleAudioCategoryOption.allowBluetoothA2DP,
          AppleAudioCategoryOption.allowAirPlay,
        },
      );
    });

    test('forced speaker does not mutate Apple category options', () {
      final manager = AudioManager.instance;

      final playback = manager.resolveAppleAudioConfigurationForTest(
        const AudioSessionOptions.media(
          apple: AppleAudioSessionConfiguration(
            category: AppleAudioCategory.playback,
            categoryOptions: {AppleAudioCategoryOption.mixWithOthers},
          ),
        ),
        forceSpeakerOutput: true,
      );

      expect(playback.appleAudioCategory, AppleAudioCategory.playback);
      expect(playback.appleAudioCategoryOptions, {AppleAudioCategoryOption.mixWithOthers});

      final playAndRecord = manager.resolveAppleAudioConfigurationForTest(
        const AudioSessionOptions.communication(
          apple: AppleAudioSessionConfiguration(
            category: AppleAudioCategory.playAndRecord,
            categoryOptions: {AppleAudioCategoryOption.allowBluetooth},
          ),
        ),
        forceSpeakerOutput: true,
      );

      expect(playAndRecord.appleAudioCategory, AppleAudioCategory.playAndRecord);
      expect(
        playAndRecord.appleAudioCategoryOptions,
        {AppleAudioCategoryOption.allowBluetooth},
      );
    });

    test('resolves Android session policy from preset or explicit override', () {
      final manager = AudioManager.instance;

      final communication = manager.resolveAndroidAudioConfigurationForTest(
        const AudioSessionOptions.communication(),
      );

      expect(communication.audioMode, AndroidAudioMode.inCommunication);
      expect(communication.streamType, AndroidAudioStreamType.voiceCall);

      final media = manager.resolveAndroidAudioConfigurationForTest(
        const AudioSessionOptions.media(),
      );

      expect(media.audioMode, AndroidAudioMode.normal);
      expect(media.streamType, AndroidAudioStreamType.music);

      final explicit = manager.resolveAndroidAudioConfigurationForTest(
        const AudioSessionOptions.communication(
          android: AndroidAudioSessionConfiguration(
            audioMode: AndroidAudioMode.normal,
            forceAudioRouting: true,
          ),
        ),
      );

      expect(explicit.audioMode, AndroidAudioMode.normal);
      expect(explicit.forceAudioRouting, isTrue);
    });

    test('Android initialize configuration uses active runtime options', () async {
      final manager = AudioManager.instance;

      await manager.setAudioSessionOptions(const AudioSessionOptions.communication());
      manager.configureDefaults(bypassVoiceProcessing: true);
      Native.bypassVoiceProcessing = true;

      expect(
        manager.androidAudioConfigurationForInitialize(assumeAndroid: true),
        containsPair('androidAudioMode', 'inCommunication'),
      );
    });

    test('handleAudioEngineState updates snapshot and stream', () async {
      final manager = AudioManager.instance;
      final states = <AudioEngineState>[];
      final subscription = manager.audioEngineStateStream.listen(states.add);

      manager.handleAudioEngineState(
        isPlayoutEnabled: true,
        isRecordingEnabled: false,
      );
      await pumpEventQueue();

      expect(
        manager.audioEngineState,
        const AudioEngineState(isPlayoutEnabled: true, isRecordingEnabled: false),
      );
      expect(states, [const AudioEngineState(isPlayoutEnabled: true, isRecordingEnabled: false)]);

      manager.handleAudioEngineState(
        isPlayoutEnabled: true,
        isRecordingEnabled: false,
      );
      await pumpEventQueue();

      expect(states, [const AudioEngineState(isPlayoutEnabled: true, isRecordingEnabled: false)]);

      manager.handleAudioEngineState(
        isPlayoutEnabled: false,
        isRecordingEnabled: false,
      );
      await pumpEventQueue();

      expect(manager.audioEngineState.isIdle, isTrue);
      expect(
        states,
        [
          const AudioEngineState(isPlayoutEnabled: true, isRecordingEnabled: false),
          const AudioEngineState(isPlayoutEnabled: false, isRecordingEnabled: false),
        ],
      );

      await subscription.cancel();
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

  group('NativeAudioConfiguration', () {
    test('serializes Apple audio wire format', () {
      final map = native_audio.NativeAudioConfiguration(
        appleAudioCategory: AppleAudioCategory.playAndRecord,
        appleAudioCategoryOptions: {
          AppleAudioCategoryOption.allowBluetooth,
          AppleAudioCategoryOption.defaultToSpeaker,
        },
        appleAudioMode: AppleAudioMode.default_,
      ).toMap();

      expect(map['appleAudioCategory'], 'playAndRecord');
      expect(
        map['appleAudioCategoryOptions'],
        unorderedEquals([
          'allowBluetooth',
          'defaultToSpeaker',
        ]),
      );
      expect(map['appleAudioMode'], 'default');
      expect(map.containsKey('preferSpeakerOutput'), isFalse);
    });
  });

  group('Native audio channel', () {
    late List<MethodCall> calls;

    setUp(() {
      calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        Native.channel,
        (call) async {
          calls.add(call);
          return call.method == 'configureNativeAudio' ? true : null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        Native.channel,
        null,
      );
    });

    test('passes forced speaker routing to platform methods', () async {
      await Native.setAndroidSpeakerphoneOn(true, force: true);
      await Native.setAppleSpeakerphoneOn(true, force: false);

      expect(calls[0].method, 'setAndroidSpeakerphoneOn');
      expect(calls[0].arguments, {'enable': true, 'force': true});
      expect(calls[1].method, 'setAppleSpeakerphoneOn');
      expect(calls[1].arguments, {'enable': true, 'force': false});
    });

    test('passes forced speaker routing to automatic Apple configuration', () async {
      final result = await Native.configureAudio(
        native_audio.NativeAudioConfiguration(
          appleAudioCategory: AppleAudioCategory.playAndRecord,
          appleAudioMode: AppleAudioMode.videoChat,
        ),
        automatic: true,
        selectCategoryByEngineState: true,
        forceSpeakerOutput: true,
      );

      expect(result, isTrue);
      expect(calls.single.method, 'configureNativeAudio');
      expect(
        calls.single.arguments,
        containsPair('forceSpeakerOutput', true),
      );
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
