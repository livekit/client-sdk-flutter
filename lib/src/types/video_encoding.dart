// Copyright 2023 LiveKit, Inc.
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

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

/// A type that represents video encoding information.
@immutable
class VideoEncoding implements Comparable<VideoEncoding> {
  final int maxFramerate;
  final int maxBitrate;

  const VideoEncoding({
    required this.maxFramerate,
    required this.maxBitrate,
  });

  VideoEncoding copyWith({
    int? maxFramerate,
    int? maxBitrate,
  }) =>
      VideoEncoding(
        maxFramerate: maxFramerate ?? this.maxFramerate,
        maxBitrate: maxBitrate ?? this.maxBitrate,
      );

  @override
  String toString() =>
      '${runtimeType}(maxFramerate: ${maxFramerate}, maxBitrate: ${maxBitrate})';

  // ----------------------------------------------------------------------
  // equality

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoEncoding &&
          maxFramerate == other.maxFramerate &&
          maxBitrate == other.maxBitrate;

  @override
  int get hashCode => Object.hash(maxFramerate, maxBitrate);

  // ----------------------------------------------------------------------
  // Comparable

  @override
  int compareTo(VideoEncoding other) {
    // compare bitrates
    final result = maxBitrate.compareTo(other.maxBitrate);
    // if bitrates are the same, compare by fps
    if (result == 0) {
      return maxFramerate.compareTo(other.maxFramerate);
    }

    return result;
  }
}

/// Convenience extension for [VideoEncoding].
extension VideoEncodingExt on VideoEncoding {
  rtc.RTCRtpEncoding toRTCRtpEncoding({
    String? rid,
    double? scaleResolutionDownBy = 1.0,
    int? numTemporalLayers,
  }) =>
      rtc.RTCRtpEncoding(
        rid: rid,
        scaleResolutionDownBy: scaleResolutionDownBy,
        maxFramerate: maxFramerate,
        maxBitrate: maxBitrate,
        numTemporalLayers: numTemporalLayers,
      );
}
