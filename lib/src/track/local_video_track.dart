import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../errors.dart';
import '../logger.dart';
import 'options.dart';
import 'track.dart';
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
    if (options != null && currentOptions.runtimeType != options.runtimeType) {
      throw Exception('options must be a ${currentOptions.runtimeType}');
    }

    currentOptions = options ?? currentOptions;

    final stream = await _createStream(currentOptions);
    final track = stream.getVideoTracks().first;
    setMediaStream(stream);
    await mediaStreamTrack.stop();
    mediaStreamTrack = track;
    await sender?.replaceTrack(track);
  }

  /// Creates a LocalVideoTrack from camera input.
  static Future<LocalVideoTrack> createCameraTrack([
    CameraTrackOptions? options,
  ]) async {
    options ??= const CameraTrackOptions();
    final stream = await _createStream(options);
    return LocalVideoTrack._(
      Track.cameraName,
      stream.getVideoTracks().first,
      stream,
      options,
    );
  }

  static Future<LocalVideoTrack> createScreenTrack([
    ScreenTrackOptions? options,
  ]) async {
    options ??= const ScreenTrackOptions();
    final stream = await _createStream(options);
    return LocalVideoTrack._(
      Track.screenShareName,
      stream.getVideoTracks().first,
      stream,
      options,
    );
  }

  static Future<MediaStream> _createStream(
    LocalVideoTrackOptions options,
  ) async {
    final constraints = <String, dynamic>{
      'audio': false,
      'video': options.toMediaConstraintsMap(),
    };

    final MediaStream stream;
    if (options is ScreenTrackOptions) {
      stream = await navigator.mediaDevices.getDisplayMedia(constraints);
    } else {
      // options is CameraVideoTrackOptions
      stream = await navigator.mediaDevices.getUserMedia(constraints);
    }

    if (stream.getVideoTracks().isEmpty) throw TrackCreateError();
    return stream;
  }
}

//
// Convenience extensions
//
extension CameraHelper on LocalVideoTrack {
  // Calls restartTrack under the hood
  Future<void> setCameraPosition(CameraPosition position) async {
    final options = currentOptions;
    if (options is! CameraTrackOptions) {
      logger.warning('Not a camera track');
      return;
    }
    await restartTrack(
      options.copyWith(cameraPosition: position),
    );
  }
}
