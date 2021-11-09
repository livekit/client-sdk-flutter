import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../exceptions.dart';
import '../logger.dart';
import 'audio_track.dart';
import 'options.dart';

class LocalAudioTrack extends AudioTrack {
  // private constructor
  LocalAudioTrack._(
    String name,
    rtc.MediaStreamTrack track,
    rtc.MediaStream stream,
  ) : super(name, track, stream);

  /// Creates a new audio track from the default audio input device.
  static Future<LocalAudioTrack> create(
      [LocalAudioTrackOptions? options]) async {
    // TODO: have back up incase the options fail
    final stream =
        await rtc.navigator.mediaDevices.getUserMedia(<String, dynamic>{
      // 'audio': <String, dynamic>{
      // 'echoCancellation': true,
      // 'noiseSuppression': true,
      // },
      'audio': true,
      'video': false,
    });

    if (stream.getAudioTracks().isEmpty) throw TrackCreateException();

    return LocalAudioTrack._('', stream.getAudioTracks().first, stream);
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
