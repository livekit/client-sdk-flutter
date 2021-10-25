import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/src/track/video_track.dart';

class RemoteVideoTrack extends VideoTrack {
  //
  RemoteVideoTrack(
    String name,
    rtc.MediaStreamTrack mediaTrack,
    rtc.MediaStream stream,
  ) : super(name, mediaTrack, stream);

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
