import '../events.dart';
import '../extensions.dart';
import '../internal/events.dart';
import '../participant/local_participant.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../track/local.dart';
import '../track/track.dart';
import 'track_publication.dart';

class LocalTrackPublication extends TrackPublication {
  final LocalParticipant _participant;

  @override
  covariant LocalTrack? track;

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
        // listen for track muted events
        ..on<TrackMuteUpdatedEvent>((event) {
          // send signal to server
          _participant.engine.signalClient.sendMuteTrack(sid, event.muted);
          // emit events
          final newEvent = event.muted
              ? TrackMutedEvent(participant: _participant, track: this)
              : TrackUnmutedEvent(participant: _participant, track: this);
          [_participant.events, _participant.roomEvents].emit(newEvent);
        });
      // dispose listener when the track is disposed
      newValue.onDispose(() => listener.dispose());
    }

    return didUpdate;
  }

  @override
  bool get muted => track?.muted ?? super.muted;

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
