// Copyright 2024 LiveKit, Inc.
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

import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

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
import '../types/video_dimensions.dart';
import '../utils.dart';
import 'track_publication.dart';
import 'track_settings.dart';

/// Represents a track publication from a RemoteParticipant. Provides methods to
/// control if we should subscribe to the track, and its quality (for video).
class RemoteTrackPublication<T extends RemoteTrack> extends TrackPublication<T> {
  /// The [RemoteParticipant] this [RemoteTrackPublication] belongs to.
  @override
  final RemoteParticipant participant;

  bool get enabled => !resolveDisabled(
        enabledPreference: _enabledPreference,
        adaptiveStreamActive: _adaptiveStreamActive,
        adaptiveStreamVisible: _adaptiveStreamVisible,
      );

  /// The user's explicit enable/disable request via [enable] / [disable].
  /// [TrackEnabledPreference.unset] means no explicit request, in which case
  /// adaptive-stream visibility decides. An explicit request takes precedence
  /// over visibility.
  TrackEnabledPreference _enabledPreference = TrackEnabledPreference.unset;

  /// The current desired FPS of the track. This is only available for video tracks that support SVC.
  int? _fps;
  int get fps => _fps ?? 0;

  // Manual settings (set by user via setVideoQuality / setVideoDimensions)
  VideoSettings? _userPreference;

  // Adaptive stream state (set automatically by visibility observer)
  VideoDimensions? _adaptiveStreamDimensions;
  // Whether adaptive stream is active for this publication (room option on +
  // remote video track). When false, view visibility never gates `disabled`.
  bool _adaptiveStreamActive = false;
  // Whether at least one view of this track is currently visible/sized.
  bool _adaptiveStreamVisible = true;

  VideoQuality get videoQuality => _userPreference?.quality ?? VideoQuality.HIGH;
  VideoDimensions? get videoDimensions => _userPreference?.dimensions;

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
    return super.subscribed ? TrackSubscriptionState.subscribed : TrackSubscriptionState.unsubscribed;
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
  }) : super(info: info, track: track) {
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
  }

  @internal
  @override
  void updateFromInfo(lk_models.TrackInfo info) {
    logger.fine('RemoteTrackPublication.updateFromInfo sid: ${info.sid} muted: ${info.muted}');
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

    // Filter visible build contexts and scale each view's logical size by its
    // own pixel density, so the server is asked for physical-pixel dimensions
    // (retina-aware). Each view's density is configured on its VideoTrackRenderer
    // and resolved per-view; with AdaptiveStreamPixelDensity.auto the actual
    // device pixel ratio is read from that view via MediaQuery. The largest
    // resulting size across all of the track's views is requested.
    final viewSizes = videoTrack.viewRegistrations
        .map((registration) {
          final context = registration.key.currentContext;
          if (context == null) return null;
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox == null || !renderBox.hasSize) return null;
          final density = registration.pixelDensity.resolve(
            MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0,
          );
          return renderBox.size * density;
        })
        .nonNulls
        .toList();

    logger.finer('[Visibility] ${track?.sid} watching ${viewSizes.length} views...');

    if (viewSizes.isNotEmpty) {
      final largestSize = viewSizes.reduce(maxOfSizes);
      _adaptiveStreamDimensions = VideoDimensions(
        largestSize.width.ceil(),
        largestSize.height.ceil(),
      );
      _adaptiveStreamVisible = true;
    } else {
      _adaptiveStreamDimensions = null;
      _adaptiveStreamVisible = false;
    }

    final settings = _buildTrackSettings();

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

  void _sendPendingTrackSettingsUpdateRequest(lk_rtc.UpdateTrackSettings _) {
    // Re-build from the current state at fire time instead of replaying the
    // snapshot captured when the debounce was scheduled. Otherwise a stale
    // snapshot could be sent after newer state (e.g. a manual setVideoQuality)
    // has already been applied, clobbering it.
    final settings = _buildTrackSettings();
    _lastSentTrackSettings = settings;
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

      // The track changed, so any adaptive-stream visibility computed for the
      // previous track is stale. Reset to the construction defaults so it can't
      // leak into a later _buildTrackSettings (e.g. via enable() / disable(),
      // which emit regardless of visibility). Repopulated by the visibility
      // observer below while adaptive stream is active.
      _adaptiveStreamDimensions = null;
      _adaptiveStreamVisible = true;

      final roomOptions = participant.room.roomOptions;
      if (roomOptions.adaptiveStream && newValue is RemoteVideoTrack) {
        _adaptiveStreamActive = true;
        // Start monitoring visibility
        _visibilityTimer = Timer.periodic(
          const Duration(milliseconds: 300),
          (_) => _computeVideoViewVisibility(),
        );

        newValue.onVideoViewBuild = () {
          logger.finer('[Visibility] VideoView did build');
          if (_lastSentTrackSettings?.disabled == true) {
            // quick enable
            _cancelPendingTrackSettingsUpdateRequest?.call();
            _computeVideoViewVisibility(quick: true);
          }
        };

        _computeVideoViewVisibility(quick: true);
      } else {
        _adaptiveStreamActive = false;
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

  bool _isManualOperationAllowed() {
    if (kind != TrackType.VIDEO) {
      logger.warning('Manual video setting updates are only supported for video tracks');
      return false;
    }

    if (!subscribed) {
      logger.warning('Manual video setting update ignored because the publication is not subscribed');
      return false;
    }

    return true;
  }

  /// For tracks that support simulcasting, adjust subscribed quality.
  ///
  /// This indicates the highest quality the client can accept. If network
  /// bandwidth does not allow, the server will automatically reduce quality to
  /// optimize for uninterrupted video.
  ///
  /// When adaptive stream is active, this preference is merged client-side with
  /// the dimensions computed from the visible views, and the smaller (more
  /// conservative) of the two is sent to the server.
  Future<void> setVideoQuality(VideoQuality newValue) async {
    if (newValue == _userPreference?.quality) return;
    if (!_isManualOperationAllowed()) return;
    _userPreference = VideoSettings.quality(newValue);
    _emitTrackUpdate();
  }

  /// Set preferred video dimensions for this track.
  ///
  /// Server will choose the appropriate layer based on these dimensions.
  /// Will override previous calls to [setVideoQuality].
  ///
  /// When adaptive stream is active, this preference is merged client-side with
  /// the dimensions computed from the visible views, and the smaller (more
  /// conservative) of the two is sent to the server.
  Future<void> setVideoDimensions(VideoDimensions newValue) async {
    if (newValue == _userPreference?.dimensions) return;
    if (!_isManualOperationAllowed()) return;
    _userPreference = VideoSettings.dimensions(newValue);
    _emitTrackUpdate();
  }

  /// Set desired FPS, server will do its best to return FPS close to this.
  /// It's only supported for video codecs that support SVC currently.
  Future<void> setVideoFPS(int newValue) async {
    if (newValue == _fps) return;
    if (!_isManualOperationAllowed()) return;
    _fps = newValue;
    _emitTrackUpdate();
  }

  Future<void> enable() async {
    if (_enabledPreference == TrackEnabledPreference.enabled) return;
    _enabledPreference = TrackEnabledPreference.enabled;
    _emitTrackUpdate();
  }

  Future<void> disable() async {
    if (_enabledPreference == TrackEnabledPreference.disabled) return;
    _enabledPreference = TrackEnabledPreference.disabled;
    _emitTrackUpdate();
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
      trackSids: [sid],
      subscribe: subscribed,
    );
    participant.room.engine.signalClient.sendUpdateSubscription(subscription);
  }

  lk_rtc.UpdateTrackSettings _buildTrackSettings() {
    final isDisabled = resolveDisabled(
      enabledPreference: _enabledPreference,
      adaptiveStreamActive: _adaptiveStreamActive,
      adaptiveStreamVisible: _adaptiveStreamVisible,
    );

    if (kind != TrackType.VIDEO) {
      return buildUpdateTrackSettings(sid: sid, disabled: isDisabled);
    }

    final resolved = resolveVideoSettings(
      adaptiveStreamDimensions: _adaptiveStreamDimensions,
      userPreference: _userPreference,
      layerDimensionsForQuality: (quality) {
        final pbQuality = quality.toPBType();
        final layer = latestInfo?.layers.where((l) => l.quality == pbQuality).firstOrNull;
        if (layer == null) return null;
        return VideoDimensions(layer.width, layer.height);
      },
    );

    return buildUpdateTrackSettings(
      sid: sid,
      disabled: isDisabled,
      dimensions: resolved.dimensions,
      quality: resolved.quality?.toPBType(),
      fps: _fps,
    );
  }

  void _emitTrackUpdate() {
    // Cancel any pending debounced visibility update so its (now potentially
    // stale) snapshot cannot fire after — and clobber — this immediate update.
    _cancelPendingTrackSettingsUpdateRequest?.call();
    final settings = _buildTrackSettings();
    _lastSentTrackSettings = settings;
    participant.room.engine.signalClient.sendUpdateTrackSettings(settings);
  }

  @internal
  void sendUpdateTrackSettings() => _emitTrackUpdate();

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
}
