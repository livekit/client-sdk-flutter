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
import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/src/token_source/custom.dart';
import 'package:livekit_client/src/token_source/jwt.dart';
import 'package:livekit_client/src/token_source/literal.dart';
import 'package:livekit_client/src/token_source/room_configuration.dart';
import 'package:livekit_client/src/token_source/token_source.dart';

void main() {
  group('JWT Validation', () {
    test('valid token returns false for isResponseExpired', () {
      final now = DateTime.timestamp();
      final exp = (now.millisecondsSinceEpoch ~/ 1000) + 3600; // +1 hour

      final token = _generateToken(exp: exp);
      final response = TokenSourceResponse(
        serverUrl: 'https://test.livekit.io',
        participantToken: token,
      );

      expect(isResponseExpired(response), isFalse);
    });

    test('expired token returns true for isResponseExpired', () {
      final now = DateTime.timestamp();
      final exp = (now.millisecondsSinceEpoch ~/ 1000) - 3600; // -1 hour

      final token = _generateToken(exp: exp);
      final response = TokenSourceResponse(
        serverUrl: 'https://test.livekit.io',
        participantToken: token,
      );

      expect(isResponseExpired(response), isTrue);
    });

    test('token within 60s tolerance returns true for isResponseExpired', () {
      final now = DateTime.timestamp();
      final exp = (now.millisecondsSinceEpoch ~/ 1000) + 30; // +30 seconds

      final token = _generateToken(exp: exp);
      final response = TokenSourceResponse(
        serverUrl: 'https://test.livekit.io',
        participantToken: token,
      );

      expect(isResponseExpired(response), isTrue);
    });

    test('token before nbf returns true for isResponseExpired', () {
      final now = DateTime.timestamp();
      final nbf = (now.millisecondsSinceEpoch ~/ 1000) + 3600; // +1 hour
      final exp = (now.millisecondsSinceEpoch ~/ 1000) + 7200; // +2 hours

      final token = _generateToken(nbf: nbf, exp: exp);
      final response = TokenSourceResponse(
        serverUrl: 'https://test.livekit.io',
        participantToken: token,
      );

      expect(isResponseExpired(response), isTrue);
    });

    test('token without exp returns true for isResponseExpired', () {
      final token = _generateToken(includeExp: false);
      final response = TokenSourceResponse(
        serverUrl: 'https://test.livekit.io',
        participantToken: token,
      );

      expect(isResponseExpired(response), isTrue);
    });

    test('invalid token returns true for isResponseExpired', () {
      final response = TokenSourceResponse(
        serverUrl: 'https://test.livekit.io',
        participantToken: 'invalid.token.here',
      );

      expect(isResponseExpired(response), isTrue);
    });
  });

  group('LiteralTokenSource', () {
    test('returns fixed response', () async {
      final source = LiteralTokenSource(
        serverUrl: 'https://test.livekit.io',
        participantToken: 'test-token',
        participantName: 'test-participant',
        roomName: 'test-room',
      );

      final result = await source.fetch();

      expect(result.serverUrl, 'https://test.livekit.io');
      expect(result.participantToken, 'test-token');
      expect(result.participantName, 'test-participant');
      expect(result.roomName, 'test-room');
    });

    test('returns fixed response with minimal parameters', () async {
      final source = LiteralTokenSource(
        serverUrl: 'https://test.livekit.io',
        participantToken: 'test-token',
      );

      final result = await source.fetch();

      expect(result.serverUrl, 'https://test.livekit.io');
      expect(result.participantToken, 'test-token');
      expect(result.participantName, isNull);
      expect(result.roomName, isNull);
    });
  });

  group('CustomTokenSource', () {
    test('calls custom function with options', () async {
      Future<TokenSourceResponse> customFunction(TokenRequestOptions options) async {
        return TokenSourceResponse(
          serverUrl: 'https://custom.livekit.io',
          participantToken: 'custom-token',
          participantName: options.participantName,
          roomName: options.roomName,
        );
      }

      final source = CustomTokenSource(customFunction);
      final result = await source.fetch(const TokenRequestOptions(
        participantName: 'custom-participant',
        roomName: 'custom-room',
      ));

      expect(result.serverUrl, 'https://custom.livekit.io');
      expect(result.participantToken, 'custom-token');
      expect(result.participantName, 'custom-participant');
      expect(result.roomName, 'custom-room');
    });

    test('handles null options', () async {
      Future<TokenSourceResponse> customFunction(TokenRequestOptions options) async {
        return const TokenSourceResponse(
          serverUrl: 'https://custom.livekit.io',
          participantToken: 'custom-token',
        );
      }

      final source = CustomTokenSource(customFunction);
      final result = await source.fetch();

      expect(result.serverUrl, 'https://custom.livekit.io');
      expect(result.participantToken, 'custom-token');
    });
  });

  group('TokenRequestOptions', () {
    test('toRequest().toJson() includes agentName and agentMetadata in room_config.agents', () {
      const options = TokenRequestOptions(
        roomName: 'test-room',
        participantName: 'test-participant',
        agentName: 'test-agent',
        agentMetadata: '{"key":"value"}',
      );

      final json = options.toRequest().toJson();

      expect(json['room_name'], 'test-room');
      expect(json['participant_name'], 'test-participant');
      expect(json['room_config'], isNotNull);
      expect(json['room_config']['agents'], isNotNull);
      expect(json['room_config']['agents'], isList);
      expect((json['room_config']['agents'] as List).length, 1);
      expect((json['room_config']['agents'] as List)[0]['agent_name'], 'test-agent');
      expect((json['room_config']['agents'] as List)[0]['metadata'], '{"key":"value"}');
    });

    test('toRequest().toJson() wraps only agentName in room_config.agents', () {
      const options = TokenRequestOptions(
        agentName: 'test-agent',
      );

      final json = options.toRequest().toJson();

      expect(json['room_config'], isNotNull);
      expect(json['room_config']['agents'], isNotNull);
      expect((json['room_config']['agents'] as List).length, 1);
      expect((json['room_config']['agents'] as List)[0]['agent_name'], 'test-agent');
      expect((json['room_config']['agents'] as List)[0].containsKey('metadata'), isFalse);
    });

    test('toRequest().toJson() wraps only agentMetadata in room_config.agents', () {
      const options = TokenRequestOptions(
        agentMetadata: '{"key":"value"}',
      );

      final json = options.toRequest().toJson();

      expect(json['room_config'], isNotNull);
      expect(json['room_config']['agents'], isNotNull);
      expect((json['room_config']['agents'] as List).length, 1);
      expect((json['room_config']['agents'] as List)[0].containsKey('agent_name'), isFalse);
      expect((json['room_config']['agents'] as List)[0]['metadata'], '{"key":"value"}');
    });
  });

  group('TokenSourceRequest', () {
    test('toRequest() wraps agentName and agentMetadata in room_config.agents', () {
      const options = TokenRequestOptions(
        roomName: 'test-room',
        participantName: 'test-participant',
        agentName: 'test-agent',
        agentMetadata: '{"key":"value"}',
      );

      final request = options.toRequest();

      expect(request.roomName, 'test-room');
      expect(request.participantName, 'test-participant');
      expect(request.roomConfiguration, isNotNull);
      expect(request.roomConfiguration!.agents, isNotNull);
      expect(request.roomConfiguration!.agents!.length, 1);
      expect(request.roomConfiguration!.agents![0].agentName, 'test-agent');
      expect(request.roomConfiguration!.agents![0].metadata, '{"key":"value"}');
    });

    test('toRequest() creates null roomConfiguration when no agent fields', () {
      const options = TokenRequestOptions(
        roomName: 'test-room',
        participantName: 'test-participant',
      );

      final request = options.toRequest();

      expect(request.roomName, 'test-room');
      expect(request.participantName, 'test-participant');
      expect(request.roomConfiguration, isNull);
    });

    test('TokenSourceRequest.toJson() produces correct wire format', () {
      final request = TokenSourceRequest(
        roomName: 'test-room',
        participantName: 'test-participant',
        participantIdentity: 'test-identity',
        participantMetadata: 'test-metadata',
        participantAttributes: {'key1': 'value1'},
        roomConfiguration: const RoomConfiguration(
          agents: [
            RoomAgentDispatch(
              agentName: 'test-agent',
              metadata: '{"key":"value"}',
            ),
          ],
        ),
      );

      final json = request.toJson();

      expect(json['room_name'], 'test-room');
      expect(json['participant_name'], 'test-participant');
      expect(json['participant_identity'], 'test-identity');
      expect(json['participant_metadata'], 'test-metadata');
      expect(json['participant_attributes'], {'key1': 'value1'});
      expect(json['room_config'], isNotNull);
      expect(json['room_config']['agents'], isNotNull);
      expect((json['room_config']['agents'] as List).length, 1);
      expect((json['room_config']['agents'] as List)[0]['agent_name'], 'test-agent');
      expect((json['room_config']['agents'] as List)[0]['metadata'], '{"key":"value"}');
    });

    test('TokenSourceRequest.toJson() only includes non-null fields', () {
      const request = TokenSourceRequest(
        roomName: 'test-room',
      );

      final json = request.toJson();

      expect(json.containsKey('room_name'), isTrue);
      expect(json.containsKey('participant_name'), isFalse);
      expect(json.containsKey('participant_identity'), isFalse);
      expect(json.containsKey('participant_metadata'), isFalse);
      expect(json.containsKey('participant_attributes'), isFalse);
      expect(json.containsKey('room_config'), isFalse);
    });

    test('toRequest() preserves all fields', () {
      const options = TokenRequestOptions(
        roomName: 'test-room',
        participantName: 'test-participant',
        participantIdentity: 'test-identity',
        participantMetadata: 'test-metadata',
        participantAttributes: {'key1': 'value1', 'key2': 'value2'},
      );

      final request = options.toRequest();

      expect(request.roomName, 'test-room');
      expect(request.participantName, 'test-participant');
      expect(request.participantIdentity, 'test-identity');
      expect(request.participantMetadata, 'test-metadata');
      expect(request.participantAttributes, {'key1': 'value1', 'key2': 'value2'});
    });
  });
}

String _generateToken({int? nbf, int? exp, bool includeExp = true}) {
  final payload = <String, dynamic>{
    'sub': 'test-participant',
    'video': {'room': 'test-room', 'roomJoin': true},
  };

  if (nbf != null) {
    payload['nbf'] = nbf;
  }

  if (includeExp && exp != null) {
    payload['exp'] = exp;
  }

  final jwt = JWT(payload);
  return jwt.sign(SecretKey('test-secret'));
}
