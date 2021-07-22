import '../proto/livekit_models.pb.dart';
import '../proto/livekit_rtc.pbserver.dart';
import '../participant/remote_participant.dart';
import 'track.dart';
import 'track_publication.dart';

class RemoteTrackPublication extends TrackPublication {
  RemoteParticipant _participant;
  bool _unsubscribed = false;
  bool _disabled = false;
  VideoQuality _videoQuality = VideoQuality.HIGH;

  VideoQuality get videoQuality => _videoQuality;
  set videoQuality(VideoQuality val) {
    _videoQuality = val;
    _sendUpdateTrackSettings();
  }

  bool get enabled => !_disabled;
  set enabled(bool val) {
    _disabled = !val;
    _sendUpdateTrackSettings();
  }

  bool get subscribed {
    if (_unsubscribed) {
      return false;
    }
    return super.subscribed;
  }

  set subscribed(bool val) {
    _unsubscribed = !val;
    _sendUpdateTrackSettings();
  }

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
  }

  RemoteTrackPublication(TrackInfo info, this._participant, [Track? track])
      : super.fromInfo(info) {
    this.track = track;
  }

  _sendUpdateTrackSettings() {
    var settings = new UpdateTrackSettings(
      trackSids: [sid],
      disabled: _disabled,
    );
    if (kind == TrackType.VIDEO) {
      settings.quality = _videoQuality;
    }
    _participant.client.sendUpdateTrackSettings(settings);
  }
}
