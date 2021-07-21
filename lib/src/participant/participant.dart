import '../proto/livekit_models.pb.dart';
import '../track/track_publication.dart';

mixin ParticipantDelegate {
  void onMetadataChanged(Participant participant);
  void onSpeakingChanged(Participant participant, bool speaking);
}

class Participant {
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

  Participant(this.sid, this.identity);

  ParticipantDelegate? _roomDelegate;
  ParticipantDelegate? delegate;

  ParticipantInfo? _participantInfo;
  bool _isSpeaking = false;

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

  set isSpeaking(bool speaking) {
    if (_isSpeaking != speaking) {
      return;
    }
    _isSpeaking = speaking;
    if (speaking) {
      lastSpokeAt = DateTime.now();
    }
    delegate?.onSpeakingChanged(this, speaking);
    _roomDelegate?.onSpeakingChanged(this, speaking);
  }

  _setMetadata(String md) {
    var changed = this._participantInfo?.metadata != md;
    this.metadata = md;
    if (changed) {
      delegate?.onMetadataChanged(this);
      _roomDelegate?.onMetadataChanged(this);
    }
  }

  _updateInfo(ParticipantInfo info) {
    this.identity = info.identity;
    this.sid = info.sid;
    if (info.metadata.isNotEmpty) {
      _setMetadata(info.metadata);
    }
    this._participantInfo = info;
  }

  _addTrackPublication(TrackPublication pub) {
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
