import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../logger.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../signal_client.dart';
import '../utils.dart';
import 'track.dart';

/// A video track will notify when its mediaTrack has changed.
class VideoTrack extends Track {
  rtc.MediaStream _mediaStream;
  // final _rendererVisibilities = <String, VisibilityInfo>{};
  // this is used to report video optimization info to the server
  // final SignalClient? _client;
  // Function(void)? _visibilityDidUpdate;
  // Function? _cancelDebounceFunc;

  VideoTrack(
    String name,
    rtc.MediaStreamTrack mediaTrack,
    this._mediaStream,
    // this._client,
  ) : super(
          lk_models.TrackType.VIDEO,
          name,
          mediaTrack,
        ) {
    // _visibilityDidUpdate = Utils.createDebounceFunc(
    //   _reportVisibilityUpdate,
    //   cancelFunc: (func) => _cancelDebounceFunc = func,
    //   wait: const Duration(seconds: 2),
    // );

    // onDispose(() async {
    //   _cancelDebounceFunc?.call();
    // });
  }

  rtc.MediaStream get mediaStream => _mediaStream;

  /// internal use
  /// {@nodoc}
  @internal
  void setMediaStream(rtc.MediaStream stream) {
    _mediaStream = stream;
    notifyListeners();
  }

  @override
  Future<bool> stop() async {
    final didStop = await super.stop();
    if (didStop) {
      await _mediaStream.dispose();
    }
    // _mediaStream = null;
    return didStop;
  }

  // called any time visibility info updates
  // from one of the renderers
  // @internal
  // void rendererVisibilityDidUpdate({
  //   required String rendererId,
  //   VisibilityInfo? info,
  // }) {
  //   //
  //   if (info != null) {
  //     logger.fine('visibility update for ${rendererId} '
  //         'visibleFraction: ${info.visibleFraction} '
  //         'size: ${info.size}');
  //     _rendererVisibilities[rendererId] = info;
  //   } else {
  //     logger.fine('visibility update for ${rendererId}, removed');
  //     _rendererVisibilities.remove(rendererId);
  //   }
  //   logger.fine('visibility total renderers: ${_rendererVisibilities.length}');
  //   _visibilityDidUpdate?.call(0);
  // }

  // void _reportVisibilityUpdate(void _) {
  //   //
  //   logger.fine('visibility should send visibility info');
  // }
}
