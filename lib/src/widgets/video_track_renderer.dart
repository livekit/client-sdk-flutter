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

import 'package:flutter/material.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../events.dart';
import '../extensions.dart';
import '../internal/events.dart';
import '../managers/event.dart';
import '../support/platform.dart';
import '../track/local/local.dart';
import '../track/local/video.dart';
import '../track/options.dart';

enum VideoViewMirrorMode {
  auto,
  off,
  mirror,
}

/// Widget that renders a [VideoTrack].
class VideoTrackRenderer extends StatefulWidget {
  final VideoTrack track;
  final rtc.RTCVideoViewObjectFit fit;
  final VideoViewMirrorMode mirrorMode;

  const VideoTrackRenderer(
    this.track, {
    this.fit = rtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
    this.mirrorMode = VideoViewMirrorMode.auto,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoTrackRendererState();
}

class _VideoTrackRendererState extends State<VideoTrackRenderer> {
  final _renderer = rtc.RTCVideoRenderer();
  bool _rendererReady = false;
  EventsListener<TrackEvent>? _listener;
  // Used to compute visibility information
  late GlobalKey _internalKey;

  @override
  void initState() {
    super.initState();
    _internalKey = widget.track.addViewKey();

    (() async {
      await _renderer.initialize();
      await _attach();
      setState(() => _rendererReady = true);
    })();
  }

  @override
  void dispose() {
    widget.track.removeViewKey(_internalKey);
    _listener?.dispose();
    _renderer.srcObject = null;
    _renderer.dispose();
    super.dispose();
  }

  Future<void> _attach() async {
    _renderer.srcObject = widget.track.mediaStream;
    await _listener?.dispose();
    _listener = widget.track.createListener()
      ..on<TrackStreamUpdatedEvent>((event) {
        if (!mounted) return;
        _renderer.srcObject = event.stream;
      })
      ..on<LocalTrackOptionsUpdatedEvent>((event) {
        if (!mounted) return;
        // force recompute of mirror mode
        setState(() {});
      });
  }

  @override
  void didUpdateWidget(covariant VideoTrackRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.track != oldWidget.track) {
      oldWidget.track.removeViewKey(_internalKey);
      _internalKey = widget.track.addViewKey();
      (() async {
        await _attach();
      })();
    }

    if ([BrowserType.safari, BrowserType.firefox].contains(lkBrowser()) &&
        oldWidget.key != widget.key) {
      _renderer.srcObject = widget.track.mediaStream;
    }
  }

  @override
  Widget build(BuildContext context) => !_rendererReady
      ? Container()
      : Builder(
          key: _internalKey,
          builder: (ctx) {
            // let it render before notifying build
            WidgetsBindingCompatible.instance
                ?.addPostFrameCallback((timeStamp) {
              widget.track.onVideoViewBuild?.call(_internalKey);
            });
            return rtc.RTCVideoView(
              _renderer,
              mirror: _shouldMirror(),
              filterQuality: FilterQuality.medium,
              objectFit: widget.fit,
            );
          },
        );

  bool _shouldMirror() {
    // on
    if (widget.mirrorMode == VideoViewMirrorMode.mirror) return true;
    // auto
    if (widget.mirrorMode == VideoViewMirrorMode.auto) {
      final track = widget.track;
      if (track is LocalVideoTrack) {
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
