import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../../logger.dart';
import '../../proto/livekit_models.pb.dart' as lk_models;
import '../../types/other.dart';
import '../options.dart';
import '../track.dart';
import 'audio.dart';
import 'local.dart';

/// A video track from the local device. Use static methods in this class to create
/// video tracks.
class LocalVideoTrack extends LocalTrack with VideoTrack {
  // Options used for this track
  @override
  covariant VideoCaptureOptions currentOptions;

  // Private constructor
  LocalVideoTrack._(
    String name,
    TrackSource source,
    rtc.MediaStream stream,
    rtc.MediaStreamTrack track,
    this.currentOptions,
  ) : super(
          name,
          lk_models.TrackType.VIDEO,
          source,
          stream,
          track,
        );

  /// Creates a LocalVideoTrack from camera input.
  static Future<LocalVideoTrack> createCameraTrack([
    CameraCaptureOptions? options,
  ]) async {
    options ??= const CameraCaptureOptions();

    final stream = await LocalTrack.createStream(options);
    return LocalVideoTrack._(
      Track.cameraName,
      TrackSource.camera,
      stream,
      stream.getVideoTracks().first,
      options,
    );
  }

  /// Creates a LocalVideoTrack from the display.
  ///
  /// Note: Android requires a foreground service to be started prior to
  /// creating a screen track. Refer to the example app for an implementation.
  static Future<LocalVideoTrack> createScreenShareTrack([
    ScreenShareCaptureOptions? options,
  ]) async {
    options ??= const ScreenShareCaptureOptions();

    final stream = await LocalTrack.createStream(options);
    return LocalVideoTrack._(
      Track.screenShareName,
      TrackSource.screenShareVideo,
      stream,
      stream.getVideoTracks().first,
      options,
    );
  }

  /// Creates a LocalTracks(audio/video) from the display.
  ///
  /// The current API is mainly used to capture audio when chrome captures tab,
  /// but in the future it can also be used for flutter native to open audio
  /// capture device when capturing screen
  static Future<List<LocalTrack>> createScreenShareTracksWithAudio([
    ScreenShareCaptureOptions? options,
  ]) async {
    options ??= const ScreenShareCaptureOptions(captureScreenAudio: true);

    final stream = await LocalTrack.createStream(options);

    List<LocalTrack> tracks = [
      LocalVideoTrack._(
        Track.screenShareName,
        TrackSource.screenShareVideo,
        stream,
        stream.getVideoTracks().first,
        options,
      )
    ];

    if (stream.getAudioTracks().isNotEmpty) {
      tracks.add(LocalAudioTrack(
          Track.screenShareName,
          TrackSource.screenShareAudio,
          stream,
          stream.getAudioTracks().first,
          const AudioCaptureOptions()));
    }
    return tracks;
  }
}

//
// Convenience extensions
//
extension LocalVideoTrackExt on LocalVideoTrack {
  // Calls restartTrack under the hood
  Future<void> setCameraPosition(CameraPosition position) async {
    final options = currentOptions;
    if (options is! CameraCaptureOptions) {
      logger.warning('Not a camera track');
      return;
    }

    await restartTrack(
      options.copyWith(cameraPosition: position),
    );
  }

  Future<void> switchCamera(String deviceId) async {
    final options = currentOptions;
    if (options is! CameraCaptureOptions) {
      logger.warning('Not a camera track');
      return;
    }

    await restartTrack(
      options.copyWith(deviceId: deviceId),
    );
  }
}
