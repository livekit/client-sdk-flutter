import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'events.dart';
import 'managers/event.dart';
import 'proto/livekit_models.pb.dart' as lk_models;
import 'proto/livekit_rtc.pb.dart' as lk_rtc;
import 'types/other.dart';

extension DataPacketKindExt on lk_models.DataPacket_Kind {
  Reliability toSDKType() => {
        lk_models.DataPacket_Kind.RELIABLE: Reliability.reliable,
        lk_models.DataPacket_Kind.LOSSY: Reliability.lossy,
      }[this]!;
}

extension LiveKitEventExt on Iterable<EventsEmitter<LiveKitEvent>> {
  void emit(LiveKitEvent event) => forEach((emitter) => emitter.emit(event));
}

extension ICEServerExt on lk_rtc.ICEServer {
  RTCIceServer toSDKType() => RTCIceServer(
        urls: urls,
        username: username.isNotEmpty ? username : null,
        credential: credential.isNotEmpty ? username : null,
      );
}

extension IterableExt<E> on Iterable<E> {
  E? elementAtOrNull(int index) =>
      (index >= 0 && index < length) ? elementAt(index) : null;
}

extension ObjectExt on Object {
  String get objectId => '${runtimeType}#${hashCode}';
}

extension ProtocolVersionExt on ProtocolVersion {
  String toStringValue() => {
        ProtocolVersion.v2: '2',
        ProtocolVersion.v3: '3',
        ProtocolVersion.v4: '4',
        ProtocolVersion.v5: '5',
        ProtocolVersion.v6: '6',
        ProtocolVersion.v7: '7',
      }[this]!;
}

extension ReliabilityExt on Reliability {
  lk_models.DataPacket_Kind toPBType() => {
        Reliability.reliable: lk_models.DataPacket_Kind.RELIABLE,
        Reliability.lossy: lk_models.DataPacket_Kind.LOSSY,
      }[this]!;
}

extension RTCDataChannelExt on rtc.RTCDataChannel {
  lk_rtc.DataChannelInfo toLKInfoType() => lk_rtc.DataChannelInfo(
        id: id,
        label: label,
      );
}

extension RTCIceCandidateExt on rtc.RTCIceCandidate {
  static rtc.RTCIceCandidate fromJson(String jsonString) {
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return rtc.RTCIceCandidate(
      map['candidate'] as String?,
      map['sdpMid'] as String?,
      map['sdpMLineIndex'] as int?,
    );
  }

  String toJson() => json.encode(toMap());
}

extension RTCPeerConnectionStateExt on rtc.RTCPeerConnectionState {
  bool isConnected() =>
      this == rtc.RTCPeerConnectionState.RTCPeerConnectionStateConnected;
}

extension RTCIceTransportPolicyExt on RTCIceTransportPolicy {
  String toStringValue() => {
        RTCIceTransportPolicy.all: 'all',
        RTCIceTransportPolicy.relay: 'relay',
      }[this]!;
}

// not so neat to directly expose protobuf types so we
// define our own types (and convert methods)
extension RTCSessionDescriptionExt on rtc.RTCSessionDescription {
  lk_rtc.SessionDescription toPBType() {
    return lk_rtc.SessionDescription(type: type, sdp: sdp);
  }
}

extension SessionDescriptionExt on lk_rtc.SessionDescription {
  rtc.RTCSessionDescription toSDKType() {
    return rtc.RTCSessionDescription(sdp, type);
  }
}

extension ConnectionQualityExt on lk_models.ConnectionQuality {
  ConnectionQuality toLKType() =>
      {
        lk_models.ConnectionQuality.POOR: ConnectionQuality.poor,
        lk_models.ConnectionQuality.GOOD: ConnectionQuality.good,
        lk_models.ConnectionQuality.EXCELLENT: ConnectionQuality.excellent,
      }[this] ??
      ConnectionQuality.unknown;
}

extension PBTrackSourceExt on lk_models.TrackSource {
  TrackSource toLKType() =>
      <lk_models.TrackSource, TrackSource>{
        lk_models.TrackSource.CAMERA: TrackSource.camera,
        lk_models.TrackSource.MICROPHONE: TrackSource.microphone,
        lk_models.TrackSource.SCREEN_SHARE: TrackSource.screenShareVideo,
        lk_models.TrackSource.SCREEN_SHARE_AUDIO: TrackSource.screenShareAudio,
      }[this] ??
      TrackSource.unknown;
}

extension LKTrackSourceExt on TrackSource {
  lk_models.TrackSource toPBType() =>
      <TrackSource, lk_models.TrackSource>{
        TrackSource.camera: lk_models.TrackSource.CAMERA,
        TrackSource.microphone: lk_models.TrackSource.MICROPHONE,
        TrackSource.screenShareVideo: lk_models.TrackSource.SCREEN_SHARE,
        TrackSource.screenShareAudio: lk_models.TrackSource.SCREEN_SHARE_AUDIO,
      }[this] ??
      lk_models.TrackSource.UNKNOWN;
}

extension PBStreamStateExt on lk_rtc.StreamState {
  StreamState toLKType() =>
      <lk_rtc.StreamState, StreamState>{
        lk_rtc.StreamState.ACTIVE: StreamState.active,
      }[this] ??
      StreamState.paused;
}

extension VideoQualityExt on lk_models.VideoQuality {
  String toRid() => {
        lk_models.VideoQuality.HIGH: 'f',
        lk_models.VideoQuality.MEDIUM: 'h',
        lk_models.VideoQuality.LOW: 'q',
      }[this]!;
}

extension ParticipantTrackPermissionExt on ParticipantTrackPermission {
  lk_rtc.TrackPermission toPBType() => lk_rtc.TrackPermission(
        participantSid: participantSid,
        allTracks: allTracksAllowed,
        trackSids: allowedTrackSids,
      );
}
