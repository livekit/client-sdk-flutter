import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dart_webrtc/dart_webrtc.dart' show MediaStreamWeb;
// ignore: implementation_imports
import 'package:dart_webrtc/src/media_stream_track_impl.dart'
    show MediaStreamTrackWeb;

import 'package:web/web.dart' as web;

import '../../track/local/local.dart' show AudioTrack;

class AudioAnalyser {
  final double Function() calculateVolume;
  final web.AnalyserNode analyser;
  final Future<void> Function() cleanup;
  AudioAnalyser({
    required this.calculateVolume,
    required this.analyser,
    required this.cleanup,
  });
}

class AudioAnalyserOptions {
  final bool? cloneTrack;
  final num? fftSize;
  final num? smoothingTimeConstant;
  final num? minDecibels;
  final num? maxDecibels;
  const AudioAnalyserOptions({
    this.cloneTrack = false,
    this.fftSize = 2048,
    this.smoothingTimeConstant = 0.8,
    this.minDecibels = -100,
    this.maxDecibels = -80,
  });

  factory AudioAnalyserOptions.from(AudioAnalyserOptions? options) {
    return AudioAnalyserOptions(
      cloneTrack: options?.cloneTrack,
      fftSize: options?.fftSize,
      smoothingTimeConstant: options?.smoothingTimeConstant,
      minDecibels: options?.minDecibels,
      maxDecibels: options?.maxDecibels,
    );
  }
}

web.AudioContext? getNewAudioContext() {
  if (web.window.hasProperty('AudioContext'.toJS).isDefinedAndNotNull) {
    return web.AudioContext(web.AudioContextOptions(
      latencyHint: 'interactive'.toJS,
    ));
  }
  return null;
}

AudioAnalyser? createAudioAnalyser(
  AudioTrack track,
  AudioAnalyserOptions? options,
) {
  final opts = AudioAnalyserOptions.from(options);

  final audioContext = getNewAudioContext();

  if (audioContext == null) {
    throw Exception('Audio Context not supported on this browser');
  }
  final streamTrack = opts.cloneTrack == true
      ? track.mediaStreamTrack.clone()
      : track.mediaStreamTrack;
  final mediaStreamSource = audioContext.createMediaStreamSource(MediaStreamWeb(
          web.MediaStream([(streamTrack as MediaStreamTrackWeb).jsTrack].toJS),
          '')
      .jsStream);
  final analyser = audioContext.createAnalyser();
  analyser.minDecibels = opts.minDecibels ?? -100;
  analyser.maxDecibels = opts.maxDecibels ?? -80;
  analyser.fftSize = opts.fftSize?.toInt() ?? 2048;
  analyser.smoothingTimeConstant = opts.smoothingTimeConstant ?? 0.8;

  mediaStreamSource.connect(analyser);
  final dataArray = Uint8List(analyser.frequencyBinCount);

  /// Calculates the current volume of the track in the range from 0 to 1
  double calculateVolume() {
    analyser.getByteFrequencyData(dataArray.toJS);
    num sum = 0;
    for (var amplitude in dataArray) {
      sum += math.pow(amplitude / 255, 2);
    }
    final volume = math.sqrt(sum / dataArray.length);
    return volume;
  }

  Future<void> cleanup() async {
    await audioContext.close().toDart;
    if (opts.cloneTrack == true) {
      await streamTrack.stop();
    }
  }

  return AudioAnalyser(
    calculateVolume: calculateVolume,
    analyser: analyser,
    cleanup: cleanup,
  );
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
    this.bands = 5,
    this.loPass = 100,
    this.hiPass = 600,
    this.updateInterval = 32,
    this.analyserOptions = const AudioAnalyserOptions(),
  });
}

List<double> normalizeFrequencies(List<double> frequencies) {
  double normalizeDb(double value) {
    final minDb = -100;
    final maxDb = -10;
    var db = 1 - (math.max(minDb, math.min(maxDb, value)) * -1) / 100;
    db = math.sqrt(db);

    return db;
  }

  // Normalize all frequency values
  return frequencies.map((value) {
    if (value.isInfinite || value.isNaN) {
      return 0.toDouble();
    }
    return normalizeDb(value);
  }).toList();
}

void createAudioVisualizer(
    AudioTrack? track, MultiBandTrackVolumeOptions options) {
  if (track == null) {
    return;
  }

  final analyser = createAudioAnalyser(track, options.analyserOptions);

  final bufferLength = analyser?.analyser.frequencyBinCount;
  final dataArray = Float32List(bufferLength ?? 0);

  updateVolume() {
    analyser?.analyser.getFloatFrequencyData(dataArray.toJS);
    var frequencies = List<double>.filled(dataArray.length, 0);
    for (var i = 0; i < dataArray.length; i++) {
      frequencies[i] = dataArray[i];
    }
    frequencies =
        frequencies.sublist(options.loPass!.toInt(), options.hiPass!.toInt());

    final normalizedFrequencies =
        normalizeFrequencies(frequencies); // is this needed ?
    final chunkSize = (normalizedFrequencies.length / options.bands!)
        .ceil(); // we want logarithmic chunking here
    final chunks = List<double>.filled(options.bands!.toInt(), 0);

    for (var i = 0; i < options.bands!.toInt(); i++) {
      final summedVolumes = normalizedFrequencies
          .sublist(i * chunkSize, (i + 1) * chunkSize)
          .reduce((acc, val) => (acc += val));
      chunks.add(summedVolumes / chunkSize);
    }

    //setFrequencyBands(chunks);
  }

  //const interval = setInterval(updateVolume, opts.updateInterval);

  //return () => {
  //  cleanup();
  //  clearInterval(interval);
  //};
}
