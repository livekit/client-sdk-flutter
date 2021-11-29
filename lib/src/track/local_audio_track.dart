import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../exceptions.dart';
import '../logger.dart';
import '../types.dart';
import 'audio_track.dart';
import 'local_track.dart';
import 'options.dart';

class LocalAudioTrack extends AudioTrack with LocalTrack {
  // private constructor
  LocalAudioTrack._(
    TrackSource source,
    String name,
    rtc.MediaStreamTrack track,
    rtc.MediaStream stream,
  ) : super(source, name, track, stream);

  /// Creates a new audio track from the default audio input device.
  static Future<LocalAudioTrack> create(
      [LocalAudioTrackOptions? options]) async {
    final audioConstraints = options?.toMediaConstraintsMap() ??
        const LocalAudioTrackOptions().toMediaConstraintsMap();
    final stream =
        await rtc.navigator.mediaDevices.getUserMedia(<String, dynamic>{
      'audio': audioConstraints,
      'video': false,
    });

    if (stream.getAudioTracks().isEmpty) throw TrackCreateException();

    return LocalAudioTrack._(
      TrackSource.microphone,
      '',
      stream.getAudioTracks().first,
      stream,
    );
  }

  @override
  Future<bool> stop() async {
    final didStop = await super.stop();
    if (didStop) {
      logger.fine('Stopping mediaStreamTrack...');
      await mediaStreamTrack.stop();
    }
    return didStop;
  }
}
