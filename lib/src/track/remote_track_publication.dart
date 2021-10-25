import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:livekit_client/src/internal/events.dart';
import 'package:livekit_client/src/logger.dart';
import 'package:meta/meta.dart';

import '../events.dart';
import '../extensions.dart';
import '../participant/remote_participant.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../utils.dart';
import 'track.dart';
import 'track_publication.dart';

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

/// Represents a track publication from a RemoteParticipant. Provides methods to
/// control if we should subscribe to the track, and its quality (for video).
class RemoteTrackPublication extends TrackPublication {
  final RemoteParticipant _participant;
  bool _disabled = false;
  lk_rtc.VideoQuality _videoQuality = lk_rtc.VideoQuality.HIGH;
  lk_rtc.VideoQuality get videoQuality => _videoQuality;

  // used to report renderer visibility to the server
  // and optimize
  final _rendererVisibilities = <String, RendererVisibility>{};
  Function(void)? _visibilityDidUpdate;
  Function? _cancelDebounceFunc;

  RemoteTrackPublication(
    lk_models.TrackInfo info,
    this._participant, [
    Track? track,
  ]) : super.fromInfo(info) {
    // register dispose func
    onDispose(() async {
      _cancelDebounceFunc?.call();
      // this object is responsible for disposing track
      await this.track?.dispose();
    });

    _visibilityDidUpdate = Utils.createDebounceFunc(
      _shouldComputeVisibilityUpdate,
      cancelFunc: (func) => _cancelDebounceFunc = func,
      wait: const Duration(seconds: 2),
    );

    this.track = track;
  }

  // called any time visibility info updates
  // from one of the renderers
  void _onVideoRendererVisibilityUpdateEvent(
      VideoRendererVisibilityUpdateEvent event) {
    final info = event.info;
    final trackSid = event.track.sid;
    if (trackSid != null && info != null) {
      logger.fine('[Visibility] ${event.rendererId} did update '
          'track: ${event.track.sid} '
          'visibleFraction: ${info.visibleFraction} '
          'size: ${info.size}');
      _rendererVisibilities[event.rendererId] = RendererVisibility(
        rendererId: event.rendererId,
        trackId: trackSid,
        visible: info.visibleFraction > 0,
        size: info.size,
      );

      // quickly enable if currently disabled
      if (!enabled && _hasVisibleRenderers()) {
        logger.fine('[Visibility] enable quickly');
        _cancelDebounceFunc?.call();
        _shouldComputeVisibilityUpdate(null);
      } else {
        _visibilityDidUpdate?.call(null);
      }
    } else {
      // widget as been disposed, but track still exists
      logger.fine('[Visibility] ${event.rendererId} was removed');
      _rendererVisibilities.remove(event.rendererId);
      _visibilityDidUpdate?.call(null);
    }

    logger.fine(
        '[Visibility] Ids ${_rendererVisibilities.values.map((e) => e.rendererId)}');
  }

  bool _hasVisibleRenderers() =>
      _rendererVisibilities.values.firstWhereOrNull((e) => e.visible) != null;

  void _shouldComputeVisibilityUpdate(void _) {
    //
    Size maxSize(Size s1, Size s2) => Size(
          max(s1.width, s2.width),
          max(s1.height, s2.height),
        );

    _disabled = !_hasVisibleRenderers();

    final settings = lk_rtc.UpdateTrackSettings(
      trackSids: [sid],
      disabled: _disabled,
    );

    if (!_disabled) {
      final largest = _rendererVisibilities.values
          .map((e) => e.size)
          .reduce((value, element) => maxSize(value, element));
      settings.width = largest.width.floor();
      settings.height = largest.height.floor();
    }

    logger.fine('[Visibility] Sending to server ${settings.toProto3Json()}');
    _participant.client.sendUpdateTrackSettings(settings);
  }

  @override
  set track(Track? newValue) {
    if (super.track != newValue) {
      logger.fine('setTrack ${newValue} $sid ${objectId}');
      // dispose previous track (if exists)
      super.track?.dispose();
      super.track = newValue;

      if (newValue != null) {
        final listener = newValue.createListener();
        listener.on<VideoRendererVisibilityUpdateEvent>(
            _onVideoRendererVisibilityUpdateEvent);
        newValue.onDispose(() async {
          await listener.dispose();
          // consider all views are disposed when track is null
          _rendererVisibilities.clear();
          // _visibilityDidUpdate?.call(null);
        });
      }

      _visibilityDidUpdate?.call(null);
    }
  }

  // Future<void> _attachTrackEventsListener() async {
  // await _listener?.dispose();
  // _listener = track?.createListener();
  // logger.fine('DISPOSE EVENT LISTENING ON ${track?.objectId}');
  // _listener?.on<VideoRendererVisibilityUpdateEvent>(
  //     _onVideoRendererVisibilityUpdateEvent);
  // }

  set videoQuality(lk_rtc.VideoQuality val) {
    if (val == _videoQuality) return;
    _videoQuality = val;
    _sendUpdateTrackSettings();
  }

  bool get enabled => !_disabled;
  set enabled(bool val) {
    if (_disabled == !val) return;
    _disabled = !val;
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
      [_participant.events, _participant.roomEvents]
          .emit(TrackUnsubscribedEvent(
        participant: _participant,
        track: track!,
        publication: this,
      ));
      // Simply set to null for now
      track = null;
    }
  }

  /// for internal use
  /// {@nodoc}
  @override
  @internal
  set muted(bool val) {
    if (val == muted) {
      return;
    }
    super.muted = val;
    if (val) {
      // Track muted
      [_participant.events, _participant.roomEvents].emit(TrackMutedEvent(
        participant: _participant,
        track: this,
      ));
    } else {
      // Track un-muted
      [_participant.events, _participant.roomEvents].emit(TrackUnmutedEvent(
        participant: _participant,
        track: this,
      ));
    }
    if (subscribed) {
      track?.mediaStreamTrack.enabled = !val;
    }
  }

  void _sendUpdateSubscription({required bool subscribed}) {
    logger.fine('Sending update subscription... ${sid} ${subscribed}');
    final subscription = lk_rtc.UpdateSubscription(
      trackSids: [sid],
      subscribe: subscribed,
    );
    _participant.client.sendUpdateSubscription(subscription);
  }

  void _sendUpdateTrackSettings() {
    final settings = lk_rtc.UpdateTrackSettings(
      trackSids: [sid],
      disabled: _disabled,
    );
    if (kind == lk_models.TrackType.VIDEO) {
      settings.quality = _videoQuality;
    }
    _participant.client.sendUpdateTrackSettings(settings);
  }
}
