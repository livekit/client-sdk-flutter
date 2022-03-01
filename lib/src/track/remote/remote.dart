import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../../proto/livekit_models.pb.dart' as lk_models;
import '../../types/other.dart';
import '../track.dart';

abstract class RemoteTrack extends Track {
  RemoteTrack(
    String name,
    lk_models.TrackType kind,
    TrackSource source,
    rtc.MediaStream stream,
    rtc.MediaStreamTrack track,
  ) : super(
          name,
          kind,
          source,
          stream,
          track,
        );

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
