import 'track/options.dart';

/// Options when joining a room.
/// {@category Room}
class ConnectOptions {
  /// Auto-subscribe to room tracks upon connect, defaults to true.
  final bool autoSubscribe;

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

  const ConnectOptions({
    this.autoSubscribe = true,
    this.defaultVideoPublishOptions = const VideoPublishOptions(),
    this.defaultAudioPublishOptions = const AudioPublishOptions(),
    this.optimizeVideo = true,
  });
}

class VideoPublishOptions {
  ///
  final VideoEncoding? videoEncoding;

  ///
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
  /// DTX (Discontinuous Transmission)
  /// https://en.wikipedia.org/wiki/Discontinuous_transmission
  /// defaults to true
  final bool dtx;

  const AudioPublishOptions({
    this.dtx = true,
  });

  @override
  String toString() => '${runtimeType}(dtx: ${dtx})';
}
