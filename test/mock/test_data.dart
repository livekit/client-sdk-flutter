// Copyright 2023 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
