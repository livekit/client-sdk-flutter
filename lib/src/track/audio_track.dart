import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../logger.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '_audio_api.dart' if (dart.library.html) '_audio_html.dart' as audio;
import 'local_audio_track.dart';
import 'track.dart';
import 'package:synchronized/synchronized.dart' as sync;

class AudioTrack extends Track {
  static final _counterLock = sync.Lock();
  static int localCount = 0;
  static int remoteCount = 0;

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
      await _counterLock.synchronized(() {
        if (this is LocalAudioTrack) {
          localCount++;
        } else if (this is! LocalAudioTrack) {
          remoteCount++;
        }
        _didUpdateCounter();
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
      await _counterLock.synchronized(() {
        if (this is LocalAudioTrack) {
          localCount--;
        } else if (this is! LocalAudioTrack) {
          remoteCount--;
        }
        _didUpdateCounter();
      });
    }

    return didStop;
  }

  void _didUpdateCounter() {
    logger.fine('didUpdateCounter: local: $localCount, remote: $remoteCount');
  }
}
