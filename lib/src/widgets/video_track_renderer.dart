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

import 'package:flutter/foundation.dart' show ValueListenable, kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../events.dart';
import '../extensions.dart';
import '../internal/events.dart';
import '../logger.dart';
import '../managers/event.dart';
import '../support/platform.dart';
import '../track/local/local.dart';
import '../track/local/video.dart';
import '../track/options.dart';
import '../track/video_track_view_registration.dart';
import '../types/other.dart' hide ConnectionState;

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

/// Widget that renders a [VideoTrack].
class VideoTrackRenderer extends StatefulWidget {
  final VideoTrack track;
  final VideoViewFit fit;
  final VideoViewMirrorMode mirrorMode;
  final VideoRenderMode renderMode;
  final rtc.RTCVideoRenderer? cachedRenderer;
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
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoTrackRendererState();
}

@visibleForTesting
rtc.RTCVideoRenderer Function() videoTrackRendererFactory = rtc.RTCVideoRenderer.new;

@visibleForTesting
bool Function(VideoRenderMode)? videoTrackRendererPlatformViewOverride;

class _VideoTrackRendererState extends State<VideoTrackRenderer> {
  rtc.VideoRenderer? _renderer;
  bool _ownsRenderer = false;
  bool _disposed = false;
  int _generation = 0;
  Future<void>? _initializing;
  Future<rtc.VideoRenderer?>? _rendererFuture;
  // for flutter web only.
  bool _rendererReadyForWeb = false;
  double? _aspectRatio;
  EventsListener<TrackEvent>? _listener;
  // Used to compute visibility information
  late VideoTrackViewRegistration _viewRegistration;

  bool _usesPlatformView(VideoRenderMode renderMode) =>
      videoTrackRendererPlatformViewOverride?.call(renderMode) ??
      (renderMode == VideoRenderMode.platformView && [PlatformType.iOS, PlatformType.macOS].contains(lkPlatform()));

  bool get _shouldUsePlatformView => _usesPlatformView(widget.renderMode);

  double? get _rendererAspectRatio {
    final renderer = _renderer;
    if (renderer != null && renderer is ValueListenable<rtc.RTCVideoValue>) {
      return (renderer as ValueListenable<rtc.RTCVideoValue>).value.aspectRatio;
    }
    return null;
  }

  Future<rtc.VideoRenderer?> _startRenderer() async {
    final generation = _generation;
    if (_shouldUsePlatformView) return null;
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
    if (kIsWeb) {
      unawaited(() async {
        final renderer = await future;
        if (renderer == null || !mounted || !identical(future, _rendererFuture)) return;
        setState(() => _rendererReadyForWeb = true);
      }());
    }
  }

  void setZoom(double zoomLevel) async {
    final videoTrack = _renderer?.srcObject!.getVideoTracks().first;
    if (videoTrack == null) return;
    await rtc.Helper.setZoom(videoTrack, zoomLevel);
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    final videoTrack = _renderer?.srcObject!.getVideoTracks().first;
    if (videoTrack == null) return;

    final point = Point<double>(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    // Don't wait here as it will slow down the UI unnecessarily.
    unawaited(rtc.Helper.setFocusPoint(videoTrack, point));
    unawaited(rtc.Helper.setExposurePoint(videoTrack, point));
  }

  /// Detaches the current renderer and drops our reference to it.
  /// Pass [dispose] only for renderers this widget created and owns.
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

  Future<void> _attach(int generation, rtc.VideoRenderer renderer) async {
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
  void didUpdateWidget(covariant VideoTrackRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final modeChanged = _usesPlatformView(oldWidget.renderMode) != _shouldUsePlatformView;
    final cachedChanged = !_shouldUsePlatformView && !identical(oldWidget.cachedRenderer, widget.cachedRenderer);
    final trackChanged = !identical(oldWidget.track, widget.track);
    if (modeChanged || cachedChanged || trackChanged) {
      _generation++;
      _rendererReadyForWeb = false;
    }
    if (modeChanged || cachedChanged) {
      // Platform view controllers and cached renderers belong to their creators.
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

    if (modeChanged || cachedChanged || (trackChanged && !_shouldUsePlatformView)) {
      _scheduleRenderer();
    } else if (trackChanged && _renderer != null) {
      unawaited(_attach(_generation, _renderer!));
    }

    if (!modeChanged &&
        !cachedChanged &&
        [BrowserType.safari, BrowserType.firefox].contains(lkBrowser()) &&
        oldWidget.key != widget.key) {
      _renderer?.srcObject = widget.track.mediaStream;
    }
  }

  Widget _videoViewForWeb() => !_rendererReadyForWeb
      ? (widget.placeholderBuilder?.call(context) ?? const SizedBox.shrink())
      : Builder(
          key: _viewRegistration.key,
          builder: (ctx) {
            // let it render before notifying build
            WidgetsBindingCompatible.instance?.addPostFrameCallback((timeStamp) {
              widget.track.onVideoViewBuild?.call();
            });
            return rtc.RTCVideoView(
              _renderer! as rtc.RTCVideoRenderer,
              mirror: _shouldMirror(),
              filterQuality: FilterQuality.medium,
              objectFit: widget.fit.toRTCType(),
              placeholderBuilder: widget.placeholderBuilder,
            );
          },
        );

  Widget _videoRendererView() {
    if (_shouldUsePlatformView) {
      final generation = _generation;
      return rtc.RTCVideoPlatFormView(
        mirror: _shouldMirror(),
        objectFit: widget.fit.toRTCType(),
        onViewReady: (controller) async {
          if (_disposed || generation != _generation || !_shouldUsePlatformView) return;
          _renderer = controller;
          await _attach(generation, controller);
        },
      );
    }
    return rtc.RTCVideoView(
      _renderer! as rtc.RTCVideoRenderer,
      mirror: _shouldMirror(),
      filterQuality: FilterQuality.medium,
      objectFit: widget.fit.toRTCType(),
      placeholderBuilder: widget.placeholderBuilder,
    );
  }

  Widget _videoViewForNative() => FutureBuilder(
    future: _rendererFuture,
    builder: (context, snapshot) {
      if ((snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData &&
              identical(snapshot.data, _renderer)) ||
          _shouldUsePlatformView) {
        return Builder(
          key: _viewRegistration.key,
          builder: (ctx) {
            // let it render before notifying build
            WidgetsBindingCompatible.instance?.addPostFrameCallback((timeStamp) {
              widget.track.onVideoViewBuild?.call();
            });

            if (!lkPlatformIsMobile() || widget.track is! LocalVideoTrack) {
              return _videoRendererView();
            }
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return GestureDetector(
                  onScaleStart: (details) {},
                  onScaleUpdate: (details) {
                    if (details.scale != 1.0) {
                      setZoom(details.scale);
                    }
                  },
                  onTapDown: (TapDownDetails details) => onViewFinderTap(details, constraints),
                  child: _videoRendererView(),
                );
              },
            );
          },
        );
      }
      return widget.placeholderBuilder?.call(context) ?? const SizedBox.shrink();
    },
  );

  // FutureBuilder will cause flickering for flutter web. so using
  // different rendering methods for web and native.
  @override
  Widget build(BuildContext context) {
    final child = kIsWeb ? _videoViewForWeb() : _videoViewForNative();

    if (widget.fit == VideoViewFit.cover) {
      return child;
    }

    final videoView = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (!constraints.hasBoundedWidth && !constraints.hasBoundedHeight) {
          return child;
        }
        if (_aspectRatio == null) {
          return child;
        }

        bool fixHeight;
        if (!constraints.hasBoundedWidth) {
          fixHeight = true;
        } else if (!constraints.hasBoundedHeight) {
          fixHeight = false;
        } else {
          // both width and height are bound, figure out which to fix based on aspect ratios
          final constraintsAspectRatio = constraints.maxWidth / constraints.maxHeight;
          fixHeight = constraintsAspectRatio > _aspectRatio!;
        }
        final double width;
        final double height;
        if (fixHeight) {
          height = constraints.maxHeight;
          width = height * _aspectRatio!;
        } else {
          width = constraints.maxWidth;
          height = width / _aspectRatio!;
        }
        return SizedBox(width: width, height: height, child: child);
      },
    );

    if (widget.autoCenter) {
      return Center(child: videoView);
    } else {
      return videoView;
    }
  }

  bool _shouldMirror() {
    // off for screen share
    if (widget.track.source == TrackSource.screenShareVideo) return false;
    // on
    if (widget.mirrorMode == VideoViewMirrorMode.mirror) return true;
    // auto
    if (widget.mirrorMode == VideoViewMirrorMode.auto) {
      final track = widget.track;
      if (track is LocalVideoTrack) {
        final settings = track.mediaStreamTrack.getSettings();
        final facingMode = settings['facingMode'];
        if (facingMode != null) {
          return facingMode == 'user';
        }
        final options = track.currentOptions;
        if (options is CameraCaptureOptions) {
          // mirror if front camera
          return options.cameraPosition == CameraPosition.front;
        }
      }
    }
    // default to false
    return false;
  }
}
