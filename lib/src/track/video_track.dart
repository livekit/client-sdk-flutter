import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../internal/events.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../types.dart';
import 'track.dart';

/// A video track will notify when its mediaTrack has changed.
abstract class VideoTrack extends Track {
  rtc.MediaStream _mediaStream;

  VideoTrack(
    TrackSource source,
    String name,
    rtc.MediaStreamTrack mediaTrack,
    this._mediaStream,
  ) : super(
          lk_models.TrackType.VIDEO,
          source,
          name,
          mediaTrack,
        );

  rtc.MediaStream get mediaStream => _mediaStream;

  /// internal use
  /// {@nodoc}
  @internal
  void setMediaStream(rtc.MediaStream stream) {
    _mediaStream = stream;
    events.emit(TrackStreamUpdatedEvent(
      track: this,
      stream: stream,
    ));
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
