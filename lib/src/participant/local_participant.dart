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
  RTCEngine _engine;
  MediaStream? _mediaStream;

  LocalParticipant({
    required RTCEngine engine,
    required ParticipantInfo info,
  })  : _engine = engine,
        super(info.sid, info.identity) {
    updateFromInfo(info);
  }

  RTCEngine get engine => _engine;

  Future<MediaStream> getMediaStream() async {
    var stream = _mediaStream;
    if (stream == null) {
      stream = await createLocalMediaStream(sid);
      _mediaStream = stream;
    }
    return stream;
  }

  /// publish an audio track to the room
  Future<TrackPublication> publishAudioTrack(LocalAudioTrack track) async {
    if (audioTracks.values.any(
        (element) => element.track?.mediaTrack.id == track.mediaTrack.id)) {
      return Future.error(TrackPublishError('track already exists'));
    }

    try {
      var trackInfo = await _engine.addTrack(
          cid: track.getCid(), name: track.name, kind: track.kind);
      var stream = await getMediaStream();
      var transceiverInit = new RTCRtpTransceiverInit(
        direction: TransceiverDirection.SendOnly,
        streams: [stream],
      );
      track.transceiver = await _engine.publisher?.pc.addTransceiver(
        track: track.mediaTrack,
        kind: track.mediaType,
        init: transceiverInit,
      );

      var pub = new LocalTrackPublication(trackInfo, track, this);
      addTrackPublication(pub);
      notifyListeners();

      return pub;
    } catch (e) {
      return Future.error(e);
    }
  }

  /// publish a video track to the room
  Future<TrackPublication> publishVideoTrack(LocalVideoTrack track) async {
    if (audioTracks.values.any(
        (element) => element.track?.mediaTrack.id == track.mediaTrack.id)) {
      return Future.error(TrackPublishError('track already exists'));
    }

    try {
      var trackInfo = await _engine.addTrack(
          cid: track.getCid(), name: track.name, kind: track.kind);
      var stream = await getMediaStream();
      var transceiverInit = new RTCRtpTransceiverInit(
        direction: TransceiverDirection.SendOnly,
        streams: [stream],
      );
      // TODO: video encodings and simulcast
      track.transceiver = await _engine.publisher?.pc.addTransceiver(
        track: track.mediaTrack,
        kind: track.mediaType,
        init: transceiverInit,
      );

      var pub = new LocalTrackPublication(trackInfo, track, this);
      addTrackPublication(pub);
      notifyListeners();

      return pub;
    } catch (e) {
      return Future.error(e);
    }
  }

  unpublishTrack(Track track) {
    var existing = tracks.values.where((element) => element.track == track);
    if (existing.isEmpty) {
      return;
    }
    var pub = existing.first;

    track.stop();
    var sender = track.transceiver?.sender;
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

    var packet = new DataPacket(
      kind: reliability,
      user: new UserPacket(
        payload: data,
        participantSid: sid,
        destinationSids: destinationSids,
      ),
    );

    var buffer = packet.writeToBuffer();
    channel.send(RTCDataChannelMessage.fromBinary(buffer));
  }

  updateFromInfo(ParticipantInfo info) {
    super.updateFromInfo(info);
  }
}
