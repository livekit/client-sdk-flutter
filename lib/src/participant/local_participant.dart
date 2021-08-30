import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../errors.dart';
import '../proto/livekit_models.pb.dart';
import '../proto/livekit_rtc.pbserver.dart';
import '../rtc_engine.dart';
import '../track/local_audio_track.dart';
import '../track/local_track_publication.dart';
import '../track/local_video_track.dart';
import '../track/track.dart';
import '../track/track_publication.dart';
import 'participant.dart';

class LocalParticipant extends Participant {
  final RTCEngine _engine;

  LocalParticipant({
    required RTCEngine engine,
    required ParticipantInfo info,
  })  : _engine = engine,
        super(info.sid, info.identity) {
    updateFromInfo(info);
  }

  RTCEngine get engine => _engine;

  /// publish an audio track to the room
  Future<TrackPublication> publishAudioTrack(LocalAudioTrack track) async {
    if (audioTracks.values.any(
        (element) => element.track?.mediaTrack.id == track.mediaTrack.id)) {
      return Future.error(TrackPublishError('track already exists'));
    }

    try {
      final trackInfo = await _engine.addTrack(
          cid: track.getCid(), name: track.name, kind: track.kind);
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
    } catch (e) {
      return Future.error(e);
    }
  }

  /// publish a video track to the room
  Future<TrackPublication> publishVideoTrack(LocalVideoTrack track) async {
    if (videoTracks.values.any(
        (element) => element.track?.mediaTrack.id == track.mediaTrack.id)) {
      return Future.error(TrackPublishError('track already exists'));
    }

    try {
      final trackInfo = await _engine.addTrack(
          cid: track.getCid(), name: track.name, kind: track.kind);
      final transceiverInit = RTCRtpTransceiverInit(
        direction: TransceiverDirection.SendOnly,
      );
      // TODO: video encodings and simulcasts
      // addTransceiver cannot pass in a kind parameter due to a bug in flutter-webrtc (web)
      track.transceiver = await _engine.publisher?.pc.addTransceiver(
        track: track.mediaTrack,
        init: transceiverInit,
      );

      final pub = LocalTrackPublication(trackInfo, track, this);
      addTrackPublication(pub);
      notifyListeners();

      return pub;
    } catch (e) {
      return Future.error(e);
    }
  }

  unpublishTrack(Track track) {
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
      case TrackType.AUDIO:
        audioTracks.remove(pub.sid);
        break;
      case TrackType.VIDEO:
        videoTracks.remove(pub.sid);
        break;
      default:
        break;
    }
  }

  publishData(List<int> data, DataPacket_Kind reliability,
      {List<String>? destinationSids}) {
    RTCDataChannel? channel;
    switch (reliability) {
      case DataPacket_Kind.RELIABLE:
        channel = engine.reliableDC;
        break;
      case DataPacket_Kind.LOSSY:
        channel = engine.lossyDC;
        break;
    }
    if (channel == null) {
      return;
    }

    final packet = DataPacket(
      kind: reliability,
      user: UserPacket(
        payload: data,
        participantSid: sid,
        destinationSids: destinationSids,
      ),
    );

    final buffer = packet.writeToBuffer();
    channel.send(RTCDataChannelMessage.fromBinary(buffer));
  }

  @override
  updateFromInfo(ParticipantInfo info) {
    super.updateFromInfo(info);
  }
}
