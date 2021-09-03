import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../errors.dart';
import 'options.dart';
import 'video_track.dart';

/// A video track from the local device. Use static methods in this class to create
/// video tracks.
class LocalVideoTrack extends VideoTrack {
  //
  // The latest options used for this track
  //
  LocalVideoTrackOptions? latestOptions;

  LocalVideoTrack(
    String name,
    MediaStreamTrack mediaTrack,
    MediaStream stream,
    this.latestOptions,
  ) : super(name, mediaTrack, stream);

  RTCRtpSender? get sender => transceiver?.sender;

  /// Restarts the track with new options. This is useful when switching between
  /// front and back cameras.
  Future<void> restartTrack([
    LocalVideoTrackOptions? options,
  ]) async {
    //
    if (sender == null) throw TrackCreateError('could not restart track');

    latestOptions = options ?? const LocalVideoTrackOptions();

    final stream = await _createCameraStream(options: latestOptions!);
    final track = stream.getVideoTracks().first;
    mediaStream = stream;
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
    final stream = await _createCameraStream(options: latestOptions);
    return LocalVideoTrack(
      'camera',
      stream.getVideoTracks().first,
      stream,
      latestOptions,
    );
  }

  static Future<MediaStream> _createCameraStream({
    required LocalVideoTrackOptions options,
  }) async {
    //
    final stream = await navigator.mediaDevices.getUserMedia(<String, dynamic>{
      'audio': false,
      'video': options.toMediaConstraintsMap(),
    });

    if (stream.getVideoTracks().isEmpty) throw TrackCreateError();

    return stream;
  }
}
