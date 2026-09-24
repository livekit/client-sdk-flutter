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

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../track/local/local.dart';
import '../track/local/video.dart';
import '../track/options.dart';
import '../types/other.dart';

enum VideoViewMirrorMode {
  auto,
  off,
  mirror,
}

enum VideoRenderMode {
  /// Let the SDK choose the rendering backend. Currently resolves to
  /// [texture] on all platforms, but the resolution may change in a
  /// future release.
  auto,

  /// Render frames into a Flutter texture.
  texture,

  /// Render with a native platform view. Supported on iOS and macOS,
  /// other platforms fall back to [texture].
  platformView,
}

enum VideoViewFit {
  contain,
  cover,
}

extension VideoViewFitExt on VideoViewFit {
  rtc.RTCVideoViewObjectFit toRTCType() {
    if (this == VideoViewFit.cover) {
      return rtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
    }
    return rtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitContain;
  }
}

rtc.RTCVideoRenderer Function() videoTrackRendererFactory = rtc.RTCVideoRenderer.new;

bool Function(VideoRenderMode)? videoTrackRendererPlatformViewOverride;

bool shouldMirror(VideoTrack track, VideoViewMirrorMode mirrorMode) {
  if (track.source == TrackSource.screenShareVideo) return false;
  if (mirrorMode == VideoViewMirrorMode.mirror) return true;
  if (mirrorMode == VideoViewMirrorMode.auto && track is LocalVideoTrack) {
    final settings = track.mediaStreamTrack.getSettings();
    final facingMode = settings['facingMode'];
    if (facingMode != null) return facingMode == 'user';
    final options = track.currentOptions;
    if (options is CameraCaptureOptions) return options.cameraPosition == CameraPosition.front;
  }
  return false;
}
