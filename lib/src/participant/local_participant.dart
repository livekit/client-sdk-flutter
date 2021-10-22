import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../events.dart';
import '../exceptions.dart';
import '../extensions.dart';
import '../logger.dart';
import '../managers/event.dart';
import '../options.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../rtc_engine.dart';
import '../track/local_audio_track.dart';
import '../track/local_track_publication.dart';
import '../track/local_video_track.dart';
import '../track/track_publication.dart';
import '../types.dart';
import '../utils.dart';
import 'participant.dart';

/// Represents the current participant in the room.
class LocalParticipant extends Participant {
  @internal
  final RTCEngine engine;
  @internal
  final TrackPublishOptions? defaultPublishOptions;

  LocalParticipant({
    required this.engine,
    required lk_models.ParticipantInfo info,
    this.defaultPublishOptions,
    required EventsEmitter<RoomEvent> roomEvents,
  }) : super(
          info.sid,
          info.identity,
          roomEvents: roomEvents,
        ) {
    updateFromInfo(info);
  }

  /// publish an audio track to the room
  Future<TrackPublication> publishAudioTrack(LocalAudioTrack track) async {
    if (audioTracks.any(
        (e) => e.track?.mediaStreamTrack.id == track.mediaStreamTrack.id)) {
      throw TrackPublishException('track already exists');
    }

    final trackInfo = await engine.addTrack(
      cid: track.getCid(),
      name: track.name,
      kind: track.kind,
    );

    await track.start();

    final transceiverInit = rtc.RTCRtpTransceiverInit(
      direction: rtc.TransceiverDirection.SendOnly,
    );
    // addTransceiver cannot pass in a kind parameter due to a bug in flutter-webrtc (web)
    track.transceiver = await engine.publisher?.pc.addTransceiver(
      track: track.mediaStreamTrack,
      kind: rtc.RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: transceiverInit,
    );
    await engine.negotiate();

    final pub = LocalTrackPublication(trackInfo, track, this);
    addTrackPublication(pub);
    notifyListeners();
    return pub;
  }

  /// Publish a video track to the room
  Future<TrackPublication> publishVideoTrack(
    LocalVideoTrack track, {
    TrackPublishOptions? options,
  }) async {
    if (videoTracks.any(
        (e) => e.track?.mediaStreamTrack.id == track.mediaStreamTrack.id)) {
      throw TrackPublishException('track already exists');
    }

    // Use default options from `ConnectOptions` if options is null
    options = options ?? defaultPublishOptions;

    final trackInfo = await engine.addTrack(
      cid: track.getCid(),
      name: track.name,
      kind: track.kind,
    );

    logger.fine('publishVideoTrack addTrack response: ${trackInfo}');

    await track.start();

    // Video encodings and simulcasts

    // use constraints passed to getUserMedia by default
    int? width = track.currentOptions.params.width;
    int? height = track.currentOptions.params.height;

    if (kIsWeb) {
      // getSettings() is only implemented for Web
      try {
        // try to use getSettings for more accurate resolution
        final settings = track.mediaStreamTrack.getSettings();
        width = settings['width'] as int?;
        height = settings['height'] as int?;
      } catch (_) {
        logger.warning('Failed to call `mediaStreamTrack.getSettings()`');
      }
    }

    logger.fine(
        'Compute encodings with resolution: ${width}x${height}, options: ${options}');

    final encodings = Utils.computeVideoEncodings(
      width: width,
      height: height,
      options: options,
    );

    logger.fine('Using encodings: ${encodings?.map((e) => e.toMap())}');

    final transceiverInit = rtc.RTCRtpTransceiverInit(
      direction: rtc.TransceiverDirection.SendOnly,
      sendEncodings: encodings,
      streams: [track.mediaStream],
    );

    logger.fine('publishVideoTrack publisher: ${engine.publisher}');

    track.transceiver = await engine.publisher?.pc.addTransceiver(
      track: track.mediaStreamTrack,
      kind: rtc.RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: transceiverInit,
    );
    await engine.negotiate();

    final pub = LocalTrackPublication(trackInfo, track, this);
    addTrackPublication(pub);
    notifyListeners();

    return pub;
  }

  /// Unpublish a track that's already published
  @override
  Future<void> unpublishTrack(String trackSid, {bool notify = true}) async {
    logger.finer('Unpublish track sid: $trackSid, notify: $notify');
    final pub = trackPublications.remove(trackSid);
    if (pub is! LocalTrackPublication) {
      await pub?.dispose();
      return;
    }

    final track = pub.track;
    if (track != null) {
      await track.stop();

      final sender = track.transceiver?.sender;
      if (sender != null) {
        try {
          await engine.publisher?.pc.removeTrack(sender);
        } catch (_) {
          logger.warning('[$objectId] rtc.removeTrack() did throw ${_}');
        }

        // doesn't make sense to negotiate if already disposed
        if (!isDisposed) {
          // manual negotiation since track changed
          await engine.negotiate();
        }
      }
    }

    if (notify) {
      [events, roomEvents].emit(TrackUnpublishedEvent(
        participant: this,
        publication: pub,
      ));
    }

    await pub.dispose();
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

    await engine.sendDataPacket(packet);
  }

  /// for internal use
  /// {@nodoc}
  @internal
  @override
  void updateFromInfo(lk_models.ParticipantInfo info) {
    super.updateFromInfo(info);
  }
}
