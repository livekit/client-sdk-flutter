import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../errors.dart';
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
    if (audioTracks.values.any((element) => element.track?.mediaTrack.id == track.mediaTrack.id)) {
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
      track: track.mediaTrack,
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

  List<VideoPreset> _presetsForResolution(
    int width,
    int height,
  ) {
    final double aspect = width / height;
    if ((aspect - 16.0 / 9.0).abs() < (aspect - 4.0 / 3.0).abs()) return VideoPreset.all_169;
    return VideoPreset.all_43;
  }

  VideoPreset _findPresetForResolution(
    int width,
    int height, {
    required List<VideoPreset> presets,
  }) {
    //
    VideoPreset result = presets.first;
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
    if (videoTracks.values.any((e) => e.track?.mediaTrack.id == track.mediaTrack.id)) {
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

    int? width = track.latestOptions?.params.width;
    int? height = track.latestOptions?.params.height;

    try {
      // TODO: Get actual video dimensions to compute more accurately
      // We need actual video dimensions but flutter_webrtc seems limited at the moment
      // For WEB, mediaStreamTrack.getSettings() seems reliable
      // For MOBILE, most likely dimensions passed to constraints are the actual dimensions

      //
      // mediaTrack.getConstraints() is not implemented for mobile
      //
      //
      // final settings = mediaStreamTrack.getSettings();
      // width = settings['width'] as int?;
      // height = settings['height'] as int?;
      //
    } catch (_) {
      //
      // Failed to getSettings()
      //
    }

    final encodings = _computeVideoEncodings(
      width: width,
      height: height,
      options: options,
    );

    // print('Using encodings: ${encodings?.map((e) => e.toMap())}');

    final transceiverInit = RTCRtpTransceiverInit(
      direction: TransceiverDirection.SendOnly,
      sendEncodings: encodings,
    );

    //
    // addTransceiver cannot pass in a kind parameter due to a bug in flutter-webrtc (web)
    //
    track.transceiver = await _engine.publisher?.pc.addTransceiver(
      track: track.mediaTrack,
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
