// Copyright 2026 LiveKit, Inc.
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

import 'package:flutter/foundation.dart';

import '../../options.dart';
import '../../publication/local.dart';
import '../../stats/stats.dart';
import '../../track/local/video.dart';
import '../../types/video_encoding.dart';
import 'checker.dart';

/// Aggregated upstream statistics gathered while publishing over a single
/// connection protocol.
class ProtocolStats {
  ProtocolStats({required this.protocol});

  final CheckProtocol protocol;
  num packetsLost = 0;
  num packetsSent = 0;

  /// Approximate time (in seconds) the encoder was limited, keyed by reason
  /// (e.g. `bandwidth`, `cpu`). Sampled from `qualityLimitationReason` once
  /// per stats interval.
  final Map<String, num> qualityLimitationDurations = {};

  // total metrics measure sum of all measurements, along with a count
  num rttTotal = 0;
  num jitterTotal = 0;
  num bitrateTotal = 0;
  int count = 0;

  @override
  String toString() => '$runtimeType(protocol: ${protocol.name}, packetsSent: $packetsSent, '
      'packetsLost: $packetsLost, count: $count)';
}

const _testDuration = Duration(seconds: 10);
const _statsInterval = Duration(seconds: 1);

/// Compares connection quality between UDP and TCP and determines the better
/// protocol for the current network.
///
/// Unlike client-sdk-js, which publishes an animated canvas track, this check
/// publishes a camera track to generate upstream traffic — so camera
/// permissions are required.
class ConnectionProtocolCheck extends Checker {
  ConnectionProtocolCheck(super.url, super.token, {super.options, super.room});

  ProtocolStats? _bestStats;

  @override
  String get description => 'Connection via UDP vs TCP';

  @override
  Object? get data => _bestStats;

  @override
  Future<void> perform() async {
    final udpStats = await _checkConnectionProtocol(CheckProtocol.udp);
    final tcpStats = await _checkConnectionProtocol(CheckProtocol.tcp);
    _bestStats = udpStats;
    // udp is typically the better protocol. however, we'd prefer TCP when
    // either of these conditions are true:
    // 1. the bandwidth limitation is worse on UDP by 500ms
    // 2. the packet loss is higher on UDP by 1%
    final udpBandwidthLimit = udpStats.qualityLimitationDurations['bandwidth'] ?? 0;
    final tcpBandwidthLimit = tcpStats.qualityLimitationDurations['bandwidth'] ?? 0;
    if (udpBandwidthLimit - tcpBandwidthLimit > 0.5 ||
        (udpStats.packetsSent > 0 && (udpStats.packetsLost - tcpStats.packetsLost) / udpStats.packetsSent > 0.01)) {
      appendMessage('best connection quality via tcp');
      _bestStats = tcpStats;
    } else {
      appendMessage('best connection quality via udp');
    }

    final stats = _bestStats!;
    if (stats.count > 0) {
      // computeBitrateForSenderStats returns bits-per-second on native
      // platforms and kilobits-per-second on web. Normalize the average to
      // megabits-per-second before displaying.
      final avgBitrate = stats.bitrateTotal / stats.count;
      final avgMbps = kIsWeb ? avgBitrate / 1e3 : avgBitrate / 1e6;
      appendMessage('upstream bitrate: ${avgMbps.toStringAsFixed(2)} mbps');
      appendMessage('RTT: ${(stats.rttTotal / stats.count * 1000).toStringAsFixed(2)} ms');
      appendMessage('jitter: ${(stats.jitterTotal / stats.count * 1000).toStringAsFixed(2)} ms');
    }

    if (stats.packetsLost > 0 && stats.packetsSent > 0) {
      appendWarning('packets lost: ${(stats.packetsLost / stats.packetsSent * 100).toStringAsFixed(2)}%');
    }
    final bandwidthLimited = stats.qualityLimitationDurations['bandwidth'] ?? 0;
    if (bandwidthLimited > 1) {
      appendWarning('bandwidth limited ${(bandwidthLimited / _testDuration.inSeconds * 100).toStringAsFixed(2)}%');
    }
    final cpuLimited = stats.qualityLimitationDurations['cpu'] ?? 0;
    if (cpuLimited > 0) {
      appendWarning('cpu limited ${(cpuLimited / _testDuration.inSeconds * 100).toStringAsFixed(2)}%');
    }
  }

  Future<ProtocolStats> _checkConnectionProtocol(CheckProtocol protocol) async {
    await connect();
    await switchProtocol(protocol);

    // client-sdk-js publishes an animated canvas track here; canvas capture
    // isn't available in Flutter, so publish a camera track instead to
    // generate upstream traffic.
    final track = await LocalVideoTrack.createCameraTrack();
    late final LocalTrackPublication<LocalVideoTrack> pub;
    final localParticipant = room.localParticipant;
    try {
      if (localParticipant == null) {
        throw const CheckException('Room has no local participant');
      }
      pub = await localParticipant.publishVideoTrack(
        track,
        publishOptions: const VideoPublishOptions(
          simulcast: false,
          degradationPreference: DegradationPreference.maintainResolution,
          videoEncoding: VideoEncoding(
            maxBitrate: 2000000,
            maxFramerate: 30,
          ),
        ),
      );
    } catch (err) {
      // the room won't clean up a track that was never published,
      // so stop capturing here
      await track.dispose();
      rethrow;
    }

    final protocolStats = ProtocolStats(protocol: protocol);
    // prime the previous sample so every counted sample has a bitrate
    final initialLayers = await track.getSenderStats();
    VideoSenderStats? prevStats = initialLayers.isEmpty ? null : initialLayers.first;

    // gather stats once a second
    final samples = _testDuration.inMilliseconds ~/ _statsInterval.inMilliseconds;
    for (var i = 0; i < samples; i++) {
      await Future<void>.delayed(_statsInterval);
      final layers = await track.getSenderStats();
      if (layers.isEmpty) {
        continue;
      }
      // simulcast is disabled, so there is a single layer
      final stats = layers.first;
      protocolStats.packetsSent = stats.packetsSent ?? protocolStats.packetsSent;
      protocolStats.packetsLost = stats.packetsLost ?? protocolStats.packetsLost;
      final limitationReason = stats.qualityLimitationReason;
      if (limitationReason != null && limitationReason.isNotEmpty && limitationReason != 'none') {
        // browsers report cumulative `qualityLimitationDurations` directly;
        // approximate it by sampling the limitation reason once per interval.
        protocolStats.qualityLimitationDurations[limitationReason] =
            (protocolStats.qualityLimitationDurations[limitationReason] ?? 0) + _statsInterval.inSeconds;
      }
      protocolStats.bitrateTotal += computeBitrateForSenderStats(stats, prevStats);
      protocolStats.rttTotal += stats.roundTripTime ?? 0;
      protocolStats.jitterTotal += stats.jitter ?? 0;
      protocolStats.count++;
      prevStats = stats;
    }

    await localParticipant.removePublishedTrack(pub.sid);
    await disconnect();
    return protocolStats;
  }
}
