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

import '../types/other.dart';
import '../types/video_dimensions.dart';

/// The result of merging adaptive stream and manual video settings.
///
/// Separates the "what to send" decision from protobuf serialization,
/// making the merge logic testable without protobuf dependencies.
class ResolvedVideoSettings {
  /// If non-null, send dimensions (width/height) to the server.
  final VideoDimensions? dimensions;

  /// If non-null and [dimensions] is null, send quality to the server.
  final VideoQuality? quality;

  const ResolvedVideoSettings({this.dimensions, this.quality});
}

/// Merges adaptive stream dimensions with manual quality/dimension settings,
/// always picking the more conservative (smaller) of the two.
///
/// This matches the JS SDK's merge behavior in `emitTrackUpdate()`.
///
/// [adaptiveStreamDimensions] — set automatically by the visibility observer.
/// [requestedDimensions] — set manually via `setVideoDimensions()`.
/// [requestedMaxQuality] — set manually via `setVideoQuality()`.
/// [layerDimensionsForQuality] — resolves a quality to dimensions using the
///   track's published layer info. Passed as a callback so callers can provide
///   it from whatever source they have (protobuf TrackInfo, test fixture, etc).
ResolvedVideoSettings resolveVideoSettings({
  VideoDimensions? adaptiveStreamDimensions,
  VideoDimensions? requestedDimensions,
  VideoQuality? requestedMaxQuality,
  VideoDimensions? Function(VideoQuality quality)? layerDimensionsForQuality,
}) {
  VideoDimensions? minDimensions = requestedDimensions;

  if (adaptiveStreamDimensions != null) {
    if (minDimensions != null) {
      // Use the smaller of adaptive vs manually requested dimensions
      if (adaptiveStreamDimensions.area() < minDimensions.area()) {
        minDimensions = adaptiveStreamDimensions;
      }
    } else if (requestedMaxQuality != null) {
      // Compare adaptive dimensions with the max quality layer dimensions
      final maxQualityLayer = layerDimensionsForQuality?.call(requestedMaxQuality);
      if (maxQualityLayer != null &&
          adaptiveStreamDimensions.area() < maxQualityLayer.area()) {
        minDimensions = adaptiveStreamDimensions;
      }
    } else {
      minDimensions = adaptiveStreamDimensions;
    }
  }

  if (minDimensions != null) {
    return ResolvedVideoSettings(dimensions: minDimensions);
  } else if (requestedMaxQuality != null) {
    return ResolvedVideoSettings(quality: requestedMaxQuality);
  }
  return ResolvedVideoSettings(quality: VideoQuality.HIGH);
}
