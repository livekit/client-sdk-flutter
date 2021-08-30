import '../proto/livekit_models.pb.dart';
import '../proto/livekit_rtc.pbserver.dart';
import '../participant/remote_participant.dart';
import 'track.dart';
import 'track_publication.dart';

class RemoteTrackPublication extends TrackPublication {
  final RemoteParticipant _participant;
  bool _unsubscribed = false;
  bool _disabled = false;
  VideoQuality _videoQuality = VideoQuality.HIGH;

  VideoQuality get videoQuality => _videoQuality;
  set videoQuality(VideoQuality val) {
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

  @override
  set muted(bool val) {
    if (val == muted) {
      return;
    }
    super.muted = val;
    if (val) {
      _participant.delegate?.onTrackMuted(_participant, this);
      _participant.roomDelegate?.onTrackMuted(_participant, this);
    } else {
      _participant.delegate?.onTrackUnmuted(_participant, this);
      _participant.roomDelegate?.onTrackUnmuted(_participant, this);
    }
    if (subscribed) {
      track?.mediaTrack.enabled = !val;
    }
    _participant.muteChanged();
  }

  RemoteTrackPublication(TrackInfo info, this._participant, [Track? track])
      : super.fromInfo(info) {
    this.track = track;
  }

  _sendUpdateTrackSettings() {
    final settings = UpdateTrackSettings(
      trackSids: [sid],
      disabled: _disabled,
    );
    if (kind == TrackType.VIDEO) {
      settings.quality = _videoQuality;
    }
    _participant.client.sendUpdateTrackSettings(settings);
  }
}
