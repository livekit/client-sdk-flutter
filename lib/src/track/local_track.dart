import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../exceptions.dart';
import '../internal/events.dart';
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

  // only local tracks can set muted
  Future<void> mute() async {
    logger.fine('LocalTrack.mute() muted: $muted');
    if (muted) return;
    await disable();
    updateMuted(true);
    events.emit(TrackMuteUpdatedEvent(track: this, muted: muted));
  }

  Future<void> unmute() async {
    logger.fine('LocalTrack.unmute() muted: $muted');
    if (!muted) return;
    await enable();
    updateMuted(false);
    events.emit(TrackMuteUpdatedEvent(track: this, muted: muted));
  }

  @override
  Future<bool> stop() async {
    final didStop = await super.stop();
    if (didStop) {
      logger.fine('Stopping mediaStreamTrack...');
      await mediaStreamTrack.stop();
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

    if (isActive) {
      // await mediaStreamTrack.stop();
      // await mediaStream.dispose();
      await stop();
    }

    // create new track with options
    final newStream = await LocalTrack.createStream(currentOptions);
    final newTrack = newStream.getTracks().first;

    // replace track on sender
    await sender?.replaceTrack(newTrack);

    // set new stream & track to this object
    updateMediaStreamAndTrack(newStream, newTrack);
  }
}
