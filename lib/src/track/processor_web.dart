import 'package:web/web.dart';

import 'processor.dart';

class AudioProcessorOptionsWeb extends AudioProcessorOptions {
  AudioProcessorOptionsWeb({
    this.audioElement,
    this.audioContext,
    required super.track,
  });

  HTMLAudioElement? audioElement;
  AudioContext? audioContext;
}
