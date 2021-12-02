import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../../proto/livekit_models.pb.dart' as lk_models;
import '../../types.dart';
import '../web/_audio_api.dart' if (dart.library.html) '../web/_audio_html.dart'
    as audio;
import '../audio_management.dart';
import '../local.dart';
import '../remote.dart';

class RemoteAudioTrack extends RemoteTrack
    with AudioTrack, AudioManagementMixin {
  //
  RemoteAudioTrack(
    String name,
    TrackSource source,
    rtc.MediaStream stream,
    rtc.MediaStreamTrack track,
  ) : super(
          name,
          lk_models.TrackType.AUDIO,
          source,
          stream,
          track,
        );

  @override
  Future<bool> start() async {
    final didStart = await super.start();
    if (didStart) {
      // web support
      audio.startAudio(getCid(), mediaStreamTrack);
    }
    return didStart;
  }

  @override
  Future<bool> stop() async {
    final didStop = await super.stop();
    if (didStop) {
      // web support
      audio.stopAudio(getCid());
    }
    return didStop;
  }
}
