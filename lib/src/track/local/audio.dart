// Copyright 2023 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../../events.dart';
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
  Future<bool> monitorStats() async {
    if (sender == null || events.isDisposed) {
      _currentBitrate = 0;
      return false;
    }
    final stats = await getSenderStats();

    if (stats != null && prevStats != null && sender != null) {
      _currentBitrate = computeBitrateForSenderStats(stats, prevStats);
      events.emit(
          AudioSenderStatsEvent(stats: stats, currentBitrate: currentBitrate));
    }

    prevStats = stats;
    return true;
  }

  Future<AudioSenderStats?> getSenderStats() async {
    if (sender == null) {
      return null;
    }

    final stats = await sender!.getStats();
    AudioSenderStats? senderStats;
    for (var v in stats) {
      if (v.type == 'outbound-rtp') {
        senderStats ??= AudioSenderStats(v.id, v.timestamp);
        senderStats.packetsSent = getNumValFromReport(v.values, 'packetsSent');
        senderStats.packetsLost = getNumValFromReport(v.values, 'packetsLost');
        senderStats.bytesSent = getNumValFromReport(v.values, 'bytesSent');
        senderStats.roundTripTime =
            getNumValFromReport(v.values, 'roundTripTime');
        senderStats.jitter = getNumValFromReport(v.values, 'jitter');

        final c = stats.firstWhereOrNull((element) => element.type == 'codec');
        if (c != null) {
          senderStats.mimeType = getStringValFromReport(c.values, 'mimeType');
          senderStats.payloadType =
              getNumValFromReport(c.values, 'payloadType');
          senderStats.channels = getNumValFromReport(c.values, 'channels');
          senderStats.clockRate = getNumValFromReport(c.values, 'clockRate');
        }
        break;
      }
    }
    return senderStats;
  }

  // private constructor
  @internal
  LocalAudioTrack(
    TrackSource source,
    rtc.MediaStream stream,
    rtc.MediaStreamTrack track,
    this.currentOptions,
  ) : super(
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
      TrackSource.microphone,
      stream,
      stream.getAudioTracks().first,
      options,
    );
  }
}
