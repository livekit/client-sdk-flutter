import 'package:livekit_client/livekit_client.dart';

import '../participant/remote_participant.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import 'track.dart';
import 'track_publication.dart';

/// Represents a track publication from a RemoteParticipant. Provides methods to
/// control if we should subscribe to the track, and its quality (for video).
class RemoteTrackPublication extends TrackPublication {
  final RemoteParticipant _participant;
  bool _unsubscribed = false;
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

  @override
  bool get subscribed {
    if (_unsubscribed) {
      return false;
    }
    return super.subscribed;
  }

  set subscribed(bool val) {
    if (_unsubscribed == !val) return;
    _unsubscribed = !val;
    _sendUpdateTrackSettings();
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
      final event = TrackMutedEvent(
        participant: _participant,
        track: this,
      );
      _participant.events.emit(event);
      _participant.roomEvents.emit(event);
    } else {
      final event = TrackUnmutedEvent(
        participant: _participant,
        track: this,
      );
      _participant.events.emit(event);
      _participant.roomEvents.emit(event);
    }
    if (subscribed) {
      track?.mediaStreamTrack.enabled = !val;
    }
    _participant.muteChanged();
  }

  RemoteTrackPublication(
    lk_models.TrackInfo info,
    this._participant, [
    Track? track,
  ]) : super.fromInfo(info) {
    this.track = track;
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
