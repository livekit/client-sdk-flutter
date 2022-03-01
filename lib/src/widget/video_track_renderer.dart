import 'package:flutter/material.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../events.dart';
import '../internal/events.dart';
import '../managers/event.dart';
import '../track/local/local.dart';
import '../track/local/video.dart';

/// Widget that renders a [VideoTrack].
class VideoTrackRenderer extends StatefulWidget {
  final VideoTrack track;
  final rtc.RTCVideoViewObjectFit fit;

  const VideoTrackRenderer(
    this.track, {
    this.fit = rtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
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
        if (mounted) {
          _renderer.srcObject = event.stream;
        }
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
            WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
              widget.track.onVideoViewBuild?.call(_internalKey);
            });
            return rtc.RTCVideoView(
              _renderer,
              mirror: widget.track is LocalVideoTrack,
              filterQuality: FilterQuality.medium,
              objectFit: widget.fit,
            );
          },
        );
}
