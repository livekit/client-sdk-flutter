import '../../events.dart' show AudioVisualizerEvent;
import '../visualizer_native.dart'
    if (dart.library.js_interop) '../visualizer_web.dart';
import 'local.dart' show AudioTrack;

abstract class Visualizer {
  Stream<AudioVisualizerEvent> get events;
  Future<void> startVisualizer();
  Future<void> stopVisualizer();
}

Visualizer createVisualizer(AudioTrack track) => createVisualizerImpl(track);
