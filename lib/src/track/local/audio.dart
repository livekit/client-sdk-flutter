import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../../proto/livekit_models.pb.dart' as lk_models;
import '../../types/other.dart';
import '../audio_management.dart';
import '../options.dart';
import '../stats.dart';
import 'local.dart';

class LocalAudioTrack extends LocalTrack
    with AudioTrack, LocalAudioManagementMixin {
  // Options used for this track
  @override
  covariant AudioCaptureOptions currentOptions;

  Future<void> setDeviceId(String deviceId) async {
    if (currentOptions.deviceId == deviceId) {
      return;
    }
    currentOptions = currentOptions.copyWith(deviceId: deviceId);
    if (!muted) {
      await restartTrack();
    }
  }

  num? _currentBitrate;
  get currentBitrate => _currentBitrate;
  AudioSenderStats? prevStats;

  @override
  Future<void> monitorSender() async {
    if (sender == null) {
      _currentBitrate = 0;
      return;
    }
    final stats = await getSenderStats();

    if (stats != null && prevStats != null && sender != null) {
      _currentBitrate = computeBitrateForSenderStats(stats, prevStats);
    }

    prevStats = stats;
  }

  Future<AudioSenderStats?> getSenderStats() async {
    if (sender == null) {
      return null;
    }

    final stats = await sender!.getStats();
    AudioSenderStats? senderStats;
    for (var v in stats) {
      if (v.type == 'outbound-rtp') {
        senderStats ??= AudioSenderStats();
        senderStats.timestamp = v.timestamp;
        senderStats.streamId = v.id;
        senderStats.bytesSent ??= getNumValFromReport(v.values, 'bytesSent');
        senderStats.packetsLost ??=
            getNumValFromReport(v.values, 'packetsLost');
        senderStats.bytesSent ??= getNumValFromReport(v.values, 'bytesSent');
        senderStats.roundTripTime ??=
            getNumValFromReport(v.values, 'roundTripTime');
        senderStats.jitter ??= getNumValFromReport(v.values, 'jitter');
      }
    }
    return senderStats;
  }

  // private constructor
  @internal
  LocalAudioTrack(
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

    return LocalAudioTrack(
      '',
      TrackSource.microphone,
      stream,
      stream.getAudioTracks().first,
      options,
    );
  }
}
