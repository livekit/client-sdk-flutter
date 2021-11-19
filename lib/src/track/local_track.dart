import '../internal/events.dart';
import 'track.dart';

mixin LocalTrack on Track {
  // only local tracks can set muted
  Future<void> mute() async {
    if (muted) return;
    await disable();
    updateMuted(true);
    events.emit(TrackMuteUpdatedEvent(track: this, muted: muted));
  }

  Future<void> unmute() async {
    if (!muted) return;
    await enable();
    updateMuted(false);
    events.emit(TrackMuteUpdatedEvent(track: this, muted: muted));
  }
}
