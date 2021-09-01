import '../imports.dart';
import '../proto/livekit_models.pb.dart' as lk_models;

class TrackDimension {
  int width;
  int height;

  TrackDimension(this.width, this.height);
}

/// Wrapper around a MediaStreamTrack with additional metadata.
class Track {
  static const screenShareName = 'screen';

  String name;
  lk_models.TrackType kind;
  MediaStreamTrack mediaTrack;
  String? sid;
  RTCRtpTransceiver? transceiver;
  String? _cid;

  Track(this.kind, this.name, this.mediaTrack);

  bool get muted => mediaTrack.muted == null ? false : mediaTrack.muted!;

  RTCRtpMediaType get mediaType {
    switch (kind) {
      case lk_models.TrackType.AUDIO:
        return RTCRtpMediaType.RTCRtpMediaTypeAudio;
      case lk_models.TrackType.VIDEO:
        return RTCRtpMediaType.RTCRtpMediaTypeVideo;
      // this should never happen
      default:
        return RTCRtpMediaType.RTCRtpMediaTypeAudio;
    }
  }

  String getCid() {
    var cid = _cid ?? mediaTrack.id;

    if (cid == null) {
      const uuid = Uuid();
      cid = uuid.v4();
      _cid = cid;
    }
    return cid;
  }

  void stop() {
    mediaTrack.stop();
  }
}
