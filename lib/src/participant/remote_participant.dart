import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/src/track/audio_track.dart';
import '../proto/livekit_models.pb.dart';
import '../signal_client.dart';
import '../track/remote_track_publication.dart';
import '../track/track.dart';
import '../track/video_track.dart';
import 'participant.dart';

/// Represents other participant in the [Room].
class RemoteParticipant extends Participant {
  final SignalClient _client;

  SignalClient get client => _client;

  RemoteParticipant(this._client, String sid, String identity)
      : super(sid, identity);

  RemoteParticipant.fromInfo(this._client, ParticipantInfo info)
      : super(info.sid, info.identity) {
    updateFromInfo(info);
  }

  RemoteTrackPublication? getTrackPublication(String sid) {
    final pub = tracks[sid];
    if (pub is RemoteTrackPublication) {
      return pub;
    }
  }

  /// for internal use
  /// {@nodoc}
  void addSubscribedMediaTrack(
      MediaStreamTrack mediaTrack, MediaStream stream, String? sid) async {
    if (sid == null) {
      const msg = 'addSubscribedMediaTrack received null sid';
      delegate?.onTrackSubscriptionFailed(this, '', msg);
      roomDelegate?.onTrackSubscriptionFailed(this, '', msg);
      return;
    }

    var pub = getTrackPublication(sid);
    if (pub == null) {
      // we may have received the track prior to metadata. wait up to 3s
      pub = await _waitForTrackPublication(sid, const Duration(seconds: 3));
      if (pub == null) {
        const msg = 'no track metadata found';
        delegate?.onTrackSubscriptionFailed(this, sid, msg);
        roomDelegate?.onTrackSubscriptionFailed(this, sid, msg);
        return;
      }
    }

    Track? track;
    if (pub.kind == TrackType.AUDIO) {
      final audioTrack = AudioTrack(pub.name, mediaTrack, stream);
      audioTrack.start();
      track = audioTrack;
    } else if (pub.kind == TrackType.VIDEO) {
      track = VideoTrack(pub.name, mediaTrack, stream);
    } else {
      final msg = 'unsupported track type ${pub.kind}';
      delegate?.onTrackSubscriptionFailed(this, sid, msg);
      roomDelegate?.onTrackSubscriptionFailed(this, sid, msg);
      return;
    }

    pub.track = track;
    addTrackPublication(pub);

    delegate?.onTrackSubscribed(this, track, pub);
    roomDelegate?.onTrackSubscribed(this, track, pub);
    notifyListeners();
  }

  /// for internal use
  /// {@nodoc}
  @override
  void updateFromInfo(ParticipantInfo info) {
    final hadInfo = hasInfo;
    super.updateFromInfo(info);

    // figuring out deltas between tracks
    final validPubs = <String, RemoteTrackPublication>{};
    final newPubs = <String, RemoteTrackPublication>{};

    for (final info in info.tracks) {
      final sid = info.sid;
      var pub = getTrackPublication(sid);

      if (pub == null) {
        pub = RemoteTrackPublication(info, this);
        newPubs[sid] = pub;
        addTrackPublication(pub);
      } else {
        pub.updateFromInfo(info);
      }

      validPubs[sid] = pub;
    }

    // notify listeners when it's not a new participant
    if (hadInfo) {
      for (final pub in newPubs.values) {
        delegate?.onTrackPublished(this, pub);
        roomDelegate?.onTrackPublished(this, pub);
      }
    }

    // remove tracks
    for (final pub in tracks.values) {
      if (!validPubs.containsKey(pub.sid)) {
        unpublishTrack(sid, true);
      }
    }
  }

  void unpublishTrack(String sid, [bool sendUnpublish = false]) {
    final pub = tracks.remove(sid);
    if (pub == null || pub is! RemoteTrackPublication) {
      return;
    }

    audioTracks.remove(sid);
    videoTracks.remove(sid);

    final track = pub.track;
    if (track != null) {
      track.stop();
      delegate?.onTrackUnsubscribed(this, track, pub);
      roomDelegate?.onTrackUnsubscribed(this, track, pub);
      notifyListeners();
    }
    if (sendUnpublish) {
      delegate?.onTrackUnpublished(this, pub);
      roomDelegate?.onTrackUnpublished(this, pub);
    }
  }

  Future<RemoteTrackPublication?> _waitForTrackPublication(
      String sid, Duration delay) async {
    final endTime = DateTime.now().add(delay);
    while (DateTime.now().isBefore(endTime)) {
      final pub = await Future<RemoteTrackPublication?>.delayed(
          const Duration(milliseconds: 100), () {
        return getTrackPublication(sid);
      });
      if (pub != null) {
        return pub;
      }
    }
  }
}
