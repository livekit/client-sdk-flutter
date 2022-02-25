import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../constants.dart';
import '../core/room.dart';
import '../events.dart';
import '../exceptions.dart';
import '../extensions.dart';
import '../logger.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../publication/remote.dart';
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
    String trackSid,
  ) async {
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
        duration: Timeouts.publish,
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
      track = RemoteVideoTrack(pub.name, pub.source, stream, mediaTrack);
    } else if (pub.kind == lk_models.TrackType.AUDIO) {
      // audio track
      track = RemoteAudioTrack(pub.name, pub.source, stream, mediaTrack);
    } else {
      throw UnexpectedStateException('Unknown track type');
    }

    await track.start();
    await pub.updateTrack(track);
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
    final hadInfo = hasInfo;
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

    // notify listeners when it's not a new participant
    if (hadInfo) {
      for (final pub in newPubs) {
        final event = TrackPublishedEvent(
          participant: this,
          publication: pub,
        );
        [events, room.events].emit(event);
      }
    }

    // unpublish any track that is not in the info
    final validSids = info.tracks.map((e) => e.sid);
    final removeSids =
        trackPublications.keys.where((e) => !validSids.contains(e)).toSet();
    for (final sid in removeSids) {
      await unpublishTrack(sid);
    }
  }

  @override
  Future<void> unpublishTrack(String trackSid, {bool notify = true}) async {
    logger.finer('Unpublish track sid: $trackSid, notify: $notify');
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

  @internal
  lk_models.ParticipantTracks participantTracks() =>
      lk_models.ParticipantTracks(
        participantSid: sid,
        trackSids: trackPublications.values.map((e) => e.sid),
      );
}
