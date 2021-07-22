import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../proto/livekit_models.pb.dart';
import 'track.dart';

class VideoTrack extends Track {
  VideoTrack(String name, MediaStreamTrack mediaTrack)
      : super(TrackType.VIDEO, name, mediaTrack);

  // TODO: keep list of video renderers

  @override
  stop() {
    super.stop();
    // TODO: remove renderer
  }
}
