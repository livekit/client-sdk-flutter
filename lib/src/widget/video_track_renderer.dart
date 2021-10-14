import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';

import '../internal/events.dart';
import '../track/local_video_track.dart';
import '../track/video_track.dart';

/// Widget that renders a [VideoTrack].
class VideoTrackRenderer extends StatefulWidget {
  final VideoTrack track;
  final rtc.RTCVideoViewObjectFit fit;

  VideoTrackRenderer(
    this.track, {
    this.fit = rtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
  })  : super(key: ValueKey(track.sid));

  @override
  State<StatefulWidget> createState() => _VideoTrackRendererState();
}

class _VideoTrackRendererState extends State<VideoTrackRenderer> {
  final _renderer = rtc.RTCVideoRenderer();
  EventsListener<TrackEvent>? _listener;

  @override
  void initState() {
    super.initState();

    (() async {
      await _renderer.initialize();
      await _attach();
    })();
  }

  @override
  void dispose() {
    _listener?.dispose();
    _renderer.srcObject = null;
    _renderer.dispose();
    super.dispose();
  }

  Future<void> _attach() async {
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
    if (widget.track != oldWidget.track) {
      await _attach();
    }
  }

  @override
  Widget build(BuildContext context) => rtc.RTCVideoView(
        _renderer,
        mirror: widget.track is LocalVideoTrack,
        filterQuality: FilterQuality.medium,
        objectFit: widget.fit,
      );
}
