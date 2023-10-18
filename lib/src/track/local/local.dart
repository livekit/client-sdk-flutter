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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../../events.dart';
import '../../exceptions.dart';
import '../../extensions.dart';
import '../../internal/events.dart';
import '../../logger.dart';
import '../../participant/remote.dart';
import '../../proto/livekit_models.pb.dart' as lk_models;
import '../../support/platform.dart';
import '../../types/other.dart';
import '../options.dart';
import '../remote/audio.dart';
import '../remote/video.dart';
import '../track.dart';
import 'audio.dart';
import 'video.dart';

/// Used to group [LocalVideoTrack] and [RemoteVideoTrack].
mixin VideoTrack on Track {
  @internal
  final List<GlobalKey> viewKeys = [];

  @internal
  Function(Key)? onVideoViewBuild;

  @internal
  GlobalKey addViewKey() {
    final key = GlobalKey();
    viewKeys.add(key);
    return key;
  }

  @internal
  void removeViewKey(GlobalKey key) {
    viewKeys.remove(key);
  }
}

/// Used to group [LocalAudioTrack] and [RemoteAudioTrack].
mixin AudioTrack on Track {}

/// Base class for [LocalAudioTrack] and [LocalVideoTrack].
abstract class LocalTrack extends Track {
  /// Options used for this track
  abstract LocalTrackOptions currentOptions;

  bool _published = false;
  bool get isPublished => _published;

  String? codec;

  LocalTrack(
    lk_models.TrackType kind,
    TrackSource source,
    rtc.MediaStream mediaStream,
    rtc.MediaStreamTrack mediaStreamTrack,
  ) : super(
          kind,
          source,
          mediaStream,
          mediaStreamTrack,
        );

  /// Mutes this [LocalTrack]. This will stop the sending of track data
  /// and notify the [RemoteParticipant] with [TrackMutedEvent].
  /// Returns true if muted, false if unchanged.
  Future<bool> mute() async {
    logger.fine('LocalTrack.mute() muted: $muted');
    if (muted) return false; // already muted
    await disable();
    if (!lkPlatformIs(PlatformType.windows)) {
      await stop();
    }
    updateMuted(true, shouldSendSignal: true);
    return true;
  }

  /// Un-mutes this [LocalTrack]. This will re-start the sending of track data
  /// and notify the [RemoteParticipant] with [TrackUnmutedEvent].
  /// Returns true if un-muted, false if unchanged.
  Future<bool> unmute() async {
    logger.fine('LocalTrack.unmute() muted: $muted');
    if (!muted) return false; // already un-muted
    if (!lkPlatformIs(PlatformType.windows)) {
      await restartTrack();
    }
    await enable();
    updateMuted(false, shouldSendSignal: true);
    return true;
  }

  @override
  Future<bool> stop() async {
    final didStop = await super.stop();
    if (didStop) {
      logger.fine('Stopping mediaStreamTrack...');
      try {
        await mediaStreamTrack.stop();
      } catch (error) {
        logger.severe('MediaStreamTrack.stop() did throw $error');
      }
      try {
        await mediaStream.dispose();
      } catch (error) {
        logger.severe('MediaStreamTrack.dispose() did throw $error');
      }
    }
    return didStop;
  }

  /// Creates a [rtc.MediaStream] from [LocalTrackOptions].
  @internal
  static Future<rtc.MediaStream> createStream(
    LocalTrackOptions options,
  ) async {
    var constraints = <String, dynamic>{
      'audio': options is AudioCaptureOptions
          ? options.toMediaConstraintsMap()
          : options is ScreenShareCaptureOptions
              ? (options).captureScreenAudio
              : false,
      'video': options is VideoCaptureOptions
          ? options.toMediaConstraintsMap()
          : false,
    };

    final rtc.MediaStream stream;
    if (options is ScreenShareCaptureOptions) {
      if (kIsWeb) {
        if (options.preferCurrentTab) {
          constraints['preferCurrentTab'] = true;
        }
        if (options.selfBrowserSurface != null) {
          constraints['selfBrowserSurface'] = options.selfBrowserSurface!;
        }

        // Remove resolution settings to fix low-resolution screen share on Safari 17.
        // related bug: https://bugs.webkit.org/show_bug.cgi?id=263015
        if (lkBrowser() == BrowserType.safari &&
            lkBrowserVersion().major == 17) {
          constraints['video'] = true;
        }
      }
      stream = await rtc.navigator.mediaDevices.getDisplayMedia(constraints);
    } else {
      // options is CameraVideoTrackOptions
      stream = await rtc.navigator.mediaDevices.getUserMedia(constraints);
    }

    // Check if the stream looks good
    if ((options is VideoCaptureOptions && stream.getVideoTracks().isEmpty) ||
        (options is AudioCaptureOptions && stream.getAudioTracks().isEmpty)) {
      throw TrackCreateException(
          'Failed to create stream, at least 1 video or audio track should exist');
    }
    return stream;
  }

  /// Restarts the track with new options. This is useful when switching between
  /// front and back cameras.
  Future<void> restartTrack([
    LocalTrackOptions? options,
  ]) async {
    if (sender == null) throw TrackCreateException('could not restart track');
    if (options != null && currentOptions.runtimeType != options.runtimeType) {
      throw Exception('options must be a ${currentOptions.runtimeType}');
    }

    currentOptions = options ?? currentOptions;

    // stop if not already stopped...
    await stop();

    // create new track with options
    final newStream = await LocalTrack.createStream(currentOptions);
    final newTrack = newStream.getTracks().first;

    // replace track on sender
    try {
      await sender?.replaceTrack(newTrack);
      if (this is LocalVideoTrack) {
        var videoTrack = this as LocalVideoTrack;
        await videoTrack.replaceTrackForMultiCodecSimulcast(newTrack);
      }
    } catch (error) {
      logger.severe('RTCRtpSender.replaceTrack() did throw $error');
    }

    // set new stream & track to this object
    updateMediaStreamAndTrack(newStream, newTrack);

    // mark as started
    await start();

    // notify so VideoView can re-compute mirror mode if necessary
    events.emit(LocalTrackOptionsUpdatedEvent(
      track: this,
      options: currentOptions,
    ));
  }

  @internal
  @mustCallSuper
  Future<bool> onPublish() async {
    if (_published) {
      // already published
      return false;
    }

    logger.fine('$objectId.publish()');
    _published = true;
    return true;
  }

  @internal
  @mustCallSuper
  Future<bool> onUnpublish() async {
    if (!_published) {
      // already unpublished
      return false;
    }

    logger.fine('$objectId.unpublish()');
    _published = false;
    return true;
  }
}
