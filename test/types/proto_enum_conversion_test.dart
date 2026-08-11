// Copyright 2026 LiveKit, Inc.
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

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/src/e2ee/options.dart';
import 'package:livekit_client/src/extensions.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import 'package:livekit_client/src/types/other.dart';

// The switches converting protobuf enums in extensions.dart cannot be compile
// time exhaustive, protobuf enums are classes rather than Dart enums, so new
// proto values silently take the wildcard arm. These tests pin the value count
// of each converted proto enum. When a count assertion fails after a proto
// regen, decide how the new value should convert in extensions.dart, then
// update the count and expectations here.
const countHint = 'proto enum gained a value, update the conversion in extensions.dart';

void main() {
  group('protobuf enum conversions cover every proto value', () {
    test('DataPacket_Kind', () {
      expect(lk_models.DataPacket_Kind.values, hasLength(2), reason: countHint);
      expect(lk_models.DataPacket_Kind.RELIABLE.toSDKType(), Reliability.reliable);
      expect(lk_models.DataPacket_Kind.LOSSY.toSDKType(), Reliability.lossy);
    });

    test('ConnectionQuality', () {
      expect(lk_models.ConnectionQuality.values, hasLength(4), reason: countHint);
      expect(lk_models.ConnectionQuality.LOST.toLKType(), ConnectionQuality.lost);
      expect(lk_models.ConnectionQuality.POOR.toLKType(), ConnectionQuality.poor);
      expect(lk_models.ConnectionQuality.GOOD.toLKType(), ConnectionQuality.good);
      expect(lk_models.ConnectionQuality.EXCELLENT.toLKType(), ConnectionQuality.excellent);
    });

    test('VideoQuality', () {
      expect(lk_models.VideoQuality.values, hasLength(4), reason: countHint);
      expect(lk_models.VideoQuality.LOW.toLKType(), VideoQuality.LOW);
      expect(lk_models.VideoQuality.MEDIUM.toLKType(), VideoQuality.MEDIUM);
      expect(lk_models.VideoQuality.HIGH.toLKType(), VideoQuality.HIGH);
      // the SDK enum has no OFF member, collapsing to LOW is intentional
      expect(lk_models.VideoQuality.OFF.toLKType(), VideoQuality.LOW);
    });

    test('TrackType', () {
      expect(lk_models.TrackType.values, hasLength(3), reason: countHint);
      expect(lk_models.TrackType.AUDIO.toLKType(), TrackType.AUDIO);
      expect(lk_models.TrackType.VIDEO.toLKType(), TrackType.VIDEO);
      expect(lk_models.TrackType.DATA.toLKType(), TrackType.DATA);
    });

    test('TrackSource', () {
      expect(lk_models.TrackSource.values, hasLength(5), reason: countHint);
      expect(lk_models.TrackSource.UNKNOWN.toLKType(), TrackSource.unknown);
      expect(lk_models.TrackSource.CAMERA.toLKType(), TrackSource.camera);
      expect(lk_models.TrackSource.MICROPHONE.toLKType(), TrackSource.microphone);
      expect(lk_models.TrackSource.SCREEN_SHARE.toLKType(), TrackSource.screenShareVideo);
      expect(lk_models.TrackSource.SCREEN_SHARE_AUDIO.toLKType(), TrackSource.screenShareAudio);
    });

    test('StreamState', () {
      expect(lk_rtc.StreamState.values, hasLength(2), reason: countHint);
      expect(lk_rtc.StreamState.ACTIVE.toLKType(), StreamState.active);
      expect(lk_rtc.StreamState.PAUSED.toLKType(), StreamState.paused);
    });

    test('Encryption_Type', () {
      expect(lk_models.Encryption_Type.values, hasLength(3), reason: countHint);
      expect(lk_models.Encryption_Type.NONE.toLkType(), EncryptionType.kNone);
      expect(lk_models.Encryption_Type.GCM.toLkType(), EncryptionType.kGcm);
      expect(lk_models.Encryption_Type.CUSTOM.toLkType(), EncryptionType.kCustom);
    });

    test('ParticipantInfo_Kind', () {
      expect(lk_models.ParticipantInfo_Kind.values, hasLength(7), reason: countHint);
      expect(lk_models.ParticipantInfo_Kind.STANDARD.toLKType(), ParticipantKind.STANDARD);
      expect(lk_models.ParticipantInfo_Kind.INGRESS.toLKType(), ParticipantKind.INGRESS);
      expect(lk_models.ParticipantInfo_Kind.EGRESS.toLKType(), ParticipantKind.EGRESS);
      expect(lk_models.ParticipantInfo_Kind.SIP.toLKType(), ParticipantKind.SIP);
      expect(lk_models.ParticipantInfo_Kind.AGENT.toLKType(), ParticipantKind.AGENT);
      // the SDK enum has no members for these yet, they collapse to STANDARD
      expect(lk_models.ParticipantInfo_Kind.CONNECTOR.toLKType(), ParticipantKind.STANDARD);
      expect(lk_models.ParticipantInfo_Kind.BRIDGE.toLKType(), ParticipantKind.STANDARD);
    });

    test('DisconnectReason', () {
      expect(lk_models.DisconnectReason.values, hasLength(17), reason: countHint);
      expect(lk_models.DisconnectReason.UNKNOWN_REASON.toSDKType(), DisconnectReason.unknown);
      expect(lk_models.DisconnectReason.CLIENT_INITIATED.toSDKType(), DisconnectReason.clientInitiated);
      expect(lk_models.DisconnectReason.DUPLICATE_IDENTITY.toSDKType(), DisconnectReason.duplicateIdentity);
      expect(lk_models.DisconnectReason.SERVER_SHUTDOWN.toSDKType(), DisconnectReason.serverShutdown);
      expect(lk_models.DisconnectReason.PARTICIPANT_REMOVED.toSDKType(), DisconnectReason.participantRemoved);
      expect(lk_models.DisconnectReason.ROOM_DELETED.toSDKType(), DisconnectReason.roomDeleted);
      expect(lk_models.DisconnectReason.STATE_MISMATCH.toSDKType(), DisconnectReason.stateMismatch);
      expect(lk_models.DisconnectReason.JOIN_FAILURE.toSDKType(), DisconnectReason.joinFailure);
    });
  });
}
