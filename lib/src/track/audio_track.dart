import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../proto/livekit_models.pb.dart' as lk_models;
import '_audio_api.dart' if (dart.library.html) '_audio_html.dart' as audio;
import 'local_audio_track.dart';
import 'track.dart';

class AudioTrack extends Track {
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
  void start() {
    if (this is LocalAudioTrack) {
      localCount++;
    } else if (this is! LocalAudioTrack) {
      audio.startAudio(getCid(), mediaStreamTrack);
      remoteCount++;
    }
  }

  @override
  Future<void> stop() async {
    await mediaStream?.dispose();
    mediaStream = null;
    audio.stopAudio(getCid());

    if (this is LocalAudioTrack) {
      localCount--;
    } else if (this is! LocalAudioTrack) {
      remoteCount--;
    }

    await super.stop();
  }
}
