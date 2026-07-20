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

import 'package:flutter/foundation.dart' show ValueListenable, kIsWeb;
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
import '../types/other.dart';

enum VideoViewMirrorMode {
  auto,
  off,
  mirror,
}

enum VideoRenderMode {
  auto,
  texture,
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
    this.renderMode = VideoRenderMode.texture,
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

class _VideoTrackRendererState extends State<VideoTrackRenderer> {
  rtc.VideoRenderer? _renderer;
  // for flutter web only.
  bool _rendererReadyForWeb = false;
  double? _aspectRatio;
  EventsListener<TrackEvent>? _listener;
  // Used to compute visibility information
  late VideoTrackViewRegistration _viewRegistration;

  bool _usesPlatformView(VideoRenderMode renderMode) =>
      renderMode == VideoRenderMode.platformView && [PlatformType.iOS, PlatformType.macOS].contains(lkPlatform());

  bool get _shouldUsePlatformView => _usesPlatformView(widget.renderMode);

  double? get _rendererAspectRatio {
    final renderer = _renderer;
    if (renderer != null && renderer is ValueListenable<rtc.RTCVideoValue>) {
      return (renderer as ValueListenable<rtc.RTCVideoValue>).value.aspectRatio;
    }
    return null;
  }

  Future<rtc.VideoRenderer?> _initializeRenderer() async {
    if (_shouldUsePlatformView) {
      return null;
    }
    // A leftover platform view controller is owned by its RTCVideoPlatFormView
    // widget, which disposes it on unmount. Only drop our reference here.
    if (_renderer != null && _renderer is! rtc.RTCVideoRenderer) {
      _releaseRenderer(dispose: false);
    }
    if (_renderer == null) {
      final cachedRenderer = widget.cachedRenderer;
      if (cachedRenderer != null) {
        _renderer = cachedRenderer;
      } else {
        _renderer = rtc.RTCVideoRenderer();
        await _renderer!.initialize();
      }
    }
    await _attach();
    return _renderer!;
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
    try {
      renderer?.onResize = null;
      renderer?.srcObject = null;
      if (dispose) {
        unawaited(renderer?.dispose());
      }
    } catch (e) {
      logger.warning('Got error releasing renderer: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    if (!_shouldUsePlatformView && widget.cachedRenderer != null) {
      _renderer = widget.cachedRenderer;
    }
    _viewRegistration = widget.track.addViewRegistration(pixelDensity: widget.adaptiveStreamPixelDensity);
    if (kIsWeb) {
      unawaited(() async {
        await _initializeRenderer();
        if (!mounted) return;
        setState(() => _rendererReadyForWeb = true);
      }());
    }
  }

  @override
  void dispose() {
    widget.track.removeViewRegistration(_viewRegistration);
    unawaited(_listener?.dispose());
    if (widget.autoDisposeRenderer) {
      _releaseRenderer(dispose: true);
    }
    super.dispose();
  }

  Future<void> _attach() async {
    _renderer?.srcObject = widget.track.mediaStream;
    await _listener?.dispose();
    _listener = widget.track.createListener()
      ..on<TrackStreamUpdatedEvent>((event) {
        if (!mounted) return;
        _renderer?.srcObject = event.stream;
      })
      ..on<LocalTrackOptionsUpdatedEvent>((event) {
        if (!mounted) return;
        // force recompute of mirror mode
        setState(() {});
      });
    _renderer?.onResize = () {
      if (mounted) {
        setState(() {
          _aspectRatio = _rendererAspectRatio;
        });
      }
    };
  }

  @override
  void didUpdateWidget(covariant VideoTrackRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_usesPlatformView(oldWidget.renderMode) != _shouldUsePlatformView) {
      // Only dispose texture renderers we created ourselves. Platform view
      // controllers belong to RTCVideoPlatFormView and a cachedRenderer
      // belongs to the caller, who may hand it back on a later switch.
      final ownsRenderer = _renderer is rtc.RTCVideoRenderer && !identical(_renderer, oldWidget.cachedRenderer);
      unawaited(_listener?.dispose());
      _listener = null;
      _aspectRatio = null;
      _releaseRenderer(dispose: ownsRenderer && oldWidget.autoDisposeRenderer);
    }

    if (widget.track != oldWidget.track) {
      oldWidget.track.removeViewRegistration(_viewRegistration);
      _viewRegistration = widget.track.addViewRegistration(pixelDensity: widget.adaptiveStreamPixelDensity);
      unawaited(() async {
        await _attach();
      }());
    } else if (widget.adaptiveStreamPixelDensity != oldWidget.adaptiveStreamPixelDensity) {
      _viewRegistration.pixelDensity = widget.adaptiveStreamPixelDensity;
    }

    if ([BrowserType.safari, BrowserType.firefox].contains(lkBrowser()) && oldWidget.key != widget.key) {
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
      return rtc.RTCVideoPlatFormView(
        mirror: _shouldMirror(),
        objectFit: widget.fit.toRTCType(),
        onViewReady: (controller) async {
          _renderer = controller;
          _renderer?.srcObject = widget.track.mediaStream;
          await _attach();
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
      future: _initializeRenderer(),
      builder: (context, snapshot) {
        if ((snapshot.hasData && _renderer != null) || _shouldUsePlatformView) {
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
      });

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
