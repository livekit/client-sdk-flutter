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

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import 'token_source.dart';

/// Parsed payload for a LiveKit-issued JWT.
class LiveKitJwtPayload {
  LiveKitJwtPayload._(this._claims);

  factory LiveKitJwtPayload.fromClaims(Map<String, dynamic> claims) {
    return LiveKitJwtPayload._(Map<String, dynamic>.from(claims));
  }

  static LiveKitJwtPayload? fromToken(String token) {
    try {
      final jwt = JWT.decode(token);
      final claims = jwt.payload;
      if (claims is Map<String, dynamic>) {
        return LiveKitJwtPayload.fromClaims(claims);
      }
      if (claims is Map) {
        return LiveKitJwtPayload.fromClaims(Map<String, dynamic>.from(claims));
      }
    } on JWTException {
      return null;
    }
    return null;
  }

  final Map<String, dynamic> _claims;

  /// A readonly view of the raw JWT claims.
  Map<String, dynamic> get claims => Map.unmodifiable(_claims);

  /// JWT issuer claim.
  String? get issuer => _claims['iss'] as String?;

  /// JWT subject claim (participant identity).
  String? get identity {
    final sub = _claims['sub'] ?? _claims['identity'];
    return sub is String ? sub : null;
  }

  /// Display name for the participant.
  String? get name => _claims['name'] as String?;

  /// Custom metadata associated with the participant.
  String? get metadata => _claims['metadata'] as String?;

  /// Custom participant attributes.
  Map<String, String>? get attributes => _stringMapFor('attributes');

  /// Video-specific grants embedded in the token, if present.
  LiveKitVideoGrant? get video {
    final raw = _claims['video'];
    if (raw is Map) {
      return LiveKitVideoGrant.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  /// Token expiration instant in UTC.
  DateTime? get expiresAt => _dateTimeFor('exp');

  /// Token not-before instant in UTC.
  DateTime? get notBefore => _dateTimeFor('nbf');

  /// Token issued-at instant in UTC.
  DateTime? get issuedAt => _dateTimeFor('iat');

  DateTime? _dateTimeFor(String key) {
    final value = _claims[key];
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch((value * 1000).round(), isUtc: true);
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return DateTime.fromMillisecondsSinceEpoch(parsed * 1000, isUtc: true);
      }
    }
    return null;
  }

  Map<String, String>? _stringMapFor(String key) {
    final value = _claims[key];
    if (value is Map) {
      final result = <String, String>{};
      value.forEach((dynamic k, dynamic v) {
        if (k != null && v != null) {
          result[k.toString()] = v.toString();
        }
      });
      return result;
    }
    return null;
  }
}

/// LiveKit-specific video grants embedded within a JWT.
class LiveKitVideoGrant {
  final String? room;
  final bool? roomCreate;
  final bool? roomJoin;
  final bool? roomList;
  final bool? roomRecord;
  final bool? roomAdmin;
  final bool? canPublish;
  final bool? canSubscribe;
  final bool? canPublishData;
  final List<String>? canPublishSources;
  final bool? hidden;
  final bool? recorder;

  const LiveKitVideoGrant({
    this.room,
    this.roomCreate,
    this.roomJoin,
    this.roomList,
    this.roomRecord,
    this.roomAdmin,
    this.canPublish,
    this.canSubscribe,
    this.canPublishData,
    this.canPublishSources,
    this.hidden,
    this.recorder,
  });

  factory LiveKitVideoGrant.fromJson(Map<String, dynamic> json) => LiveKitVideoGrant(
        room: json['room'] as String?,
        roomCreate: json['room_create'] as bool?,
        roomJoin: json['room_join'] as bool?,
        roomList: json['room_list'] as bool?,
        roomRecord: json['room_record'] as bool?,
        roomAdmin: json['room_admin'] as bool?,
        canPublish: json['can_publish'] as bool?,
        canSubscribe: json['can_subscribe'] as bool?,
        canPublishData: json['can_publish_data'] as bool?,
        canPublishSources: (json['can_publish_sources'] as List?)?.map((dynamic item) => item.toString()).toList(),
        hidden: json['hidden'] as bool?,
        recorder: json['recorder'] as bool?,
      );
}

extension TokenSourceJwt on TokenSourceResponse {
  /// Decode the participant token and return the parsed payload, if valid.
  LiveKitJwtPayload? get jwtPayload => LiveKitJwtPayload.fromToken(participantToken);

  /// Returns `true` when the participant token is valid (not expired and past its not-before time).
  ///
  /// [tolerance] allows treating tokens as expired ahead of their actual expiry to avoid edge cases.
  /// [currentTime] is primarily intended for testing; it defaults to the current system time.
  bool hasValidToken({Duration tolerance = const Duration(seconds: 60), DateTime? currentTime}) {
    final payload = jwtPayload;
    if (payload == null) {
      return false;
    }

    final nowUtc = (currentTime ?? DateTime.timestamp()).toUtc();

    final notBefore = payload.notBefore;
    if (notBefore != null && nowUtc.isBefore(notBefore)) {
      return false;
    }

    final expiresAt = payload.expiresAt;
    if (expiresAt == null) {
      return false;
    }

    final comparisonInstant = nowUtc.add(tolerance);
    if (!expiresAt.isAfter(comparisonInstant)) {
      return false;
    }

    return true;
  }
}

/// Extension to extract LiveKit-specific claims from JWT tokens.
extension LiveKitClaims on JWT {
  LiveKitJwtPayload? get _liveKitPayload {
    final claims = payload;
    if (claims is Map<String, dynamic>) {
      return LiveKitJwtPayload.fromClaims(claims);
    }
    if (claims is Map) {
      return LiveKitJwtPayload.fromClaims(Map<String, dynamic>.from(claims));
    }
    return null;
  }

  /// The display name for the participant.
  String? get name => _liveKitPayload?.name;

  /// Custom metadata associated with the participant.
  String? get metadata => _liveKitPayload?.metadata;

  /// Custom attributes for the participant.
  Map<String, String>? get attributes => _liveKitPayload?.attributes;

  /// Video-specific grants embedded in the token.
  LiveKitVideoGrant? get video => _liveKitPayload?.video;
}

/// Validates whether the JWT token in the response is expired or invalid.
///
/// Returns `true` if the token is expired, invalid, or not yet valid (before nbf).
/// Returns `false` if the token is valid and can be used.
///
/// This function checks:
/// - Token validity (can be decoded)
/// - Not-before time (nbf) - token is not yet valid
/// - Expiration time (exp) with configurable tolerance
///
/// A missing expiration field is treated as invalid.
bool isResponseExpired(
  TokenSourceResponse response, {
  Duration tolerance = const Duration(seconds: 60),
  DateTime? currentTime,
}) {
  return !response.hasValidToken(tolerance: tolerance, currentTime: currentTime);
}
