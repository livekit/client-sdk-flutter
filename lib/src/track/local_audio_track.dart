import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../proto/livekit_models.pb.dart' as lk_models;
import '../types.dart';
import 'audio_management.dart';
import 'local_track.dart';
import 'options.dart';

class LocalAudioTrack extends LocalTrack with AudioTrack, AudioManagementMixin {
  // Options used for this track
  @override
  covariant LocalAudioTrackOptions currentOptions;

  // private constructor
  LocalAudioTrack._(
    String name,
    TrackSource source,
    rtc.MediaStream stream,
    rtc.MediaStreamTrack track,
    this.currentOptions,
  ) : super(
          name,
          lk_models.TrackType.AUDIO,
          source,
          stream,
          track,
        );

  /// Creates a new audio track from the default audio input device.
  static Future<LocalAudioTrack> create([
    LocalAudioTrackOptions? options,
  ]) async {
    options ??= const LocalAudioTrackOptions();
    final stream = await LocalTrack.createStream(options);

    return LocalAudioTrack._(
      '',
      TrackSource.microphone,
      stream,
      stream.getAudioTracks().first,
      options,
    );
  }
}
