import '../participant/local_participant.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import 'track.dart';
import 'track_publication.dart';

class LocalTrackPublication extends TrackPublication {
  final LocalParticipant _participant;

  LocalTrackPublication(
    lk_models.TrackInfo info,
    Track track,
    this._participant,
  ) : super.fromInfo(info) {
    this.track = track;
  }

  /// Mute or unmute the current track. When muted, track will stop sending data
  @override
  set muted(bool val) {
    if (val == muted) {
      return;
    }
    super.muted = val;
    track?.mediaTrack.enabled = !val;
    _participant.engine.client.sendMuteTrack(sid, val);

    if (val) {
      _participant.delegate?.onTrackMuted(_participant, this);
      _participant.roomDelegate?.onTrackMuted(_participant, this);
    } else {
      _participant.delegate?.onTrackUnmuted(_participant, this);
      _participant.roomDelegate?.onTrackUnmuted(_participant, this);
    }
    _participant.muteChanged();
  }
}
