import '../participant/local_participant.dart';
import '../proto/livekit_models.pb.dart';
import 'track.dart';
import 'track_publication.dart';

class LocalTrackPublication extends TrackPublication {
  LocalParticipant _participant;

  LocalTrackPublication(TrackInfo info, Track track, this._participant)
      : super.fromInfo(info) {
    this.track = track;
  }
}
