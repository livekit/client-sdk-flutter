import 'package:synchronized/synchronized.dart' as sync;

import '../logger.dart';
import '../support/native.dart';
import '../support/native_audio.dart';
import '../support/platform.dart';
import 'local/audio.dart';
import 'local/local.dart';

enum AudioTrackState {
  none,
  remoteOnly,
  localOnly,
  localAndRemote,
}

typedef ConfigureNativeAudioFunc = Future<NativeAudioConfiguration> Function(
    AudioTrackState state);

mixin AudioManagementMixin on AudioTrack {
  // it's possible to set custom function here to customize audio session configuration
  static ConfigureNativeAudioFunc nativeAudioConfigurationForAudioTrackState =
      defaultNativeAudioConfigurationFunc;

  static final _trackCounterLock = sync.Lock();
  static AudioTrackState audioTrackState = AudioTrackState.none;
  static int _localTrackCount = 0;
  static int _remoteTrackCount = 0;

  /// Start playing audio track. On web platform, create an audio element and
  /// start playback
  @override
  Future<bool> start() async {
    final didStart = await super.start();
    if (didStart) {
      // update counter
      await _trackCounterLock.synchronized(() async {
        if (this is LocalAudioTrack) {
          _localTrackCount++;
        } else if (this is! LocalAudioTrack) {
          _remoteTrackCount++;
        }
        await _onAudioTrackCountDidChange();
      });
    }
    return didStart;
  }

  @override
  Future<bool> stop() async {
    final didStop = await super.stop();
    if (didStop) {
      // update counter
      await _trackCounterLock.synchronized(() async {
        if (this is LocalAudioTrack) {
          _localTrackCount--;
        } else if (this is! LocalAudioTrack) {
          _remoteTrackCount--;
        }
        await _onAudioTrackCountDidChange();
      });
    }
    return didStop;
  }

  Future<void> _onAudioTrackCountDidChange() async {
    logger.fine('[$runtimeType] onAudioTrackCountDidChange: '
        'local: $_localTrackCount, remote: $_remoteTrackCount');

    final newState = _computeAudioTrackState();

    if (audioTrackState != newState) {
      audioTrackState = newState;
      logger.fine('[$runtimeType] didUpdateSate: $audioTrackState');

      NativeAudioConfiguration? config;
      if (lkPlatformIs(PlatformType.iOS)) {
        // Only iOS for now...
        config = await nativeAudioConfigurationForAudioTrackState
            .call(audioTrackState);
      }

      if (config != null) {
        logger.fine(
            '[$runtimeType] configuring for ${audioTrackState} using ${config}...');
        try {
          await Native.configureAudio(config);
        } catch (error) {
          logger.warning('[$runtimeType] Failed to configure ${error}');
        }
      }
    }
  }

  static AudioTrackState _computeAudioTrackState() {
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
      appleAudioMode: AppleAudioMode.videoChat,
    );
  }

  return NativeAudioConfiguration(
    appleAudioCategory: AppleAudioCategory.soloAmbient,
    appleAudioCategoryOptions: {},
    appleAudioMode: AppleAudioMode.default_,
  );
}
