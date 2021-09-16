import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'proto/livekit_rtc.pb.dart' as lk_rtc;
import 'proto/livekit_models.pb.dart' as lk_models;

import 'types.dart';

extension LKObjectExt on Object {
  String get objectId => '${runtimeType}${hashCode}';
}

extension RTCIceTransportPolicyExt on RTCIceTransportPolicy {
  String toStringValue() => {
        RTCIceTransportPolicy.all: 'all',
        RTCIceTransportPolicy.relay: 'relay',
      }[this]!;
}

extension LKSessionDescriptionExt on lk_rtc.SessionDescription {
  rtc.RTCSessionDescription toSDKType() {
    return rtc.RTCSessionDescription(sdp, type);
  }
}

extension RTCSessionDescriptionExt on rtc.RTCSessionDescription {
  lk_rtc.SessionDescription toSDKType() {
    return lk_rtc.SessionDescription(type: type, sdp: sdp);
  }
}

extension LKRTCIceCandidateExt on rtc.RTCIceCandidate {
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

extension LKIceServerEtc on lk_rtc.ICEServer {
  RTCIceServer toSDKType() => RTCIceServer(
        urls: urls,
        username: username.isNotEmpty ? username : null,
        credential: credential.isNotEmpty ? username : null,
      );
}

// not so neat to directly expose protobuf types so we
// define our own types (and convert methods)
extension LKDataPacketKindExt on lk_models.DataPacket_Kind {
  LKReliability toSDKType() => {
        lk_models.DataPacket_Kind.RELIABLE: LKReliability.reliable,
        lk_models.DataPacket_Kind.LOSSY: LKReliability.lossy,
      }[this]!;
}

extension LKReliabilityExt on LKReliability {
  lk_models.DataPacket_Kind toPBType() => {
        LKReliability.reliable: lk_models.DataPacket_Kind.RELIABLE,
        LKReliability.lossy: lk_models.DataPacket_Kind.LOSSY,
      }[this]!;
}
