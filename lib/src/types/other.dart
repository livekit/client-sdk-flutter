// Copyright 2023 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';

import '../extensions.dart';
import '../participant/participant.dart';

typedef CancelListenFunc = Function();

/// Protocol version to use when connecting to server.
/// Usually it's not recommended to change this.
enum ProtocolVersion {
  v2,
  v3, // Subscriber as primary
  v4,
  v5,
  v6, // Session migration
  v7, // Remote unpublish
  v8,
  v9,
}

/// Connection state type used throughout the SDK.
enum ConnectionState {
  disconnected,
  connecting,
  reconnecting,
  connected,
}

/// Connection quality between the [Participant] and server.
enum ConnectionQuality {
  unknown,
  poor,
  good,
  excellent,
}

/// Reliability used for publishing data through data channel.
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

enum TrackSubscriptionState {
  unsubscribed,
  subscribed,
  notAllowed,
}

/// The state of track data stream.
/// This is controlled by server to optimize bandwidth.
enum StreamState {
  paused,
  active,
}

enum DisconnectReason {
  unknown,
  clientInitiated,
  duplicateIdentity,
  serverShutdown,
  participantRemoved,
  roomDeleted,
  stateMismatch,
  joinFailure,
}

/// The reason why a track failed to publish.
enum TrackSubscribeFailReason {
  invalidServerResponse,
  notTrackMetadataFound,
  unsupportedTrackType,
  // ...
}

/// The iceTransportPolicy used for [RTCConfiguration].
/// See https://developer.mozilla.org/en-US/docs/Web/API/RTCPeerConnection/RTCPeerConnection
enum RTCIceTransportPolicy {
  all,
  relay,
}

@immutable
class RTCConfiguration {
  final int? iceCandidatePoolSize;
  final List<RTCIceServer>? iceServers;
  final RTCIceTransportPolicy? iceTransportPolicy;
  final bool? encodedInsertableStreams;

  const RTCConfiguration({
    this.iceCandidatePoolSize,
    this.iceServers,
    this.iceTransportPolicy,
    this.encodedInsertableStreams,
  });

  Map<String, dynamic> toMap() {
    final iceServersMap = <Map<String, dynamic>>[
      if (iceServers != null)
        for (final e in iceServers!) e.toMap()
    ];

    return <String, dynamic>{
      // only supports unified plan
      'sdpSemantics': 'unified-plan',
      if (encodedInsertableStreams != null)
        'encodedInsertableStreams': encodedInsertableStreams,
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
    bool? encodedInsertableStreams,
  }) =>
      RTCConfiguration(
        iceCandidatePoolSize: iceCandidatePoolSize ?? this.iceCandidatePoolSize,
        iceServers: iceServers ?? this.iceServers,
        iceTransportPolicy: iceTransportPolicy ?? this.iceTransportPolicy,
        encodedInsertableStreams:
            encodedInsertableStreams ?? this.encodedInsertableStreams,
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
class ParticipantTrackPermission {
  /// The participant identity this permission applies to.
  final String participantIdentity;

  /// If set to true, the target participant can subscribe to all tracks from the local participant.
  /// Takes precedence over [allowedTrackSids].
  final bool allTracksAllowed;

  /// The list of track ids that the target participant can subscribe to.
  final List<String>? allowedTrackSids;

  const ParticipantTrackPermission(
    this.participantIdentity,
    this.allTracksAllowed,
    this.allowedTrackSids,
  );
}
