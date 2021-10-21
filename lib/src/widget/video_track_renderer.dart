import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/utils.dart';
import 'package:uuid/uuid.dart';
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

  const VideoTrackRenderer(
    this.track, {
    this.fit = rtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoTrackRendererState();
}

class _VideoTrackRendererState extends State<VideoTrackRenderer> {
  // // unique ID used to identify this instance
  // // used to report visibility info to the track/engine
  // static const uuid = Uuid();
  // final _id = uuid.v4();
  // RTC renderer and ready state
  final _renderer = rtc.RTCVideoRenderer();
  bool _rendererReady = false;
  EventsListener<TrackEvent>? _listener;
  // for visibility detector
  // Function(VisibilityInfo)? _visibilityDidUpdate;
  // Function? _cancelDebounce;

  Key get _keyForVisibilityDetector =>
      ValueKey('${objectId}-VisibilityDetector');

  @override
  void initState() {
    super.initState();

    logger.fine('[VideoTrackRenderer] initState');

    // _visibilityDidUpdate = Utils.createDebounceFunc(
    //   _reportVisibilityUpdate,
    //   cancelFunc: (func) => _cancelDebounce = func,
    //   wait: const Duration(seconds: 2),
    // );

    (() async {
      await _renderer.initialize();
      await _attach();
      setState(() => _rendererReady = true);
    })();
  }

  // void _reportVisibilityUpdate(VisibilityInfo info) {
  //   // TODO: Report to engine to mute/unmute track

  //   logger.fine('visibility changed for ${objectId} '
  //       'visibleFraction: ${info.visibleFraction} '
  //       'size: ${info.size}');
  //   widget.track.visibilityDidUpdate(rendererId: objectId, info: info);
  // }

  @override
  void dispose() {
    logger.fine('[VideoTrackRenderer] dispose');
    // don't fire visibility events anymore
    // _cancelDebounce?.call();
    VisibilityDetectorController.instance.forget(_keyForVisibilityDetector);
    // report that instance is disposing
    widget.track.visibilityDidUpdate(rendererId: objectId);
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
          onVisibilityChanged: (VisibilityInfo info) => widget.track
              .visibilityDidUpdate(rendererId: objectId, info: info),
          child: rtc.RTCVideoView(
            _renderer,
            mirror: widget.track is LocalVideoTrack,
            filterQuality: FilterQuality.medium,
            objectFit: widget.fit,
          ),
        );
}
