import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../proto/livekit_models.pb.dart';
import 'track.dart';

class LocalAudioTrack extends Track {
  LocalAudioTrack(String name, MediaStreamTrack track) : super(TrackType.AUDIO, name, track);
}
