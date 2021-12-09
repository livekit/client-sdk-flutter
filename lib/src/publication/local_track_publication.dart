import '../events.dart';
import '../extensions.dart';
import '../internal/events.dart';
import '../participant/local_participant.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../track/local.dart';
import 'track_publication.dart';

class LocalTrackPublication<T extends LocalTrack> extends TrackPublication<T> {
  @override
  final LocalParticipant participant;

  LocalTrackPublication({
    required this.participant,
    required lk_models.TrackInfo info,
    required T track,
  }) : super(info: info) {
    updateTrack(track);
    // register dispose func
    onDispose(() async {
      // this object is responsible for disposing track
      await this.track?.dispose();
    });
  }

  @override
  Future<bool> updateTrack(T? newValue) async {
    final didUpdate = await super.updateTrack(newValue);

    if (newValue != null) {
      // attach listener to track
      final listener = newValue.createListener()
        // listen for track muted events
        ..on<TrackMuteUpdatedEvent>((event) {
          // send signal to server
          participant.room.engine.signalClient.sendMuteTrack(sid, event.muted);
          // emit events
          final newEvent = event.muted
              ? TrackMutedEvent(participant: participant, track: this)
              : TrackUnmutedEvent(participant: participant, track: this);
          [participant.events, participant.room.events].emit(newEvent);
        });
      // dispose listener when the track is disposed
      newValue.onDispose(() => listener.dispose());
    }

    return didUpdate;
  }

  @override
  bool get muted => track?.muted ?? super.muted;

  /// Mute the track associated with this publication
  Future<void> mute() async => await track?.mute();

  /// Unmute the track associated with this publication
  Future<void> unmute() async => await track?.unmute();
}
