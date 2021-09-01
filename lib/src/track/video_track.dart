import '../imports.dart';
import '../proto/livekit_models.pb.dart' as lk_models;

/// A video track will notify when its mediaTrack has changed.
class VideoTrack extends Track with ChangeNotifier {
  //
  MediaStream? _mediaStream;

  VideoTrack(
    String name,
    MediaStreamTrack mediaTrack,
    this._mediaStream,
  ) : super(
          lk_models.TrackType.VIDEO,
          name,
          mediaTrack,
        );

  MediaStream? get mediaStream => _mediaStream;

  /// internal use
  /// {@nodoc}
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
