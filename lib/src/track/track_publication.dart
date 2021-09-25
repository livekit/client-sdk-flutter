import '../classes/disposable.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../types.dart';
import 'track.dart';

/// Represents a track that's published to the server. This class contains
/// metadata associated with tracks.
///
/// Base for [RemoteTrackPublication] and [LocalTrackPublication],
/// can not be instantiated directly.

abstract class TrackPublication extends Disposable {
  final String sid;
  final String name;
  final lk_models.TrackType kind;

  Track? track;
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

  // Equality operators
  // Object is considered equal when sid is equal
  @override
  int get hashCode => sid.hashCode;

  @override
  bool operator ==(Object other) => other is TrackPublication && sid == other.sid;
}
