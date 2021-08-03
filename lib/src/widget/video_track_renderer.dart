import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../track/video_track.dart';
import '../track/local_video_track.dart';

class VideoTrackRenderer extends StatefulWidget {
  final VideoTrack track;
  final RTCVideoRenderer renderer;

  VideoTrackRenderer(this.track)
      : renderer = RTCVideoRenderer(),
        super(key: ValueKey(track.sid));

  @override
  State<StatefulWidget> createState() {
    return _VideoTrackRendererState();
  }
}

class _VideoTrackRendererState extends State<VideoTrackRenderer> {
  final _renderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  @override
  void dispose() {
    _renderer.dispose();
    super.dispose();
  }

  _initRenderer() async {
    await _renderer.initialize();
    _renderer.srcObject = widget.track.mediaStream;
  }

  @override
  Widget build(BuildContext context) {
    var isLocal = widget.track is LocalVideoTrack;
    return RTCVideoView(
      _renderer,
      mirror: isLocal,
      filterQuality: FilterQuality.medium,
    );
  }
}
