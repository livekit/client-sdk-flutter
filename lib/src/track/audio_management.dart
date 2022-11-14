import 'package:synchronized/synchronized.dart' as sync;

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

  Future<void> onTrackStopped() async {
    await _trackCounterLock.synchronized(() async {
      _localTrackCount--;
      await _onAudioTrackCountDidChange();
    });
  }

  Future<void> onTrackStarted() async {
    await _trackCounterLock.synchronized(() async {
      _localTrackCount++;
      await _onAudioTrackCountDidChange();
    });
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
      appleAudioMode: AppleAudioMode.videoChat,
    );
  }

  return NativeAudioConfiguration(
    appleAudioCategory: AppleAudioCategory.soloAmbient,
    appleAudioCategoryOptions: {},
    appleAudioMode: AppleAudioMode.default_,
  );
}
