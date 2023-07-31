// Copyright 2023 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../events.dart';
import '../extensions.dart';
import '../internal/events.dart';
import '../logger.dart';
import '../managers/event.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../support/disposable.dart';
import '../types/other.dart';
import 'stats.dart';

/// Wrapper around a MediaStreamTrack with additional metadata.
/// Base for [AudioTrack] and [VideoTrack],
/// can not be instantiated directly.
abstract class Track extends DisposableChangeNotifier
    with EventsEmittable<TrackEvent> {
  static const uuid = Uuid();
  @Deprecated('Use TrackPublication.name instead')
  final String name = 'Deprecated, please use TrackPublication.name instead';
  final lk_models.TrackType kind;
  final TrackSource source;

  // read only
  rtc.MediaStream get mediaStream => _mediaStream;
  rtc.MediaStream _mediaStream;

  // read only
  rtc.MediaStreamTrack get mediaStreamTrack => _mediaStreamTrack;
  rtc.MediaStreamTrack _mediaStreamTrack;

  String? sid;
  rtc.RTCRtpTransceiver? transceiver;
  String? _cid;

  // started / stopped
  bool _active = false;
  bool get isActive => _active;

  bool _muted = false;
  bool get muted => _muted;

  rtc.RTCRtpSender? get sender => transceiver?.sender;

  rtc.RTCRtpReceiver? receiver;

  Track(this.kind, this.source, this._mediaStream, this._mediaStreamTrack,
      {this.receiver}) {
    // Any event emitted will trigger ChangeNotifier
    events.listen((event) {
      logger.fine('[TrackEvent] $event, will notifyListeners()');
      notifyListeners();
    });

    onDispose(() async {
      logger.fine('${objectId} onDispose()');
      await stop();
      // dispose events
      await events.dispose();
    });
  }

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

  /// Start this [Track] if not started.
  /// Returns true if started, false if already started
  @mustCallSuper
  Future<bool> start() async {
    if (_active) {
      // already started
      return false;
    }

    logger.fine('$objectId.start()');

    startMonitor();

    _active = true;
    return true;
  }

  /// Stop this [Track] if not stopped.
  /// Returns true if stopped, false if already stopped
  @mustCallSuper
  Future<bool> stop() async {
    if (!_active) {
      // already stopped
      return false;
    }

    stopMonitor();

    logger.fine('$objectId.stop()');

    _active = false;
    return true;
  }

  Future<void> enable() async {
    logger.fine('$objectId.enable() enabling ${mediaStreamTrack.objectId}...');
    try {
      if (_active) {
        mediaStreamTrack.enabled = true;
      }
    } catch (_) {
      logger.warning(
          '[$objectId] set rtc.mediaStreamTrack.enabled did throw ${_}');
    }
  }

  Future<void> disable() async {
    logger
        .fine('$objectId.disable() disabling ${mediaStreamTrack.objectId}...');
    try {
      if (_active) {
        mediaStreamTrack.enabled = false;
      }
    } catch (_) {
      logger.warning(
          '[$objectId] set rtc.mediaStreamTrack.enabled did throw ${_}');
    }
  }

  Timer? _monitorTimer;

  Future<bool> monitorStats();

  @internal
  void startMonitor() {
    _monitorTimer ??= Timer.periodic(
        const Duration(milliseconds: monitorFrequency), (_) async {
      if (!await monitorStats()) {
        stopMonitor();
      }
    });
  }

  @internal
  void stopMonitor() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  @internal
  void updateMuted(
    bool muted, {
    bool shouldNotify = true,
    bool shouldSendSignal = false,
  }) {
    if (_muted == muted) return;
    _muted = muted;
    if (shouldNotify) {
      events.emit(InternalTrackMuteUpdatedEvent(
        track: this,
        muted: muted,
        shouldSendSignal: shouldSendSignal,
      ));
    }
  }

  @internal
  void updateMediaStreamAndTrack(
      rtc.MediaStream stream, rtc.MediaStreamTrack track) {
    _mediaStream = stream;
    _mediaStreamTrack = track;
    events.emit(TrackStreamUpdatedEvent(
      track: this,
      stream: stream,
    ));
  }
}
