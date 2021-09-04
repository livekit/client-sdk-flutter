import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../errors.dart';
import 'options.dart';
import 'video_track.dart';

/// A video track from the local device. Use static methods in this class to create
/// video tracks.
class LocalVideoTrack extends VideoTrack {
  //
  // Options used for this track
  //
  LocalVideoTrackOptions currentOptions;

  //
  // Private constructor
  //
  LocalVideoTrack._(
    String name,
    MediaStreamTrack mediaTrack,
    MediaStream stream,
    this.currentOptions,
  ) : super(name, mediaTrack, stream);

  RTCRtpSender? get sender => transceiver?.sender;

  /// Restarts the track with new options. This is useful when switching between
  /// front and back cameras.
  Future<void> restartTrack([
    LocalVideoTrackOptions? options,
  ]) async {
    //
    if (sender == null) throw TrackCreateError('could not restart track');

    currentOptions = options ?? currentOptions;

    final stream = await _createStream(options: currentOptions);
    final track = stream.getVideoTracks().first;
    setMediaStream(stream);
    await mediaStreamTrack.stop();
    mediaStreamTrack = track;
    await sender?.replaceTrack(track);
  }

  /// Creates a LocalVideoTrack from camera input.
  static Future<LocalVideoTrack> createCameraTrack({
    LocalVideoTrackOptions? options,
  }) async {
    //
    final latestOptions = options ?? const LocalVideoTrackOptions();

    final stream = await _createStream(options: latestOptions);
    return LocalVideoTrack._(
      'camera',
      stream.getVideoTracks().first,
      stream,
      latestOptions,
    );
  }

  static Future<MediaStream> _createStream({
    required LocalVideoTrackOptions options,
  }) async {
    //
    final constraints = <String, dynamic>{
      'audio': false,
      'video': options.toMediaConstraintsMap(),
    };

    final MediaStream stream;

    if (options.type == LocalVideoTrackType.display) {
      stream = await navigator.mediaDevices.getDisplayMedia(constraints);
    } else {
      stream = await navigator.mediaDevices.getUserMedia(constraints);
    }

    if (stream.getVideoTracks().isEmpty) throw TrackCreateError();

    return stream;
  }
}
