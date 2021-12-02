import 'package:meta/meta.dart';

import '../extensions.dart';
import '../participant/participant.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../support/disposable.dart';
import '../track/track.dart';
import '../types.dart';

/// Represents a track that's published to the server. This class contains
/// metadata associated with tracks.
///
/// Base for [RemoteTrackPublication] and [LocalTrackPublication],
/// can not be instantiated directly.

abstract class TrackPublication<T extends Track> extends Disposable {
  final String sid;
  final String name;
  final lk_models.TrackType kind;
  final TrackSource source;

  /// The current [Track] for this publication (readonly).
  T? get track => _track;
  T? _track;

  /// The [Participant] this publication belongs to.
  abstract final Participant participant;

  // metadata-muted
  bool _muted = false;
  bool get muted => _muted;

  bool simulcasted = false;
  TrackDimension? dimension;

  bool get subscribed => track != null;

  TrackPublication({
    required lk_models.TrackInfo info,
  })  : sid = info.sid,
        name = info.name,
        kind = info.type,
        source = info.source.toLKType() {
    updateFromInfo(info);
  }

  /// True when the track is published with name [Track.screenShareName].
  bool get isScreenShare =>
      kind == lk_models.TrackType.VIDEO && name == Track.screenShareName;

  void updateFromInfo(lk_models.TrackInfo info) {
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
  bool operator ==(Object other) =>
      other is TrackPublication && sid == other.sid;

  @internal
  void updateMuted(bool muted) => _muted = muted;

  // Update track to new value, dispose previous if exists.
  // Returns true if value has changed.
  // Intended for internal use only.
  @internal
  Future<bool> updateTrack(T? newValue) async {
    if (_track == newValue) return false;
    // dispose previous track (if exists)
    await _track?.dispose();
    _track = newValue;
    return true;
  }
}
