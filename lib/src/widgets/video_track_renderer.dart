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

import 'package:flutter/widgets.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../track/local/local.dart';
import '../types/other.dart';
import 'video_track_renderer_common.dart';

import 'video_track_renderer_native.dart'
    if (dart.library.js_interop) 'video_track_renderer_web.dart'
    as implementation;

export 'video_track_renderer_common.dart' show VideoRenderMode, VideoViewFit, VideoViewFitExt, VideoViewMirrorMode;

/// Widget that renders a [VideoTrack].
class VideoTrackRenderer extends StatefulWidget {
  final VideoTrack track;
  final VideoViewFit fit;
  final VideoViewMirrorMode mirrorMode;
  final VideoRenderMode renderMode;

  /// An existing renderer borrowed by this widget. The caller remains responsible
  /// for disposing it; the widget detaches it but never disposes it.
  final rtc.RTCVideoRenderer? cachedRenderer;

  /// Whether to dispose a renderer created by this widget when it is released.
  /// Defaults to true. This has no effect on [cachedRenderer].
  final bool autoDisposeRenderer;

  /// wrap the video view in a Center widget (if [fit] is [VideoViewFit.contain])
  final bool autoCenter;

  /// Controls how this view's logical size is converted to the physical-pixel
  /// dimensions requested from the server when adaptive stream is enabled.
  /// Defaults to [AdaptiveStreamPixelDensity.auto] (the view's own device pixel
  /// ratio), avoiding an under-sized layer on retina / high-density displays.
  final AdaptiveStreamPixelDensity adaptiveStreamPixelDensity;

  /// Placeholder builder to display while the track is loading.
  ///
  /// On iOS and macOS, this has no effect when [renderMode] is [VideoRenderMode.platformView].
  final WidgetBuilder? placeholderBuilder;

  const VideoTrackRenderer(
    this.track, {
    this.fit = VideoViewFit.contain,
    this.mirrorMode = VideoViewMirrorMode.auto,
    this.renderMode = VideoRenderMode.auto,
    this.autoDisposeRenderer = true,
    this.cachedRenderer,
    this.autoCenter = true,
    this.adaptiveStreamPixelDensity = AdaptiveStreamPixelDensity.auto,
    this.placeholderBuilder,
    super.key,
  });

  @override
  State<VideoTrackRenderer> createState() => _VideoTrackRendererState();
}

class _VideoTrackRendererState extends State<VideoTrackRenderer> {
  @override
  Widget build(BuildContext context) => implementation.buildVideoTrackRenderer(
    track: widget.track,
    fit: widget.fit,
    mirrorMode: widget.mirrorMode,
    renderMode: widget.renderMode,
    cachedRenderer: widget.cachedRenderer,
    autoDisposeRenderer: widget.autoDisposeRenderer,
    autoCenter: widget.autoCenter,
    adaptiveStreamPixelDensity: widget.adaptiveStreamPixelDensity,
    placeholderBuilder: widget.placeholderBuilder,
  );
}
