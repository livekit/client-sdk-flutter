import 'package:livekit_client/src/support/disposable.dart';
import '../events.dart' show AudioVisualizerEvent;
import '../managers/event.dart' show EventsEmittable;
import 'local/local.dart' show AudioTrack;

import 'visualizer_native.dart'
    if (dart.library.js_interop) 'visualizer_web.dart';

class VisualizerOptions {
  final bool centeredBands;
  final int barCount;
  const VisualizerOptions({
    this.centeredBands = true,
    this.barCount = 7,
  });
}

abstract class Visualizer extends DisposableChangeNotifier
    with EventsEmittable<AudioVisualizerEvent> {
  Future<void> start();
  Future<void> stop();
}

Visualizer createVisualizer(AudioTrack track, {VisualizerOptions? options}) =>
    createVisualizerImpl(track, options: options);
