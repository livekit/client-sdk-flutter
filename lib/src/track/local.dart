import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import '../support/platform.dart';
import 'package:meta/meta.dart';

import '../exceptions.dart';
import '../logger.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../types.dart';
import 'options.dart';
import 'track.dart';
import '../track/local/audio.dart';
import '../track/local/video.dart';
import '../track/remote/audio.dart';
import '../track/remote/video.dart';
import '../events.dart';
import '../participant/remote_participant.dart';

/// Used to group [LocalVideoTrack] and [RemoteVideoTrack].
mixin VideoTrack on Track {}

/// Used to group [LocalAudioTrack] and [RemoteAudioTrack].
mixin AudioTrack on Track {}

/// Base class for [LocalAudioTrack] and [LocalVideoTrack].
abstract class LocalTrack extends Track {
  /// Options used for this track
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
    final constraints = <String, dynamic>{
      'audio': options is AudioCaptureOptions
          ? options.toMediaConstraintsMap()
          : false,
      'video': options is VideoCaptureOptions
          ? options.toMediaConstraintsMap()
          : false,
    };

    final rtc.MediaStream stream;
    if (options is ScreenShareCaptureOptions) {
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
    } catch (error) {
      logger.severe('RTCRtpSender.replaceTrack() did throw $error');
    }

    // set new stream & track to this object
    updateMediaStreamAndTrack(newStream, newTrack);

    // mark as started
    await start();
  }
}
