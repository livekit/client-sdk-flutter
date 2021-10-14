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
  EventsListener<TrackEvent>? _listener;
  // for visibility
  VisibilityInfo? _visibilityInfo;
  Function? _visibilityDidUpdate;
  Function? _cancelDebounce;

  @override
  void initState() {
    super.initState();

    _visibilityDidUpdate = Utils.createDebounceFunc(
      _onShouldReportVisibilityChange,
      cancelFunc: (func) => _cancelDebounce = func,
      wait: const Duration(seconds: 2),
    );

    (() async {
      await _renderer.initialize();
      await _attach();
    })();
  }

  void _onShouldReportVisibilityChange() {
    final info = _visibilityInfo;
    if (info == null) return;

    // TODO: Report to engine to mute/unmute track

    logger.fine('visibility changed for ${widget.objectId} '
        'visibleFraction: ${info.visibleFraction}');
  }

  @override
  void dispose() {
    _cancelDebounce?.call();
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
  Future<void> didUpdateWidget(covariant VideoTrackRenderer oldWidget) async {
    super.didUpdateWidget(oldWidget);
    // TODO: re-attach only if needed
    await _attach();
  }

  @override
  Widget build(BuildContext context) => VisibilityDetector(
        key: ValueKey('VisibilityDetector-${widget.track.sid}'),
        onVisibilityChanged: (VisibilityInfo info) {
          _visibilityInfo = info;
          _visibilityDidUpdate?.call();
        },
        child: rtc.RTCVideoView(
          _renderer,
          mirror: widget.track is LocalVideoTrack,
          filterQuality: FilterQuality.medium,
          objectFit: widget.fit,
        ),
      );
}
