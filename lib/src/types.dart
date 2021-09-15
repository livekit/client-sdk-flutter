//
// LiveKit
//

import 'package:flutter/material.dart';

import 'extensions.dart';
import 'proto/livekit_rtc.pb.dart' as lk_rtc;

enum RTCIceTransportPolicy {
  all,
  relay,
}

@immutable
class RTCOfferOptions {
  final bool iceRestart;

  const RTCOfferOptions({
    this.iceRestart = false,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
        if (iceRestart) 'iceRestart': true,
      };
}

@immutable
class RTCConfiguration {
  final int? iceCandidatePoolSize;
  final List<RTCIceServer>? iceServers;
  final RTCIceTransportPolicy? iceTransportPolicy;

  const RTCConfiguration({
    this.iceCandidatePoolSize,
    this.iceServers,
    this.iceTransportPolicy,
  });

  Map<String, dynamic> toMap() {
    final iceServersMap = <Map<String, dynamic>>[
      if (iceServers != null)
        for (final e in iceServers!) e.toMap()
    ];

    return <String, dynamic>{
      // only supports unified plan
      'sdpSemantics': 'unified-plan',
      if (iceServersMap.isNotEmpty) 'iceServers': iceServersMap,
      if (iceCandidatePoolSize != null) 'iceCandidatePoolSize': iceCandidatePoolSize,
      if (iceTransportPolicy != null) 'iceTransportPolicy': iceTransportPolicy!.toStringValue(),
    };
  }

  // Returns new options with updated properties
  RTCConfiguration copyWith({
    int? iceCandidatePoolSize,
    List<RTCIceServer>? iceServers,
    RTCIceTransportPolicy? iceTransportPolicy,
  }) =>
      RTCConfiguration(
        iceCandidatePoolSize: iceCandidatePoolSize ?? this.iceCandidatePoolSize,
        iceServers: iceServers ?? this.iceServers,
        iceTransportPolicy: iceTransportPolicy ?? this.iceTransportPolicy,
      );

  RTCConfiguration updateIceServers(
    List<lk_rtc.ICEServer> lkIceServers, {
    bool force = false,
  }) {
    // don't overwrite if already has an element
    if (!(iceServers?.isEmpty ?? true) || !force) return this;
    final _ = lkIceServers.map((e) => e.toRTCObject()).toList();
    return copyWith(iceServers: _);
  }
}

@immutable
class RTCIceServer {
  final List<String>? urls;
  final String? username;
  final String? credential;

  const RTCIceServer({
    this.urls,
    this.username,
    this.credential,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
        if (urls != null) 'urls': urls,
        if (username != null) 'username': username,
        if (credential != null) 'credential': credential,
      };
}
