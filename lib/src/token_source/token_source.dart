// Copyright 2024 LiveKit, Inc.
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

import 'package:collection/collection.dart';

import 'room_configuration.dart';

/// Request parameters for generating connection credentials.
class TokenRequestOptions {
  /// The name of the room to connect to. Required for most token generation scenarios.
  final String? roomName;

  /// The display name for the participant in the room. Optional but recommended for user experience.
  final String? participantName;

  /// A unique identifier for the participant. Used for permissions and room management.
  final String? participantIdentity;

  /// Custom metadata associated with the participant. Can be used for user profiles or additional context.
  final String? participantMetadata;

  /// Custom attributes for the participant. Useful for storing key-value data like user roles or preferences.
  final Map<String, String>? participantAttributes;

  /// Name of the agent to dispatch.
  final String? agentName;

  /// Metadata passed to the agent job.
  final String? agentMetadata;

  const TokenRequestOptions({
    this.roomName,
    this.participantName,
    this.participantIdentity,
    this.participantMetadata,
    this.participantAttributes,
    this.agentName,
    this.agentMetadata,
  });

  /// Converts this options object to a wire-format request.
  TokenSourceRequest toRequest() {
    final List<RoomAgentDispatch>? agents = (agentName != null || agentMetadata != null)
        ? [RoomAgentDispatch(agentName: agentName, metadata: agentMetadata)]
        : null;

    return TokenSourceRequest(
      roomName: roomName,
      participantName: participantName,
      participantIdentity: participantIdentity,
      participantMetadata: participantMetadata,
      participantAttributes: participantAttributes,
      roomConfiguration: RoomConfiguration(agents: agents),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TokenRequestOptions) return false;

    return other.roomName == roomName &&
        other.participantName == participantName &&
        other.participantIdentity == participantIdentity &&
        other.participantMetadata == participantMetadata &&
        other.agentName == agentName &&
        other.agentMetadata == agentMetadata &&
        const MapEquality().equals(other.participantAttributes, participantAttributes);
  }

  @override
  int get hashCode {
    return Object.hash(
      roomName,
      participantName,
      participantIdentity,
      participantMetadata,
      agentName,
      agentMetadata,
      const MapEquality().hash(participantAttributes),
    );
  }
}

/// The JSON serializable format of the request sent to standard LiveKit token servers.
///
/// This is an internal wire format class that separates the public API ([TokenRequestOptions])
/// from the JSON structure sent over the network.
class TokenSourceRequest {
  final String? roomName;
  final String? participantName;
  final String? participantIdentity;
  final String? participantMetadata;
  final Map<String, String>? participantAttributes;
  final RoomConfiguration? roomConfiguration;

  const TokenSourceRequest({
    this.roomName,
    this.participantName,
    this.participantIdentity,
    this.participantMetadata,
    this.participantAttributes,
    this.roomConfiguration,
  });

  Map<String, dynamic> toJson() {
    return {
      if (roomName != null) 'room_name': roomName,
      if (participantName != null) 'participant_name': participantName,
      if (participantIdentity != null) 'participant_identity': participantIdentity,
      if (participantMetadata != null) 'participant_metadata': participantMetadata,
      if (participantAttributes != null) 'participant_attributes': participantAttributes,
      if (roomConfiguration != null) 'room_config': roomConfiguration!.toJson(),
    };
  }
}

/// Response containing the credentials needed to connect to a LiveKit room.
class TokenSourceResponse {
  /// The WebSocket URL for the LiveKit server. Use this to establish the connection.
  final String serverUrl;

  /// The JWT token containing participant permissions and metadata. Required for authentication.
  final String participantToken;

  /// The display name for the participant in the room. May be null if not specified.
  final String? participantName;

  /// The name of the room the participant will join. May be null if not specified.
  final String? roomName;

  const TokenSourceResponse({
    required this.serverUrl,
    required this.participantToken,
    this.participantName,
    this.roomName,
  });

  factory TokenSourceResponse.fromJson(Map<String, dynamic> json) {
    return TokenSourceResponse(
      serverUrl: (json['server_url'] ?? json['serverUrl']) as String,
      participantToken: (json['participant_token'] ?? json['participantToken']) as String,
      participantName: (json['participant_name'] ?? json['participantName']) as String?,
      roomName: (json['room_name'] ?? json['roomName']) as String?,
    );
  }
}

/// A token source that returns a fixed set of credentials without configurable options.
///
/// This abstract class is designed for backwards compatibility with existing authentication infrastructure
/// that doesn't support dynamic room, participant, or agent parameter configuration.
abstract class TokenSourceFixed {
  Future<TokenSourceResponse> fetch();
}

/// A token source that provides configurable options for room, participant, and agent parameters.
///
/// This abstract class allows dynamic configuration of connection parameters, making it suitable for
/// production applications that need flexible authentication and room management.
///
/// Common implementations:
/// - [SandboxTokenSource]: For testing with LiveKit Cloud sandbox token server
/// - [EndpointTokenSource]: For custom backend endpoints using LiveKit's JSON format
/// - [CachingTokenSource]: For caching credentials (or use the `.cached()` extension method)
abstract class TokenSourceConfigurable {
  Future<TokenSourceResponse> fetch(TokenRequestOptions options);
}
