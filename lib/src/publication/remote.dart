import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../core/signal_client.dart';
import '../events.dart';
import '../extensions.dart';
import '../logger.dart';
import '../options.dart';
import '../participant/remote.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../track/local/local.dart';
import '../track/remote/remote.dart';
import '../track/remote/video.dart';
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
  lk_rtc.UpdateTrackSettings? _lastSentTrackSettings;
  Timer? _visibilityTimer;

  Function(lk_rtc.UpdateTrackSettings)? _setPendingTrackSettingsUpdateRequest;
  Function? _cancelPendingTrackSettingsUpdateRequest;

  RemoteTrackPublication({
    required this.participant,
    required lk_models.TrackInfo info,
    T? track,
  }) : super(info: info) {
    logger.fine('RemoteTrackPublication.init track: $track, info: $info');

    // register dispose func
    onDispose(() async {
      _cancelPendingTrackSettingsUpdateRequest?.call();
      _visibilityTimer?.cancel();
      // this object is responsible for disposing track
      await this.track?.dispose();
    });

    _setPendingTrackSettingsUpdateRequest = Utils.createDebounceFunc(
      _sendPendingTrackSettingsUpdateRequest,
      cancelFunc: (func) => _cancelPendingTrackSettingsUpdateRequest = func,
      wait: const Duration(milliseconds: 1500),
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

  void _computeVideoViewVisibility({
    bool quick = false,
  }) {
    //
    Size maxOfSizes(Size s1, Size s2) => Size(
          max(s1.width, s2.width),
          max(s1.height, s2.height),
        );

    final videoTrack = track as VideoTrack;

    final settings = lk_rtc.UpdateTrackSettings(
      trackSids: [sid],
      disabled: true,
    );

    // filter visible build contexts
    final viewSizes = videoTrack.viewKeys
        .map((e) => e.currentContext)
        .whereNotNull()
        .map((e) => e.findRenderObject() as RenderBox?)
        .whereNotNull()
        .map((e) => e.size);

    logger.finer(
        '[Visibility] ${track?.sid} watching ${viewSizes.length} views...');

    if (viewSizes.isNotEmpty) {
      // compute largest size
      final largestSize =
          viewSizes.reduce((value, element) => maxOfSizes(value, element));

      settings
        ..disabled = false
        ..width = largestSize.width.ceil()
        ..height = largestSize.height.ceil();
    }

    // Only send new settings to server if it changed
    if (settings != _lastSentTrackSettings) {
      _lastSentTrackSettings = settings;
      logger.fine('[Visibility] Change detected, quick: $quick');
      if (quick) {
        _sendPendingTrackSettingsUpdateRequest(settings);
      } else {
        _setPendingTrackSettingsUpdateRequest?.call(settings);
      }
    }
  }

  void _sendPendingTrackSettingsUpdateRequest(
      lk_rtc.UpdateTrackSettings settings) {
    logger.fine('[Visibility] Sending... ${settings.toProto3Json()}');
    participant.room.engine.signalClient.sendUpdateTrackSettings(settings);
  }

  @internal
  @override
  Future<bool> updateTrack(covariant T? newValue) async {
    logger.fine('RemoteTrackPublication.updateTrack track: $newValue');
    final didUpdate = await super.updateTrack(newValue);

    if (didUpdate) {
      // Stop current visibility timer (if exists)
      _cancelPendingTrackSettingsUpdateRequest?.call();
      _visibilityTimer?.cancel();

      final roomOptions = participant.room.roomOptions ?? const RoomOptions();
      if (roomOptions.adaptiveStream && newValue is RemoteVideoTrack) {
        // Start monitoring visibility
        _visibilityTimer = Timer.periodic(
          const Duration(milliseconds: 300),
          (_) => _computeVideoViewVisibility(),
        );

        newValue.onVideoViewBuild = (_) {
          logger.fine('[Visibility] VideoView did build');
          if (_lastSentTrackSettings?.disabled == true) {
            // quick enable
            _cancelPendingTrackSettingsUpdateRequest?.call();
            _computeVideoViewVisibility(quick: true);
          }
        };
      }

      if (newValue != null) {
        // if new Track has been set to this RemoteTrackPublication,
        // update the Track's muted state from the latest info.
        newValue.updateMuted(
          _metadataMuted,
          shouldNotify: false, // don't emit event since this is initial state
        );
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
