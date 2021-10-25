import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import '_audio_api.dart' if (dart.library.html) '_audio_html.dart' as audio;
import 'audio_track.dart';

class RemoteAudioTrack extends AudioTrack {
  //
  RemoteAudioTrack(
    String name,
    rtc.MediaStreamTrack track,
    rtc.MediaStream stream,
  ) : super(name, track, stream);

  @override
  Future<bool> start() async {
    final didStart = await super.start();
    if (didStart) {
      // web support
      audio.startAudio(getCid(), mediaStreamTrack);
      await enable();
    }
    return didStart;
  }

  @override
  Future<bool> stop() async {
    final didStop = await super.stop();
    if (didStop) {
      // web support
      audio.stopAudio(getCid());
      await disable();
    }
    return didStop;
  }
}
