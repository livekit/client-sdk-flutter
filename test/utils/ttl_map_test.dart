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

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/src/utils/ttl_map.dart';

void main() {
  group('TTLMap', () {
    test('should store and retrieve values', () {
      final map = TTLMap<String, int>(5000);

      map.set('key1', 100);
      map.set('key2', 200);

      expect(map.get('key1'), equals(100));
      expect(map.get('key2'), equals(200));
      expect(map.has('key1'), isTrue);
      expect(map.has('key2'), isTrue);

      map.dispose();
    });

    test('should return null for non-existent keys', () {
      final map = TTLMap<String, int>(5000);

      expect(map.get('nonexistent'), isNull);
      expect(map.has('nonexistent'), isFalse);

      map.dispose();
    });

    test('should delete values', () {
      final map = TTLMap<String, int>(5000);

      map.set('key1', 100);
      expect(map.has('key1'), isTrue);

      map.delete('key1');
      expect(map.has('key1'), isFalse);
      expect(map.get('key1'), isNull);

      map.dispose();
    });

    test('should clear all values', () {
      final map = TTLMap<String, int>(5000);

      map.set('key1', 100);
      map.set('key2', 200);
      expect(map.has('key1'), isTrue);
      expect(map.has('key2'), isTrue);

      map.clear();
      expect(map.has('key1'), isFalse);
      expect(map.has('key2'), isFalse);

      map.dispose();
    });

    test('should return keys', () {
      final map = TTLMap<String, int>(5000);

      map.set('key1', 100);
      map.set('key2', 200);
      map.set('key3', 300);

      final keys = map.keys.toSet();
      expect(keys, equals({'key1', 'key2', 'key3'}));

      map.dispose();
    });

    test('should expire values after TTL', () async {
      final map = TTLMap<String, int>(100); // 100ms TTL

      map.set('key1', 100);
      expect(map.has('key1'), isTrue);

      // Wait for expiry
      await Future.delayed(const Duration(milliseconds: 150));

      expect(map.has('key1'), isFalse);
      expect(map.get('key1'), isNull);

      map.dispose();
    });

    test('should not expire values before TTL', () async {
      final map = TTLMap<String, int>(200); // 200ms TTL

      map.set('key1', 100);
      expect(map.has('key1'), isTrue);

      // Wait less than TTL
      await Future.delayed(const Duration(milliseconds: 50));

      expect(map.has('key1'), isTrue);
      expect(map.get('key1'), equals(100));

      map.dispose();
    });

    test('should handle concurrent access', () {
      final map = TTLMap<String, int>(5000);

      // Simulate concurrent access
      for (int i = 0; i < 100; i++) {
        map.set('key$i', i);
      }

      for (int i = 0; i < 100; i++) {
        expect(map.get('key$i'), equals(i));
      }

      map.dispose();
    });

    test('should cleanup expired entries automatically', () async {
      final map = TTLMap<String, int>(50); // Very short TTL

      // Add multiple entries
      for (int i = 0; i < 10; i++) {
        map.set('key$i', i);
      }

      // All should be present initially
      for (int i = 0; i < 10; i++) {
        expect(map.has('key$i'), isTrue);
      }

      // Wait for cleanup cycle (TTL/2 + some buffer)
      await Future.delayed(const Duration(milliseconds: 100));

      // All should be expired and cleaned up
      for (int i = 0; i < 10; i++) {
        expect(map.has('key$i'), isFalse);
      }

      map.dispose();
    });

    test('should update existing keys', () {
      final map = TTLMap<String, int>(5000);

      map.set('key1', 100);
      expect(map.get('key1'), equals(100));

      map.set('key1', 200);
      expect(map.get('key1'), equals(200));

      map.dispose();
    });

    test('should handle different value types', () {
      final stringMap = TTLMap<String, String>(5000);
      final listMap = TTLMap<String, List<int>>(5000);

      stringMap.set('text', 'hello world');
      listMap.set('numbers', [1, 2, 3, 4, 5]);

      expect(stringMap.get('text'), equals('hello world'));
      expect(listMap.get('numbers'), equals([1, 2, 3, 4, 5]));

      stringMap.dispose();
      listMap.dispose();
    });

    test('should dispose cleanly', () {
      final map = TTLMap<String, int>(5000);

      map.set('key1', 100);
      expect(map.has('key1'), isTrue);

      map.dispose();

      // After dispose, map should be empty
      expect(map.has('key1'), isFalse);
      expect(map.get('key1'), isNull);
    });

    test('should handle keys property correctly', () {
      final map = TTLMap<String, int>(5000);

      expect(map.keys.isEmpty, isTrue);

      map.set('key1', 100);
      expect(map.keys.length, equals(1));
      expect(map.keys, contains('key1'));

      map.set('key2', 200);
      expect(map.keys.length, equals(2));
      expect(map.keys, containsAll(['key1', 'key2']));

      map.delete('key1');
      expect(map.keys.length, equals(1));
      expect(map.keys, contains('key2'));
      expect(map.keys, isNot(contains('key1')));

      map.clear();
      expect(map.keys.isEmpty, isTrue);

      map.dispose();
    });

    test('should handle size property correctly', () {
      final map = TTLMap<String, int>(5000);

      expect(map.size, equals(0));

      map.set('key1', 100);
      expect(map.size, equals(1));

      map.set('key2', 200);
      expect(map.size, equals(2));

      map.set('key3', 300);
      expect(map.size, equals(3));

      map.delete('key1');
      expect(map.size, equals(2));

      map.clear();
      expect(map.size, equals(0));

      map.dispose();
    });

    test('should handle key iteration', () {
      final map = TTLMap<String, int>(5000);

      map.set('key1', 100);
      map.set('key2', 200);
      map.set('key3', 300);

      final collectedKeys = <String>[];
      for (final key in map.keys) {
        collectedKeys.add(key);
      }

      expect(collectedKeys.length, equals(3));
      expect(collectedKeys, containsAll(['key1', 'key2', 'key3']));

      map.dispose();
    });

    test('should handle null values correctly', () {
      final map = TTLMap<String, String?>(5000);

      map.set('nullKey', null);
      expect(map.has('nullKey'), isTrue);
      expect(map.get('nullKey'), isNull);

      // Different from non-existent key
      expect(map.has('nonExistent'), isFalse);

      map.dispose();
    });

    test('should handle stress test with rapid operations', () {
      final map = TTLMap<String, int>(10000);

      // Rapid set/get operations
      for (int i = 0; i < 1000; i++) {
        map.set('stress$i', i);
        expect(map.get('stress$i'), equals(i));
      }

      expect(map.size, equals(1000));

      map.dispose();
    });

    test('should update size correctly during TTL expiration', () async {
      final map = TTLMap<String, int>(100); // 100ms TTL

      // Start with empty map
      expect(map.size, equals(0));

      // Add some entries
      map.set('key1', 100);
      map.set('key2', 200);
      map.set('key3', 300);
      expect(map.size, equals(3));

      // Wait for expiry
      await Future.delayed(const Duration(milliseconds: 150));

      // Size should be updated after accessing expired entries
      expect(map.has('key1'), isFalse); // This triggers cleanup
      expect(map.size, equals(0));

      map.dispose();
    });
  });
}
