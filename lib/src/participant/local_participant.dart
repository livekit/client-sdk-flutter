import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';

import '../errors.dart';
import '../logger.dart';
import '../options.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../rtc_engine.dart';
import '../track/local_audio_track.dart';
import '../track/local_track_publication.dart';
import '../track/local_video_track.dart';
import '../track/options.dart';
import '../track/track.dart';
import '../track/track_publication.dart';
import 'participant.dart';

/// Represents the current participant in the room.
class LocalParticipant extends Participant {
  //
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
    if (audioTracks.values
        .any((element) => element.track?.mediaStreamTrack.id == track.mediaStreamTrack.id)) {
      return Future.error(TrackPublishError('track already exists'));
    }

    // try {
    final trackInfo = await _engine.addTrack(
      cid: track.getCid(),
      name: track.name,
      kind: track.kind,
    );

    final transceiverInit = RTCRtpTransceiverInit(
      direction: TransceiverDirection.SendOnly,
    );
    // addTransceiver cannot pass in a kind parameter due to a bug in flutter-webrtc (web)
    track.transceiver = await _engine.publisher?.pc.addTransceiver(
      track: track.mediaStreamTrack,
      init: transceiverInit,
    );

    final pub = LocalTrackPublication(trackInfo, track, this);
    addTrackPublication(pub);
    notifyListeners();

    return pub;
    // } catch (e) {
    //   return Future.error(e);
    // }
  }

  List<VideoParameter> _presetsForResolution(
    int width,
    int height,
  ) {
    final double aspect = width / height;
    if ((aspect - 16.0 / 9.0).abs() < (aspect - 4.0 / 3.0).abs()) return VideoParameter.presets169;
    return VideoParameter.presets43;
  }

  VideoParameter _findPresetForResolution(
    int width,
    int height, {
    required List<VideoParameter> presets,
  }) {
    //
    VideoParameter result = presets.first;
    for (final preset in presets) {
      if (width >= preset.width && height >= preset.height) result = preset;
    }

    return result;
  }

  List<RTCRtpEncoding>? _computeVideoEncodings({
    int? width,
    int? height,
    TrackPublishOptions? options,
  }) {
    //
    options ??= const TrackPublishOptions();

    VideoEncoding? videoEncoding = options.videoEncoding;

    if ((videoEncoding == null && !options.simulcast) || width == null || height == null) {
      // don't set encoding when we are not simulcasting and user isn't restricting
      // encoding parameters
      return null;
    }

    final presets = _presetsForResolution(width, height);

    if (videoEncoding == null) {
      // find the right encoding based on width/height
      final preset = _findPresetForResolution(width, height, presets: presets);
      // print('Using preset: ${preset.id}');
      videoEncoding = preset.encoding;
      //   log.debug('using video encoding', videoEncoding);
    }

    if (options.simulcast) {
      final midPreset = presets[1];
      final lowPreset = presets[0];
      return [
        videoEncoding.toRTCRtpEncoding(
          rid: 'f',
        ),
        // if resolution is high enough, we would send both h and q res..
        // otherwise only send h
        if (height * 0.7 >= midPreset.height) ...[
          midPreset.encoding.toRTCRtpEncoding(
            rid: 'h',
            scaleResolutionDownBy: height / midPreset.height,
          ),
          lowPreset.encoding.toRTCRtpEncoding(
            rid: 'q',
            scaleResolutionDownBy: height / lowPreset.height,
          ),
        ] else
          lowPreset.encoding.toRTCRtpEncoding(
            rid: 'h',
            scaleResolutionDownBy: height / lowPreset.height,
          ),
      ];
    }

    return [
      videoEncoding.toRTCRtpEncoding(),
    ];
  }

  /// Publish a video track to the room
  Future<TrackPublication> publishVideoTrack(
    LocalVideoTrack track, {
    TrackPublishOptions? options,
  }) async {
    //
    if (videoTracks.values.any((e) => e.track?.mediaStreamTrack.id == track.mediaStreamTrack.id)) {
      throw TrackPublishError('track already exists');
    }

    //
    // Use default options from `ConnectOptions` if options is null
    //
    options = options ?? defaultPublishOptions;

    final trackInfo = await _engine.addTrack(
      cid: track.getCid(),
      name: track.name,
      kind: track.kind,
    );

    //
    // Video encodings and simulcasts
    //

    // use constraints passed to getUserMedia by default
    int? width = track.latestOptions?.params.width;
    int? height = track.latestOptions?.params.height;

    if (kIsWeb) {
      // getSettings() is only implemented for Web
      try {
        // try to use getSettings for more accurate resolution
        final settings = track.mediaStreamTrack.getSettings();
        width = settings['width'] as int?;
        height = settings['height'] as int?;
        //
        // TODO: Get actual video dimensions to compute more accurately
        // mediaTrack.getConstraints() is not implemented for mobile
        //
      } catch (_) {
        logger.log(Level.WARNING, 'Failed to call `mediaStreamTrack.getSettings()`');
      }
    }

    final encodings = _computeVideoEncodings(
      width: width,
      height: height,
      options: options,
    );

    logger.info('Using encodings: ${encodings?.map((e) => e.toMap())}');

    final transceiverInit = RTCRtpTransceiverInit(
      direction: TransceiverDirection.SendOnly,
      sendEncodings: encodings,
      streams: [track.mediaStream!],
    );

    //
    // addTransceiver cannot pass in a kind parameter due to a bug in flutter-webrtc (web)
    //
    track.transceiver = await _engine.publisher?.pc.addTransceiver(
      track: track.mediaStreamTrack,
      init: transceiverInit,
    );

    final pub = LocalTrackPublication(trackInfo, track, this);
    addTrackPublication(pub);
    notifyListeners();

    return pub;
    // } catch (e) {
    //   return Future.error(e);
    // }
  }

  /// Unpublish a track that's already published
  void unpublishTrack(Track track) {
    final existing = tracks.values.where((element) => element.track == track);
    if (existing.isEmpty) {
      return;
    }
    final pub = existing.first;

    track.stop();
    final sender = track.transceiver?.sender;
    if (sender != null) {
      engine.publisher?.pc.removeTrack(sender);
    }

    tracks.remove(pub.sid);
    switch (pub.kind) {
      case lk_models.TrackType.AUDIO:
        audioTracks.remove(pub.sid);
        break;
      case lk_models.TrackType.VIDEO:
        videoTracks.remove(pub.sid);
        break;
      default:
        break;
    }
  }

  /// Publish a new data payload to the room.
  /// @param destinationSids When empty, data will be forwarded to each participant in the room.
  void publishData(List<int> data, lk_rtc.DataPacket_Kind reliability,
      {List<String>? destinationSids}) {
    RTCDataChannel? channel;
    switch (reliability) {
      case lk_rtc.DataPacket_Kind.RELIABLE:
        channel = engine.reliableDC;
        break;
      case lk_rtc.DataPacket_Kind.LOSSY:
        channel = engine.lossyDC;
        break;
    }
    if (channel == null) {
      return;
    }

    final packet = lk_rtc.DataPacket(
      kind: reliability,
      user: lk_rtc.UserPacket(
        payload: data,
        participantSid: sid,
        destinationSids: destinationSids,
      ),
    );

    final buffer = packet.writeToBuffer();
    channel.send(RTCDataChannelMessage.fromBinary(buffer));
  }

  /// for internal use
  /// {@nodoc}
  @override
  void updateFromInfo(lk_models.ParticipantInfo info) {
    super.updateFromInfo(info);
  }
}
