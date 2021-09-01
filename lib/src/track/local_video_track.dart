import '../imports.dart';

/// A video track from the local device. Use static methods in this class to create
/// video tracks.
class LocalVideoTrack extends VideoTrack {
  RTCRtpSender? get sender => transceiver?.sender;

  LocalVideoTrack(String name, MediaStreamTrack mediaTrack, MediaStream stream)
      : super(name, mediaTrack, stream);

  /// Creates a LocalVideoTrack from camera input.
  static Future<LocalVideoTrack> createCameraTrack([LocalVideoTrackOptions? options]) async {
    options ??= LocalVideoTrackOptions(params: VideoPreset.qhd);

    try {
      final stream = await _createCameraStream(options);
      return LocalVideoTrack('camera', stream.getVideoTracks().first, stream);
    } catch (e) {
      return Future.error(e);
    }
  }

  /// Restarts the track with new options. This is useful when switching between
  /// front and back cameras.
  Future<void> restartTrack([LocalVideoTrackOptions? options]) async {
    if (sender == null) {
      return Future.error(TrackCreateError('could not restart track'));
    }

    options ??= LocalVideoTrackOptions(params: VideoPreset.qhd);

    try {
      final stream = await _createCameraStream(options);
      final track = stream.getVideoTracks().first;
      mediaStream = stream;
      await mediaTrack.stop();
      mediaTrack = track;
      await sender?.replaceTrack(track);
    } catch (e) {
      return Future.error(e);
    }
  }

  static Future<MediaStream> _createCameraStream(LocalVideoTrackOptions? options) async {
    //
    options ??= LocalVideoTrackOptions(params: VideoPreset.qhd);

    try {
      final stream = await navigator.mediaDevices.getUserMedia(<String, dynamic>{
        'audio': false,
        'video': options.toMediaConstraintsMap(),
      });

      if (stream.getVideoTracks().isEmpty) {
        return Future.error(TrackCreateError());
      }

      return stream;
    } catch (e) {
      return Future.error(e);
    }
  }
}
