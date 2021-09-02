import '../proto/livekit_models.pb.dart' as lk_models;
import 'track.dart';

/// Represents a track that's published to the server. This class contains
/// metadata associated with tracks.
class TrackPublication {
  Track? track;
  String name;
  String sid;
  lk_models.TrackType kind;
  bool muted = false;
  bool simulcasted = false;
  TrackDimension? dimension;

  bool get subscribed => track != null;

  TrackPublication.fromInfo(lk_models.TrackInfo info)
      : sid = info.sid,
        name = info.name,
        kind = info.type {
    updateFromInfo(info);
  }

  /// True when the track is published with name [Track.screenShareName].
  bool get isScreenShare => kind == lk_models.TrackType.VIDEO && name == Track.screenShareName;

  void updateFromInfo(lk_models.TrackInfo info) {
    muted = info.muted;
    simulcasted = info.simulcast;
    if (info.type == lk_models.TrackType.VIDEO) {
      dimension = TrackDimension(info.width, info.height);
    }
  }
}
