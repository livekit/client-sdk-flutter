import 'package:livekit_client/livekit_client.dart';

const monitorFrequency = 2000;

// key stats for senders and receivers
class SenderStats {
  /// number of packets sent
  num? packetsSent;

  /// number of bytes sent
  num? bytesSent;

  /// jitter as perceived by remote
  num? jitter;

  /// packets reported lost by remote
  num? packetsLost;

  /// RTT reported by remote
  num? roundTripTime;

  /// ID of the outbound stream
  String? streamId;

  num? timestamp;
}

class AudioSenderStats extends SenderStats {
  AudioSenderStats();
  TrackType type = TrackType.AUDIO;
}

class VideoSenderStats extends SenderStats {
  VideoSenderStats();
  TrackType type = TrackType.VIDEO;

  num? firCount;

  num? pliCount;

  num? nackCount;

  String? rid;

  num? frameWidth;

  num? frameHeight;

  num? framesSent;

  // bandwidth, cpu, other, none
  String? qualityLimitationReason;

  num? qualityLimitationResolutionChanges;

  num? retransmittedPacketsSent;
}

class ReceiverStats {
  num? jitterBufferDelay;

  /// packets reported lost by remote
  num? packetsLost;

  /// number of packets sent
  num? packetsReceived;

  num? bytesReceived;

  String? streamId;

  num? jitter;

  num? timestamp;
}

class AudioReceiverStats extends ReceiverStats {
  AudioReceiverStats();
  TrackType type = TrackType.AUDIO;

  num? concealedSamples;

  num? concealmentEvents;

  num? silentConcealedSamples;

  num? silentConcealmentEvents;

  num? totalAudioEnergy;

  num? totalSamplesDuration;
}

class VideoReceiverStats extends ReceiverStats {
  VideoReceiverStats();

  TrackType type = TrackType.VIDEO;

  num? framesDecoded;

  num? framesDropped;

  num? framesReceived;

  num? frameWidth;

  num? frameHeight;

  num? firCount;

  num? pliCount;

  num? nackCount;

  String? decoderImplementation;
}

num computeBitrateForSenderStats(
  SenderStats currentStats,
  SenderStats? prevStats,
) {
  if (prevStats == null) {
    return 0;
  }
  num? bytesNow;
  num? bytesPrev;
  bytesNow = currentStats.bytesSent;
  bytesPrev = prevStats.bytesSent;
  if (bytesNow == null ||
      bytesPrev == null ||
      currentStats.timestamp == null ||
      prevStats.timestamp == null) {
    return 0;
  }
  return ((bytesNow - bytesPrev) * 8 * 1000) /
      (currentStats.timestamp! - prevStats.timestamp!);
}

num computeBitrateForReceiverStats(
  ReceiverStats currentStats,
  ReceiverStats? prevStats,
) {
  if (prevStats == null) {
    return 0;
  }
  num? bytesNow;
  num? bytesPrev;

  bytesNow = currentStats.bytesReceived;
  bytesPrev = prevStats.bytesReceived;

  if (bytesNow == null ||
      bytesPrev == null ||
      currentStats.timestamp == null ||
      prevStats.timestamp == null) {
    return 0;
  }
  return ((bytesNow - bytesPrev) * 8 * 1000) /
      (currentStats.timestamp! - prevStats.timestamp!);
}

num? getNumValFromReport(Map<dynamic, dynamic> values, String key) {
  if (values.containsKey(key)) {
    return (values[key] is String)
        ? num.tryParse(values[key])
        : values[key] as num;
  }
  return null;
}

String? getStringValFromReport(Map<dynamic, dynamic> values, String key) {
  if (values.containsKey(key)) {
    return values[key] as String;
  }
  return null;
}
