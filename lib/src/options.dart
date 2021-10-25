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

  const ConnectOptions({
    this.autoSubscribe = true,
    this.defaultVideoPublishOptions = const VideoPublishOptions(),
    this.defaultAudioPublishOptions = const AudioPublishOptions(),
  });
}

class VideoPublishOptions {
  ///
  final VideoEncoding? videoEncoding;

  ///
  final bool simulcast;

  const VideoPublishOptions({
    this.videoEncoding,
    this.simulcast = false,
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
