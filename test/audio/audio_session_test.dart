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
import 'package:livekit_client/src/audio/audio_session_policy.dart';
import 'package:livekit_client/src/support/native.dart';
import 'package:livekit_client/src/support/native_audio.dart' as native_audio;
import 'package:livekit_client/src/support/webrtc_initialize_options.dart';
import 'package:livekit_client/src/track/options.dart' as track_options;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AudioManager.instance.resetForTest();
    Native.bypassVoiceProcessing = false;
  });

  native_audio.NativeAudioConfiguration resolveApplePolicy(
    AudioSessionOptions options, {
    bool preferSpeakerOutput = true,
    bool forceSpeakerOutput = false,
    bool automatic = true,
  }) =>
      ResolvedAudioSessionPolicy(
        options: options,
        preferSpeakerOutput: preferSpeakerOutput,
        forceSpeakerOutput: forceSpeakerOutput && preferSpeakerOutput,
        automatic: automatic,
      ).appleConfiguration;

  AndroidAudioSessionConfiguration resolveAndroidPolicy(
    AudioSessionOptions options, {
    bool automatic = true,
  }) =>
      ResolvedAudioSessionPolicy(
        options: options,
        preferSpeakerOutput: AudioManager.instance.isSpeakerOutputPreferred,
        forceSpeakerOutput: AudioManager.instance.isSpeakerOutputForced,
        automatic: automatic,
      ).androidConfiguration;

  group('AudioSessionManagementMode', () {
    test('supports automatic, manual, and external call system management', () {
      expect(
        AudioSessionManagementMode.values,
        [
          AudioSessionManagementMode.automatic,
          AudioSessionManagementMode.manual,
          AudioSessionManagementMode.externalCallSystem,
        ],
      );
    });
  });

  group('AudioSessionOptions', () {
    test('communication constructor pre-fills platform configs', () {
      const options = AudioSessionOptions.communication();

      expect(options.apple.category, AppleAudioCategory.playAndRecord);
      expect(
        options.apple.categoryOptions,
        {
          AppleAudioCategoryOption.allowBluetooth,
          AppleAudioCategoryOption.allowBluetoothA2DP,
          AppleAudioCategoryOption.allowAirPlay,
        },
      );
      expect(options.apple.mode, AppleAudioMode.videoChat);
      expect(options.android.audioMode, AndroidAudioMode.inCommunication);
      expect(options.android.streamType, AndroidAudioStreamType.voiceCall);
    });

    test('mediaPlayback constructor pre-fills platform configs', () {
      const options = AudioSessionOptions.mediaPlayback();

      expect(options.apple.category, AppleAudioCategory.playback);
      expect(options.apple.categoryOptions, {AppleAudioCategoryOption.mixWithOthers});
      expect(options.apple.mode, AppleAudioMode.spokenAudio);
      expect(options.android.audioMode, AndroidAudioMode.normal);
      expect(options.android.streamType, AndroidAudioStreamType.music);
      expect(options.android.forceAudioRouting, isNull);
    });

    test('copyWith replaces platform configs', () {
      const options = AudioSessionOptions.communication();

      final updated = options.copyWith(
        apple: const ValueOrAbsent.value(
          AppleAudioSessionConfiguration(
            mode: AppleAudioMode.voiceChat,
          ),
        ),
      );

      expect(updated.apple.category, isNull);
      expect(updated.apple.mode, AppleAudioMode.voiceChat);
      expect(updated.android.audioMode, AndroidAudioMode.inCommunication);

      final restored = updated.copyWith(
        apple: const ValueOrAbsent.value(AppleAudioSessionConfiguration.communication),
        android: const ValueOrAbsent.value(AndroidAudioSessionConfiguration.communication),
      );

      expect(restored.apple.category, AppleAudioCategory.playAndRecord);
      expect(restored.apple.mode, AppleAudioMode.videoChat);
      expect(restored.android.audioMode, AndroidAudioMode.inCommunication);
    });

    test('Apple configuration copyWith updates and clears nullable fields', () {
      const config = AppleAudioSessionConfiguration(
        category: AppleAudioCategory.playAndRecord,
        categoryOptions: {AppleAudioCategoryOption.allowBluetooth},
        mode: AppleAudioMode.voiceChat,
      );

      final updated = config.copyWith(
        category: const ValueOrAbsent.value(AppleAudioCategory.playback),
        categoryOptions: const ValueOrAbsent.value({AppleAudioCategoryOption.mixWithOthers}),
        mode: const ValueOrAbsent.value(AppleAudioMode.spokenAudio),
      );

      expect(updated.category, AppleAudioCategory.playback);
      expect(updated.categoryOptions, {AppleAudioCategoryOption.mixWithOthers});
      expect(updated.mode, AppleAudioMode.spokenAudio);

      final cleared = updated.copyWith(
        category: const ValueOrAbsent.value(null),
        categoryOptions: const ValueOrAbsent.value(null),
        mode: const ValueOrAbsent.value(null),
      );

      expect(cleared.category, isNull);
      expect(cleared.categoryOptions, isNull);
      expect(cleared.mode, isNull);
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
        audioMode: const ValueOrAbsent.value(AndroidAudioMode.normal),
        manageAudioFocus: const ValueOrAbsent.value(false),
        focusMode: const ValueOrAbsent.value(AndroidAudioFocusMode.gainTransient),
        streamType: const ValueOrAbsent.value(AndroidAudioStreamType.music),
        usageType: const ValueOrAbsent.value(AndroidAudioAttributesUsageType.media),
        contentType: const ValueOrAbsent.value(AndroidAudioAttributesContentType.unknown),
        forceAudioRouting: const ValueOrAbsent.value(false),
      );

      expect(updated.audioMode, AndroidAudioMode.normal);
      expect(updated.manageAudioFocus, isFalse);
      expect(updated.focusMode, AndroidAudioFocusMode.gainTransient);
      expect(updated.streamType, AndroidAudioStreamType.music);
      expect(updated.usageType, AndroidAudioAttributesUsageType.media);
      expect(updated.contentType, AndroidAudioAttributesContentType.unknown);
      expect(updated.forceAudioRouting, isFalse);

      final cleared = updated.copyWith(
        audioMode: const ValueOrAbsent.value(null),
        manageAudioFocus: const ValueOrAbsent.value(null),
        focusMode: const ValueOrAbsent.value(null),
        streamType: const ValueOrAbsent.value(null),
        usageType: const ValueOrAbsent.value(null),
        contentType: const ValueOrAbsent.value(null),
        forceAudioRouting: const ValueOrAbsent.value(null),
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

  group('AudioProcessingException', () {
    test('uses fallback messages when native omits details', () {
      final invalid = track_options.AudioProcessingException(
        track_options.AudioProcessingFailureReason.invalidCombination,
        '',
      );
      final platformUnavailable = track_options.AudioProcessingException(
        track_options.AudioProcessingFailureReason.platformUnavailable,
        '  ',
      );
      final applyFailed = track_options.AudioProcessingException(
        track_options.AudioProcessingFailureReason.applyFailed,
        '',
      );
      final unknown = track_options.AudioProcessingException(
        track_options.AudioProcessingFailureReason.unknown,
        '',
      );

      expect(invalid.message, 'The requested audio processing mode combination is invalid.');
      expect(platformUnavailable.message, 'Audio processing options are unavailable on this platform or device.');
      expect(
        applyFailed.message,
        'The native WebRTC audio processing module could not apply the requested options.',
      );
      expect(unknown.message, 'Audio processing options failed for an unknown reason.');
    });

    test('preserves native messages when provided', () {
      final error = track_options.AudioProcessingException(
        track_options.AudioProcessingFailureReason.applyFailed,
        '  native detail  ',
      );

      expect(error.reason, track_options.AudioProcessingFailureReason.applyFailed);
      expect(error.message, 'native detail');
      expect(error.toString(), 'AudioProcessingException(applyFailed): native detail');
    });

    test('exposes unknown failure reason', () {
      expect(
        track_options.AudioProcessingFailureReason.values,
        contains(track_options.AudioProcessingFailureReason.unknown),
      );
    });
  });

  group('AudioManager', () {
    test('management mode can be set independently from options', () async {
      final manager = AudioManager.instance;

      await manager.setAudioSessionManagementMode(AudioSessionManagementMode.manual);

      expect(manager.managementMode, AudioSessionManagementMode.manual);
      expect(manager.options.android.audioMode, AndroidAudioMode.inCommunication);

      await manager.setAudioSessionManagementMode(AudioSessionManagementMode.automatic);
    });

    test('setAudioSessionOptions switches management to manual', () async {
      final manager = AudioManager.instance;
      expect(manager.managementMode, AudioSessionManagementMode.automatic);

      await manager.setAudioSessionOptions(const AudioSessionOptions.mediaPlayback());

      expect(manager.managementMode, AudioSessionManagementMode.manual);
      expect(manager.options.apple.category, AppleAudioCategory.playback);
      expect(manager.options.android.streamType, AndroidAudioStreamType.music);
    });

    test('setInitialAudioSessionOptions seeds options without switching to manual', () {
      final manager = AudioManager.instance;

      manager.setInitialAudioSessionOptions(const AudioSessionOptions.mediaPlayback());

      expect(manager.managementMode, AudioSessionManagementMode.automatic);
      expect(manager.options.android.streamType, AndroidAudioStreamType.music);

      final android = resolveAndroidPolicy(manager.options);
      expect(android.audioMode, AndroidAudioMode.normal);
      expect(android.streamType, AndroidAudioStreamType.music);
    });

    test('setInitialAudioSessionOptions does not replace manual options', () async {
      final manager = AudioManager.instance;
      await manager.setAudioSessionOptions(const AudioSessionOptions.communication());

      manager.setInitialAudioSessionOptions(const AudioSessionOptions.mediaPlayback());

      expect(manager.managementMode, AudioSessionManagementMode.manual);
      expect(manager.options.android.streamType, AndroidAudioStreamType.voiceCall);
    });

    test('deactivateAudioSession switches management to manual', () async {
      final manager = AudioManager.instance;
      expect(manager.managementMode, AudioSessionManagementMode.automatic);

      await manager.deactivateAudioSession();

      expect(manager.managementMode, AudioSessionManagementMode.manual);
    });

    test('setAudioSessionOptions preserves the runtime speaker preference', () async {
      final manager = AudioManager.instance;

      // The speaker preference is runtime state owned by
      // setSpeakerOutputPreferred, so changing the session intent must not reset
      // it.
      expect(manager.isSpeakerOutputPreferred, isTrue);

      await manager.setAudioSessionOptions(
        const AudioSessionOptions.mediaPlayback(),
      );
      expect(manager.isSpeakerOutputPreferred, isTrue);

      await manager.setAudioSessionOptions(
        const AudioSessionOptions.communication(),
      );
      expect(manager.isSpeakerOutputPreferred, isTrue);
    });

    test('resolves communication Apple session policy from speaker preference', () {
      final speaker = resolveApplePolicy(
        const AudioSessionOptions.communication(),
        preferSpeakerOutput: true,
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

      final receiver = resolveApplePolicy(
        const AudioSessionOptions.communication(),
        preferSpeakerOutput: false,
      );

      expect(receiver.appleAudioCategory, AppleAudioCategory.playAndRecord);
      expect(receiver.appleAudioMode, AppleAudioMode.voiceChat);
    });

    test('automatic Apple policy ignores manual media options', () {
      final config = resolveApplePolicy(
        const AudioSessionOptions.mediaPlayback(),
      );

      expect(config.appleAudioCategory, AppleAudioCategory.playAndRecord);
      expect(config.appleAudioMode, AppleAudioMode.videoChat);
      expect(
        config.appleAudioCategoryOptions,
        {
          AppleAudioCategoryOption.allowBluetooth,
          AppleAudioCategoryOption.allowBluetoothA2DP,
          AppleAudioCategoryOption.allowAirPlay,
        },
      );
    });

    test('resolves manual media Apple session policy as fixed playback', () {
      final config = resolveApplePolicy(
        const AudioSessionOptions.mediaPlayback(),
        automatic: false,
      );

      expect(config.appleAudioCategory, AppleAudioCategory.playback);
      expect(config.appleAudioMode, AppleAudioMode.spokenAudio);
      expect(config.appleAudioCategoryOptions, {AppleAudioCategoryOption.mixWithOthers});
    });

    test('forced speaker does not mutate Apple category options', () {
      final playback = resolveApplePolicy(
        const AudioSessionOptions.mediaPlayback(
          apple: AppleAudioSessionConfiguration(
            category: AppleAudioCategory.playback,
            categoryOptions: {AppleAudioCategoryOption.mixWithOthers},
          ),
        ),
        automatic: false,
        forceSpeakerOutput: true,
      );

      expect(playback.appleAudioCategory, AppleAudioCategory.playback);
      expect(playback.appleAudioCategoryOptions, {AppleAudioCategoryOption.mixWithOthers});

      final playAndRecord = resolveApplePolicy(
        const AudioSessionOptions.communication(
          apple: AppleAudioSessionConfiguration(
            category: AppleAudioCategory.playAndRecord,
            categoryOptions: {AppleAudioCategoryOption.allowBluetooth},
          ),
        ),
        automatic: false,
        forceSpeakerOutput: true,
      );

      expect(playAndRecord.appleAudioCategory, AppleAudioCategory.playAndRecord);
      expect(
        playAndRecord.appleAudioCategoryOptions,
        {AppleAudioCategoryOption.allowBluetooth},
      );
    });

    test('resolves Android session policy from current options', () {
      final automaticMedia = resolveAndroidPolicy(
        const AudioSessionOptions.mediaPlayback(),
      );

      expect(automaticMedia.audioMode, AndroidAudioMode.normal);
      expect(automaticMedia.streamType, AndroidAudioStreamType.music);

      final media = resolveAndroidPolicy(
        const AudioSessionOptions.mediaPlayback(),
        automatic: false,
      );

      expect(media.audioMode, AndroidAudioMode.normal);
      expect(media.streamType, AndroidAudioStreamType.music);

      final explicit = resolveAndroidPolicy(
        const AudioSessionOptions.communication(
          android: AndroidAudioSessionConfiguration(
            audioMode: AndroidAudioMode.normal,
            forceAudioRouting: true,
          ),
        ),
        automatic: false,
      );

      expect(explicit.audioMode, AndroidAudioMode.normal);
      expect(explicit.forceAudioRouting, isTrue);
    });

    test('automatic Apple policy ignores stored options while Android uses them', () async {
      final manager = AudioManager.instance;

      await manager.setAudioSessionOptions(const AudioSessionOptions.mediaPlayback());
      await manager.setAudioSessionManagementMode(AudioSessionManagementMode.automatic);

      final isAutomatic = manager.managementMode == AudioSessionManagementMode.automatic;
      final apple = resolveApplePolicy(
        manager.options,
        automatic: isAutomatic,
        preferSpeakerOutput: false,
      );
      final android = resolveAndroidPolicy(
        manager.options,
        automatic: isAutomatic,
      );

      expect(apple.appleAudioCategory, AppleAudioCategory.playAndRecord);
      expect(apple.appleAudioMode, AppleAudioMode.voiceChat);
      expect(
        apple.appleAudioCategoryOptions,
        {
          AppleAudioCategoryOption.allowBluetooth,
          AppleAudioCategoryOption.allowBluetoothA2DP,
          AppleAudioCategoryOption.allowAirPlay,
        },
      );
      expect(android.audioMode, AndroidAudioMode.normal);
      expect(android.streamType, AndroidAudioStreamType.music);
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
      expect(config.forceAudioRouting, isNull);
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

    test('passes forced speaker routing to Android platform method', () async {
      await Native.setAndroidSpeakerphoneOn(true, force: true);

      expect(calls.single.method, 'setAndroidSpeakerphoneOn');
      expect(calls.single.arguments, {'enable': true, 'force': true});
    });

    test('passes microphone mute mode to platform method', () async {
      await Native.setMicrophoneMuteMode('inputMixer');

      expect(calls.single.method, 'setMicrophoneMuteMode');
      expect(calls.single.arguments, {'mode': 'inputMixer'});
    });

    test('passes session activation ownership to Apple management method', () async {
      await Native.setAppleAudioSessionAutomaticManagementEnabled(true, sessionActivationEnabled: false);

      expect(calls.single.method, 'setAppleAudioSessionAutomaticManagementEnabled');
      expect(calls.single.arguments, {'enabled': true, 'sessionActivationEnabled': false});
    });

    test('passes engine availability to platform method', () async {
      await Native.setEngineAvailability(isInputAvailable: false, isOutputAvailable: true);

      expect(calls.single.method, 'setEngineAvailability');
      expect(calls.single.arguments, {'isInputAvailable': false, 'isOutputAvailable': true});
    });

    test('initial session options seed under an external call system', () async {
      AudioManager.instance.resetForTest();
      await AudioManager.instance.setAudioSessionManagementMode(AudioSessionManagementMode.externalCallSystem);

      const options = AudioSessionOptions.mediaPlayback();
      AudioManager.instance.setInitialAudioSessionOptions(options);

      expect(AudioManager.instance.options, options);

      AudioManager.instance.resetForTest();
    });

    test('deactivateAudioSession is a no-op under an external call system', () async {
      AudioManager.instance.resetForTest();
      await AudioManager.instance.setAudioSessionManagementMode(AudioSessionManagementMode.externalCallSystem);
      calls.clear();

      await AudioManager.instance.deactivateAudioSession();

      expect(calls, isEmpty);
      expect(AudioManager.instance.managementMode, AudioSessionManagementMode.externalCallSystem);

      AudioManager.instance.resetForTest();
    });

    test('passes audio session deactivation to platform methods', () async {
      await Native.stopAndroidAudioSession();
      await Native.deactivateAppleAudioSession();

      expect(calls[0].method, 'stopAndroidAudioSession');
      expect(calls[0].arguments, isNull);
      expect(calls[1].method, 'deactivateAppleAudioSession');
      expect(calls[1].arguments, <String, dynamic>{});
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

    test('returns platform unavailable when audio processing channel is missing', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        Native.channel,
        null,
      );

      final result = await Native.setAudioProcessingOptions(
        'track-id',
        <String, dynamic>{'echoCancellation': true},
      );

      expect(
        result,
        {
          'result': false,
          'code': 'rejectedPlatformUnavailable',
          'message': 'Audio processing options are unavailable on this platform.',
        },
      );
    });

    test('returns platform unavailable when audio processing method is unimplemented', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        Native.channel,
        (call) async {
          calls.add(call);
          throw PlatformException(
            code: 'Unimplemented',
            details: 'livekit for web does not implement ${call.method}',
          );
        },
      );

      final result = await Native.setAudioProcessingOptions(
        'track-id',
        <String, dynamic>{'echoCancellation': true},
      );

      expect(calls.single.method, 'setAudioProcessingOptions');
      expect(calls.single.arguments, containsPair('trackId', 'track-id'));
      expect(
        result,
        {
          'result': false,
          'code': 'rejectedPlatformUnavailable',
          'message': 'Audio processing options are unavailable on this platform.',
        },
      );
    });

    test('propagates other audio processing channel failures', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        Native.channel,
        (call) async {
          throw PlatformException(code: 'nativeFailure', message: 'boom');
        },
      );

      await expectLater(
        Native.setAudioProcessingOptions(
          'track-id',
          <String, dynamic>{'echoCancellation': true},
        ),
        throwsA(isA<PlatformException>().having((error) => error.code, 'code', 'nativeFailure')),
      );
    });

    test('throws platform unavailable when startLocalRecording channel is missing', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        Native.channel,
        null,
      );

      await expectLater(
        Native.startLocalRecording(<String, dynamic>{'echoCancellation': true}),
        throwsA(isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'rejectedPlatformUnavailable',
        )),
      );
    });

    test('throws platform unavailable when startLocalRecording is unimplemented', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        Native.channel,
        (call) async {
          calls.add(call);
          throw PlatformException(code: 'Unimplemented');
        },
      );

      await expectLater(
        Native.startLocalRecording(<String, dynamic>{'echoCancellation': true}),
        throwsA(isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'rejectedPlatformUnavailable',
        )),
      );
      expect(calls.single.method, 'startLocalRecording');
    });

    test('ignores stopLocalRecording platform failures', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        Native.channel,
        (call) async {
          calls.add(call);
          throw PlatformException(code: 'nativeFailure', message: 'boom');
        },
      );

      await Native.stopLocalRecording();

      expect(calls.single.method, 'stopLocalRecording');
    });

    test('ignores stopLocalRecording missing plugin', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        Native.channel,
        null,
      );

      await Native.stopLocalRecording();
    });
  });

  group('androidAudioSessionConfigurationToMap', () {
    test('serializes communication preset for the native session manager', () {
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

    test('serializes media preset without forced routing', () {
      expect(
        androidAudioSessionConfigurationToMap(AndroidAudioSessionConfiguration.media),
        {
          'manageAudioFocus': true,
          'androidAudioMode': 'normal',
          'androidAudioFocusMode': 'gain',
          'androidAudioStreamType': 'music',
          'androidAudioAttributesUsageType': 'media',
          'androidAudioAttributesContentType': 'unknown',
        },
      );
    });
  });

  group('liveKitWebRTCInitializeOptions', () {
    test('includes Android audio configuration for Android startup', () {
      expect(
        liveKitWebRTCInitializeOptions(
          bypassVoiceProcessing: true,
          initialAudioSessionOptions: const AudioSessionOptions.mediaPlayback(),
          includeAndroidAudioConfiguration: true,
        ),
        {
          'bypassVoiceProcessing': true,
          'androidAudioConfiguration': {
            'manageAudioFocus': true,
            'androidAudioMode': 'normal',
            'androidAudioFocusMode': 'gain',
            'androidAudioStreamType': 'music',
            'androidAudioAttributesUsageType': 'media',
            'androidAudioAttributesContentType': 'unknown',
          },
        },
      );
    });

    test('omits Android audio configuration on non-Android startup', () {
      expect(
        liveKitWebRTCInitializeOptions(
          bypassVoiceProcessing: false,
          initialAudioSessionOptions: const AudioSessionOptions.mediaPlayback(),
          includeAndroidAudioConfiguration: false,
        ),
        isEmpty,
      );
    });
  });
}
