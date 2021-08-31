import '../proto/livekit_models.pb.dart';
import 'track.dart';

/// Represents a track that's published to the server. This class contains
/// metadata associated with tracks.
class TrackPublication {
  Track? track;
  String name;
  String sid;
  TrackType kind;
  bool muted = false;
  bool simulcasted = false;
  TrackDimension? dimension;

  bool get subscribed => track != null;

  TrackPublication.fromInfo(TrackInfo info)
      : sid = info.sid,
        name = info.name,
        kind = info.type {
    updateFromInfo(info);
  }

  /// True when the track is published with name [Track.screenShareName].
  bool get isScreenShare =>
      kind == TrackType.VIDEO && name == Track.screenShareName;

  void updateFromInfo(TrackInfo info) {
    muted = info.muted;
    simulcasted = info.simulcast;
    if (info.type == TrackType.VIDEO) {
      dimension = TrackDimension(info.width, info.height);
    }
  }
}
