import 'package:livekit_client/src/support/disposable.dart';
import '../events.dart' show AudioVisualizerEvent;
import '../managers/event.dart' show EventsEmittable;
import 'local/local.dart' show AudioTrack;

import 'audio_visualizer_native.dart'
    if (dart.library.js_interop) 'audio_visualizer_web.dart';

class AudioVisualizerOptions {
  final bool centeredBands;
  final int barCount;
  const AudioVisualizerOptions({
    this.centeredBands = true,
    this.barCount = 7,
  });
}

abstract class AudioVisualizer extends DisposableChangeNotifier
    with EventsEmittable<AudioVisualizerEvent> {
  Future<void> start();
  Future<void> stop();
}

AudioVisualizer createVisualizer(AudioTrack track,
        {AudioVisualizerOptions? options}) =>
    createVisualizerImpl(track, options: options);
