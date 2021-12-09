import 'track/options.dart';
import 'track/track.dart';
import 'types.dart';

class ConnectOptions {
  /// Auto-subscribe to room tracks upon connect, defaults to true.
  final bool autoSubscribe;
  final RTCConfiguration rtcConfiguration;
  final ProtocolVersion protocolVersion;

  const ConnectOptions({
    this.autoSubscribe = true,
    this.rtcConfiguration = const RTCConfiguration(),
    this.protocolVersion = ProtocolVersion.v5,
  });
}

/// Options when joining a room.
/// {@category Room}
class RoomOptions {
  /// Default options used when publishing a video track
  final VideoPublishOptions defaultVideoPublishOptions;

  /// Default options used when publishing a audio track
  final AudioPublishOptions defaultAudioPublishOptions;

  /// When this is turned on, the following optimizations will be made:
  /// - [RemoteTrackPublication] will be enabled/disabled based on the corresponding
  /// [VideoTrackRenderer]'s visibility on screen.
  /// - Re-sizing a [VideoTrackRenderer] will signal the server to send down
  /// a relavant quality layer (if simulcast is enabled on the publisher)
  /// defaults to true.
  final bool optimizeVideo;

  /// Set this to false in case you would like to stop the track yourself.
  /// If you set this to false, make sure you call [Track.stop].
  /// defaults to true.
  final bool stopLocalTrackOnUnpublish;

  const RoomOptions({
    this.defaultVideoPublishOptions = const VideoPublishOptions(),
    this.defaultAudioPublishOptions = const AudioPublishOptions(),
    this.optimizeVideo = true,
    this.stopLocalTrackOnUnpublish = true,
  });
}

class VideoPublishOptions {
  ///
  final VideoEncoding? videoEncoding;

  /// Whether to enable simulcast or not.
  /// https://blog.livekit.io/an-introduction-to-webrtc-simulcast-6c5f1f6402eb
  /// defaults to true.
  final bool simulcast;

  const VideoPublishOptions({
    this.videoEncoding,
    this.simulcast = true,
  });

  @override
  String toString() =>
      '${runtimeType}(videoEncoding: ${videoEncoding}, simulcast: ${simulcast})';
}

class AudioPublishOptions {
  /// Whether to enable DTX (Discontinuous Transmission) or not.
  /// https://en.wikipedia.org/wiki/Discontinuous_transmission
  /// defaults to true.
  final bool dtx;

  const AudioPublishOptions({
    this.dtx = true,
  });

  @override
  String toString() => '${runtimeType}(dtx: ${dtx})';
}
