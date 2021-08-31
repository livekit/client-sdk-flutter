import 'package:flutter/foundation.dart';

import 'remote_participant.dart';
import '../proto/livekit_models.pb.dart';
import '../track/remote_track_publication.dart';
import '../track/track.dart';
import '../track/track_publication.dart';

/// Callbacks for participant changes
mixin ParticipantDelegate {
  /// The participant's metadata has changed
  void onMetadataChanged(Participant participant) {}

  /// The participant's isSpeaking property has changed
  void onSpeakingChanged(Participant participant, bool speaking) {}

  /// This participant has muted one of their tracks
  void onTrackMuted(Participant participant, TrackPublication publication) {}

  /// This participant has unmuted one of their tracks
  void onTrackUnmuted(Participant participant, TrackPublication publication) {}

  /// This participant has published a new [Track] to the [Room].
  void onTrackPublished(RemoteParticipant participant, RemoteTrackPublication publication) {}

  /// This participant has unpublished one of their [Track].
  void onTrackUnpublished(RemoteParticipant participant, RemoteTrackPublication publication) {}

  /// The [LocalParticipant] has subscribed to a new track published by this
  /// [RemoteParticipant]
  void onTrackSubscribed(
      RemoteParticipant participant, Track track, RemoteTrackPublication publication) {}

  /// The [LocalParticipant] has unsubscribed from a track published by this
  /// [RemoteParticipant]. This event is fired when the track was unpublished
  void onTrackUnsubscribed(
      RemoteParticipant participant, Track track, RemoteTrackPublication publication) {}

  /// Data received from this [RemoteParticipant].
  void onDataReceived(RemoteParticipant participant, List<int> data) {}

  /// An error has occured during track subscription.
  void onTrackSubscriptionFailed(RemoteParticipant participant, String sid, String? message) {}
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
    final pi = _participantInfo;
    if (pi != null) {
      return DateTime.fromMillisecondsSinceEpoch(pi.joinedAt.toInt() * 1000, isUtc: true);
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

  bool get hasAudio => audioTracks.isNotEmpty;

  bool get hasVideo => videoTracks.isNotEmpty;

  /// tracks that are subscribed to
  List<TrackPublication> get subscribedTracks {
    List<TrackPublication> result = [];
    for (final track in tracks.values) {
      if (track.subscribed) {
        result.add(track);
      }
    }
    return result;
  }

  /// for internal use
  /// {@nodoc}
  bool get hasInfo => _participantInfo != null;

  Participant(this.sid, this.identity);

  /// for internal use
  /// {@nodoc}
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

  void _setMetadata(String md) {
    final changed = _participantInfo?.metadata != md;
    metadata = md;
    if (changed) {
      delegate?.onMetadataChanged(this);
      roomDelegate?.onMetadataChanged(this);
      notifyListeners();
    }
  }

  /// for internal use
  /// {@nodoc}
  void updateFromInfo(ParticipantInfo info) {
    identity = info.identity;
    sid = info.sid;
    if (info.metadata.isNotEmpty) {
      _setMetadata(info.metadata);
    }
    _participantInfo = info;
  }

  /// for internal use
  /// {@nodoc}
  void muteChanged() {
    notifyListeners();
  }

  /// for internal use
  /// {@nodoc}
  void addTrackPublication(TrackPublication pub) {
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
