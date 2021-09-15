import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'proto/livekit_rtc.pb.dart' as lk_rtc;
import 'types.dart';

extension RTCIceTransportPolicyExt on RTCIceTransportPolicy {
  String toStringValue() => {
        RTCIceTransportPolicy.all: 'all',
        RTCIceTransportPolicy.relay: 'relay',
      }[this]!;
}

extension LKSessionDescriptionExt on lk_rtc.SessionDescription {
  rtc.RTCSessionDescription toRTCObject() {
    return rtc.RTCSessionDescription(sdp, type);
  }
}

extension RTCSessionDescriptionExt on rtc.RTCSessionDescription {
  lk_rtc.SessionDescription toLKObject() {
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
  RTCIceServer toRTCObject() => RTCIceServer(
        urls: urls,
        username: username.isNotEmpty ? username : null,
        credential: credential.isNotEmpty ? username : null,
      );
}
