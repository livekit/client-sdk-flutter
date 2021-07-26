import 'package:flutter/foundation.dart';

import 'remote_participant.dart';
import '../proto/livekit_models.pb.dart';
import '../track/remote_track_publication.dart';
import '../track/track.dart';
import '../track/track_publication.dart';

mixin ParticipantDelegate {
  void onMetadataChanged(Participant participant) {}
  void onSpeakingChanged(Participant participant, bool speaking) {}
  void onTrackMuted(Participant participant, TrackPublication publication) {}
  void onTrackUnmuted(Participant participant, TrackPublication publication) {}
  void onTrackPublished(
      RemoteParticipant participant, RemoteTrackPublication publication) {}
  void onTrackUnpublished(
      RemoteParticipant participant, RemoteTrackPublication publication) {}
  void onTrackSubscribed(RemoteParticipant participant, Track track,
      RemoteTrackPublication publication) {}
  void onTrackUnsubscribed(RemoteParticipant participant, Track track,
      RemoteTrackPublication publication) {}
  void onDataReceived(RemoteParticipant participant, List<int> data) {}
  void onTrackSubscriptionFailed(
      RemoteParticipant participant, String sid, String? message) {}
}

/// Represents a Participant in the room, notifies changes via delegates as
/// well as ChangeNotifier/providers.
/// A change notification is triggered when
/// - speaking status changed
/// - mute status changed
/// - added/removed subscribed tracks
/// - metadata changed
class Participant extends ChangeNotifier {
  Map<String, TrackPublication> audioTracks = {};
  Map<String, TrackPublication> videoTracks = {};

  /// map of track sid => published track
  Map<String, TrackPublication> tracks = {};

  /// audio level between 0-1, 1 being the loudest
  double audioLevel = 0;

  /// server assigned unique id
  String sid;

  /// user-assigned identity
  String identity;

  /// client-assigned metadata, opaque to livekit
  String? metadata;

  /// when the participant had last spoken
  DateTime? lastSpokeAt;

  ParticipantDelegate? roomDelegate;

  /// delegate to receive participant callbacks
  ParticipantDelegate? delegate;

  ParticipantInfo? _participantInfo;
  bool _isSpeaking = false;

  /// when the participant joined the room
  DateTime get joinedAt {
    var pi = _participantInfo;
    if (pi != null) {
      return DateTime.fromMillisecondsSinceEpoch((pi.joinedAt as int) * 1000,
          isUtc: true);
    }
    return DateTime.now();
  }

  /// if participant is currently speaking
  bool get isSpeaking => _isSpeaking;

  /// true if participant is publishing an audio track and is muted
  bool get isMuted {
    if (audioTracks.values.isEmpty) {
      return false;
    }
    return audioTracks.values.first.muted;
  }

  bool get hasAudio => audioTracks.length > 0;

  bool get hasVideo => videoTracks.length > 0;

  /// tracks that are subscribed to
  List<TrackPublication> get subscribedTracks {
    List<TrackPublication> result = [];
    for (var track in tracks.values) {
      if (track.subscribed) {
        result.add(track);
      }
    }
    return result;
  }

  /// internal use
  bool get hasInfo => _participantInfo != null;

  Participant(this.sid, this.identity);

  set isSpeaking(bool speaking) {
    if (_isSpeaking == speaking) {
      return;
    }
    _isSpeaking = speaking;
    if (speaking) {
      lastSpokeAt = DateTime.now();
    }
    delegate?.onSpeakingChanged(this, speaking);
    roomDelegate?.onSpeakingChanged(this, speaking);
    notifyListeners();
  }

  _setMetadata(String md) {
    var changed = this._participantInfo?.metadata != md;
    this.metadata = md;
    if (changed) {
      delegate?.onMetadataChanged(this);
      roomDelegate?.onMetadataChanged(this);
      notifyListeners();
    }
  }

  updateFromInfo(ParticipantInfo info) {
    this.identity = info.identity;
    this.sid = info.sid;
    if (info.metadata.isNotEmpty) {
      _setMetadata(info.metadata);
    }
    this._participantInfo = info;
  }

  muteChanged() {
    notifyListeners();
  }

  addTrackPublication(TrackPublication pub) {
    pub.track?.sid = pub.sid;
    tracks[pub.sid] = pub;
    switch (pub.kind) {
      case TrackType.AUDIO:
        audioTracks[pub.sid] = pub;
        break;
      case TrackType.VIDEO:
        videoTracks[pub.sid] = pub;
        break;
      default:
      // nothing
    }
  }
}
