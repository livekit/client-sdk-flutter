import '../internal/events.dart';
import '../logger.dart';
import 'track.dart';

mixin LocalTrack on Track {
  // only local tracks can set muted
  Future<void> mute() async {
    logger.fine('LocalTrack.mute() muted: $muted');
    if (muted) return;
    await disable();
    updateMuted(true);
    events.emit(TrackMuteUpdatedEvent(track: this, muted: muted));
  }

  Future<void> unmute() async {
    logger.fine('LocalTrack.unmute() muted: $muted');
    if (!muted) return;
    await enable();
    updateMuted(false);
    events.emit(TrackMuteUpdatedEvent(track: this, muted: muted));
  }
}
