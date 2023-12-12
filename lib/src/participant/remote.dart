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

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../core/room.dart';
import '../events.dart';
import '../exceptions.dart';
import '../extensions.dart';
import '../internal/events.dart';
import '../logger.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../publication/remote.dart';
import '../support/platform.dart';
import '../track/options.dart';
import '../track/remote/audio.dart';
import '../track/remote/remote.dart';
import '../track/remote/video.dart';
import '../types/other.dart';
import 'participant.dart';

/// Represents other participant in the [Room].
class RemoteParticipant extends Participant<RemoteTrackPublication> {
  @internal
  RemoteParticipant({
    required Room room,
    required String sid,
    required String identity,
    required String name,
  }) : super(
          room: room,
          sid: sid,
          identity: identity,
          name: name,
        );

  @internal
  RemoteParticipant.fromInfo({
    required Room room,
    required lk_models.ParticipantInfo info,
  }) : super(
          room: room,
          sid: info.sid,
          identity: info.identity,
          name: info.name,
        ) {
    updateFromInfo(info);
  }

  /// A convenience property to get all video tracks.
  @override
  List<RemoteTrackPublication<RemoteVideoTrack>> get videoTracks =>
      trackPublications.values
          .whereType<RemoteTrackPublication<RemoteVideoTrack>>()
          .toList();

  /// A convenience property to get all audio tracks.
  @override
  List<RemoteTrackPublication<RemoteAudioTrack>> get audioTracks =>
      trackPublications.values
          .whereType<RemoteTrackPublication<RemoteAudioTrack>>()
          .toList();

  List<RemoteTrackPublication> get subscribedTracks => trackPublications.values
      .where((e) => e.subscribed)
      .cast<RemoteTrackPublication>()
      .toList();

  RemoteTrackPublication? getTrackPublication(String sid) {
    final pub = trackPublications[sid];
    if (pub is RemoteTrackPublication) return pub;
    return null;
  }

  /// for internal use
  /// {@nodoc}
  @internal
  Future<void> addSubscribedMediaTrack(
    rtc.MediaStreamTrack mediaTrack,
    rtc.MediaStream stream,
    String trackSid, {
    rtc.RTCRtpReceiver? receiver,
    AudioOutputOptions audioOutputOptions = const AudioOutputOptions(),
  }) async {
    logger.fine('addSubscribedMediaTrack()');

    // If publication doesn't exist yet...
    RemoteTrackPublication? pub = getTrackPublication(trackSid);
    if (pub == null) {
      logger.fine('addSubscribedMediaTrack() pub is null, will wait...');
      logger.fine('addSubscribedMediaTrack() tracks: $trackPublications');
      // Wait for the metadata to arrive
      final event = await events.waitFor<TrackPublishedEvent>(
        filter: (event) =>
            event.participant == this && event.publication.sid == trackSid,
        duration: room.connectOptions.timeouts.publish,
        onTimeout: () => throw TrackSubscriptionExceptionEvent(
          participant: this,
          sid: trackSid,
          reason: TrackSubscribeFailReason.notTrackMetadataFound,
        ),
      );
      pub = event.publication;
      logger.fine('addSubscribedMediaTrack() did receive pub');
    }

    // Check if track type is supported, throw if not.
    if (![lk_models.TrackType.AUDIO, lk_models.TrackType.VIDEO]
        .contains(pub.kind)) {
      throw TrackSubscriptionExceptionEvent(
        participant: this,
        sid: trackSid,
        reason: TrackSubscribeFailReason.unsupportedTrackType,
      );
    }

    // create Track
    final RemoteTrack track;
    if (pub.kind == lk_models.TrackType.VIDEO) {
      // video track
      track =
          RemoteVideoTrack(pub.source, stream, mediaTrack, receiver: receiver);
    } else if (pub.kind == lk_models.TrackType.AUDIO) {
      // audio track
      track =
          RemoteAudioTrack(pub.source, stream, mediaTrack, receiver: receiver);

      var listener = track.createListener();
      listener.on<AudioPlaybackStarted>((event) {
        logger.fine('AudioPlaybackStarted');
        room.engine.events.emit(event);
      });

      listener.on<AudioPlaybackFailed>((event) {
        logger.fine('AudioPlaybackFailed');
        room.engine.events.emit(event);
      });
    } else {
      throw UnexpectedStateException('Unknown track type');
    }

    await track.start();

    /// Apply audio output selection for the web.
    if (pub.kind == lk_models.TrackType.AUDIO &&
        lkPlatformIs(PlatformType.web)) {
      if (audioOutputOptions.deviceId != null) {
        await (track as RemoteAudioTrack)
            .setSinkId(audioOutputOptions.deviceId!);
      }
    }

    await pub.updateTrack(track);
    await pub.updateSubscriptionAllowed(true);
    addTrackPublication(pub);

    [events, room.events].emit(TrackSubscribedEvent(
      participant: this,
      track: track,
      publication: pub,
    ));
  }

  /// for internal use
  /// {@nodoc}
  @override
  @internal
  Future<void> updateFromInfo(lk_models.ParticipantInfo info) async {
    logger.fine('RemoteParticipant.updateFromInfo(info: $info)');
    super.updateFromInfo(info);

    // figuring out deltas between tracks
    final newPubs = <RemoteTrackPublication>{};

    for (final trackInfo in info.tracks) {
      RemoteTrackPublication? pub = getTrackPublication(trackInfo.sid);
      if (pub == null) {
        final RemoteTrackPublication pub;
        if (trackInfo.type == lk_models.TrackType.VIDEO) {
          pub = RemoteTrackPublication<RemoteVideoTrack>(
            participant: this,
            info: trackInfo,
          );
        } else if (trackInfo.type == lk_models.TrackType.AUDIO) {
          pub = RemoteTrackPublication<RemoteAudioTrack>(
            participant: this,
            info: trackInfo,
          );
        } else {
          throw UnexpectedStateException('Unknown track type');
        }
        newPubs.add(pub);
        addTrackPublication(pub);
      } else {
        pub.updateFromInfo(trackInfo);
      }
    }

    // always emit events for new publications, Room will not forward them unless it's ready
    for (final pub in newPubs) {
      final event = TrackPublishedEvent(
        participant: this,
        publication: pub,
      );
      if (room.connectionState == ConnectionState.connected) {
        [events, room.events].emit(event);
      }
    }

    // remove any published track that is not in the info
    final validSids = info.tracks.map((e) => e.sid);
    final removeSids =
        trackPublications.keys.where((e) => !validSids.contains(e)).toSet();
    for (final sid in removeSids) {
      await removePublishedTrack(sid);
    }
  }

  Future<void> removePublishedTrack(String trackSid,
      {bool notify = true}) async {
    logger.finer('removePublishedTrack track sid: $trackSid, notify: $notify');
    final pub = trackPublications.remove(trackSid);
    if (pub == null) {
      logger.warning('Publication not found $trackSid');
      return;
    }
    await pub.dispose();

    final track = pub.track;
    // if has track
    if (track != null) {
      await track.stop();
      [events, room.events].emit(TrackUnsubscribedEvent(
        participant: this,
        track: track,
        publication: pub,
      ));
    }

    if (notify) {
      [events, room.events].emit(TrackUnpublishedEvent(
        participant: this,
        publication: pub,
      ));
    }

    await pub.dispose();
  }

  @Deprecated(
      '`unpublishTrack` is deprecated, use `removePublishedTrack` instead')
  @override
  Future<void> unpublishTrack(String trackSid, {bool notify = true}) =>
      removePublishedTrack(trackSid, notify: notify);

  @internal
  lk_models.ParticipantTracks participantTracks() =>
      lk_models.ParticipantTracks(
        participantSid: sid,
        trackSids: trackPublications.values.map((e) => e.sid),
      );
}
