import '../events.dart';
import '../extensions.dart';
import '../internal/events.dart';
import '../participant/local_participant.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../track/local_track.dart';
import 'track.dart';
import 'track_publication.dart';

class LocalTrackPublication extends TrackPublication {
  final LocalParticipant _participant;

  LocalTrackPublication(
    lk_models.TrackInfo info,
    Track track,
    this._participant,
  ) : super.fromInfo(info) {
    updateTrack(track);
    // register dispose func
    onDispose(() async {
      // this object is responsible for disposing track
      await this.track?.dispose();
    });
  }

  @override
  Future<bool> updateTrack(Track? newValue) async {
    final didUpdate = await super.updateTrack(newValue);

    if (newValue != null) {
      // attach listener to track
      final listener = newValue.createListener()
        ..on<TrackMuteUpdatedEvent>((event) {
          // send signal
          _participant.engine.signalClient.sendMuteTrack(sid, event.muted);
          // emit events
          if (event.muted) {
            [_participant.events, _participant.roomEvents].emit(TrackMutedEvent(
              participant: _participant,
              track: this,
            ));
          } else {
            [_participant.events, _participant.roomEvents]
                .emit(TrackUnmutedEvent(
              participant: _participant,
              track: this,
            ));
          }
        });
      // dispose listener when the track is disposed
      newValue.onDispose(() => listener.dispose());
    }

    return didUpdate;
  }

  Future<void> mute() async {
    if (track is! LocalTrack) return;
    // Mute the track associated with this publication
    return (track as LocalTrack).mute();
  }

  Future<void> unmute() async {
    if (track is! LocalTrack) return;
    // Unmute the track associated with this publication
    return (track as LocalTrack).unmute();
  }
}
