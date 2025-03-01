import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:livekit_client/src/events.dart' show AudioVisualizerEvent;
import 'package:livekit_client/src/track/local/local.dart';
import '../support/native.dart' show Native;
import 'visualizer.dart';

class VisualizerNative extends Visualizer {
  final String visualizerId = '${DateTime.now().millisecondsSinceEpoch}';
  EventChannel? _eventChannel;
  StreamSubscription? _streamSubscription;
  final AudioTrack? _audioTrack;
  MediaStreamTrack get mediaStreamTrack => _audioTrack!.mediaStreamTrack;
  final VisualizerOptions visualizerOptions;
  VisualizerNative(this._audioTrack, {required this.visualizerOptions}) {
    onDispose(() async {
      await events.dispose();
    });
  }

  @override
  Future<void> start() async {
    if (_eventChannel != null) {
      return;
    }

    await Native.startVisualizer(
      mediaStreamTrack.id!,
      isCentered: visualizerOptions.centeredBands,
      barCount: visualizerOptions.barCount,
      visualizerId: visualizerId,
    );

    _eventChannel = EventChannel(
        'io.livekit.audio.visualizer/eventChannel-${mediaStreamTrack.id}-$visualizerId');
    _streamSubscription =
        _eventChannel?.receiveBroadcastStream().listen((event) {
      //logger.fine('[$objectId] visualizer event(${event})');
      events.emit(AudioVisualizerEvent(
        track: _audioTrack!,
        event: event,
      ));
    });
  }

  @override
  Future<void> stop() async {
    if (_eventChannel == null) {
      return;
    }

    await Native.stopVisualizer(mediaStreamTrack.id!,
        visualizerId: visualizerId);

    events.emit(AudioVisualizerEvent(
      track: _audioTrack!,
      event: [],
    ));

    await _streamSubscription?.cancel();
    _streamSubscription = null;
    _eventChannel = null;
  }
}

Visualizer createVisualizerImpl(AudioTrack track,
        {VisualizerOptions? options}) =>
    VisualizerNative(track, visualizerOptions: options ?? VisualizerOptions());
