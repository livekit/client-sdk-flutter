import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../errors.dart';
import 'options.dart';
import 'video_track.dart';

class LocalVideoTrack extends VideoTrack {
  LocalVideoTrack(String name, MediaStreamTrack mediaTrack, MediaStream stream)
      : super(name, mediaTrack, stream);

  Future<LocalVideoTrack> createCameraTrack(
      LocalVideoTrackOptions? options) async {
    if (options == null) {
      options = LocalVideoTrackOptions(params: VideoPresets.qhd);
    }

    try {
      var stream = await navigator.mediaDevices.getUserMedia({
        "audio": false,
        "video": options.mediaConstraints,
      });

      if (stream.getVideoTracks().length == 0) {
        return Future.error(TrackCreateError());
      }

      return LocalVideoTrack("", stream.getVideoTracks().first, stream);
    } catch (e) {
      return Future.error(e);
    }
  }
}
