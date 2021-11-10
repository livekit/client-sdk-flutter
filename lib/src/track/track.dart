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
import '../types.dart';

/// Wrapper around a MediaStreamTrack with additional metadata.
/// Base for [AudioTrack] and [VideoTrack],
/// can not be instantiated directly.
abstract class Track extends DisposableChangeNotifier
    with EventsEmittable<TrackEvent> {
  static const uuid = Uuid();
  static const cameraName = 'camera';
  static const screenShareName = 'screenshare';

  final String name;
  final lk_models.TrackType kind;
  final TrackSource source;
  rtc.MediaStreamTrack mediaStreamTrack;

  String? sid;
  rtc.RTCRtpTransceiver? transceiver;
  String? _cid;

  // started / stopped
  bool _active = false;
  bool get isActive => _active;

  Track(
    this.kind,
    this.source,
    this.name,
    this.mediaStreamTrack,
  ) {
    // Any event emitted will trigger ChangeNotifier
    events.listen((event) {
      logger.fine('[TrackEvent] $event, will notifyListeners()');
      notifyListeners();
    });

    onDispose(() async {
      logger.fine('${objectId} onDispose()');
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

    logger.fine('Track.start()');

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

    logger.fine('Track.stop()');

    _active = false;
    return true;
  }

  Future<void> enable() async {
    logger.fine('Track.enable()');
    try {
      mediaStreamTrack.enabled = true;
    } catch (_) {
      logger.warning(
          '[$objectId] set rtc.mediaStreamTrack.enabled did throw ${_}');
    }
  }

  Future<void> disable() async {
    logger.fine('Track.disable()');
    try {
      mediaStreamTrack.enabled = false;
    } catch (_) {
      logger.warning(
          '[$objectId] set rtc.mediaStreamTrack.enabled did throw ${_}');
    }
  }
}
