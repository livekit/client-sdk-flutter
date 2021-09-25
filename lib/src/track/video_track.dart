import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../proto/livekit_models.pb.dart' as lk_models;
import 'track.dart';

/// A video track will notify when its mediaTrack has changed.
class VideoTrack extends Track {
  //
  rtc.MediaStream _mediaStream;

  VideoTrack(
    String name,
    rtc.MediaStreamTrack mediaTrack,
    this._mediaStream,
  ) : super(
          lk_models.TrackType.VIDEO,
          name,
          mediaTrack,
        );

  rtc.MediaStream get mediaStream => _mediaStream;

  /// internal use
  /// {@nodoc}
  void setMediaStream(rtc.MediaStream stream) {
    _mediaStream = stream;
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    await super.stop();
    await _mediaStream.dispose();
    // _mediaStream = null;
  }
}
