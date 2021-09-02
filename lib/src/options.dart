import 'track/options.dart';

/// Options when joining a room.
/// {@category Room}
class ConnectOptions {
  /// Auto-subscribe to room tracks upon connect, defaults to true.
  final bool autoSubscribe;

  //
  final TrackPublishOptions defaultPublishOptions;

  const ConnectOptions({
    this.autoSubscribe = true,
    this.defaultPublishOptions = const TrackPublishOptions(),
  });
}

class TrackPublishOptions {
  ///
  final VideoEncoding? videoEncoding;

  ///
  final bool simulcast;

  const TrackPublishOptions({
    this.videoEncoding,
    this.simulcast = false,
  });
}
