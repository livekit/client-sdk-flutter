import '../imports.dart';

/// Widget that renders a [VideoTrack].
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
    widget.track.addListener(_trackChanged);
    _initRenderer();
  }

  @override
  void dispose() {
    widget.track.removeListener(_trackChanged);
    _renderer.srcObject = null;
    _renderer.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VideoTrackRenderer oldWidget) {
    oldWidget.track.removeListener(_trackChanged);
    widget.track.addListener(_trackChanged);
    _trackChanged();
    super.didUpdateWidget(oldWidget);
  }

  void _trackChanged() {
    setState(() {
      _renderer.srcObject = widget.track.mediaStream;
    });
  }

  void _initRenderer() async {
    await _renderer.initialize();
    _trackChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isLocal = widget.track is LocalVideoTrack;
    return RTCVideoView(
      _renderer,
      mirror: isLocal,
      filterQuality: FilterQuality.medium,
    );
  }
}
