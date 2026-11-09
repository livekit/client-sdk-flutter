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

import 'package:meta/meta.dart' show immutable, internal;

import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../types/other.dart';
import '../types/video_dimensions.dart';

/// Represents a video quality setting — either explicit dimensions or a
/// quality level (LOW/MEDIUM/HIGH), never both.
///
/// Used for both user-requested settings and the resolved merge result.
@internal
@immutable
class VideoSettings {
  final VideoDimensions? dimensions;
  final VideoQuality? quality;

  const VideoSettings.dimensions(VideoDimensions this.dimensions) : quality = null;

  const VideoSettings.quality(VideoQuality this.quality) : dimensions = null;

  static const high = VideoSettings.quality(VideoQuality.HIGH);
}

/// Merges adaptive stream dimensions with manual [VideoSettings],
/// always picking the more conservative (smaller) of the two.
///
/// This matches the JS SDK's merge behavior in `emitTrackUpdate()`.
@internal
VideoSettings resolveVideoSettings({
  VideoDimensions? adaptiveStreamDimensions,
  VideoSettings? userPreference,
  VideoDimensions? Function(VideoQuality quality)? layerDimensionsForQuality,
}) {
  VideoDimensions? minDimensions = userPreference?.dimensions;

  if (adaptiveStreamDimensions != null) {
    if (minDimensions != null) {
      // Use the smaller of adaptive vs manually requested dimensions
      if (adaptiveStreamDimensions.area() < minDimensions.area()) {
        minDimensions = adaptiveStreamDimensions;
      }
    } else if (userPreference?.quality != null) {
      // Compare adaptive dimensions with the dimensions implied by the requested quality.
      final requestedQualityLayerDimensions = layerDimensionsForQuality?.call(userPreference!.quality!);
      if (requestedQualityLayerDimensions != null &&
          adaptiveStreamDimensions.area() < requestedQualityLayerDimensions.area()) {
        minDimensions = adaptiveStreamDimensions;
      }
    } else {
      minDimensions = adaptiveStreamDimensions;
    }
  }

  if (minDimensions != null) {
    return VideoSettings.dimensions(minDimensions);
  } else if (userPreference?.quality != null) {
    return VideoSettings.quality(userPreference!.quality!);
  }
  return VideoSettings.high;
}

/// The user's explicit enable/disable request for a track, used to decide
/// whether visibility may gate the track. Equivalent to the JS SDK's
/// `requestedDisabled` tri-state (`undefined` / `false` / `true`).
@internal
enum TrackEnabledPreference {
  /// No explicit request; adaptive-stream visibility decides.
  unset,

  /// User explicitly enabled; overrides visibility (track keeps streaming).
  enabled,

  /// User explicitly disabled; overrides visibility (track stays off).
  disabled,
}

/// Resolves whether a subscribed track should be sent as `disabled`.
///
/// Mirrors the JS SDK's `isEnabled` precedence: an explicit user
/// enable/disable always wins; otherwise, when adaptive stream is active for
/// the track, view visibility decides; otherwise the track is enabled.
@internal
bool resolveDisabled({
  required TrackEnabledPreference enabledPreference,
  required bool adaptiveStreamActive,
  required bool adaptiveStreamVisible,
}) {
  switch (enabledPreference) {
    case TrackEnabledPreference.enabled:
      return false;
    case TrackEnabledPreference.disabled:
      return true;
    case TrackEnabledPreference.unset:
      return adaptiveStreamActive ? !adaptiveStreamVisible : false;
  }
}

/// Builds the [lk_rtc.UpdateTrackSettings] request sent to the server from the
/// already-resolved [disabled] flag and, for video, the resolved [dimensions]
/// or [quality] plus an optional [fps]. [dimensions] takes precedence over
/// [quality]; pass neither for non-video tracks.
@internal
lk_rtc.UpdateTrackSettings buildUpdateTrackSettings({
  required String sid,
  required bool disabled,
  VideoDimensions? dimensions,
  lk_models.VideoQuality? quality,
  int? fps,
}) {
  final settings = lk_rtc.UpdateTrackSettings(
    trackSids: [sid],
    disabled: disabled,
  );
  if (dimensions != null) {
    settings.width = dimensions.width;
    settings.height = dimensions.height;
  } else if (quality != null) {
    settings.quality = quality;
  }
  if (fps != null) settings.fps = fps;
  return settings;
}
