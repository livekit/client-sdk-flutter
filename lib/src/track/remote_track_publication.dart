import 'package:livekit_client/src/logger.dart';

import '../events.dart';
import '../extensions.dart';
import '../participant/remote_participant.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import 'track.dart';
import 'track_publication.dart';

/// Represents a track publication from a RemoteParticipant. Provides methods to
/// control if we should subscribe to the track, and its quality (for video).
class RemoteTrackPublication extends TrackPublication {
  final RemoteParticipant _participant;
  bool _disabled = false;
  lk_rtc.VideoQuality _videoQuality = lk_rtc.VideoQuality.HIGH;
  lk_rtc.VideoQuality get videoQuality => _videoQuality;

  set videoQuality(lk_rtc.VideoQuality val) {
    if (val == _videoQuality) return;
    _videoQuality = val;
    _sendUpdateTrackSettings();
  }

  bool get enabled => !_disabled;
  set enabled(bool val) {
    if (_disabled == !val) return;
    _disabled = !val;
    _sendUpdateTrackSettings();
  }

  set subscribed(bool val) {
    logger.fine('setting subscribed = ${val}');
    if (val == super.subscribed) return;
    _sendUpdateSubscription(subscribed: val);
    if (!val && track != null) {
      // Ideally, we should wait for WebRTC's onRemoveTrack event
      // but it does not work reliably across platforms.
      // So for now we will assume remove track succeeded.
      [_participant.events, _participant.roomEvents]
          .emit(TrackUnsubscribedEvent(
        participant: _participant,
        track: track!,
        publication: this,
      ));
      // Simply set to null for now
      track = null;
    }
  }

  /// for internal use
  /// {@nodoc}
  @override
  set muted(bool val) {
    if (val == muted) {
      return;
    }
    super.muted = val;
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
    if (subscribed) {
      track?.mediaStreamTrack.enabled = !val;
    }
  }

  RemoteTrackPublication(
    lk_models.TrackInfo info,
    this._participant, [
    Track? track,
  ]) : super.fromInfo(info) {
    this.track = track;
  }

  void _sendUpdateSubscription({required bool subscribed}) {
    logger.fine('Sending update subscription... ${sid} ${subscribed}');
    final subscription = lk_rtc.UpdateSubscription(
      trackSids: [sid],
      subscribe: subscribed,
    );
    _participant.client.sendUpdateSubscription(subscription);
  }

  void _sendUpdateTrackSettings() {
    final settings = lk_rtc.UpdateTrackSettings(
      trackSids: [sid],
      disabled: _disabled,
    );
    if (kind == lk_models.TrackType.VIDEO) {
      settings.quality = _videoQuality;
    }
    _participant.client.sendUpdateTrackSettings(settings);
  }
}
