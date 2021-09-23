import '../events.dart';
import '../logger.dart';
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
    if (val == muted) return;
    logger.finer('setMute: ${val}');

    super.muted = val;
    track?.mediaStreamTrack.enabled = !val;
    _participant.engine.client.sendMuteTrack(sid, val);

    if (val) {
      final event = TrackMutedEvent(
        participant: _participant,
        track: this,
      );
      _participant.events.emit(event);
      _participant.roomEvents.emit(event);
    } else {
      final event = TrackUnmutedEvent(
        participant: _participant,
        track: this,
      );
      _participant.events.emit(event);
      _participant.roomEvents.emit(event);
    }
    _participant.muteChanged();
  }
}
