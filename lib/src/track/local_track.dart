import 'package:livekit_client/livekit_client.dart';

import 'track.dart';

mixin LocalTrack on Track {
  // only local tracks can set muted
  Future<void> mute() async {
    if (muted) return;
    await disable();
    updateMuted(true);
    events.emit(TrackMutedEvent(track: this));
  }

  Future<void> unmute() async {
    if (!muted) return;
    await enable();
    updateMuted(false);
    events.emit(TrackUnmutedEvent(track: this));
  }
}
