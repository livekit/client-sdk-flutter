import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../exceptions.dart';
import 'audio_track.dart';
import 'options.dart';

class LocalAudioTrack extends AudioTrack {
  LocalAudioTrack(
    String name,
    rtc.MediaStreamTrack track,
    rtc.MediaStream stream,
  ) : super(name, track, stream);

  /// Creates a new audio track from the default audio input device.
  static Future<LocalAudioTrack> create([LocalAudioTrackOptions? options]) async {
    // try {
    final stream = await rtc.navigator.mediaDevices.getUserMedia(<String, dynamic>{
      'audio': true,
      'video': false,
    });

    if (stream.getAudioTracks().isEmpty) throw TrackCreateException();

    return LocalAudioTrack('', stream.getAudioTracks().first, stream);
  }
}
