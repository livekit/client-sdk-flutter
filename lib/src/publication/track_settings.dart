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
      // Compare adaptive dimensions with the max quality layer dimensions
      final maxQualityLayer = layerDimensionsForQuality?.call(userPreference!.quality!);
      if (maxQualityLayer != null && adaptiveStreamDimensions.area() < maxQualityLayer.area()) {
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
