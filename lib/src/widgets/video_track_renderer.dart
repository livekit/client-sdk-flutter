import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/src/support/platform.dart';

import '../events.dart';
import '../extensions.dart';
import '../hardware/hardware.dart';
import '../internal/events.dart';
import '../managers/event.dart';
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

  /// Creates a [VideoTrackRenderer] widget.
  /// [fit] is used to specify how the video should be resized to fit the view.
  /// [mirrorMode] is used to specify if the video should be mirrored.
  /// [audioOutput] is used to specify the audio output device for the track.
  /// This is only supported on web. for native platforms, use
  /// [Hardware.selectAudioOutput] to change the audio output device.
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
      ..on<TrackStreamUpdatedEvent>((event) async {
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
    //
    if (widget.track != oldWidget.track) {
      oldWidget.track.removeViewKey(_internalKey);
      _internalKey = widget.track.addViewKey();
      // TODO: re-attach only if needed
      (() async {
        await _attach();
      })();
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
