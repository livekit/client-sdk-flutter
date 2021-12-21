import '../participant/local.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../track/local/local.dart';
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

  /// Mute the track associated with this publication
  Future<void> mute() async => await track?.mute();

  /// Unmute the track associated with this publication
  Future<void> unmute() async => await track?.unmute();
}
