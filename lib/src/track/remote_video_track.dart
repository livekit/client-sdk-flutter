import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../track/video_track.dart';
import '../types.dart';

class RemoteVideoTrack extends VideoTrack {
  //
  RemoteVideoTrack(
    TrackSource source,
    String name,
    rtc.MediaStreamTrack mediaTrack,
    rtc.MediaStream stream,
  ) : super(source, name, mediaTrack, stream);

  @override
  Future<bool> start() async {
    final didStart = await super.start();
    if (didStart) {
      await enable();
    }
    return didStart;
  }

  @override
  Future<bool> stop() async {
    final didStop = await super.stop();
    if (didStop) {
      await disable();
    }
    return didStop;
  }
}
