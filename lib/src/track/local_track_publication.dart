import '../events.dart';
import '../extensions.dart';
import '../logger.dart';
import '../managers/event.dart';
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
    _participant.engine.signalClient.sendMuteTrack(sid, val);

    if (val) {
      // Track muted
      [_participant.events, _participant.roomEvents].emit(TrackMutedEvent(
        participant: _participant,
        track: this,
      ));
    } else {
      // Track un-muted
      [_participant.events, _participant.roomEvents].emit(TrackUnmutedEvent(
        participant: _participant,
        track: this,
      ));
    }
  }
}
