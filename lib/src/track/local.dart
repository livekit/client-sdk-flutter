import 'dart:io' show Platform;

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../exceptions.dart';
import '../logger.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../types.dart';
import 'options.dart';
import 'track.dart';

mixin VideoTrack on Track {}
mixin AudioTrack on Track {}

abstract class LocalTrack extends Track {
  // Options used for this track
  abstract LocalTrackOptions currentOptions;

  LocalTrack(
    String name,
    lk_models.TrackType kind,
    TrackSource source,
    rtc.MediaStream mediaStream,
    rtc.MediaStreamTrack mediaStreamTrack,
  ) : super(
          name,
          kind,
          source,
          mediaStream,
          mediaStreamTrack,
        );

  // Only local tracks can set muted.
  // Returns true if muted, false if unchanged.
  Future<bool> mute() async {
    logger.fine('LocalTrack.mute() muted: $muted');
    if (muted) return false; // already muted
    await disable();
    if (!Platform.isWindows) {
      await stop();
    }
    updateMuted(true, shouldSendSignal: true);
    return true;
  }

  // Returns true if unmuted, false if unchanged.
  Future<bool> unmute() async {
    logger.fine('LocalTrack.unmute() muted: $muted');
    if (!muted) return false; // already un-muted
    if (!Platform.isWindows) {
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
      await mediaStreamTrack.stop();
      await mediaStream.dispose();
    }
    return didStop;
  }

  /// Creates a [rtc.MediaStream] from LocalTrackOptions.
  @internal
  static Future<rtc.MediaStream> createStream(
    LocalTrackOptions options,
  ) async {
    final constraints = <String, dynamic>{
      'audio': options is LocalAudioTrackOptions
          ? options.toMediaConstraintsMap()
          : false,
      'video': options is LocalVideoTrackOptions
          ? options.toMediaConstraintsMap()
          : false,
    };

    final rtc.MediaStream stream;
    if (options is ScreenShareTrackOptions) {
      stream = await rtc.navigator.mediaDevices.getDisplayMedia(constraints);
    } else {
      // options is CameraVideoTrackOptions
      stream = await rtc.navigator.mediaDevices.getUserMedia(constraints);
    }

    // Check if the stream looks good
    if ((options is LocalVideoTrackOptions &&
            stream.getVideoTracks().isEmpty) ||
        (options is LocalAudioTrackOptions &&
            stream.getAudioTracks().isEmpty)) {
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
    await sender?.replaceTrack(newTrack);

    // set new stream & track to this object
    updateMediaStreamAndTrack(newStream, newTrack);

    // mark as started
    await start();
  }
}
