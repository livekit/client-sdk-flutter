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

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:livekit_client/src/token_source/endpoint.dart';
import 'package:livekit_client/src/token_source/room_configuration.dart';
import 'package:livekit_client/src/token_source/token_source.dart';

void main() {
  group('EndpointTokenSource HTTP Tests', () {
    test('POST endpoint with agentName and agentMetadata in room_config.agents', () async {
      http.Request? capturedRequest;

      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'server_url': 'wss://www.example.com',
            'room_name': 'room-name',
            'participant_name': 'participant-name',
            'participant_token': 'token',
          }),
          200,
        );
      });

      final source = EndpointTokenSource(
        url: Uri.parse('https://example.com/token'),
        method: 'POST',
        headers: {'hello': 'world'},
        client: mockClient,
      );

      const options = TokenRequestOptions(
        roomName: 'room-name',
        participantName: 'participant-name',
        participantIdentity: 'participant-identity',
        participantMetadata: 'participant-metadata',
        agentName: 'agent-name',
        agentMetadata: 'agent-metadata',
      );

      final response = await source.fetch(options);

      expect(response.serverUrl, 'wss://www.example.com');
      expect(response.participantToken, 'token');
      expect(response.participantName, 'participant-name');
      expect(response.roomName, 'room-name');

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.method, 'POST');
      expect(capturedRequest!.headers['hello'], 'world');
      expect(capturedRequest!.headers['Content-Type'], contains('application/json'));

      final requestBody = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;

      expect(requestBody['room_name'], 'room-name');
      expect(requestBody['participant_name'], 'participant-name');
      expect(requestBody['participant_identity'], 'participant-identity');
      expect(requestBody['participant_metadata'], 'participant-metadata');

      expect(requestBody['room_config'], isNotNull);
      expect(requestBody['room_config']['agents'], isList);

      final agents = requestBody['room_config']['agents'] as List;
      expect(agents.length, 1);
      expect(agents[0]['agent_name'], 'agent-name');
      expect(agents[0]['metadata'], 'agent-metadata');
    });

    test('GET endpoint with body', () async {
      http.Request? capturedRequest;

      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'server_url': 'wss://www.example.com',
            'participant_token': 'token',
          }),
          200,
        );
      });

      final source = EndpointTokenSource(
        url: Uri.parse('https://example.com/token'),
        method: 'GET',
        client: mockClient,
      );

      final response = await source.fetch(const TokenRequestOptions());

      expect(response.serverUrl, 'wss://www.example.com');
      expect(response.participantToken, 'token');

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.method, 'GET');
      // Body is always sent even for GET requests
      expect(capturedRequest!.body, '{"room_config":{}}');
    });

    test('accepts non-200 success responses', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'server_url': 'wss://www.example.com',
            'participant_token': 'token',
          }),
          201,
        );
      });

      final source = EndpointTokenSource(
        url: Uri.parse('https://example.com/token'),
        client: mockClient,
      );

      final response = await source.fetch(const TokenRequestOptions());

      expect(response.serverUrl, 'wss://www.example.com');
      expect(response.participantToken, 'token');
    });

    test('camelCase backward compatibility', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'serverUrl': 'wss://www.example.com',
            'roomName': 'room-name',
            'participantName': 'participant-name',
            'participantToken': 'token',
          }),
          200,
        );
      });

      final source = EndpointTokenSource(
        url: Uri.parse('https://example.com/token'),
        client: mockClient,
      );

      final response = await source.fetch(const TokenRequestOptions());

      expect(response.serverUrl, 'wss://www.example.com');
      expect(response.participantToken, 'token');
      expect(response.participantName, 'participant-name');
      expect(response.roomName, 'room-name');
    });

    test('missing optional keys default to null', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'server_url': 'wss://www.example.com',
            'participant_token': 'token',
          }),
          200,
        );
      });

      final source = EndpointTokenSource(
        url: Uri.parse('https://example.com/token'),
        client: mockClient,
      );

      final response = await source.fetch(const TokenRequestOptions());

      expect(response.serverUrl, 'wss://www.example.com');
      expect(response.participantToken, 'token');
      expect(response.participantName, isNull);
      expect(response.roomName, isNull);
    });

    test('error response throws structured exception', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final source = EndpointTokenSource(
        url: Uri.parse('https://example.com/token'),
        client: mockClient,
      );

      expect(
        () => source.fetch(const TokenRequestOptions()),
        throwsA(
          isA<TokenSourceHttpException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.body, 'body', 'Not Found')
              .having((e) => e.uri.toString(), 'uri', 'https://example.com/token'),
        ),
      );
    });

    test('server error response throws structured exception', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final source = EndpointTokenSource(
        url: Uri.parse('https://example.com/token'),
        client: mockClient,
      );

      expect(
        () => source.fetch(const TokenRequestOptions()),
        throwsA(
          isA<TokenSourceHttpException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.body, 'body', 'Internal Server Error'),
        ),
      );
    });
  });

  group('TokenRequestOptions Serialization', () {
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

    test('includes participant attributes', () {
      const options = TokenRequestOptions(
        participantAttributes: {
          'key1': 'value1',
          'key2': 'value2',
        },
      );

      final json = options.toRequest().toJson();

      expect(json['participant_attributes'], isMap);
      expect(json['participant_attributes']['key1'], 'value1');
      expect(json['participant_attributes']['key2'], 'value2');
    });

    test('handles empty options', () {
      const options = TokenRequestOptions();

      final json = options.toRequest().toJson();

      expect(json.keys, contains('room_config'));
      expect(json['room_config'], isMap);
      expect((json['room_config'] as Map), isEmpty);
    });

    test('only includes non-null fields', () {
      const options = TokenRequestOptions(
        roomName: 'test-room',
        participantName: null,
        participantIdentity: 'test-identity',
      );

      final json = options.toRequest().toJson();

      expect(json.containsKey('room_name'), isTrue);
      expect(json.containsKey('participant_name'), isFalse);
      expect(json.containsKey('participant_identity'), isTrue);
      expect(json.containsKey('room_config'), isTrue);
      expect((json['room_config'] as Map), isEmpty);
    });
  });

  group('TokenSourceResponse', () {
    test('fromJson parses all fields', () {
      final json = {
        'server_url': 'https://test.livekit.io',
        'participant_token': 'test-token',
        'participant_name': 'test-participant',
        'room_name': 'test-room',
      };

      final response = TokenSourceResponse.fromJson(json);

      expect(response.serverUrl, 'https://test.livekit.io');
      expect(response.participantToken, 'test-token');
      expect(response.participantName, 'test-participant');
      expect(response.roomName, 'test-room');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'server_url': 'https://test.livekit.io',
        'participant_token': 'test-token',
      };

      final response = TokenSourceResponse.fromJson(json);

      expect(response.serverUrl, 'https://test.livekit.io');
      expect(response.participantToken, 'test-token');
      expect(response.participantName, isNull);
      expect(response.roomName, isNull);
    });
  });

  group('RoomConfiguration', () {
    test('toJson includes all fields', () {
      const config = RoomConfiguration(
        name: 'test-room',
        emptyTimeout: 300,
        departureTimeout: 60,
        maxParticipants: 10,
        metadata: 'test-metadata',
        minPlayoutDelay: 100,
        maxPlayoutDelay: 500,
        syncStreams: true,
        agents: [
          RoomAgentDispatch(
            agentName: 'test-agent',
            metadata: '{"key":"value"}',
          ),
        ],
      );

      final json = config.toJson();

      expect(json['name'], 'test-room');
      expect(json['empty_timeout'], 300);
      expect(json['departure_timeout'], 60);
      expect(json['max_participants'], 10);
      expect(json['metadata'], 'test-metadata');
      expect(json['min_playout_delay'], 100);
      expect(json['max_playout_delay'], 500);
      expect(json['sync_streams'], true);
      expect(json['agents'], isList);
      expect((json['agents'] as List).length, 1);
    });

    test('toJson only includes non-null fields', () {
      const config = RoomConfiguration(
        name: 'test-room',
        maxParticipants: 10,
      );

      final json = config.toJson();

      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('max_participants'), isTrue);
      expect(json.containsKey('empty_timeout'), isFalse);
      expect(json.containsKey('departure_timeout'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
      expect(json.containsKey('min_playout_delay'), isFalse);
      expect(json.containsKey('max_playout_delay'), isFalse);
      expect(json.containsKey('sync_streams'), isFalse);
      expect(json.containsKey('agents'), isFalse);
    });
  });

  group('RoomAgentDispatch', () {
    test('toJson includes all fields', () {
      const dispatch = RoomAgentDispatch(
        agentName: 'test-agent',
        metadata: '{"key":"value"}',
      );

      final json = dispatch.toJson();

      expect(json['agent_name'], 'test-agent');
      expect(json['metadata'], '{"key":"value"}');
    });

    test('toJson only includes non-null fields', () {
      const dispatch = RoomAgentDispatch(
        agentName: 'test-agent',
      );

      final json = dispatch.toJson();

      expect(json.containsKey('agent_name'), isTrue);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('toJson handles both fields as null', () {
      const dispatch = RoomAgentDispatch();

      final json = dispatch.toJson();

      expect(json.isEmpty, isTrue);
    });
  });
}
