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

import 'package:livekit_client/src/token_source/caching.dart';
import 'package:livekit_client/src/token_source/token_source.dart';

void main() {
  group('CachingTokenSource', () {
    test('caches valid token and reuses it', () async {
      var fetchCount = 0;
      final mockSource = _MockTokenSource((options) async {
        fetchCount++;
        final token = _generateValidToken();
        return TokenSourceResponse(
          serverUrl: 'https://test.livekit.io',
          participantToken: token,
        );
      });

      final cachingSource = CachingTokenSource(mockSource);

      // First fetch
      final result1 = await cachingSource.fetch(const TokenRequestOptions());
      expect(fetchCount, 1);

      // Second fetch should use cache
      final result2 = await cachingSource.fetch(const TokenRequestOptions());
      expect(fetchCount, 1);
      expect(result2.participantToken, result1.participantToken);
    });

    test('refetches when token is expired', () async {
      var fetchCount = 0;
      final mockSource = _MockTokenSource((options) async {
        fetchCount++;
        final token = fetchCount == 1 ? _generateExpiredToken() : _generateValidToken();
        return TokenSourceResponse(
          serverUrl: 'https://test.livekit.io',
          participantToken: token,
        );
      });

      final cachingSource = CachingTokenSource(mockSource);

      // First fetch with expired token
      await cachingSource.fetch(const TokenRequestOptions());
      expect(fetchCount, 1);

      // Second fetch should refetch due to expiration
      await cachingSource.fetch(const TokenRequestOptions());
      expect(fetchCount, 2);
    });

    test('refetches when options change', () async {
      var fetchCount = 0;
      final mockSource = _MockTokenSource((options) async {
        fetchCount++;
        final token = _generateValidToken();
        return TokenSourceResponse(
          serverUrl: 'https://test.livekit.io',
          participantToken: token,
        );
      });

      final cachingSource = CachingTokenSource(mockSource);

      // First fetch with initial options
      await cachingSource.fetch(const TokenRequestOptions(roomName: 'room1'));
      expect(fetchCount, 1);

      // Fetch with same options should use cache
      await cachingSource.fetch(const TokenRequestOptions(roomName: 'room1'));
      expect(fetchCount, 1);

      // Fetch with different options should refetch
      await cachingSource.fetch(const TokenRequestOptions(roomName: 'room2'));
      expect(fetchCount, 2);
    });

    test('refetches when participant metadata changes', () async {
      var fetchCount = 0;
      final mockSource = _MockTokenSource((options) async {
        fetchCount++;
        final token = _generateValidToken();
        return TokenSourceResponse(
          serverUrl: 'https://test.livekit.io',
          participantToken: token,
        );
      });

      final cachingSource = CachingTokenSource(mockSource);

      await cachingSource.fetch(const TokenRequestOptions(participantMetadata: 'meta1'));
      expect(fetchCount, 1);

      await cachingSource.fetch(const TokenRequestOptions(participantMetadata: 'meta2'));
      expect(fetchCount, 2);
    });

    test('refetches when participant attributes change', () async {
      var fetchCount = 0;
      final mockSource = _MockTokenSource((options) async {
        fetchCount++;
        final token = _generateValidToken();
        return TokenSourceResponse(
          serverUrl: 'https://test.livekit.io',
          participantToken: token,
        );
      });

      final cachingSource = CachingTokenSource(mockSource);

      await cachingSource.fetch(const TokenRequestOptions(
        participantAttributes: {'key1': 'value1'},
      ));
      expect(fetchCount, 1);

      await cachingSource.fetch(const TokenRequestOptions(
        participantAttributes: {'key1': 'value2'},
      ));
      expect(fetchCount, 2);
    });

    test('refetches when agentName changes', () async {
      var fetchCount = 0;
      final mockSource = _MockTokenSource((options) async {
        fetchCount++;
        final token = _generateValidToken();
        return TokenSourceResponse(
          serverUrl: 'https://test.livekit.io',
          participantToken: token,
        );
      });

      final cachingSource = CachingTokenSource(mockSource);

      await cachingSource.fetch(const TokenRequestOptions(agentName: 'agent1'));
      expect(fetchCount, 1);

      await cachingSource.fetch(const TokenRequestOptions(agentName: 'agent2'));
      expect(fetchCount, 2);
    });

    test('refetches when agentMetadata changes', () async {
      var fetchCount = 0;
      final mockSource = _MockTokenSource((options) async {
        fetchCount++;
        final token = _generateValidToken();
        return TokenSourceResponse(
          serverUrl: 'https://test.livekit.io',
          participantToken: token,
        );
      });

      final cachingSource = CachingTokenSource(mockSource);

      await cachingSource.fetch(const TokenRequestOptions(agentMetadata: 'meta1'));
      expect(fetchCount, 1);

      await cachingSource.fetch(const TokenRequestOptions(agentMetadata: 'meta2'));
      expect(fetchCount, 2);
    });

    test('handles concurrent fetches with single request', () async {
      var fetchCount = 0;
      final mockSource = _MockTokenSource((options) async {
        fetchCount++;
        await Future.delayed(Duration(milliseconds: 100));
        final token = _generateValidToken();
        return TokenSourceResponse(
          serverUrl: 'https://test.livekit.io',
          participantToken: token,
        );
      });

      final cachingSource = CachingTokenSource(mockSource);

      // Start multiple concurrent fetches
      final futures = List.generate(5, (_) => cachingSource.fetch(const TokenRequestOptions()));
      final results = await Future.wait(futures);

      // Should only fetch once despite concurrent requests
      expect(fetchCount, 1);
      expect(results.every((r) => r.participantToken == results.first.participantToken), isTrue);
    });

    test('concurrent fetches with different options fetch independently', () async {
      var fetchCount = 0;
      final mockSource = _MockTokenSource((options) async {
        fetchCount++;
        await Future.delayed(Duration(milliseconds: 50));
        final token = _generateValidToken();
        return TokenSourceResponse(
          serverUrl: 'https://test.livekit.io',
          participantToken: '$token-${options.roomName}',
        );
      });

      final cachingSource = CachingTokenSource(mockSource);

      final futureOne = cachingSource.fetch(const TokenRequestOptions(roomName: 'room-a'));
      final futureTwo = cachingSource.fetch(const TokenRequestOptions(roomName: 'room-b'));

      final responses = await Future.wait([futureOne, futureTwo]);

      expect(fetchCount, 2);
      expect(responses[0].participantToken == responses[1].participantToken, isFalse);
    });

    test('invalidate clears cache', () async {
      var fetchCount = 0;
      final mockSource = _MockTokenSource((options) async {
        fetchCount++;
        final token = _generateValidToken();
        return TokenSourceResponse(
          serverUrl: 'https://test.livekit.io',
          participantToken: token,
        );
      });

      final cachingSource = CachingTokenSource(mockSource);

      await cachingSource.fetch(const TokenRequestOptions());
      expect(fetchCount, 1);

      // Invalidate cache
      await cachingSource.invalidate();

      // Should refetch after invalidation
      await cachingSource.fetch(const TokenRequestOptions());
      expect(fetchCount, 2);
    });

    test('cachedResponse returns current cached response', () async {
      final mockSource = _MockTokenSource((options) async {
        final token = _generateValidToken();
        return TokenSourceResponse(
          serverUrl: 'https://test.livekit.io',
          participantToken: token,
        );
      });

      final cachingSource = CachingTokenSource(mockSource);

      expect(await cachingSource.cachedResponse(), isNull);

      final response = await cachingSource.fetch(const TokenRequestOptions());
      expect(await cachingSource.cachedResponse(), isNotNull);
      expect((await cachingSource.cachedResponse())?.participantToken, response.participantToken);

      await cachingSource.invalidate();
      expect(await cachingSource.cachedResponse(), isNull);
    });

    test('custom validator is respected', () async {
      var fetchCount = 0;
      final mockSource = _MockTokenSource((options) async {
        fetchCount++;
        final token = _generateValidToken();
        return TokenSourceResponse(
          serverUrl: 'https://test.livekit.io',
          participantToken: token,
        );
      });

      // Custom validator that only caches when participantName is 'charlie'
      bool customValidator(TokenRequestOptions? options, TokenSourceResponse response) {
        return options?.participantName == 'charlie' && response.participantToken.isNotEmpty;
      }

      final cachingSource = CachingTokenSource(
        mockSource,
        validator: customValidator,
      );

      // First fetch with matching validator
      const charlieOptions = TokenRequestOptions(
        roomName: 'test-room',
        participantName: 'charlie',
      );
      final result1 = await cachingSource.fetch(charlieOptions);
      expect(fetchCount, 1);

      // Second fetch with same options should use cache (validator returns true)
      final result2 = await cachingSource.fetch(charlieOptions);
      expect(fetchCount, 1);
      expect(result2.participantToken, result1.participantToken);

      // Fetch with different participantName should refetch (validator returns false)
      const aliceOptions = TokenRequestOptions(
        roomName: 'test-room',
        participantName: 'alice',
      );
      await cachingSource.fetch(aliceOptions);
      expect(fetchCount, 2);

      // Fetch again with alice should refetch again (validator always returns false for alice)
      await cachingSource.fetch(aliceOptions);
      expect(fetchCount, 3);
    });

    test('cached extension creates CachingTokenSource', () {
      final mockSource = _MockTokenSource((options) async {
        return TokenSourceResponse(
          serverUrl: 'https://test.livekit.io',
          participantToken: _generateValidToken(),
        );
      });

      final cachedSource = mockSource.cached();
      expect(cachedSource, isA<CachingTokenSource>());
    });
  });
}

class _MockTokenSource implements TokenSourceConfigurable {
  final Future<TokenSourceResponse> Function(TokenRequestOptions options) _fetchFn;

  _MockTokenSource(this._fetchFn);

  @override
  Future<TokenSourceResponse> fetch(TokenRequestOptions options) => _fetchFn(options);
}

String _generateValidToken() {
  final now = DateTime.timestamp();
  final exp = (now.millisecondsSinceEpoch ~/ 1000) + 3600; // +1 hour

  final payload = {
    'sub': 'test-participant',
    'video': {'room': 'test-room', 'roomJoin': true},
    'exp': exp,
  };

  final jwt = JWT(payload);
  return jwt.sign(SecretKey('test-secret'));
}

String _generateExpiredToken() {
  final now = DateTime.timestamp();
  final exp = (now.millisecondsSinceEpoch ~/ 1000) - 3600; // -1 hour

  final payload = {
    'sub': 'test-participant',
    'video': {'room': 'test-room', 'roomJoin': true},
    'exp': exp,
  };

  final jwt = JWT(payload);
  return jwt.sign(SecretKey('test-secret'));
}
