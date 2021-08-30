import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/src/track/audio_track.dart';

import '../errors.dart';
import 'options.dart';

class LocalAudioTrack extends AudioTrack {
  LocalAudioTrack(String name, MediaStreamTrack track, MediaStream stream)
      : super(name, track, stream);

  static Future<LocalAudioTrack> createTrack(
      [LocalAudioTrackOptions? options]) async {
    try {
      final stream = await navigator.mediaDevices.getUserMedia(<String, dynamic>{
        "audio": true,
        "video": false,
      });

      if (stream.getAudioTracks().isEmpty) {
        return Future.error(TrackCreateError());
      }

      return LocalAudioTrack("", stream.getAudioTracks().first, stream);
    } catch (e) {
      return Future.error(e);
    }
  }
}
