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

class AudioAnalyserOptions {
  bool? cloneTrack;
  num? fftSize;
  num? smoothingTimeConstant;
  num? minDecibels;
  num? maxDecibels;
  AudioAnalyserOptions({
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

dynamic createAudioAnalyser(
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
  calculateVolume() {
    analyser.getByteFrequencyData(dataArray.toJS);
    num sum = 0;
    for (var amplitude in dataArray) {
      sum += math.pow(amplitude / 255, 2);
    }
    final volume = math.sqrt(sum / dataArray.length);
    return volume;
  }

  cleanup() async {
    await audioContext.close().toDart;
    if (opts.cloneTrack == true) {
      await streamTrack.stop();
    }
  }

  return {calculateVolume, analyser, cleanup};
}
