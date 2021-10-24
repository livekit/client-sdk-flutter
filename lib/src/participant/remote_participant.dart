import 'package:flutter/rendering.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/src/internal/events.dart';
import 'package:meta/meta.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:collection/collection.dart';

import '../constants.dart';
import '../events.dart';
import '../extensions.dart';
import '../logger.dart';
import '../managers/event.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../signal_client.dart';
import '../track/audio_track.dart';
import '../track/remote_track_publication.dart';
import '../track/track.dart';
import '../track/video_track.dart';
import '../types.dart';
import '../utils.dart';
import 'participant.dart';

class RendererVisibility {
  final String rendererId;
  final String trackId;
  final bool visible;
  final Size size;
  RendererVisibility({
    required this.rendererId,
    required this.trackId,
    required this.visible,
    required this.size,
  });
}

/// Represents other participant in the [Room].
class RemoteParticipant extends Participant {
  final SignalClient _client;
  SignalClient get client => _client;

  // used to report renderer visibility to the server
  // and optimize
  // final _rendererVisibilities = <String, RendererVisibility>{};
  // Function(void)? _visibilityDidUpdate;
  // Function? _cancelDebounceFunc;

  RemoteParticipant(
    this._client,
    String sid,
    String identity, {
    required EventsEmitter<RoomEvent> roomEvents,
  }) : super(
          sid,
          identity,
          roomEvents: roomEvents,
        ) {
    _commonInit();
  }

  RemoteParticipant.fromInfo(
    this._client,
    lk_models.ParticipantInfo info, {
    required EventsEmitter<RoomEvent> roomEvents,
  }) : super(
          info.sid,
          info.identity,
          roomEvents: roomEvents,
        ) {
    _commonInit();
    updateFromInfo(info);
  }

  void _commonInit() {
    // _visibilityDidUpdate = Utils.createDebounceFunc(
    //   _shouldComputeVisibilityUpdate,
    //   cancelFunc: (func) => _cancelDebounceFunc = func,
    //   wait: const Duration(seconds: 2),
    // );

    // onDispose(() async {
    //   _cancelDebounceFunc?.call();
    // });
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
      track = VideoTrack(pub.name, mediaTrack, stream);
    }

    // // listen for visibility events
    // // TODO: Not the best design, room for improvement
    // final listener = track.createListener()
    //   ..on<VideoRendererVisibilityUpdateEvent>(
    //       (event) => _onVideoRendererVisibilityUpdateEvent(event));

    // // dispose listener when track disposes
    // track.onDispose(() async {
    //   logger.fine('disposing Track, removing listener...');
    //   await listener.dispose();
    // });

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

    // void cleanUpVisibilityEntriesForDisposedTrack() {
    //   // remove all visibility info for dispoed tracks
    //   _rendererVisibilities
    //       .removeWhere((key, value) => value.trackId == trackSid);
    //   // _visibilityDidUpdate?.call(null);
    // }

    if (pub is! RemoteTrackPublication) {
      // no publication exists for trackSid
      // or publication is not RemoteTrackPublication
      // logger.warning('pub is not RemoteTrackPublication');

      await pub?.dispose();
      // cleanUpVisibilityEntriesForDisposedTrack();
      return;
    }

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
    // cleanUpVisibilityEntriesForDisposedTrack();
  }

  // called any time visibility info updates
  // from one of the renderers
  // void _onVideoRendererVisibilityUpdateEvent(
  //     VideoRendererVisibilityUpdateEvent event) {
  //   //
  //   final info = event.info;
  //   final trackSid = event.track.sid;
  //   if (trackSid != null && info != null) {
  //     logger.fine('visibility update for ${event.rendererId} '
  //         'track: ${event.track.sid} '
  //         'visibleFraction: ${info.visibleFraction} '
  //         'size: ${info.size}');
  //     _rendererVisibilities[event.rendererId] = RendererVisibility(
  //       rendererId: event.rendererId,
  //       trackId: trackSid,
  //       visible: info.visibleFraction != 0,
  //       size: info.size,
  //     );
  //     _visibilityDidUpdate?.call(null);
  //   } else {
  //     // widget as been disposed
  //     logger.fine('visibility update for ${event.rendererId}, removed');
  //     _rendererVisibilities.remove(event.rendererId);
  //   }
  // }

  // void _shouldComputeVisibilityUpdate(void _) {
  //   //
  //   logger.fine('should compute visibility info');

  //   // final notAttachedOrNotVisibleTrackIds = <String>{};

  //   // for (final entry in trackPublications.entries) {
  //   //   final visible = _rendererVisibilities.values.firstWhereOrNull((e) => e.trackId == entry.key && e.visible);
  //   //   if (visible == null) notAttachedOrNotVisibleTrackIds.add(entry.key);
  //   // }

  //   // final trackSizes = <String, Size>{};

  //   // // final trackIds = _rendererVisibilities.values.map((e) => e.trackId);
  //   // for (final entry in _rendererVisibilities.entries) {
  //   //   //
  //   // }

  //   //final settings = lk_rtc.UpdateTrackSettings(
  //   //  trackSids: [],
  //   //  height: 0,
  //   //  width: 0,
  //   //  disabled: 
  //   //);

  //   // _client.sendUpdateTrackSettings(settings);
  // }
}
