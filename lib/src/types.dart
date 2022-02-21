import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'extensions.dart';
import 'participant/participant.dart';

typedef CancelListenFunc = Function();

/// Protocol version to use when connecting to server.
/// Usually it's not recommended to change this.
enum ProtocolVersion {
  v2,
  v3, // Subscriber as primary
  v4,
  v5,
  v6, // Session migration
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
  user,
  peerConnection,
  signal,
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

/// A simple class that represents dimensions of video.
@immutable
class VideoDimensions {
  // 16:9 aspect ratio presets
  static const h90_169 = VideoDimensions(160, 90);
  static const h180_169 = VideoDimensions(320, 180);
  static const h216_169 = VideoDimensions(384, 216);
  static const h360_169 = VideoDimensions(640, 360);
  static const h540_169 = VideoDimensions(960, 540);
  static const h720_169 = VideoDimensions(1280, 720);
  static const h1080_169 = VideoDimensions(1920, 1080);
  static const h1440_169 = VideoDimensions(2560, 1440);
  static const h2160_169 = VideoDimensions(3840, 2160);

  // 4:3 aspect ratio presets
  static const h120_43 = VideoDimensions(160, 120);
  static const h180_43 = VideoDimensions(240, 180);
  static const h240_43 = VideoDimensions(320, 240);
  static const h360_43 = VideoDimensions(480, 360);
  static const h480_43 = VideoDimensions(640, 480);
  static const h540_43 = VideoDimensions(720, 540);
  static const h720_43 = VideoDimensions(960, 720);
  static const h1080_43 = VideoDimensions(1440, 1080);
  static const h1440_43 = VideoDimensions(1920, 1440);

  final int width;
  final int height;

  const VideoDimensions(
    this.width,
    this.height,
  );

  @override
  String toString() => '${runtimeType}(${width}x${height})';

  /// Returns the larger value
  int max() => math.max(width, height);

  /// Returns the smaller value
  int min() => math.min(width, height);

  VideoDimensions copyWith({
    int? width,
    int? height,
  }) =>
      VideoDimensions(
        width ?? this.width,
        height ?? this.height,
      );
}

@immutable
class ParticipantTrackPermission {
  /// The participant id this permission applies to.
  final String participantSid;

  /// If set to true, the target participant can subscribe to all tracks from the local participant.
  /// Takes precedence over [allowedTrackSids].
  final bool allTracksAllowed;

  /// The list of track ids that the target participant can subscribe to.
  final List<String> allowedTrackSids;

  const ParticipantTrackPermission(
    this.participantSid,
    this.allTracksAllowed,
    this.allowedTrackSids,
  );
}
