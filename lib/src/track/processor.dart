import 'package:webrtc_interface/webrtc_interface.dart';

import '../core/room.dart';
import '../types/other.dart';

class ProcessorOptions<T extends TrackType> {
  T kind;
  MediaStreamTrack track;
  ProcessorOptions({
    required this.kind,
    required this.track,
  });
}

abstract class TrackProcessor<T extends ProcessorOptions> {
  String get name;

  Future<void> init(T options);

  Future<void> restart(T options);

  Future<void> destroy();

  Future<void> onPublish(Room room);

  Future<void> onUnpublish();

  MediaStreamTrack? get processedTrack;
}
