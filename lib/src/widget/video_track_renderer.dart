import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../extensions.dart';
import '../internal/events.dart';
import '../logger.dart';
import '../track/local_video_track.dart';
import '../track/video_track.dart';

/// Widget that renders a [VideoTrack].
class VideoTrackRenderer extends StatefulWidget {
  final VideoTrack track;
  final rtc.RTCVideoViewObjectFit fit;

  VideoTrackRenderer(
    this.track, {
    this.fit = rtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
  }) : super(key: ValueKey('VideoTrackRenderer-${track.sid}'));

  @override
  State<StatefulWidget> createState() => _VideoTrackRendererState();
}

class _VideoTrackRendererState extends State<VideoTrackRenderer> {
  final _renderer = rtc.RTCVideoRenderer();
  bool _rendererReady = false;
  EventsListener<TrackEvent>? _listener;
  // for visibility detector
  Function(VisibilityInfo)? _visibilityDidUpdate;
  Function? _cancelDebounce;

  Key get _keyForVisibilityDetector =>
      ValueKey('VisibilityDetector-${widget.track.sid}');

  @override
  void initState() {
    super.initState();

    logger.fine('[VideoTrackRenderer] initState');

    _visibilityDidUpdate = Utils.createDebounceFunc(
      _onShouldReportVisibilityChange,
      cancelFunc: (func) => _cancelDebounce = func,
      wait: const Duration(seconds: 2),
    );

    (() async {
      await _renderer.initialize();
      await _attach();
      setState(() => _rendererReady = true);
    })();
  }

  void _onShouldReportVisibilityChange(VisibilityInfo info) {
    // TODO: Report to engine to mute/unmute track

    logger.fine('visibility changed for ${widget.objectId} '
        'visibleFraction: ${info.visibleFraction} '
        'size: ${info.size}');
  }

  @override
  void dispose() {
    logger.fine('[VideoTrackRenderer] dispose');
    _cancelDebounce?.call();
    VisibilityDetectorController.instance.forget(_keyForVisibilityDetector);
    _listener?.dispose();
    _renderer.srcObject = null;
    _renderer.dispose();
    super.dispose();
  }

  Future<void> _attach() async {
    logger.fine('[VideoTrackRenderer] attached to ${widget.track.objectId}');
    _renderer.srcObject = widget.track.mediaStream;
    await _listener?.dispose();
    _listener = widget.track.createListener()
      ..on<TrackUpdatedStream>((event) {
        _renderer.srcObject = event.stream;
      });
  }

  @override
  void didUpdateWidget(covariant VideoTrackRenderer oldWidget) {
    logger.fine('[VideoTrackRenderer] didUpdateWidget');
    super.didUpdateWidget(oldWidget);
    // TODO: re-attach only if needed
    (() async {
      await _attach();
    })();
  }

  @override
  Widget build(BuildContext context) => !_rendererReady
      ? Container()
      : VisibilityDetector(
          key: _keyForVisibilityDetector,
          onVisibilityChanged: (VisibilityInfo info) =>
              _visibilityDidUpdate?.call(info),
          child: rtc.RTCVideoView(
            _renderer,
            mirror: widget.track is LocalVideoTrack,
            filterQuality: FilterQuality.medium,
            objectFit: widget.fit,
          ),
        );
}
