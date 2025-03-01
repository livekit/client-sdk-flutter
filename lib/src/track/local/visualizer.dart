import '../../events.dart' show AudioVisualizerEvent;
import 'local.dart' show AudioTrack;

import '../visualizer_native.dart'
    if (dart.library.js_interop) '../visualizer_web.dart';

class VisualizerOptions {
  bool isCentered;
  int barCount;
  VisualizerOptions({
    this.isCentered = true,
    this.barCount = 7,
  });
}

abstract class Visualizer {
  Stream<AudioVisualizerEvent> get events;
  Future<void> startVisualizer();
  Future<void> stopVisualizer();
}

Visualizer createVisualizer(AudioTrack track, {VisualizerOptions? options}) =>
    createVisualizerImpl(track, options: options);
