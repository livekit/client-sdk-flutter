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

import 'package:collection/collection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../../events.dart';
import '../../internal/events.dart';
import '../../proto/livekit_models.pb.dart' as lk_models;
import '../../types/other.dart';
import '../audio_management.dart';
import '../local/local.dart';
import '../stats.dart';
import 'remote.dart';

import '../web/_audio_api.dart' if (dart.library.html) '../web/_audio_html.dart'
    as audio;

class RemoteAudioTrack extends RemoteTrack
    with AudioTrack, RemoteAudioManagementMixin {
  String? _deviceId;
  RemoteAudioTrack(
      TrackSource source, rtc.MediaStream stream, rtc.MediaStreamTrack track,
      {rtc.RTCRtpReceiver? receiver})
      : super(
          lk_models.TrackType.AUDIO,
          source,
          stream,
          track,
          receiver: receiver,
        );

  @override
  Future<bool> start() async {
    final didStart = await super.start();
    if (didStart) {
      try {
        // web support
        await audio.startAudio(getCid(), mediaStreamTrack);
        if (_deviceId != null) {
          audio.setSinkId(getCid(), _deviceId!);
        }
      } catch (e) {
        if (e.toString().startsWith('NotAllowedError')) {
          events.emit(AudioPlaybackFailed(track: this));
        }
      }
    }
    return didStart;
  }

  @override
  Future<bool> stop() async {
    final didStop = await super.stop();
    if (didStop) {
      // web support
      audio.stopAudio(getCid());
    }
    return didStop;
  }

  Future<void> setSinkId(String deviceId) async {
    audio.setSinkId(getCid(), deviceId);
    _deviceId = deviceId;
  }

  AudioReceiverStats? prevStats;
  num? _currentBitrate;
  get currentBitrate => _currentBitrate;

  @override
  Future<bool> monitorStats() async {
    if (receiver == null && events.isDisposed) {
      _currentBitrate = 0;
      return false;
    }
    final stats = await getReceiverStats();

    if (stats != null && prevStats != null && receiver != null) {
      _currentBitrate = computeBitrateForReceiverStats(stats, prevStats);
      events.emit(AudioReceiverStatsEvent(
          stats: stats, currentBitrate: currentBitrate));
    }

    prevStats = stats;
    return true;
  }

  Future<AudioReceiverStats?> getReceiverStats() async {
    if (receiver == null) {
      return null;
    }

    final stats = await receiver!.getStats();
    AudioReceiverStats? receiverStats;
    for (var v in stats) {
      if (v.type == 'inbound-rtp') {
        receiverStats ??= AudioReceiverStats(v.id, v.timestamp);

        receiverStats.jitter = getNumValFromReport(v.values, 'jitter');
        receiverStats.packetsLost =
            getNumValFromReport(v.values, 'packetsLost');
        receiverStats.jitterBufferDelay =
            getNumValFromReport(v.values, 'jitterBufferDelay');
        receiverStats.bytesReceived =
            getNumValFromReport(v.values, 'bytesReceived');
        receiverStats.packetsReceived =
            getNumValFromReport(v.values, 'packetsReceived');
        receiverStats.concealedSamples =
            getNumValFromReport(v.values, 'concealedSamples');
        receiverStats.concealmentEvents =
            getNumValFromReport(v.values, 'concealmentEvents');
        receiverStats.silentConcealedSamples =
            getNumValFromReport(v.values, 'silentConcealedSamples');
        receiverStats.silentConcealmentEvents =
            getNumValFromReport(v.values, 'silentConcealmentEvents');
        receiverStats.totalAudioEnergy =
            getNumValFromReport(v.values, 'totalAudioEnergy');
        receiverStats.totalSamplesDuration =
            getNumValFromReport(v.values, 'totalSamplesDuration');

        final c = stats.firstWhereOrNull((element) => element.type == 'codec');
        if (c != null) {
          receiverStats.mimeType = getStringValFromReport(c.values, 'mimeType');
          receiverStats.payloadType =
              getNumValFromReport(c.values, 'payloadType');
          receiverStats.channels = getNumValFromReport(c.values, 'channels');
          receiverStats.clockRate = getNumValFromReport(c.values, 'clockRate');
        }
        break;
      }
    }
    return receiverStats;
  }
}
