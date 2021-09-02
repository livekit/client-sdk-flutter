import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../proto/livekit_models.pb.dart' as lk_models;
import '_audio_api.dart' if (dart.library.html) '_audio_html.dart' as audio;
import 'local_audio_track.dart';
import 'track.dart';

class AudioTrack extends Track {
  MediaStream? mediaStream;

  AudioTrack(String name, MediaStreamTrack track, this.mediaStream)
      : super(lk_models.TrackType.AUDIO, name, track);

  /// Start playing audio track. On web platform, create an audio element and
  /// start playback
  void start() {
    if (this is! LocalAudioTrack) {
      audio.startAudio(getCid(), mediaTrack);
    }
  }

  @override
  void stop() {
    mediaStream?.dispose();
    mediaStream = null;
    audio.stopAudio(getCid());
    super.stop();
  }
}
