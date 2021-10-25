import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../proto/livekit_models.pb.dart' as lk_models;
import 'track.dart';

/// A video track will notify when its mediaTrack has changed.
abstract class VideoTrack extends Track {
  rtc.MediaStream _mediaStream;

  VideoTrack(
    String name,
    rtc.MediaStreamTrack mediaTrack,
    this._mediaStream,
    // this._client,
  ) : super(
          lk_models.TrackType.VIDEO,
          name,
          mediaTrack,
        );

  rtc.MediaStream get mediaStream => _mediaStream;

  /// internal use
  /// {@nodoc}
  @internal
  void setMediaStream(rtc.MediaStream stream) {
    _mediaStream = stream;
    notifyListeners();
  }

  @override
  Future<bool> stop() async {
    final didStop = await super.stop();
    if (didStop) {
      await _mediaStream.dispose();
    }
    // _mediaStream = null;
    return didStop;
  }
}
