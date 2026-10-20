// Copyright 2026 LiveKit, Inc.
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

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'package:livekit_client/livekit_client.dart';
import '../mock/e2ee_fake_manager.dart';

BaseKeyProvider _keyProvider({required bool sharedKey}) => BaseKeyProvider(
  TestKeyProvider(),
  rtc.KeyProviderOptions(
    sharedKey: sharedKey,
    ratchetSalt: Uint8List(16),
    ratchetWindowSize: 16,
    keyRingSize: 16,
    failureTolerance: -1,
    discardFrameWhenCryptorNotReady: false,
  ),
);

void main() {
  group('shared key mode', () {
    test('defaults to index 0 before any key is set', () {
      final keyProvider = _keyProvider(sharedKey: true);
      expect(keyProvider.getLatestIndex('alice'), 0);
    });

    test('setSharedKey moves the index used for every participant', () async {
      final keyProvider = _keyProvider(sharedKey: true);
      await keyProvider.setSharedKey('key', keyIndex: 5);
      expect(keyProvider.getLatestIndex('alice'), 5);
      expect(keyProvider.getLatestIndex('bob'), 5);
    });

    test('setKey and setRawKey move the shared index', () async {
      final keyProvider = _keyProvider(sharedKey: true);
      await keyProvider.setKey('key', keyIndex: 3);
      expect(keyProvider.getLatestIndex('alice'), 3);
      await keyProvider.setRawKey(Uint8List.fromList('key'.codeUnits), keyIndex: 7);
      expect(keyProvider.getLatestIndex('alice'), 7);
    });

    test('setSharedKey without an index goes back to index 0', () async {
      final keyProvider = _keyProvider(sharedKey: true);
      await keyProvider.setSharedKey('key', keyIndex: 5);
      await keyProvider.setSharedKey('key');
      expect(keyProvider.getLatestIndex('alice'), 0);
    });
  });

  group('per-participant key mode', () {
    test('tracks the index per participant', () async {
      final keyProvider = _keyProvider(sharedKey: false);
      await keyProvider.setKey('key', participantId: 'alice', keyIndex: 2);
      expect(keyProvider.getLatestIndex('alice'), 2);
      expect(keyProvider.getLatestIndex('bob'), 0);
    });
  });
}
