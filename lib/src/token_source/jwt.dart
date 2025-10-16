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

/// Extension to extract LiveKit-specific claims from JWT tokens.
extension LiveKitClaims on JWT {
  /// The display name for the participant.
  String? get name => payload['name'] as String?;

  /// Custom metadata associated with the participant.
  String? get metadata => payload['metadata'] as String?;

  /// Custom attributes for the participant.
  Map<String, String>? get attributes {
    final attrs = payload['attributes'];
    return attrs != null ? Map<String, String>.from(attrs as Map) : null;
  }
}

/// Validates whether the JWT token in the response is expired or invalid.
///
/// Returns `true` if the token is expired, invalid, or not yet valid (before nbf).
/// Returns `false` if the token is valid and can be used.
///
/// This function checks:
/// - Token validity (can be decoded)
/// - Not-before time (nbf) - token is not yet valid
/// - Expiration time (exp) with 60 second tolerance
///
/// A missing expiration field is treated as invalid.
bool isResponseExpired(TokenSourceResponse response) {
  try {
    final jwt = JWT.decode(response.participantToken);
    final payload = jwt.payload as Map<String, dynamic>;

    final now = DateTime.timestamp();

    // Check notBefore (nbf) - token not yet valid
    final nbf = payload['nbf'] as int?;
    if (nbf != null) {
      final nbfTime = DateTime.fromMillisecondsSinceEpoch(nbf * 1000, isUtc: true);
      if (now.isBefore(nbfTime)) return true;
    }

    // Check expiration (exp) with 60 second tolerance
    final exp = payload['exp'] as int?;
    if (exp == null) return true; // Missing exp = invalid
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000 - 60000, isUtc: true);

    return now.isAfter(expiresAt);
  } on JWTException {
    return true; // Invalid token = expired
  }
}
