import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../proto/livekit_models.pb.dart';
import 'track.dart';

/// A video track will notify when its mediaTrack has changed.
class VideoTrack extends Track with ChangeNotifier {
  MediaStream? _mediaStream;

  VideoTrack(String name, MediaStreamTrack mediaTrack, this._mediaStream)
      : super(TrackType.VIDEO, name, mediaTrack);

  MediaStream? get mediaStream => _mediaStream;

  set mediaStream(MediaStream? stream) {
    _mediaStream = stream;
    notifyListeners();
  }

  @override
  stop() {
    super.stop();
    _mediaStream?.dispose();
    _mediaStream = null;
  }
}
