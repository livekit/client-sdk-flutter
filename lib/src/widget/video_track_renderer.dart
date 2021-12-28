import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:uuid/uuid.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../events.dart';
import '../internal/events.dart';
import '../managers/event.dart';
import '../track/local/local.dart';
import '../track/local/video.dart';

/// Widget that renders a [VideoTrack].
class VideoTrackRenderer extends StatefulWidget {
  final VideoTrack track;
  final rtc.RTCVideoViewObjectFit fit;
  static const uuid = Uuid();

  VideoTrackRenderer(
    this.track, {
    this.fit = rtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
    Key? key,
  }) : super(key: key ?? ValueKey('VideoView-${uuid.v4()}'));

  @override
  State<StatefulWidget> createState() => _VideoTrackRendererState();
}

class _VideoTrackRendererState extends State<VideoTrackRenderer> {
  final _renderer = rtc.RTCVideoRenderer();
  bool _rendererReady = false;
  EventsListener<TrackEvent>? _listener;

  @override
  void initState() {
    super.initState();

    (() async {
      await _renderer.initialize();
      await _attach();
      setState(() => _rendererReady = true);
    })();
  }

  @override
  void dispose() {
    VisibilityDetectorController.instance.forget(widget.key!);
    // report that instance is disposing
    // if the track is disposed first we can't emit event
    widget.track.events.emit(TrackVisibilityUpdatedEvent(
      rendererId: widget.key!.toString(),
      track: widget.track,
      info: null,
    ));
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
    if (widget.track != oldWidget.track) {
      // TODO: re-attach only if needed
      (() async {
        await _attach();
      })();
    }
  }

  @override
  Widget build(BuildContext context) => !_rendererReady
      ? Container()
      : VisibilityDetector(
          key: widget.key!,
          // emit event when visibility updates
          onVisibilityChanged: (VisibilityInfo info) =>
              widget.track.events.emit(TrackVisibilityUpdatedEvent(
            rendererId: widget.key!.toString(),
            track: widget.track,
            info: info,
          )),
          child: rtc.RTCVideoView(
            _renderer,
            mirror: widget.track is LocalVideoTrack,
            filterQuality: FilterQuality.medium,
            objectFit: widget.fit,
          ),
        );
}
