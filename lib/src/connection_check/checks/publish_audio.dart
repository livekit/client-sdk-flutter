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

import '../../track/local/audio.dart';
import 'checker.dart';

/// Verifies that audio can be captured from the microphone and published to
/// the server.
class PublishAudioCheck extends Checker {
  PublishAudioCheck(super.url, super.token, {super.options, super.room});

  @override
  String get description => 'Can publish audio';

  @override
  Future<void> perform() async {
    final room = await connect();

    final track = await LocalAudioTrack.create();

    try {
      final localParticipant = room.localParticipant;
      if (localParticipant == null) {
        throw const CheckException('Room has no local participant');
      }
      await localParticipant.publishAudioTrack(track);
    } catch (err) {
      // the room won't clean up a track that was never published,
      // so stop capturing here
      await track.dispose();
      rethrow;
    }

    // wait for a few seconds to publish
    await Future<void>.delayed(const Duration(seconds: 3));

    // verify RTC stats that it's publishing
    final stats = await track.getSenderStats();
    if (stats == null) {
      throw const CheckException('Could not get RTCStats');
    }
    final numPackets = stats.packetsSent ?? 0;
    if (numPackets == 0) {
      throw const CheckException('Could not determine packets are sent');
    }

    // WebAudio-based silence detection isn't available in Flutter, so inspect
    // the captured audio energy from the RTC media-source stats instead.
    final totalAudioEnergy = stats.audioSourceStats?.totalAudioEnergy;
    if (totalAudioEnergy == null) {
      appendWarning('could not verify microphone audio: media-source stats unavailable on this platform');
    } else if (totalAudioEnergy == 0) {
      throw const CheckException('unable to detect audio from microphone');
    } else {
      appendMessage('detected audio from microphone');
    }

    appendMessage('published $numPackets audio packets');
  }
}
