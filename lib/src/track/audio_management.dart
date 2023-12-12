// Copyright 2023 LiveKit, Inc.
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

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:synchronized/synchronized.dart' as sync;

import '../hardware/hardware.dart';
import '../logger.dart';
import '../support/native.dart';
import '../support/native_audio.dart';
import '../support/platform.dart';
import 'local/local.dart';
import 'remote/remote.dart';

enum AudioTrackState {
  none,
  remoteOnly,
  localOnly,
  localAndRemote,
}

typedef ConfigureNativeAudioFunc = Future<NativeAudioConfiguration> Function(
    AudioTrackState state);

// it's possible to set custom function here to customize audio session configuration
ConfigureNativeAudioFunc onConfigureNativeAudio =
    defaultNativeAudioConfigurationFunc;

final _trackCounterLock = sync.Lock();
AudioTrackState _audioTrackState = AudioTrackState.none;

AudioTrackState get audioTrackState => _audioTrackState;

int _localTrackCount = 0;
int _remoteTrackCount = 0;

mixin LocalAudioManagementMixin on LocalTrack, AudioTrack {
  @override
  Future<bool> onPublish() async {
    final didUpdate = await super.onPublish();
    if (didUpdate) {
      // update counter
      await _trackCounterLock.synchronized(() async {
        _localTrackCount++;
        await _onAudioTrackCountDidChange();
      });
    }
    return didUpdate;
  }

  @override
  Future<bool> onUnpublish() async {
    final didUpdate = await super.onUnpublish();
    if (didUpdate) {
      // update counter
      await _trackCounterLock.synchronized(() async {
        _localTrackCount--;
        await _onAudioTrackCountDidChange();
      });
    }
    return didUpdate;
  }
}
mixin RemoteAudioManagementMixin on RemoteTrack, AudioTrack {
  /// Start playing audio track. On web platform, create an audio element and
  /// start playback
  @override
  Future<bool> start() async {
    final didStart = await super.start();
    if (didStart) {
      await _trackCounterLock.synchronized(() async {
        _remoteTrackCount++;
        await _onAudioTrackCountDidChange();
      });
    }
    return didStart;
  }

  @override
  Future<bool> stop() async {
    final didStop = await super.stop();
    if (didStop) {
      await _trackCounterLock.synchronized(() async {
        _remoteTrackCount--;
        await _onAudioTrackCountDidChange();
      });
    }
    return didStop;
  }
}

Future<void> _onAudioTrackCountDidChange() async {
  logger.fine('onAudioTrackCountDidChange: '
      'local: $_localTrackCount, remote: $_remoteTrackCount');

  final newState = _computeAudioTrackState();

  if (_audioTrackState != newState) {
    _audioTrackState = newState;
    logger.fine('didUpdateSate: $_audioTrackState');

    NativeAudioConfiguration? config;
    if (lkPlatformIs(PlatformType.iOS)) {
      // Only iOS for now...
      config = await onConfigureNativeAudio.call(_audioTrackState);
    }

    if (config != null) {
      logger.fine('configuring for ${_audioTrackState} using ${config}...');
      try {
        await Native.configureAudio(config);
      } catch (error) {
        logger.warning('failed to configure ${error}');
      }
    }

    if (lkPlatformIs(PlatformType.iOS)) {
      if (Hardware.instance.speakerOn != null &&
          Hardware.instance.canSwitchSpeakerphone) {
        await rtc.Helper.setSpeakerphoneOn(Hardware.instance.speakerOn!);
      }
    }
  }
}

AudioTrackState _computeAudioTrackState() {
  if (_localTrackCount > 0 && _remoteTrackCount == 0) {
    return AudioTrackState.localOnly;
  } else if (_localTrackCount == 0 && _remoteTrackCount > 0) {
    return AudioTrackState.remoteOnly;
  } else if (_localTrackCount > 0 && _remoteTrackCount > 0) {
    return AudioTrackState.localAndRemote;
  }
  // Default
  return AudioTrackState.none;
}

Future<NativeAudioConfiguration> defaultNativeAudioConfigurationFunc(
    AudioTrackState state) async {
  //
  if (state == AudioTrackState.remoteOnly) {
    return NativeAudioConfiguration(
      appleAudioCategory: AppleAudioCategory.playback,
      appleAudioCategoryOptions: {
        AppleAudioCategoryOption.mixWithOthers,
      },
      appleAudioMode: AppleAudioMode.spokenAudio,
    );
  } else if ([
    AudioTrackState.localOnly,
    AudioTrackState.localAndRemote,
  ].contains(state)) {
    return NativeAudioConfiguration(
      appleAudioCategory: AppleAudioCategory.playAndRecord,
      appleAudioCategoryOptions: {
        AppleAudioCategoryOption.allowBluetooth,
        AppleAudioCategoryOption.mixWithOthers,
      },
      appleAudioMode: Hardware.instance.preferSpeakerOutput
          ? AppleAudioMode.videoChat
          : AppleAudioMode.voiceChat,
    );
  }

  return NativeAudioConfiguration(
    appleAudioCategory: AppleAudioCategory.soloAmbient,
    appleAudioCategoryOptions: {},
    appleAudioMode: AppleAudioMode.default_,
  );
}
