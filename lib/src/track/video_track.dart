import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../proto/livekit_models.pb.dart';
import 'track.dart';

class VideoTrack extends Track {
  MediaStream? mediaStream;

  VideoTrack(String name, MediaStreamTrack mediaTrack, this.mediaStream)
      : super(TrackType.VIDEO, name, mediaTrack);

  @override
  stop() {
    super.stop();
    mediaStream?.dispose();
    mediaStream = null;
  }
}
