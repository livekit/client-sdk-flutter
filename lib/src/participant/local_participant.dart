import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';

import '../errors.dart';
import '../extensions.dart';
import '../logger.dart';
import '../options.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../rtc_engine.dart';
import '../track/local_audio_track.dart';
import '../track/local_track_publication.dart';
import '../track/local_video_track.dart';
import '../track/track.dart';
import '../track/track_publication.dart';
import '../utils.dart';
import 'participant.dart';

/// Represents the current participant in the room.
class LocalParticipant extends Participant {
  final RTCEngine _engine;
  final TrackPublishOptions? defaultPublishOptions;

  LocalParticipant({
    required RTCEngine engine,
    required lk_models.ParticipantInfo info,
    this.defaultPublishOptions,
  })  : _engine = engine,
        super(info.sid, info.identity) {
    updateFromInfo(info);
  }

  /// for internal use
  /// {@nodoc}
  RTCEngine get engine => _engine;

  /// publish an audio track to the room
  Future<TrackPublication> publishAudioTrack(LocalAudioTrack track) async {
    if (audioTracks.any((e) => e.track?.mediaStreamTrack.id == track.mediaStreamTrack.id)) {
      throw TrackPublishException('track already exists');
    }

    // try {
    final trackInfo = await _engine.addTrack(
      cid: track.getCid(),
      name: track.name,
      kind: track.kind,
    );

    final transceiverInit = rtc.RTCRtpTransceiverInit(
      direction: rtc.TransceiverDirection.SendOnly,
    );
    // addTransceiver cannot pass in a kind parameter due to a bug in flutter-webrtc (web)
    track.transceiver = await _engine.publisher?.pc.addTransceiver(
      track: track.mediaStreamTrack,
      kind: rtc.RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: transceiverInit,
    );
    await _engine.negotiate();

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
    if (videoTracks.any((e) => e.track?.mediaStreamTrack.id == track.mediaStreamTrack.id)) {
      throw TrackPublishException('track already exists');
    }

    // Use default options from `ConnectOptions` if options is null
    options = options ?? defaultPublishOptions;

    final trackInfo = await _engine.addTrack(
      cid: track.getCid(),
      name: track.name,
      kind: track.kind,
    );
    logger.fine('publishVideoTrack addTrack response: ${trackInfo}');

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
        // TODO: Get actual video dimensions to compute more accurately
        // mediaTrack.getConsstraints() is not implemented for mobile
      } catch (_) {
        logger.warning('Failed to call `mediaStreamTrack.getSettings()`');
      }
    }

    logger.fine('Compute encodings with resolution: ${width}x${height}, options: ${options}');

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

    logger.fine('publishVideoTrack publisher: ${_engine.publisher}');

    track.transceiver = await _engine.publisher?.pc.addTransceiver(
      track: track.mediaStreamTrack,
      kind: rtc.RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: transceiverInit,
    );
    await _engine.negotiate();

    final pub = LocalTrackPublication(trackInfo, track, this);
    addTrackPublication(pub);
    notifyListeners();

    return pub;
  }

  /// Unpublish a track that's already published
  Future<void> unpublishTrack(Track track) async {
    final existing = tracks.values.where((element) => element.track == track);
    if (existing.isEmpty) return;

    final pub = existing.first;

    await track.stop();

    final sender = track.transceiver?.sender;
    if (sender != null) {
      await engine.publisher?.pc.removeTrack(sender);
      await engine.negotiate();
    }

    tracks.remove(pub.sid);
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
  @override
  void updateFromInfo(lk_models.ParticipantInfo info) {
    super.updateFromInfo(info);
  }
}
