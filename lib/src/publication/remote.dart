import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../core/signal_client.dart';
import '../events.dart';
import '../extensions.dart';
import '../internal/events.dart';
import '../internal/types.dart';
import '../logger.dart';
import '../options.dart';
import '../participant/remote.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../track/local/video.dart';
import '../track/remote/remote.dart';
import '../types.dart';
import '../utils.dart';
import 'track_publication.dart';

/// Represents a track publication from a RemoteParticipant. Provides methods to
/// control if we should subscribe to the track, and its quality (for video).
class RemoteTrackPublication<T extends RemoteTrack>
    extends TrackPublication<T> {
  @override
  final RemoteParticipant participant;

  bool _enabled = true;
  lk_models.VideoQuality _videoQuality = lk_models.VideoQuality.HIGH;
  lk_models.VideoQuality get videoQuality => _videoQuality;

  StreamState _streamState = StreamState.paused;

  /// The server may pause the track when they are bandwidth limitations and resume
  /// when there is more capacity. This property will be updated when the track is
  /// paused / resumed by the server. See [TrackStreamStateUpdatedEvent] for the
  /// relevant event.
  StreamState get streamState => _streamState;

  // latest TrackInfo
  bool _metadataMuted = false;

  @internal
  Future<void> updateStreamState(StreamState streamState) async {
    // return if no change
    if (_streamState == streamState) return;
    _streamState = streamState;
    [participant.events, participant.room.events]
        .emit(TrackStreamStateUpdatedEvent(
      participant: participant,
      trackPublication: this,
      streamState: streamState,
    ));
  }

  // used to report renderer visibility to the server
  // and optimize
  final _visibilities = <String, RendererVisibility>{};
  Function(void)? _visibilityDidUpdate;
  Function? _cancelVisibilityDebounceFunc;

  RemoteTrackPublication({
    required this.participant,
    required lk_models.TrackInfo info,
    T? track,
  }) : super(info: info) {
    logger.fine('RemoteTrackPublication.init track: $track, info: $info');

    // register dispose func
    onDispose(() async {
      _cancelVisibilityDebounceFunc?.call();
      // this object is responsible for disposing track
      await this.track?.dispose();
    });

    _visibilityDidUpdate = Utils.createDebounceFunc(
      _shouldComputeVisibilityUpdate,
      cancelFunc: (func) => _cancelVisibilityDebounceFunc = func,
      wait: const Duration(seconds: 2),
    );

    updateTrack(track);
  }

  @internal
  @override
  void updateFromInfo(lk_models.TrackInfo info) {
    logger.fine(
        'RemoteTrackPublication.updateFromInfo sid: ${info.sid} muted: ${info.muted}');
    super.updateFromInfo(info);
    track?.updateMuted(info.muted);
    _metadataMuted = info.muted;
  }

  // called any time visibility info updates
  // from one of the renderers
  void _onVideoRendererVisibilityUpdateEvent(
      TrackVisibilityUpdatedEvent event) {
    final info = event.info;
    final trackSid = event.track.sid;
    if (trackSid != null && info != null) {
      logger.fine('[Visibility] ${event.rendererId} did update '
          'track: ${event.track.sid} '
          'visibleFraction: ${info.visibleFraction} '
          'size: ${info.size}');
      _visibilities[event.rendererId] = RendererVisibility(
        rendererId: event.rendererId,
        trackId: trackSid,
        visible: info.visibleFraction > 0,
        size: info.size,
      );

      // quickly enable if currently disabled
      if (!enabled && _hasVisibleRenderers()) {
        logger.fine('[Visibility] Trying to re-enable quickly');
        _cancelVisibilityDebounceFunc?.call();
        _shouldComputeVisibilityUpdate(null);
      } else {
        _visibilityDidUpdate?.call(null);
      }
    } else {
      // widget as been disposed, but track still exists
      logger.fine('[Visibility] ${event.rendererId} was removed');
      _visibilities.remove(event.rendererId);
      _visibilityDidUpdate?.call(null);
    }

    logger.fine(
        '[Visibility] Ids ${_visibilities.length} ${_visibilities.values.map((e) => e.rendererId)}');
  }

  bool _hasVisibleRenderers() =>
      _visibilities.values.firstWhereOrNull((e) => e.visible) != null;

  void _shouldComputeVisibilityUpdate(void _) {
    if (isDisposed) {
      logger.warning('_shouldComputeVisibilityUpdate already disposed');
      return;
    }

    Size maxSize(Size s1, Size s2) => Size(
          max(s1.width, s2.width),
          max(s1.height, s2.height),
        );

    _enabled = _hasVisibleRenderers();

    final settings = lk_rtc.UpdateTrackSettings(
      trackSids: [sid],
      disabled: !_enabled,
    );

    if (_enabled) {
      final largest = _visibilities.values
          .map((e) => e.size)
          .reduce((value, element) => maxSize(value, element));
      settings.width = largest.width.floor();
      settings.height = largest.height.floor();
    }

    logger.fine('[Visibility] Sending to server ${settings.toProto3Json()}');
    participant.room.engine.signalClient.sendUpdateTrackSettings(settings);
  }

  @internal
  @override
  Future<bool> updateTrack(covariant T? newValue) async {
    logger.fine('RemoteTrackPublication.updateTrack track: $newValue');
    final didUpdate = await super.updateTrack(newValue);

    final roomOptions = participant.room.roomOptions ?? const RoomOptions();

    if (didUpdate && newValue != null) {
      // if new Track has been set to this RemoteTrackPublication,
      // update the Track's muted state from the latest info.
      newValue.updateMuted(
        _metadataMuted,
        shouldNotify: false, // don't emit event since this is initial state
      );

      // Only listen for visibility updates if video optimization is on
      // and the attached track is a video track
      if (roomOptions.optimizeVideo &&
          newValue.kind == lk_models.TrackType.VIDEO) {
        // Attach visibility event listener
        final listener = newValue.createListener();
        listener.on<TrackVisibilityUpdatedEvent>(
            _onVideoRendererVisibilityUpdateEvent);

        newValue.onDispose(() async {
          await listener.dispose();
          // consider all views are disposed when track is null
          _visibilities.clear();
          if (!isDisposed) _visibilityDidUpdate?.call(null);
        });
      }
    }

    return didUpdate;
  }

  set videoQuality(lk_models.VideoQuality val) {
    if (val == _videoQuality) return;
    _videoQuality = val;
    _sendUpdateTrackSettings();
  }

  bool get enabled => _enabled;
  set enabled(bool val) {
    if (_enabled == val) return;
    _enabled = val;
    _sendUpdateTrackSettings();
  }

  set subscribed(bool val) {
    logger.fine('setting subscribed = ${val}');
    if (val == super.subscribed) return;
    _sendUpdateSubscription(subscribed: val);
    if (!val && track != null) {
      // Ideally, we should wait for WebRTC's onRemoveTrack event
      // but it does not work reliably across platforms.
      // So for now we will assume remove track succeeded.
      [participant.events, participant.room.events].emit(TrackUnsubscribedEvent(
        participant: participant,
        track: track!,
        publication: this,
      ));
      // Simply set to null for now
      updateTrack(null);
    }
  }

  void _sendUpdateSubscription({required bool subscribed}) {
    logger.fine('Sending update subscription... ${sid} ${subscribed}');
    final subscription = lk_rtc.UpdateSubscription(
      trackSids: [sid],
      subscribe: subscribed,
    );
    participant.room.engine.signalClient.sendUpdateSubscription(subscription);
  }

  void _sendUpdateTrackSettings() {
    final settings = lk_rtc.UpdateTrackSettings(
      trackSids: [sid],
      disabled: !_enabled,
    );
    if (kind == lk_models.TrackType.VIDEO) {
      settings.quality = _videoQuality;
    }
    participant.room.engine.signalClient.sendUpdateTrackSettings(settings);
  }
}
