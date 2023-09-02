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

import '../options.dart';
import '../participant/local.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../track/local/local.dart';
import 'track_publication.dart';

/// A [TrackPublication] which belongs to the [LocalParticipant].
class LocalTrackPublication<T extends LocalTrack> extends TrackPublication<T> {
  /// The [LocalParticipant] this instance belongs to.
  @override
  final LocalParticipant participant;

  BackupVideoCodec? backupVideoCodec;

  LocalTrackPublication({
    required this.participant,
    required lk_models.TrackInfo info,
    required T track,
  }) : super(info: info) {
    updateTrack(track);
    // register dispose func
    onDispose(() async {
      // this object is responsible for disposing track
      await this.track?.dispose();
    });
  }

  /// Mute the track associated with this publication
  Future<void> mute() async => await track?.mute();

  /// Unmute the track associated with this publication
  Future<void> unmute() async => await track?.unmute();

  lk_rtc.TrackPublishedResponse toPBTrackPublishedResponse() =>
      lk_rtc.TrackPublishedResponse(
        cid: track?.mediaStreamTrack.id,
        track: latestInfo,
      );
}
