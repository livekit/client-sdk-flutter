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

import '../../track/local/video.dart';
import 'checker.dart';

/// Verifies that video can be captured from the camera and published to the
/// server.
class PublishVideoCheck extends Checker {
  PublishVideoCheck(super.url, super.token, {super.options, super.room});

  @override
  String get description => 'Can publish video';

  @override
  Future<void> perform() async {
    final room = await connect();

    final track = await LocalVideoTrack.createCameraTrack();

    try {
      final localParticipant = room.localParticipant;
      if (localParticipant == null) {
        throw const CheckException('Room has no local participant');
      }
      await localParticipant.publishVideoTrack(track);
    } catch (err) {
      // the room won't clean up a track that was never published,
      // so stop capturing here
      await track.dispose();
      rethrow;
    }

    // wait for a few seconds to publish
    await Future<void>.delayed(const Duration(seconds: 5));

    // verify RTC stats that it's publishing
    final stats = await track.getSenderStats();
    if (stats.isEmpty) {
      throw const CheckException('Could not get RTCStats');
    }
    num numPackets = 0;
    num numFrames = 0;
    for (final layer in stats) {
      numPackets += layer.packetsSent ?? 0;
      numFrames += layer.framesSent ?? 0;
    }
    if (numPackets == 0) {
      throw const CheckException('Could not determine packets are sent');
    }
    // Canvas-based black frame detection isn't available in Flutter, so use
    // the sent frame counter to verify the camera is producing frames
    // (only enforced on platforms that report it).
    if (stats.any((layer) => layer.framesSent != null)) {
      if (numFrames == 0) {
        throw const CheckException('unable to detect frames from camera');
      }
      appendMessage('received video frames');
    } else {
      appendWarning('could not verify camera frames: framesSent stats unavailable on this platform');
    }
    appendMessage('published $numPackets video packets');
  }
}
