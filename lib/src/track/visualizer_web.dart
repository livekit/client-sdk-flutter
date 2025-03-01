import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/src/events.dart' show AudioVisualizerEvent;

import 'local/local.dart' show AudioTrack;
import 'local/visualizer.dart';

import 'web/_audio_analyser.dart';

class VisualizerWeb implements Visualizer {
  final _events = StreamController<AudioVisualizerEvent>.broadcast(sync: true);
  @override
  Stream<AudioVisualizerEvent> get events => _events.stream;

  AudioAnalyser? _audioAnalyser;

  MultiBandTrackVolumeOptions options = MultiBandTrackVolumeOptions();

  Timer? _timer;

  final AudioTrack? _audioTrack;
  MediaStreamTrack get mediaStreamTrack => _audioTrack!.mediaStreamTrack;

  VisualizerWeb(this._audioTrack);

  @override
  Future<void> startVisualizer() async {
    if (_audioAnalyser != null) {
      return;
    }

    _audioAnalyser = createAudioAnalyser(_audioTrack!, options.analyserOptions);

    final bufferLength = _audioAnalyser?.analyser.frequencyBinCount;

    _timer = Timer.periodic(
      Duration(milliseconds: options.updateInterval!.toInt()),
      (timer) {
        try {
          var tmp = JSFloat32Array.withLength(bufferLength ?? 0);
          _audioAnalyser?.analyser.getFloatFrequencyData(tmp);
          Float32List frequencies = Float32List(tmp.toDart.length);
          for (var i = 0; i < tmp.toDart.length; i++) {
            var element = tmp.toDart[i];
            frequencies[i] = element;
          }
          frequencies = frequencies.sublist(
              options.loPass!.toInt(), options.hiPass!.toInt());

          final normalizedFrequencies =
              normalizeFrequencies(frequencies); // is this needed ?
          final chunkSize = (normalizedFrequencies.length / options.bands!)
              .ceil(); // we want logarithmic chunking here
          Float32List chunks = Float32List(options.bands!.toInt() - 1);

          for (var i = 0; i < options.bands!.toInt() - 1; i++) {
            final summedVolumes = normalizedFrequencies
                .sublist(i * chunkSize, (i + 1) * chunkSize)
                .reduce((acc, val) => (acc += val));
            chunks[i] = (summedVolumes / chunkSize);
          }

          _events.add(AudioVisualizerEvent(
            track: _audioTrack,
            event: chunks,
          ));
        } catch (e) {
          print(e);
        }
      },
    );
  }

  @override
  Future<void> stopVisualizer() async {
    if (_audioAnalyser == null) {
      return;
    }

    _timer?.cancel();
    _timer = null;

    await _audioAnalyser?.cleanup();
    _audioAnalyser = null;
  }
}

class MultiBandTrackVolumeOptions {
  final num? bands;

  /// cut off of frequency bins on the lower end
  /// Note: this is not a frequency measure, but in relation to analyserOptions.fftSize,
  final num? loPass;

  /// cut off of frequency bins on the higher end
  /// Note: this is not a frequency measure, but in relation to analyserOptions.fftSize,
  final num? hiPass;

  /// update should run every x ms
  final num? updateInterval;

  final AudioAnalyserOptions? analyserOptions;

  const MultiBandTrackVolumeOptions({
    this.bands = 8,
    this.loPass = 0,
    this.hiPass = 170,
    this.updateInterval = 32,
    this.analyserOptions = const AudioAnalyserOptions(),
  });
}

double normalizeDb(num value) {
  const minDb = -100.0;
  const maxDb = -10.0;

  var db =
      1.0 - (math.max(minDb, math.min(maxDb, value)) * -1.0).toDouble() / 100.0;
  db = math.sqrt(db);

  return db;
}

List<num> normalizeFrequencies(List<double> frequencies) {
  // Normalize all frequency values
  return frequencies.map((value) {
    if (value.isInfinite || value.isNaN) {
      return 0;
    }
    return normalizeDb(value);
  }).toList();
}

Visualizer createVisualizerImpl(AudioTrack track) => VisualizerWeb(track);
