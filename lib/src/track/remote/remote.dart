import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../../proto/livekit_models.pb.dart' as lk_models;
import '../../types/other.dart';
import '../stats.dart';
import '../track.dart';

abstract class RemoteTrack extends Track {
  RemoteTrack(String name, lk_models.TrackType kind, TrackSource source,
      rtc.MediaStream stream, rtc.MediaStreamTrack track,
      {rtc.RTCRtpReceiver? receiver})
      : super(
          name,
          kind,
          source,
          stream,
          track,
          receiver: receiver,
        );

  @override
  Future<bool> start() async {
    final didStart = await super.start();
    if (didStart) {
      await enable();
      startMonitor();
    }
    return didStart;
  }

  @override
  Future<bool> stop() async {
    final didStop = await super.stop();
    if (didStop) {
      await disable();
    }
    stopMonitor();
    return didStop;
  }

  Timer? _monitorTimer;

  Future<void> monitorReceiver();

  @internal
  void startMonitor() {
    _monitorTimer ??=
        Timer.periodic(const Duration(milliseconds: monitorFrequency), (_) {
      monitorReceiver();
    });
  }

  @internal
  void stopMonitor() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }
}
