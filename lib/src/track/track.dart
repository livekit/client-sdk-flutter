import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

import '../proto/livekit_models.pb.dart';

class TrackDimension {
  int width;
  int height;

  TrackDimension(this.width, this.height);
}

/// Wrapper around a MediaStreamTrack with additional metadata.
class Track {
  static const ScreenShareName = "screen";

  String name;
  TrackType kind;
  MediaStreamTrack mediaTrack;
  String? sid;
  RTCRtpTransceiver? transceiver;
  String? _cid;

  Track(this.kind, this.name, this.mediaTrack);

  bool get muted => mediaTrack.muted == null ? false : mediaTrack.muted!;

  RTCRtpMediaType get mediaType {
    switch (kind) {
      case TrackType.AUDIO:
        return RTCRtpMediaType.RTCRtpMediaTypeAudio;
      case TrackType.VIDEO:
        return RTCRtpMediaType.RTCRtpMediaTypeVideo;
      // this should never happen
      default:
        return RTCRtpMediaType.RTCRtpMediaTypeAudio;
    }
  }

  String getCid() {
    var cid = _cid;
    if (cid == null) {
      cid = mediaTrack.id;
    }
    if (cid == null) {
      var uuid = Uuid();
      cid = uuid.v4();
      _cid = cid;
    }
    return cid;
  }

  stop() {
    mediaTrack.stop();
  }
}
