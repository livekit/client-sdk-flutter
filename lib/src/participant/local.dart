import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../core/room.dart';
import '../core/signal_client.dart';
import '../events.dart';
import '../exceptions.dart';
import '../extensions.dart';
import '../logger.dart';
import '../options.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../publication/local.dart';
import '../track/local/audio.dart';
import '../track/local/local.dart';
import '../track/local/video.dart';
import '../track/options.dart';
import '../types/other.dart';
import '../types/participant_permissions.dart';
import '../types/video_dimensions.dart';
import '../utils.dart';
import 'participant.dart';

/// Represents the current participant in the room. Instance of [LocalParticipant] is automatically
/// created after successfully connecting to a [Room] and will be accessible from [Room.localParticipant].
class LocalParticipant extends Participant<LocalTrackPublication> {
  bool stopMicTrackOnMute = false;
  @internal
  LocalParticipant({
    required Room room,
    required lk_models.ParticipantInfo info,
  }) : super(
          room: room,
          sid: info.sid,
          identity: info.identity,
          name: info.name,
        ) {
    updateFromInfo(info);
  }

  /// Publish an [AudioTrack] to the [Room].
  /// For most cases, using [setMicrophoneEnabled] would be simpler and recommended.
  Future<LocalTrackPublication<LocalAudioTrack>> publishAudioTrack(
    LocalAudioTrack track, {
    AudioPublishOptions? publishOptions,
  }) async {
    if (audioTracks.any(
        (e) => e.track?.mediaStreamTrack.id == track.mediaStreamTrack.id)) {
      throw TrackPublishException('track already exists');
    }

    // Use defaultPublishOptions if options is null
    publishOptions =
        publishOptions ?? room.roomOptions.defaultAudioPublishOptions;

    stopMicTrackOnMute = publishOptions.stopMicTrackOnMute;

    final trackInfo = await room.engine.addTrack(
      cid: track.getCid(),
      name: track.name,
      kind: track.kind,
      source: track.source.toPBType(),
      dtx: publishOptions.dtx,
    );

    await track.start();

    final transceiverInit = rtc.RTCRtpTransceiverInit(
      direction: rtc.TransceiverDirection.SendOnly,
      sendEncodings: [
        if (publishOptions.audioBitrate > 0)
          rtc.RTCRtpEncoding(maxBitrate: publishOptions.audioBitrate),
      ],
    );
    // addTransceiver cannot pass in a kind parameter due to a bug in flutter-webrtc (web)
    track.transceiver = await room.engine.publisher?.pc.addTransceiver(
      track: track.mediaStreamTrack,
      kind: rtc.RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: transceiverInit,
    );

    await room.engine.negotiate();

    final pub = LocalTrackPublication<LocalAudioTrack>(
      participant: this,
      info: trackInfo,
      track: track,
    );
    addTrackPublication(pub);

    // did publish
    await track.onPublish();

    [events, room.events].emit(LocalTrackPublishedEvent(
      participant: this,
      publication: pub,
    ));

    return pub;
  }

  /// Publish a [LocalVideoTrack] to the [Room].
  /// For most cases, using [setCameraEnabled] would be simpler and recommended.
  Future<LocalTrackPublication<LocalVideoTrack>> publishVideoTrack(
    LocalVideoTrack track, {
    VideoPublishOptions? publishOptions,
  }) async {
    if (videoTracks.any(
        (e) => e.track?.mediaStreamTrack.id == track.mediaStreamTrack.id)) {
      throw TrackPublishException('track already exists');
    }

    // Use defaultPublishOptions if options is null
    publishOptions =
        publishOptions ?? room.roomOptions.defaultVideoPublishOptions;

    // use constraints passed to getUserMedia by default
    VideoDimensions dimensions = track.currentOptions.params.dimensions;

    if (kIsWeb) {
      // getSettings() is only implemented for Web
      try {
        // try to use getSettings for more accurate resolution
        final settings = track.mediaStreamTrack.getSettings();
        if (settings['width'] is int) {
          dimensions = dimensions.copyWith(width: settings['width'] as int);
        }
        if (settings['height'] is int) {
          dimensions = dimensions.copyWith(height: settings['height'] as int);
        }
      } catch (_) {
        logger.warning('Failed to call `mediaStreamTrack.getSettings()`');
      }
    }

    logger.fine(
        'Compute encodings with resolution: ${dimensions}, options: ${publishOptions}');

    // Video encodings and simulcasts
    final encodings = Utils.computeVideoEncodings(
      isScreenShare: track.source == TrackSource.screenShareVideo,
      dimensions: dimensions,
      options: publishOptions,
    );

    logger.fine('Using encodings: ${encodings?.map((e) => e.toMap())}');

    final layers = Utils.computeVideoLayers(dimensions, encodings);

    logger.fine('Video layers: ${layers.map((e) => e)}');

    final trackInfo = await room.engine.addTrack(
      cid: track.getCid(),
      name: track.name,
      kind: track.kind,
      source: track.source.toPBType(),
      dimensions: dimensions,
      videoLayers: layers,
    );

    logger.fine('publishVideoTrack addTrack response: ${trackInfo}');

    await track.start();

    final transceiverInit = rtc.RTCRtpTransceiverInit(
      direction: rtc.TransceiverDirection.SendOnly,
      sendEncodings: encodings,
      streams: [track.mediaStream],
    );

    logger.fine('publishVideoTrack publisher: ${room.engine.publisher}');

    track.transceiver = await room.engine.publisher?.pc.addTransceiver(
      track: track.mediaStreamTrack,
      kind: rtc.RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: transceiverInit,
    );

    await room.engine.negotiate();

    final pub = LocalTrackPublication<LocalVideoTrack>(
      participant: this,
      info: trackInfo,
      track: track,
    );
    addTrackPublication(pub);

    // did publish
    await track.onPublish();

    [events, room.events].emit(LocalTrackPublishedEvent(
      participant: this,
      publication: pub,
    ));

    return pub;
  }

  /// Unpublish a [LocalTrackPublication] that's already published by this [LocalParticipant].
  @override
  Future<void> unpublishTrack(String trackSid, {bool notify = true}) async {
    logger.finer('Unpublish track sid: $trackSid, notify: $notify');
    final pub = trackPublications.remove(trackSid);
    if (pub == null) {
      logger.warning('Publication not found $trackSid');
      return;
    }
    await pub.dispose();

    final track = pub.track;
    if (track != null) {
      if (room.roomOptions.stopLocalTrackOnUnpublish) {
        await track.stop();
      }

      final sender = track.transceiver?.sender;
      if (sender != null) {
        try {
          await room.engine.publisher?.pc.removeTrack(sender);
        } catch (_) {
          logger.warning('[$objectId] rtc.removeTrack() did throw ${_}');
        }

        // doesn't make sense to negotiate if already disposed
        if (!isDisposed) {
          // manual negotiation since track changed
          await room.engine.negotiate();
        }
      }

      // did unpublish
      await track.onUnpublish();
    }

    if (notify) {
      [events, room.events].emit(LocalTrackUnpublishedEvent(
        participant: this,
        publication: pub,
      ));
    }

    await pub.dispose();
  }

  Future<void> rePublishAllTracks() async {
    final tracks = trackPublications.values.toList();
    trackPublications.clear();
    for (LocalTrackPublication track in tracks) {
      if (track.track is LocalAudioTrack) {
        await publishAudioTrack(track.track as LocalAudioTrack);
      } else if (track.track is LocalVideoTrack) {
        await publishVideoTrack(track.track as LocalVideoTrack);
      }
    }
  }

  /// Publish a new data payload to the room.
  /// @param destinationSids When empty, data will be forwarded to each participant in the room.
  Future<void> publishData(
    List<int> data, {
    Reliability reliability = Reliability.reliable,
    List<String>? destinationSids,
  }) async {
    final packet = lk_models.DataPacket(
      kind: reliability.toPBType(),
      user: lk_models.UserPacket(
        payload: data,
        participantSid: sid,
        destinationSids: destinationSids,
      ),
    );

    await room.engine.sendDataPacket(packet);
  }

  /// A convenience property to get all video tracks.
  @override
  List<LocalTrackPublication<LocalVideoTrack>> get videoTracks =>
      trackPublications.values
          .whereType<LocalTrackPublication<LocalVideoTrack>>()
          .toList();

  /// A convenience property to get all audio tracks.
  @override
  List<LocalTrackPublication<LocalAudioTrack>> get audioTracks =>
      trackPublications.values
          .whereType<LocalTrackPublication<LocalAudioTrack>>()
          .toList();

  /// Shortcut for publishing a [TrackSource.camera]
  Future<LocalTrackPublication?> setCameraEnabled(bool enabled) async {
    return setSourceEnabled(TrackSource.camera, enabled);
  }

  /// Shortcut for publishing a [TrackSource.microphone]
  Future<LocalTrackPublication?> setMicrophoneEnabled(bool enabled) async {
    return setSourceEnabled(TrackSource.microphone, enabled);
  }

  /// Shortcut for publishing a [TrackSource.screenShareVideo]
  Future<LocalTrackPublication?> setScreenShareEnabled(bool enabled,
      {bool? captureScreenAudio}) async {
    return setSourceEnabled(TrackSource.screenShareVideo, enabled,
        captureScreenAudio: captureScreenAudio);
  }

  /// A convenience method to publish a track for a specific [TrackSource].
  /// This is the recommended method to publish tracks.
  Future<LocalTrackPublication?> setSourceEnabled(
      TrackSource source, bool enabled,
      {bool? captureScreenAudio}) async {
    logger.fine('setSourceEnabled(source: $source, enabled: $enabled)');
    final publication = getTrackPublicationBySource(source);
    if (publication != null) {
      var track = publication.track;
      var stopOnMute = stopMicTrackOnMute && track is LocalAudioTrack;
      if (enabled) {
        await publication.unmute();
        if (stopOnMute) {
          await track.restartTrack();
          await track.onTrackStarted();
        }
      } else {
        if (source == TrackSource.screenShareVideo) {
          await unpublishTrack(publication.sid);
        } else {
          await publication.mute();
          if (stopOnMute) {
            await track.sender?.setTrack(null);
            await track.stop();
            await track.onTrackStopped();
          }
        }
      }
      return publication;
    } else if (enabled) {
      if (source == TrackSource.camera) {
        final track = await LocalVideoTrack.createCameraTrack(
            room.roomOptions.defaultCameraCaptureOptions);
        return await publishVideoTrack(track);
      } else if (source == TrackSource.microphone) {
        final track = await LocalAudioTrack.create(
            room.roomOptions.defaultAudioCaptureOptions);
        return await publishAudioTrack(track);
      } else if (source == TrackSource.screenShareVideo) {
        /// When capturing chrome table audio, we can't capture audio/video
        /// track separately, it has to be returned once in getDisplayMedia,
        /// so we publish it twice here, but only return videoTrack to user.
        if (captureScreenAudio != null) {
          final tracks = await LocalVideoTrack.createScreenShareTracksWithAudio(
              ScreenShareCaptureOptions(
                  captureScreenAudio: captureScreenAudio));
          LocalTrackPublication<LocalVideoTrack>? publication;
          for (final track in tracks) {
            if (track is LocalVideoTrack) {
              publication = await publishVideoTrack(track);
            } else if (track is LocalAudioTrack) {
              await publishAudioTrack(track);
            }
          }

          /// just return the video track publication
          return publication;
        }
        final track = await LocalVideoTrack.createScreenShareTrack(
            room.roomOptions.defaultScreenShareCaptureOptions);
        return await publishVideoTrack(track);
      }
    }
    return null;
  }

  bool _allParticipantsAllowed = true;
  List<ParticipantTrackPermission> _participantTrackPermissions = [];

  /// Control who can subscribe to LocalParticipant's published tracks.
  ///
  /// By default, all participants can subscribe. This allows fine-grained control over
  /// who is able to subscribe at a participant and track level.
  ///
  /// Note: if access is given at a track-level (i.e. both [allParticipantsAllowed] and
  /// [ParticipantTrackPermission.allTracksAllowed] are false), any newer published tracks
  /// will not grant permissions to any participants and will require a subsequent
  /// permissions update to allow subscription.
  ///
  /// [allParticipantsAllowed] Allows all participants to subscribe all tracks.
  /// Takes precedence over [trackPermissions] if set to true.
  /// By default this is set to true.
  ///
  /// [trackPermissions] Full list of individual permissions per
  /// participant/track. Any omitted participants will not receive any permissions.

  void setTrackSubscriptionPermissions({
    required bool allParticipantsAllowed,
    List<ParticipantTrackPermission> trackPermissions = const [],
  }) {
    _allParticipantsAllowed = allParticipantsAllowed;
    _participantTrackPermissions = trackPermissions;
    sendTrackSubscriptionPermissions();
  }

  void sendTrackSubscriptionPermissions() {
    if (room.engine.connectionState != ConnectionState.connected) {
      return;
    }
    room.engine.signalClient.sendUpdateSubscriptionPermissions(
      allParticipants: _allParticipantsAllowed,
      trackPermissions:
          _participantTrackPermissions.map((e) => e.toPBType()).toList(),
    );
  }

  @internal
  Iterable<lk_rtc.TrackPublishedResponse> publishedTracksInfo() =>
      trackPublications.values.map((e) => e.toPBTrackPublishedResponse());

  @internal
  @override
  ParticipantPermissions? setPermissions(ParticipantPermissions newValue) {
    final oldValue = super.setPermissions(newValue);
    if (oldValue != null) {
      // notify
      [events, room.events].emit(ParticipantPermissionsUpdatedEvent(
        participant: this,
        permissions: newValue,
        oldPermissions: oldValue,
      ));
    }
    return oldValue;
  }
}
