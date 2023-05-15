import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/src/internal/events.dart';

import '../../proto/livekit_models.pb.dart' as lk_models;
import '../../types/other.dart';
import '../audio_management.dart';
import '../local/local.dart';
import 'remote.dart';

import '../web/_audio_api.dart' if (dart.library.html) '../web/_audio_html.dart'
    as audio;

class RemoteAudioTrack extends RemoteTrack
    with AudioTrack, RemoteAudioManagementMixin {
  String? _deviceId;
  RemoteAudioTrack(String name, TrackSource source, rtc.MediaStream stream,
      rtc.MediaStreamTrack track,
      {rtc.RTCRtpReceiver? receiver})
      : super(
          name,
          lk_models.TrackType.AUDIO,
          source,
          stream,
          track,
          receiver: receiver,
        );

  @override
  Future<bool> start() async {
    final didStart = await super.start();
    if (didStart) {
      try {
        // web support
        await audio.startAudio(getCid(), mediaStreamTrack);
        if (_deviceId != null) {
          audio.setSinkId(getCid(), _deviceId!);
        }
      } catch (e) {
        if (e.toString().startsWith('NotAllowedError')) {
          events.emit(AudioPlaybackFailed(track: this));
        }
      }
    }
    return didStart;
  }

  @override
  Future<bool> stop() async {
    final didStop = await super.stop();
    if (didStop) {
      // web support
      audio.stopAudio(getCid());
    }
    return didStop;
  }

  Future<void> setSinkId(String deviceId) async {
    audio.setSinkId(getCid(), deviceId);
    _deviceId = deviceId;
  }
}
