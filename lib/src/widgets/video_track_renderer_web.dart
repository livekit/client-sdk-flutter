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

import 'package:flutter/material.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../events.dart';
import '../extensions.dart';
import '../internal/events.dart';
import '../logger.dart';
import '../managers/event.dart';
import '../support/platform.dart';
import '../track/local/local.dart';
import '../track/video_track_view_registration.dart';
import '../types/other.dart';
import 'video_track_renderer_common.dart';

Widget buildVideoTrackRenderer({
  required VideoTrack track,
  required VideoViewFit fit,
  required VideoViewMirrorMode mirrorMode,
  required VideoRenderMode renderMode,
  required rtc.RTCVideoRenderer? cachedRenderer,
  required bool autoDisposeRenderer,
  required bool autoCenter,
  required AdaptiveStreamPixelDensity adaptiveStreamPixelDensity,
  required WidgetBuilder? placeholderBuilder,
}) => _WebVideoTrackRenderer(
  track: track,
  fit: fit,
  mirrorMode: mirrorMode,
  renderMode: renderMode,
  cachedRenderer: cachedRenderer,
  autoDisposeRenderer: autoDisposeRenderer,
  autoCenter: autoCenter,
  adaptiveStreamPixelDensity: adaptiveStreamPixelDensity,
  placeholderBuilder: placeholderBuilder,
);

class _WebVideoTrackRenderer extends StatefulWidget {
  const _WebVideoTrackRenderer({
    required this.track,
    required this.fit,
    required this.mirrorMode,
    required this.renderMode,
    required this.cachedRenderer,
    required this.autoDisposeRenderer,
    required this.autoCenter,
    required this.adaptiveStreamPixelDensity,
    required this.placeholderBuilder,
  });

  final VideoTrack track;
  final VideoViewFit fit;
  final VideoViewMirrorMode mirrorMode;
  final VideoRenderMode renderMode;
  final rtc.RTCVideoRenderer? cachedRenderer;
  final bool autoDisposeRenderer;
  final bool autoCenter;
  final AdaptiveStreamPixelDensity adaptiveStreamPixelDensity;
  final WidgetBuilder? placeholderBuilder;

  @override
  State<_WebVideoTrackRenderer> createState() => _WebVideoTrackRendererState();
}

class _WebVideoTrackRendererState extends State<_WebVideoTrackRenderer> {
  rtc.RTCVideoRenderer? _renderer;
  bool _ownsRenderer = false;
  bool _disposed = false;
  int _generation = 0;
  Future<void>? _initializing;
  Future<rtc.RTCVideoRenderer?>? _rendererFuture;
  bool _rendererReadyForWeb = false;
  double? _aspectRatio;
  EventsListener<TrackEvent>? _listener;
  late VideoTrackViewRegistration _viewRegistration;

  double? get _rendererAspectRatio => _renderer?.value.aspectRatio;

  Future<rtc.RTCVideoRenderer?> _startRenderer() async {
    final generation = _generation;
    if (_renderer == null) {
      final cached = widget.cachedRenderer;
      if (cached != null) {
        _renderer = cached;
      } else {
        final renderer = videoTrackRendererFactory();
        _renderer = renderer;
        _ownsRenderer = true;
        _initializing = renderer.initialize();
      }
    }
    final renderer = _renderer!;
    await _initializing;
    if (identical(renderer, _renderer)) _initializing = null;
    if (_disposed || generation != _generation || !identical(renderer, _renderer)) return null;
    await _attach(generation, renderer);
    if (_disposed || generation != _generation || !identical(renderer, _renderer)) return null;
    return renderer;
  }

  void _scheduleRenderer() {
    final future = _rendererFuture = _startRenderer();
    unawaited(() async {
      final renderer = await future;
      if (renderer == null || !mounted || !identical(future, _rendererFuture)) return;
      setState(() => _rendererReadyForWeb = true);
    }());
  }

  void _releaseRenderer({required bool dispose}) {
    final renderer = _renderer;
    _renderer = null;
    final ownsRenderer = _ownsRenderer;
    _ownsRenderer = false;
    final initializing = _initializing;
    _initializing = null;
    renderer?.onResize = null;
    if (renderer == null) return;
    if (initializing == null) {
      try {
        renderer.srcObject = null;
      } catch (e) {
        logger.warning('Got error detaching renderer: $e');
      }
      if (dispose && ownsRenderer) unawaited(renderer.dispose());
    } else {
      unawaited(() async {
        try {
          await initializing;
          renderer.srcObject = null;
        } catch (e) {
          logger.warning('Got error detaching renderer: $e');
        } finally {
          if (dispose && ownsRenderer) await renderer.dispose();
        }
      }());
    }
  }

  @override
  void initState() {
    super.initState();
    _viewRegistration = widget.track.addViewRegistration(pixelDensity: widget.adaptiveStreamPixelDensity);
    _scheduleRenderer();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    widget.track.removeViewRegistration(_viewRegistration);
    final listener = _listener;
    _listener = null;
    unawaited(listener?.dispose());
    _releaseRenderer(dispose: widget.autoDisposeRenderer);
    super.dispose();
  }

  Future<void> _attach(int generation, rtc.RTCVideoRenderer renderer) async {
    final oldListener = _listener;
    _listener = null;
    await oldListener?.dispose();
    if (_disposed || generation != _generation || !identical(renderer, _renderer)) return;
    final track = widget.track;
    renderer.srcObject = track.mediaStream;
    _listener = track.createListener()
      ..on<TrackStreamUpdatedEvent>((event) {
        if (_disposed || generation != _generation || !identical(renderer, _renderer)) return;
        renderer.srcObject = event.stream;
      })
      ..on<LocalTrackOptionsUpdatedEvent>((event) {
        if (_disposed || generation != _generation || !mounted) return;
        setState(() {});
      });
    renderer.onResize = () {
      if (_disposed || generation != _generation || !identical(renderer, _renderer) || !mounted) return;
      setState(() => _aspectRatio = _rendererAspectRatio);
    };
  }

  @override
  void didUpdateWidget(covariant _WebVideoTrackRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cachedChanged = !identical(oldWidget.cachedRenderer, widget.cachedRenderer);
    final trackChanged = !identical(oldWidget.track, widget.track);
    if (cachedChanged || trackChanged) {
      _generation++;
      _rendererReadyForWeb = false;
    }
    if (cachedChanged) {
      final listener = _listener;
      _listener = null;
      unawaited(listener?.dispose());
      _aspectRatio = null;
      _releaseRenderer(dispose: oldWidget.autoDisposeRenderer);
    }
    if (trackChanged) {
      oldWidget.track.removeViewRegistration(_viewRegistration);
      _viewRegistration = widget.track.addViewRegistration(pixelDensity: widget.adaptiveStreamPixelDensity);
    } else if (widget.adaptiveStreamPixelDensity != oldWidget.adaptiveStreamPixelDensity) {
      _viewRegistration.pixelDensity = widget.adaptiveStreamPixelDensity;
    }
    if (cachedChanged || trackChanged) {
      _scheduleRenderer();
    }
    if (!cachedChanged &&
        [BrowserType.safari, BrowserType.firefox].contains(lkBrowser()) &&
        oldWidget.key != widget.key) {
      _renderer?.srcObject = widget.track.mediaStream;
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = !_rendererReadyForWeb
        ? (widget.placeholderBuilder?.call(context) ?? const SizedBox.shrink())
        : Builder(
            key: _viewRegistration.key,
            builder: (context) {
              WidgetsBindingCompatible.instance?.addPostFrameCallback((timeStamp) {
                widget.track.onVideoViewBuild?.call();
              });
              return rtc.RTCVideoView(
                _renderer!,
                mirror: shouldMirror(widget.track, widget.mirrorMode),
                filterQuality: FilterQuality.medium,
                objectFit: widget.fit.toRTCType(),
                placeholderBuilder: widget.placeholderBuilder,
              );
            },
          );
    if (widget.fit == VideoViewFit.cover) return child;
    final videoView = LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth && !constraints.hasBoundedHeight || _aspectRatio == null) return child;
        final fixHeight =
            !constraints.hasBoundedWidth ||
            constraints.hasBoundedHeight && constraints.maxWidth / constraints.maxHeight > _aspectRatio!;
        final width = fixHeight ? constraints.maxHeight * _aspectRatio! : constraints.maxWidth;
        final height = fixHeight ? constraints.maxHeight : constraints.maxWidth / _aspectRatio!;
        return SizedBox(width: width, height: height, child: child);
      },
    );
    return widget.autoCenter ? Center(child: videoView) : videoView;
  }
}
