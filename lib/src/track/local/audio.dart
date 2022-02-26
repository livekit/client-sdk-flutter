import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../../proto/livekit_models.pb.dart' as lk_models;
import '../../types/other.dart';
import '../audio_management.dart';
import '../options.dart';
import 'local.dart';

class LocalAudioTrack extends LocalTrack with AudioTrack, AudioManagementMixin {
  // Options used for this track
  @override
  covariant AudioCaptureOptions currentOptions;

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
    AudioCaptureOptions? options,
  ]) async {
    options ??= const AudioCaptureOptions();
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
