import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:livekit_client/src/events.dart' show AudioVisualizerEvent;
import 'package:livekit_client/src/track/local/local.dart';
import '../support/native.dart' show Native;
import 'local/visualizer.dart';

class VisualizerNative implements Visualizer {
  final _events = StreamController<AudioVisualizerEvent>.broadcast(sync: true);
  @override
  Stream<AudioVisualizerEvent> get events => _events.stream;
  EventChannel? _eventChannel;
  StreamSubscription? _streamSubscription;
  final AudioTrack? _audioTrack;
  MediaStreamTrack get mediaStreamTrack => _audioTrack!.mediaStreamTrack;

  final VisualizerOptions visualizerOptions;
  VisualizerNative(this._audioTrack, {required this.visualizerOptions});

  @override
  Future<void> startVisualizer() async {
    if (_eventChannel != null) {
      return;
    }

    await Native.startVisualizer(
      mediaStreamTrack.id!,
      isCentered: visualizerOptions.isCentered,
      barCount: visualizerOptions.barCount,
    );

    _eventChannel = EventChannel(
        'io.livekit.audio.visualizer/eventChannel-${mediaStreamTrack.id}');
    _streamSubscription =
        _eventChannel?.receiveBroadcastStream().listen((event) {
      //logger.fine('[$objectId] visualizer event(${event})');
      _events.add(AudioVisualizerEvent(
        track: _audioTrack!,
        event: event,
      ));
    });
  }

  @override
  Future<void> stopVisualizer() async {
    if (_eventChannel == null) {
      return;
    }

    await Native.stopVisualizer(mediaStreamTrack.id!);

    _events.add(AudioVisualizerEvent(
      track: _audioTrack!,
      event: [],
    ));

    await _streamSubscription?.cancel();
    _streamSubscription = null;
    _eventChannel = null;
    await _events.close();
  }
}

Visualizer createVisualizerImpl(AudioTrack track,
        {VisualizerOptions? options}) =>
    VisualizerNative(track, visualizerOptions: options ?? VisualizerOptions());
