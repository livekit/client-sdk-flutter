import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;

final localAudioTrack = lk_models.TrackInfo(
  sid: 'local_audio_track_sid',
  type: TrackType.AUDIO,
);

final remoteAudioTrack = lk_models.TrackInfo(
  sid: 'remote_audio_track_sid',
  type: TrackType.AUDIO,
);

final localParticipantData = lk_models.ParticipantInfo(
  sid: 'local_participant_sid',
  identity: 'local_participant_identity',
  state: lk_models.ParticipantInfo_State.ACTIVE,
);

final remoteParticipantData = lk_models.ParticipantInfo(
  sid: 'remote_participant_sid',
  identity: 'remote_participant_identity',
  state: lk_models.ParticipantInfo_State.ACTIVE,
  tracks: [remoteAudioTrack],
);

final remoteSpeakerInfo = lk_models.SpeakerInfo(
  sid: remoteParticipantData.sid,
  level: 1.0,
  active: true,
);
