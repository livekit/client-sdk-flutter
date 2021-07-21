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

  bool get isSubscribed => track != null;

  TrackPublication({required this.sid, required this.name, required this.kind});

  TrackPublication.fromInfo(TrackInfo info)
      : sid = info.sid,
        name = info.name,
        kind = info.type {
    _updateFromInfo(info);
  }

  _updateFromInfo(TrackInfo info) {
    muted = info.muted;
    simulcasted = info.simulcast;
    if (info.type == TrackType.VIDEO) {
      dimension = new TrackDimension(info.width, info.height);
    }
  }
}
