import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'video_track.dart';

class LocalVideoTrack extends VideoTrack {
  LocalVideoTrack(String name, MediaStreamTrack mediaTrack)
      : super(name, mediaTrack);
}
