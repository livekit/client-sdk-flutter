import '../proto/livekit_models.pb.dart';
import 'track.dart';

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

  bool get isScreenShare =>
      kind == TrackType.VIDEO && name == Track.ScreenShareName;

  updateFromInfo(TrackInfo info) {
    muted = info.muted;
    simulcasted = info.simulcast;
    if (info.type == TrackType.VIDEO) {
      dimension = TrackDimension(info.width, info.height);
    }
  }
}
