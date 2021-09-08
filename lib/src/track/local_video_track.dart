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
    if (sender == null) throw TrackCreateError('could not restart track');
    currentOptions = options ?? currentOptions;

    final stream = await _createStream(currentOptions);
    final track = stream.getVideoTracks().first;
    setMediaStream(stream);
    await mediaStreamTrack.stop();
    mediaStreamTrack = track;
    await sender?.replaceTrack(track);
  }

  /// Creates a LocalVideoTrack from camera input.
  static Future<LocalVideoTrack> create([
    LocalVideoTrackOptions? options,
  ]) async {
    options ??= const LocalVideoTrackOptions();
    final stream = await _createStream(options);
    return LocalVideoTrack._(
      'camera',
      stream.getVideoTracks().first,
      stream,
      options,
    );
  }

  //
  // Convenience constructors
  //
  // static Future<LocalVideoTrack> createCamera(
  //   LocalVideoTrackOptions? options,
  // ) async {
  //   final _ = options ?? const LocalVideoTrackOptions();
  //   return create(_.copyWith(type: LocalVideoTrackType.camera));
  // }

  // static Future<LocalVideoTrack> createScreen(
  //   LocalVideoTrackOptions? options,
  // ) async {
  //   final _ = options ?? const LocalVideoTrackOptions();
  //   return create(_.copyWith(type: LocalVideoTrackType.display));
  // }

  static Future<MediaStream> _createStream(
    LocalVideoTrackOptions options,
  ) async {
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
