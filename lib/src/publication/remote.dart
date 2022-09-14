import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../core/signal_client.dart';
import '../events.dart';
import '../extensions.dart';
import '../logger.dart';
import '../participant/remote.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../track/local/local.dart';
import '../track/remote/remote.dart';
import '../track/remote/video.dart';
import '../types/other.dart';
import '../utils.dart';
import 'track_publication.dart';

/// Represents a track publication from a RemoteParticipant. Provides methods to
/// control if we should subscribe to the track, and its quality (for video).
class RemoteTrackPublication<T extends RemoteTrack>
    extends TrackPublication<T> {
  /// The [RemoteParticipant] this [RemoteTrackPublication] belongs to.
  @override
  final RemoteParticipant participant;

  bool get enabled => _enabled;
  bool _enabled = true;

  lk_models.VideoQuality _videoQuality = lk_models.VideoQuality.HIGH;
  lk_models.VideoQuality get videoQuality => _videoQuality;

  /// The server may pause the track when they are bandwidth limitations and resume
  /// when there is more capacity. This property will be updated when the track is
  /// paused / resumed by the server. See [TrackStreamStateUpdatedEvent] for the
  /// relevant event.
  StreamState get streamState => _streamState;
  StreamState _streamState = StreamState.paused;

  // latest TrackInfo
  bool _metadataMuted = false;

  // allowed to subscribe
  bool _subscriptionAllowed = true;
  bool get subscriptionAllowed => _subscriptionAllowed;

  @override
  bool get subscribed {
    // always return false when subscription is not allowed
    if (!_subscriptionAllowed) return false;
    return super.subscribed;
  }

  TrackSubscriptionState get subscriptionState {
    if (!_subscriptionAllowed) return TrackSubscriptionState.notAllowed;
    return super.subscribed
        ? TrackSubscriptionState.subscribed
        : TrackSubscriptionState.unsubscribed;
  }

  @internal
  Future<void> updateStreamState(StreamState streamState) async {
    // return if no change
    if (_streamState == streamState) return;
    _streamState = streamState;
    [
      participant.events,
    ].emit(TrackStreamStateUpdatedEvent(
      participant: participant,
      publication: this,
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

      final roomOptions = participant.room.roomOptions;
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

  @Deprecated('use setVideoQuality() instead')
  set videoQuality(lk_models.VideoQuality newValue) {
    setVideoQuality(newValue);
  }

  Future<void> setVideoQuality(lk_models.VideoQuality newValue) async {
    if (newValue == _videoQuality) return;
    _videoQuality = newValue;
    sendUpdateTrackSettings();
  }

  Future<void> enable() async {
    if (_enabled) return;
    _enabled = true;
    sendUpdateTrackSettings();
  }

  Future<void> disable() async {
    if (!_enabled) return;
    _enabled = false;
    sendUpdateTrackSettings();
  }

  Future<void> subscribe() async {
    if (super.subscribed || !_subscriptionAllowed) {
      logger.fine('ignoring subscribe() request...');
      return;
    }
    _sendUpdateSubscription(subscribed: true);
  }

  Future<void> unsubscribe() async {
    if (!super.subscribed || !_subscriptionAllowed) {
      logger.fine('ignoring unsubscribe() request...');
      return;
    }
    _sendUpdateSubscription(subscribed: false);
    if (track != null) {
      // Ideally, we should wait for WebRTC's onRemoveTrack event
      // but it does not work reliably across platforms.
      // So for now we will assume remove track succeeded.
      [participant.events, participant.room.events].emit(TrackUnsubscribedEvent(
        participant: participant,
        track: track!,
        publication: this,
      ));
      // Simply set to null for now
      await updateTrack(null);
    }
  }

  void _sendUpdateSubscription({required bool subscribed}) {
    logger.fine('Sending update subscription... ${sid} ${subscribed}');
    final participantTrack = lk_models.ParticipantTracks(
      participantSid: participant.sid,
      trackSids: [sid],
    );
    final subscription = lk_rtc.UpdateSubscription(
      participantTracks: [participantTrack],
      trackSids: [sid], // Deprecated
      subscribe: subscribed,
    );
    participant.room.engine.signalClient.sendUpdateSubscription(subscription);
  }

  @internal
  void sendUpdateTrackSettings() {
    final settings = lk_rtc.UpdateTrackSettings(
      trackSids: [sid],
      disabled: !_enabled,
    );
    if (kind == lk_models.TrackType.VIDEO) {
      settings.quality = _videoQuality;
    }
    participant.room.engine.signalClient.sendUpdateTrackSettings(settings);
  }

  @internal
  // Update internal var and return true if changed
  Future<bool> updateSubscriptionAllowed(bool allowed) async {
    if (_subscriptionAllowed == allowed) return false;
    _subscriptionAllowed = allowed;

    logger.fine('updateSubscriptionAllowed allowed: ${allowed}');
    // emit events
    [
      participant.events,
    ].emit(TrackSubscriptionPermissionChangedEvent(
      participant: participant,
      publication: this,
      state: subscriptionState,
    ));

    if (!_subscriptionAllowed && super.subscribed /* track != null */) {
      // Ideally, we should wait for WebRTC's onRemoveTrack event
      // but it does not work reliably across platforms.
      // So for now we will assume remove track succeeded.
      [participant.events, participant.room.events].emit(TrackUnsubscribedEvent(
        participant: participant,
        track: track!,
        publication: this,
      ));
      // Simply set to null for now
      await updateTrack(null);
    }

    return true;
  }

  // Deprecated --------------------------------------------------

  @Deprecated('use subscribe() or unsubscribe() instead')
  set subscribed(bool newValue) {
    logger.fine('Setting subscribed = ${newValue}');
    newValue ? subscribe() : unsubscribe();
  }

  @Deprecated('Use enable() or disable() instead')
  set enabled(bool newValue) {
    logger.fine('Setting enabled = ${newValue}');
    newValue ? enable() : disable();
  }
}
