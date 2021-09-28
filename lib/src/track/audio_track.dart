import 'package:audio_session/audio_session.dart' as _as;
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:synchronized/synchronized.dart' as sync;

import '../logger.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '_audio_api.dart' if (dart.library.html) '_audio_html.dart' as audio;
import 'local_audio_track.dart';
import 'track.dart';

enum AudioTrackState {
  none,
  remoteOnly,
  localOnly,
  localAndRemote,
}

typedef AudioTrackConfigureAudioSession = Future<void> Function(AudioTrackState state);

class AudioTrack extends Track {
  // it's possible to set custom function here to customize audio session configuration
  static AudioTrackConfigureAudioSession onConfigureAudioSession =
      AudioTrackExt.configureAudioSession;
  static final _counterLock = sync.Lock();
  static AudioTrackState state = AudioTrackState.none;
  static int _localCount = 0;
  static int _remoteCount = 0;

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
      await _counterLock.synchronized(() async {
        if (this is LocalAudioTrack) {
          _localCount++;
        } else if (this is! LocalAudioTrack) {
          _remoteCount++;
        }
        await _didUpdateCounter();
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
      await _counterLock.synchronized(() async {
        if (this is LocalAudioTrack) {
          _localCount--;
        } else if (this is! LocalAudioTrack) {
          _remoteCount--;
        }
        await _didUpdateCounter();
      });
    }

    return didStop;
  }

  Future<void> _didUpdateCounter() async {
    logger.fine('[$runtimeType] didUpdateCounter: local: $_localCount, remote: $_remoteCount');
    final newState = AudioTrackStateExt.computeAudioTrackState(
      local: _localCount,
      remote: _remoteCount,
    );

    if (state != newState) {
      state = newState;
      logger.fine('[$runtimeType] didUpdateSate: $state');
      await AudioTrackExt.configureAudioSession(state);
    }
  }
}

extension AudioTrackExt on AudioTrack {
  //
  static Future<void> configureAudioSession(AudioTrackState state) async {
    final config = state.defaultConfiguration();
    logger.fine('[AudioTrack] configuring for ${state}, ${config.avAudioSessionCategory}...');
    try {
      final _audioSession = await _as.AudioSession.instance;
      await _audioSession.configure(config);
      await _audioSession.setActive(true);
    } catch (error) {
      logger.warning('[$AudioTrack] Failed to configure ${error}');
    }
  }
}

extension AudioTrackStateExt on AudioTrackState {
  //
  static AudioTrackState computeAudioTrackState({
    required int local,
    required int remote,
  }) {
    if (local > 0 && remote == 0) {
      return AudioTrackState.localOnly;
    } else if (local == 0 && remote > 0) {
      return AudioTrackState.remoteOnly;
    } else if (local > 0 && remote > 0) {
      return AudioTrackState.localAndRemote;
    }
    // Default
    return AudioTrackState.none;
  }
}

extension AudioRecommendationTypeExt on AudioTrackState {
  // returns default configuration for the AudioTrackState
  _as.AudioSessionConfiguration defaultConfiguration() {
    //
    final _baseConfiguration = _as.AudioSessionConfiguration(
      // ios defaults to soloAmbient
      avAudioSessionCategory: _as.AVAudioSessionCategory.soloAmbient,
      avAudioSessionCategoryOptions: _as.AVAudioSessionCategoryOptions.mixWithOthers &
          _as.AVAudioSessionCategoryOptions.allowBluetooth &
          _as.AVAudioSessionCategoryOptions.allowAirPlay &
          _as.AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: _as.AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy: _as.AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: _as.AVAudioSessionSetActiveOptions.none,
    );

    if (this == AudioTrackState.remoteOnly) {
      return _baseConfiguration.copyWith(
        avAudioSessionCategory: _as.AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: _as.AVAudioSessionCategoryOptions.none,
        avAudioSessionMode: _as.AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy: _as.AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: _as.AVAudioSessionSetActiveOptions.none,
      );
      // } else if (this == AudioTrackState.localOnly) {
      //   return _baseConfiguration.copyWith(
      //     avAudioSessionCategory: _as.AVAudioSessionCategory.record,
      //     avAudioSessionCategoryOptions: _as.AVAudioSessionCategoryOptions.allowBluetooth,
      //     avAudioSessionMode: _as.AVAudioSessionMode.spokenAudio,
      //     avAudioSessionRouteSharingPolicy: _as.AVAudioSessionRouteSharingPolicy.defaultPolicy,
      //     avAudioSessionSetActiveOptions: _as.AVAudioSessionSetActiveOptions.none,
      //   );
    } else if (this == AudioTrackState.localAndRemote || this == AudioTrackState.localOnly) {
      return _baseConfiguration.copyWith(
        avAudioSessionCategory: _as.AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: _as.AVAudioSessionCategoryOptions.mixWithOthers &
            _as.AVAudioSessionCategoryOptions.allowBluetooth &
            _as.AVAudioSessionCategoryOptions.allowAirPlay &
            _as.AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: _as.AVAudioSessionMode.voiceChat,
        avAudioSessionRouteSharingPolicy: _as.AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: _as.AVAudioSessionSetActiveOptions.none,
      );
    }

    return _baseConfiguration;
  }
}
