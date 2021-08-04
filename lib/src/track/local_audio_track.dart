import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../errors.dart';
import '../proto/livekit_models.pb.dart';
import 'options.dart';
import 'track.dart';

class LocalAudioTrack extends Track {
  MediaStream? mediaStream;

  LocalAudioTrack(String name, MediaStreamTrack track, this.mediaStream)
      : super(TrackType.AUDIO, name, track);

  static Future<LocalAudioTrack> createTrack(
      [LocalAudioTrackOptions? options]) async {
    try {
      var stream = await navigator.mediaDevices.getUserMedia({
        "audio": true,
        "video": false,
      });

      if (stream.getAudioTracks().length == 0) {
        return Future.error(TrackCreateError());
      }

      return LocalAudioTrack("", stream.getAudioTracks().first, stream);
    } catch (e) {
      return Future.error(e);
    }
  }

  @override
  stop() {
    super.stop();
    mediaStream?.dispose();
    mediaStream = null;
  }
}
