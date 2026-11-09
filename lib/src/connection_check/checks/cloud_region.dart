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

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../../participant/local.dart';
import '../../stats/stats.dart';
import '../../support/region_url_provider.dart';
import '../../types/data_stream.dart';
import 'checker.dart';

/// Connection statistics for a single LiveKit Cloud region.
class RegionStats {
  const RegionStats({
    required this.region,
    required this.rtt,
    required this.duration,
  });

  final String region;

  /// Current round trip time in milliseconds.
  final num rtt;

  /// Time in milliseconds it took to send 1MB of data to the region.
  final num duration;

  @override
  String toString() => '$runtimeType(region: $region, rtt: $rtt, duration: $duration)';
}

/// Checks connection quality to the closest LiveKit Cloud regions and
/// determines the one with the best quality.
///
/// Skipped when the server is not a LiveKit Cloud instance.
class CloudRegionCheck extends Checker {
  CloudRegionCheck(super.url, super.token, {super.options, super.room});

  RegionStats? _bestStats;

  @override
  String get description => 'Cloud regions';

  @override
  Object? get data => _bestStats;

  @override
  Future<void> perform() async {
    final regionProvider = RegionUrlProvider(
      url: url,
      token: token,
      networkOptions: networkOptions,
    );
    if (!regionProvider.isCloud()) {
      skip();
      return;
    }

    final regionStats = <RegionStats>[];
    final seenUrls = <String>{};
    for (var i = 0; i < 3; i++) {
      final regionUrl = await regionProvider.getNextBestRegionUrl();
      if (regionUrl == null) {
        break;
      }
      if (!seenUrls.add(regionUrl)) {
        continue;
      }
      final stats = await _checkCloudRegion(regionUrl);
      appendMessage('${stats.region} RTT: ${stats.rtt}ms, duration: ${stats.duration}ms');
      regionStats.add(stats);
    }

    if (regionStats.isEmpty) {
      throw const CheckException('No regions could be checked');
    }
    regionStats.sort((a, b) {
      final score = (a.duration - b.duration) * 0.5 + (a.rtt - b.rtt) * 0.5;
      return score.compareTo(0);
    });
    final bestRegion = regionStats.first;
    _bestStats = bestRegion;
    appendMessage('best Cloud region: ${bestRegion.region}');
  }

  Future<RegionStats> _checkCloudRegion(String url) async {
    await connect(url);
    if (options.protocol == CheckProtocol.tcp) {
      await switchProtocol(CheckProtocol.tcp);
    }
    final region = room.serverRegion;
    if (region == null || region.isEmpty) {
      throw const CheckException('Region not found');
    }

    final localParticipant = room.localParticipant;
    if (localParticipant == null) {
      throw const CheckException('Room has no local participant');
    }

    // send ~1MB of data over a text stream and measure how long it takes
    final writer = await localParticipant.streamText(StreamTextOptions(topic: 'test'));
    const chunkSize = 1000; // each chunk is about 1000 bytes
    const totalSize = 1000000; // approximately 1MB of data
    const numChunks = totalSize ~/ chunkSize; // will yield 1000 chunks
    final chunkData = 'A' * chunkSize;

    final stopwatch = Stopwatch()..start();
    for (var i = 0; i < numChunks; i++) {
      await writer.write(chunkData);
    }
    await writer.close();
    stopwatch.stop();

    num rtt = 10000;
    final publisherPc = engine.publisher?.pc;
    if (publisherPc != null) {
      rtt = await _currentRoundTripTimeMs(publisherPc) ?? rtt;
    }
    final regionStats = RegionStats(
      region: region,
      rtt: rtt,
      duration: stopwatch.elapsedMilliseconds,
    );

    await disconnect();
    return regionStats;
  }
}

/// Reads the current round trip time (in milliseconds) of the selected
/// candidate pair from [pc]'s stats, or null when unavailable.
Future<num?> _currentRoundTripTimeMs(rtc.RTCPeerConnection pc) async {
  final stats = await pc.getStats();
  String? selectedPairId;
  final candidatePairs = <String, rtc.StatsReport>{};
  rtc.StatsReport? selectedPair;
  for (final report in stats) {
    if (report.type == 'transport') {
      selectedPairId = getStringValFromReport(report.values, 'selectedCandidatePairId') ?? selectedPairId;
    } else if (report.type == 'candidate-pair') {
      candidatePairs[report.id] = report;
      // fallback for platforms that don't report a transport stat
      final selected = getBoolValFromReport(report.values, 'selected');
      final nominated = getBoolValFromReport(report.values, 'nominated');
      if (selected || (nominated && selectedPair == null)) {
        selectedPair = report;
      }
    }
  }
  if (selectedPairId != null) {
    selectedPair = candidatePairs[selectedPairId] ?? selectedPair;
  }
  if (selectedPair == null) {
    return null;
  }
  final rttSeconds = getNumValFromReport(selectedPair.values, 'currentRoundTripTime');
  if (rttSeconds == null) {
    return null;
  }
  return rttSeconds * 1000;
}
