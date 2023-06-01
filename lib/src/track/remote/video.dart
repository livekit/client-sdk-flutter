import 'package:collection/collection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../../events.dart';
import '../../proto/livekit_models.pb.dart' as lk_models;
import '../../types/other.dart';
import '../local/local.dart';
import '../stats.dart';
import 'remote.dart';

class RemoteVideoTrack extends RemoteTrack with VideoTrack {
  RemoteVideoTrack(String name, TrackSource source, rtc.MediaStream stream,
      rtc.MediaStreamTrack track,
      {rtc.RTCRtpReceiver? receiver})
      : super(
          name,
          lk_models.TrackType.VIDEO,
          source,
          stream,
          track,
          receiver: receiver,
        );

  VideoReceiverStats? prevStats;
  num? _currentBitrate;
  get currentBitrate => _currentBitrate;

  @internal
  String? getDecoderImplementation() {
    return prevStats?.decoderImplementation;
  }

  @override
  Future<void> monitorReceiver() async {
    if (receiver == null) {
      _currentBitrate = 0;
      return;
    }
    final stats = await getReceiverStats();

    if (stats != null && prevStats != null && receiver != null) {
      _currentBitrate = computeBitrateForReceiverStats(stats, prevStats);
      events.emit(VideoReceiverStatsEvent(
          stats: stats, currentBitrate: currentBitrate));
    }

    prevStats = stats;
  }

  Future<VideoReceiverStats?> getReceiverStats() async {
    if (receiver == null) {
      return null;
    }

    final stats = await receiver!.getStats();
    VideoReceiverStats? receiverStats;
    for (var v in stats) {
      if (v.type == 'inbound-rtp') {
        receiverStats ??= VideoReceiverStats(v.id, v.timestamp);
        receiverStats.jitter = getNumValFromReport(v.values, 'jitter');
        receiverStats.jitterBufferDelay =
            getNumValFromReport(v.values, 'jitterBufferDelay');
        receiverStats.bytesReceived =
            getNumValFromReport(v.values, 'bytesReceived');
        receiverStats.packetsLost =
            getNumValFromReport(v.values, 'packetsLost');
        receiverStats.framesDecoded =
            getNumValFromReport(v.values, 'framesDecoded');
        receiverStats.framesDropped =
            getNumValFromReport(v.values, 'framesDropped');
        receiverStats.framesReceived =
            getNumValFromReport(v.values, 'framesReceived');
        receiverStats.packetsReceived =
            getNumValFromReport(v.values, 'packetsReceived');
        receiverStats.framesPerSecond =
            getNumValFromReport(v.values, 'framesPerSecond');
        receiverStats.frameWidth = getNumValFromReport(v.values, 'frameWidth');
        receiverStats.frameHeight =
            getNumValFromReport(v.values, 'frameHeight');
        receiverStats.pliCount = getNumValFromReport(v.values, 'pliCount');
        receiverStats.firCount = getNumValFromReport(v.values, 'firCount');
        receiverStats.nackCount = getNumValFromReport(v.values, 'nackCount');
        receiverStats.decoderImplementation =
            getStringValFromReport(v.values, 'decoderImplementation');

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
