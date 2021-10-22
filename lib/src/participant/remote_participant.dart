import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../constants.dart';
import '../events.dart';
import '../extensions.dart';
import '../logger.dart';
import '../managers/event.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../signal_client.dart';
import '../track/audio_track.dart';
import '../track/remote_track_publication.dart';
import '../track/track.dart';
import '../track/video_track.dart';
import '../types.dart';
import 'participant.dart';

/// Represents other participant in the [Room].
class RemoteParticipant extends Participant {
  final SignalClient _client;
  SignalClient get client => _client;

  RemoteParticipant(
    this._client,
    String sid,
    String identity, {
    required EventsEmitter<RoomEvent> roomEvents,
  }) : super(
          sid,
          identity,
          roomEvents: roomEvents,
        );

  RemoteParticipant.fromInfo(
    this._client,
    lk_models.ParticipantInfo info, {
    required EventsEmitter<RoomEvent> roomEvents,
  }) : super(
          info.sid,
          info.identity,
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
    final Track track;
    if (pub.kind == lk_models.TrackType.AUDIO) {
      // audio track
      final audioTrack = AudioTrack(pub.name, mediaTrack, stream);
      await audioTrack.start();
      track = audioTrack;
    } else {
      // video track
      track = VideoTrack(pub.name, mediaTrack, stream, _client);
    }

    pub.track = track;
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
        pub = RemoteTrackPublication(trackInfo, this);
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
      await unpublishTrack(sid, notify: true);
    }
  }

  @override
  Future<void> unpublishTrack(String trackSid, {bool notify = true}) async {
    logger.finer('Unpublish track sid: $trackSid, notify: $notify');
    final pub = trackPublications.remove(trackSid);
    if (pub is! RemoteTrackPublication) return;

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
  }
}
