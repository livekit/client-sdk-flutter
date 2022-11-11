import 'constants.dart';
import 'core/room.dart';
import 'publication/remote.dart';
import 'track/local/audio.dart';
import 'track/local/video.dart';
import 'track/options.dart';
import 'track/track.dart';
import 'types/other.dart';
import 'types/video_encoding.dart';
import 'types/video_parameters.dart';

class TrackOption<E extends Object, T extends Object> {
  final E? enabled;
  final T? track;
  const TrackOption({this.enabled, this.track});
}

class FastConnectOptions {
  FastConnectOptions({
    this.microphone = const TrackOption(enabled: false),
    this.camera = const TrackOption(enabled: false),
    this.screen = const TrackOption(enabled: false),
  });
  final TrackOption<bool, LocalAudioTrack> microphone;
  final TrackOption<bool, LocalVideoTrack> camera;
  final TrackOption<bool, LocalVideoTrack> screen;
}

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

  final Timeouts timeouts;

  const ConnectOptions({
    this.autoSubscribe = true,
    this.rtcConfiguration = const RTCConfiguration(),
    this.protocolVersion = ProtocolVersion.v8,
    this.timeouts = Timeouts.defaultTimeouts,
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

  /// AdaptiveStream lets LiveKit automatically manage quality of subscribed
  /// video tracks to optimize for bandwidth and CPU.
  /// When attached video elements are visible, it'll choose an appropriate
  /// resolution based on the size of largest video element it's attached to.
  ///
  /// When none of the video elements are visible, it'll temporarily pause
  /// the data flow until they are visible again.
  final bool adaptiveStream;

  /// enable Dynacast, off by default. With Dynacast dynamically pauses
  /// video layers that are not being consumed by any subscribers, significantly
  /// reducing publishing CPU and bandwidth usage.
  final bool dynacast;

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
    this.dynacast = false,
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

  final List<VideoParameters> videoSimulcastLayers;

  final List<VideoParameters> screenShareSimulcastLayers;

  const VideoPublishOptions({
    this.videoEncoding,
    this.simulcast = true,
    this.videoSimulcastLayers = const [],
    this.screenShareSimulcastLayers = const [],
  });

  @override
  String toString() =>
      '${runtimeType}(videoEncoding: ${videoEncoding}, simulcast: ${simulcast})';
}

class AudioPreset {
  static const telephone = 12000;
  static const speech = 20000;
  static const music = 32000;
  static const musicStereo = 48000;
  static const musicHighQuality = 64000;
  static const musicHighQualityStereo = 96000;
}

/// Options used when publishing audio.
class AudioPublishOptions {
  /// Whether to enable DTX (Discontinuous Transmission) or not.
  /// https://en.wikipedia.org/wiki/Discontinuous_transmission
  /// Defaults to true.
  final bool dtx;

  /// max audio bitrate
  final int audioBitrate;

  /// Turn off the audio track when muted, to avoid the microphone
  /// indicator light on.
  final bool stopMicTrackOnMute;

  const AudioPublishOptions({
    this.dtx = true,
    this.audioBitrate = AudioPreset.music,
    this.stopMicTrackOnMute = true,
  });

  @override
  String toString() => '${runtimeType}(dtx: ${dtx})';
}
