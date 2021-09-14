import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:uuid/uuid.dart';

import '../proto/livekit_models.pb.dart' as lk_models;

class TrackDimension {
  int width;
  int height;

  TrackDimension(this.width, this.height);
}

/// Wrapper around a MediaStreamTrack with additional metadata.
class Track {
  static const cameraName = 'camera';
  static const screenShareName = 'screen';

  String name;
  lk_models.TrackType kind;
  rtc.MediaStreamTrack mediaStreamTrack;
  String? sid;
  rtc.RTCRtpTransceiver? transceiver;
  String? _cid;

  Track(this.kind, this.name, this.mediaStreamTrack);

  bool get muted => mediaStreamTrack.muted == null ? false : mediaStreamTrack.muted!;

  rtc.RTCRtpMediaType get mediaType {
    switch (kind) {
      case lk_models.TrackType.AUDIO:
        return rtc.RTCRtpMediaType.RTCRtpMediaTypeAudio;
      case lk_models.TrackType.VIDEO:
        return rtc.RTCRtpMediaType.RTCRtpMediaTypeVideo;
      // this should never happen
      default:
        return rtc.RTCRtpMediaType.RTCRtpMediaTypeAudio;
    }
  }

  String getCid() {
    var cid = _cid ?? mediaStreamTrack.id;

    if (cid == null) {
      const uuid = Uuid();
      cid = uuid.v4();
      _cid = cid;
    }
    return cid;
  }

  Future<void> stop() async {
    await mediaStreamTrack.stop();
  }
}
