import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../errors.dart';
import 'options.dart';
import 'video_track.dart';

class LocalVideoTrack extends VideoTrack {
  RTCRtpSender? get sender => transceiver?.sender;

  LocalVideoTrack(String name, MediaStreamTrack mediaTrack, MediaStream stream)
      : super(name, mediaTrack, stream);

  static Future<LocalVideoTrack> createCameraTrack(
      [LocalVideoTrackOptions? options]) async {

    options ??= LocalVideoTrackOptions(params: VideoPresets.qhd);

    try {
      final stream = await _createCameraStream(options);
      return LocalVideoTrack("camera", stream.getVideoTracks().first, stream);
    } catch (e) {
      return Future.error(e);
    }
  }

  Future<void> restartTrack([LocalVideoTrackOptions? options]) async {
    if (sender == null) {
      return Future.error(TrackCreateError('could not restart track'));
    }

    options ??= LocalVideoTrackOptions(params: VideoPresets.qhd);

    try {
      final stream = await _createCameraStream(options);
      final track = stream.getVideoTracks().first;
      mediaStream = stream;
      await mediaTrack.stop();
      mediaTrack = track;
      await sender?.replaceTrack(track);
    } catch (e) {
      return Future.error(e);
    }
  }

  static Future<MediaStream> _createCameraStream(
      LocalVideoTrackOptions? options) async {

    options ??= LocalVideoTrackOptions(params: VideoPresets.qhd);

    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        "audio": false,
        "video": options.mediaConstraints,
      });

      if (stream.getVideoTracks().isEmpty) {
        return Future.error(TrackCreateError());
      }

      return stream;
    } catch (e) {
      return Future.error(e);
    }
  }
}
