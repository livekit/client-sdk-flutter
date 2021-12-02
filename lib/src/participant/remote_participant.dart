import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';
import 'package:meta/meta.dart';

import '../constants.dart';
import '../events.dart';
import '../extensions.dart';
import '../logger.dart';
import '../managers/event.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../publication/remote_track_publication.dart';
import '../rtc_engine.dart';
import '../track/remote/audio.dart';
import '../track/remote/video.dart';
import '../types.dart';
import 'participant.dart';

/// Represents other participant in the [Room].
class RemoteParticipant extends Participant<RemoteTrackPublication> {
  @override
  List<RemoteTrackPublication> get subscribedTracks =>
      super.subscribedTracks.cast<RemoteTrackPublication>().toList();

  @override
  List<RemoteTrackPublication<RemoteVideoTrack>> get videoTracks =>
      trackPublications.values
          .whereType<RemoteTrackPublication<RemoteVideoTrack>>()
          .toList();

  @override
  List<RemoteTrackPublication<RemoteAudioTrack>> get audioTracks =>
      trackPublications.values
          .whereType<RemoteTrackPublication<RemoteAudioTrack>>()
          .toList();

  RemoteParticipant({
    required RTCEngine engine,
    required String sid,
    required String identity,
    required EventsEmitter<RoomEvent> roomEvents,
  }) : super(
          engine: engine,
          sid: sid,
          identity: identity,
          roomEvents: roomEvents,
        );

  RemoteParticipant.fromInfo({
    required RTCEngine engine,
    required lk_models.ParticipantInfo info,
    required EventsEmitter<RoomEvent> roomEvents,
  }) : super(
          engine: engine,
          sid: info.sid,
          identity: info.identity,
          roomEvents: roomEvents,
        ) {
    updateFromInfo(info);
  }

  RemoteTrackPublication? getTrackPublication(String sid) {
    final pub = trackPublications[sid];
    if (pub is RemoteTrackPublication) return pub;
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
    if (pub.kind == lk_models.TrackType.AUDIO) {
      // audio track
      track = RemoteAudioTrack(pub.name, pub.source, stream, mediaTrack);
    } else {
      // video track
      track = RemoteVideoTrack(pub.name, pub.source, stream, mediaTrack);
    }

    await track.start();
    await pub.updateTrack(track);
    addTrackPublication(pub);

    [events, roomEvents].emit(TrackSubscribedEvent(
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
        [events, roomEvents].emit(event);
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
      [events, roomEvents].emit(TrackUnsubscribedEvent(
        participant: this,
        track: track,
        publication: pub,
      ));
    }

    if (notify) {
      [events, roomEvents].emit(TrackUnpublishedEvent(
        participant: this,
        publication: pub,
      ));
    }

    await pub.dispose();
  }
}
