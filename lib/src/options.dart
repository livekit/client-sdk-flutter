import 'core/room.dart';
import 'publication/remote.dart';
import 'track/local/audio.dart';
import 'track/local/video.dart';
import 'track/options.dart';
import 'track/track.dart';
import 'types.dart';

/// Options used when connecting to the server.
class ConnectOptions {
  /// Auto-subscribe to existing and new [RemoteTrackPublication]s after
  /// successfully connecting to the [Room].
  /// Defaults to true.
  final bool autoSubscribe;

  /// The default [RTCConfiguration] to be used.
  final RTCConfiguration rtcConfiguration;

  /// The protocol version to be used. Usually this doesn't need to be modified.
  final ProtocolVersion protocolVersion;

  const ConnectOptions({
    this.autoSubscribe = true,
    this.rtcConfiguration = const RTCConfiguration(),
    this.protocolVersion = ProtocolVersion.v5,
  });
}

/// Options used to modify the behavior of the [Room].
/// {@category Room}
class RoomOptions {
  /// Default options used for [LocalVideoTrack.createCameraTrack].
  final CameraCaptureOptions defaultCameraCaptureOptions;

  /// Default options used for [LocalVideoTrack.createScreenShareTrack].
  final ScreenShareCaptureOptions defaultScreenShareCaptureOptions;

  /// Default options used when capturing video for a [LocalAudioTrack].
  final AudioCaptureOptions defaultAudioCaptureOptions;

  /// Default options used when publishing a [LocalVideoTrack].
  final VideoPublishOptions defaultVideoPublishOptions;

  /// Default options used when publishing a [LocalAudioTrack].
  final AudioPublishOptions defaultAudioPublishOptions;

  /// When this is turned on, the following optimizations will be made:
  /// - [RemoteTrackPublication] will be enabled/disabled based on the corresponding
  /// [VideoTrackRenderer]'s visibility on screen.
  /// - Re-sizing a [VideoTrackRenderer] will signal the server to send down
  /// a relavant quality layer (if simulcast is enabled on the publisher)
  /// Defaults to false.
  final bool adaptiveStream;

  /// Set this to false in case you would like to stop the track yourself.
  /// If you set this to false, make sure you call [Track.stop].
  /// Defaults to true.
  final bool stopLocalTrackOnUnpublish;

  const RoomOptions({
    this.defaultCameraCaptureOptions = const CameraCaptureOptions(),
    this.defaultScreenShareCaptureOptions = const ScreenShareCaptureOptions(),
    this.defaultAudioCaptureOptions = const AudioCaptureOptions(),
    this.defaultVideoPublishOptions = const VideoPublishOptions(),
    this.defaultAudioPublishOptions = const AudioPublishOptions(),
    this.adaptiveStream = false,
    this.stopLocalTrackOnUnpublish = true,
  });
}

/// Options used when publishing video.
class VideoPublishOptions {
  /// If provided, this will be used instead of the SDK's suggested encodings.
  /// Usually you don't need to provide this.
  /// Defaults to null.
  final VideoEncoding? videoEncoding;

  /// Whether to enable simulcast or not.
  /// https://blog.livekit.io/an-introduction-to-webrtc-simulcast-6c5f1f6402eb
  /// Defaults to true.
  final bool simulcast;

  const VideoPublishOptions({
    this.videoEncoding,
    this.simulcast = true,
  });

  @override
  String toString() =>
      '${runtimeType}(videoEncoding: ${videoEncoding}, simulcast: ${simulcast})';
}

/// Options used when publishing audio.
class AudioPublishOptions {
  /// Whether to enable DTX (Discontinuous Transmission) or not.
  /// https://en.wikipedia.org/wiki/Discontinuous_transmission
  /// Defaults to true.
  final bool dtx;

  const AudioPublishOptions({
    this.dtx = true,
  });

  @override
  String toString() => '${runtimeType}(dtx: ${dtx})';
}
