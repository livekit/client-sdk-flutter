// import 'package:audio_session/audio_session.dart' as _as;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:synchronized/synchronized.dart' as sync;

import '../logger.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../support/native_audio.dart';
import '_audio_api.dart' if (dart.library.html) '_audio_html.dart' as audio;
import 'local_audio_track.dart';
import 'track.dart';

enum AudioTrackState {
  none,
  remoteOnly,
  localOnly,
  localAndRemote,
}

typedef ConfigureNativeAudioFunc = Future<NativeAudioConfiguration> Function(AudioTrackState state);

class AudioTrack extends Track {
  // it's possible to set custom function here to customize audio session configuration
  static ConfigureNativeAudioFunc nativeAudioConfigurationForAudioTrackState =
      defaultNativeAudioConfigurationFunc;

  static final _trackCounterLock = sync.Lock();
  static AudioTrackState audioTrackState = AudioTrackState.none;
  static int _localTrackCount = 0;
  static int _remoteTrackCount = 0;

  rtc.MediaStream? mediaStream;

  AudioTrack(
    String name,
    rtc.MediaStreamTrack track,
    this.mediaStream,
  ) : super(
          lk_models.TrackType.AUDIO,
          name,
          track,
        );

  /// Start playing audio track. On web platform, create an audio element and
  /// start playback
  @override
  Future<bool> start() async {
    final didStart = await super.start();
    if (didStart) {
      if (this is! LocalAudioTrack) {
        audio.startAudio(getCid(), mediaStreamTrack);
      }

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
      await mediaStream?.dispose();
      mediaStream = null;
      audio.stopAudio(getCid());

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
      if (kIsWeb || !Platform.isIOS) {
        // Only iOS for now...
        config = await nativeAudioConfigurationForAudioTrackState.call(audioTrackState);
      }

      if (config != null) {
        logger.fine('[$runtimeType] configuring for ${audioTrackState} using ${config}...');
        try {
          await configureNativeAudio(config);
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

Future<NativeAudioConfiguration> defaultNativeAudioConfigurationFunc(AudioTrackState state) async {
  //
  if (state == AudioTrackState.remoteOnly) {
    return NativeAudioConfiguration(
      appleAudioCategory: AppleAudioCategory.playback,
      appleAudioCategoryOptions: {
        AppleAudioCategoryOption.mixWithOthers,
        // IosAudioCategoryOption.duckOthers,
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
        // IosAudioCategoryOption.duckOthers,
      },
      appleAudioMode: AppleAudioMode.voiceChat,
    );
  }

  // TODO: .record category causes exception in WebRTC lib for unknown reason
  // if (this == AudioTrackState.localOnly) {
  //   return NativeAudioConfiguration(
  //     iosCategory: IosAudioCategory.record,
  //     iosCategoryOptions: {
  //       // IosAudioCategoryOption.allowBluetooth,
  //     },
  //     iosMode: IosAudioMode.spokenAudio,
  //   );
  // }

  return NativeAudioConfiguration(
    appleAudioCategory: AppleAudioCategory.soloAmbient,
    appleAudioCategoryOptions: {},
    appleAudioMode: AppleAudioMode.default_,
  );
}
