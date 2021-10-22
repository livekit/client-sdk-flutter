import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../events.dart';
import '../extensions.dart';
import '../logger.dart';
import '../managers/event.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../support/disposable.dart';

/// Wrapper around a MediaStreamTrack with additional metadata.
/// Base for [AudioTrack] and [VideoTrack],
/// can not be instantiated directly.
abstract class Track extends DisposableChangeNotifier
    with EventsEmittable<TrackEvent> {
  static const uuid = Uuid();
  static const cameraName = 'camera';
  static const screenShareName = 'screen';

  final String name;
  final lk_models.TrackType kind;
  rtc.MediaStreamTrack mediaStreamTrack;

  String? sid;
  rtc.RTCRtpTransceiver? transceiver;
  String? _cid;

  // started / stopped
  bool _active = false;
  bool get isActive => _active;

  Track(
    this.kind,
    this.name,
    this.mediaStreamTrack,
  ) {
    onDispose(() async {
      logger.fine('Track disposed');
      // dispose events
      await events.dispose();
    });
  }

  bool get muted =>
      mediaStreamTrack.muted == null ? false : mediaStreamTrack.muted!;

  rtc.RTCRtpMediaType get mediaType {
    switch (kind) {
      case lk_models.TrackType.AUDIO:
        return rtc.RTCRtpMediaType.RTCRtpMediaTypeAudio;
      case lk_models.TrackType.VIDEO:
        return rtc.RTCRtpMediaType.RTCRtpMediaTypeVideo;
      // this should never happen
      default:
        return rtc.RTCRtpMediaType.RTCRtpMediaTypeAudio;
    }
  }

  String getCid() {
    var cid = _cid ?? mediaStreamTrack.id;

    if (cid == null) {
      cid = uuid.v4();
      _cid = cid;
    }
    return cid;
  }

  // returns true if started, false if already started
  @mustCallSuper
  Future<bool> start() async {
    if (_active) {
      // already started
      return false;
    }

    _active = true;
    return true;
  }

  // returns true if stopped, false if already stopped
  @mustCallSuper
  Future<bool> stop() async {
    if (!_active) {
      // already stopped
      return false;
    }

    try {
      await mediaStreamTrack.stop();
    } catch (_) {
      logger.warning('[$objectId] rtc.mediaStreamTrack.stop() did throw ${_}');
    }

    _active = false;
    return true;
  }
}
