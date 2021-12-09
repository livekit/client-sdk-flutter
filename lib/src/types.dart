import 'package:flutter/material.dart';

import 'extensions.dart';

typedef CancelListenFunc = Function();

enum ProtocolVersion {
  v2,
  v3,
  v4,
  v5,
}

enum ConnectionState {
  disconnected,
  connected,
  reconnecting,
}

enum ConnectionQuality {
  unknown,
  poor,
  good,
  excellent,
}

enum Reliability {
  reliable,
  lossy,
}

enum TrackSource {
  unknown,
  camera,
  microphone,
  screenShareVideo,
  screenShareAudio,
}

enum CloseReason {
  network,
  // ...
}

enum TrackSubscribeFailReason {
  invalidServerResponse,
  notTrackMetadataFound,
  unsupportedTrackType,
  // ...
}

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
      if (iceCandidatePoolSize != null)
        'iceCandidatePoolSize': iceCandidatePoolSize,
      if (iceTransportPolicy != null)
        'iceTransportPolicy': iceTransportPolicy!.toStringValue(),
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
        if (urls?.isNotEmpty ?? false) 'urls': urls,
        if (username?.isNotEmpty ?? false) 'username': username,
        if (credential?.isNotEmpty ?? false) 'credential': credential,
      };
}

@immutable
class TrackDimension {
  final int width;
  final int height;

  const TrackDimension(
    this.width,
    this.height,
  );
}
