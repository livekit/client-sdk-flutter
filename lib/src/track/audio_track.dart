import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../proto/livekit_models.pbenum.dart';
import 'local_audio_track.dart';
import 'track.dart';
import '_audio_api.dart' if (dart.library.html) '_audio_html.dart' as audio;

class AudioTrack extends Track {
  MediaStream? mediaStream;

  AudioTrack(String name, MediaStreamTrack track, this.mediaStream)
      : super(TrackType.AUDIO, name, track);

  start() {
    if (this is! LocalAudioTrack) {
      audio.startAudio(getCid(), mediaTrack);
    }
  }

  @override
  stop() {
    mediaStream?.dispose();
    mediaStream = null;
    audio.stopAudio(getCid());
    super.stop();
  }
}
