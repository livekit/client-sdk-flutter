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

import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'package:livekit_client/livekit_client.dart';

class TestKeyProvider implements rtc.KeyProvider {
  TestKeyProvider({this.id = 'test-key-provider'});

  @override
  final String id;

  Uint8List? _sharedKey;
  final Map<String, Map<int, Uint8List>> _participantKeys = {};

  @override
  Future<void> dispose() async {}

  @override
  Future<Uint8List> exportKey({required String participantId, required int index}) async {
    return _participantKeys[participantId]?[index] ?? Uint8List(0);
  }

  @override
  Future<Uint8List> exportSharedKey({int index = 0}) async => _sharedKey ?? Uint8List(0);

  @override
  Future<Uint8List> ratchetKey({required String participantId, required int index}) async {
    return _participantKeys[participantId]?[index] ?? Uint8List(0);
  }

  @override
  Future<Uint8List> ratchetSharedKey({int index = 0}) async => _sharedKey ?? Uint8List(0);

  @override
  Future<bool> setKey({
    required String participantId,
    required int index,
    required Uint8List key,
  }) async {
    _participantKeys.putIfAbsent(participantId, () => {});
    _participantKeys[participantId]![index] = Uint8List.fromList(key);
    return true;
  }

  @override
  Future<void> setSharedKey({required Uint8List key, int index = 0}) async {
    _sharedKey = Uint8List.fromList(key);
  }

  @override
  Future<void> setSifTrailer({required Uint8List trailer}) async {}
}

class TestE2EEManager implements E2EEManager {
  TestE2EEManager({bool dcEncryptionEnabled = true})
      : _keyProvider = BaseKeyProvider(
          TestKeyProvider(),
          rtc.KeyProviderOptions(
            sharedKey: true,
            ratchetSalt: Uint8List(16),
            ratchetWindowSize: 16,
            keyRingSize: 1,
            failureTolerance: -1,
            discardFrameWhenCryptorNotReady: false,
          ),
        ),
        _dcEncryptionEnabled = dcEncryptionEnabled;

  final BaseKeyProvider _keyProvider;
  final bool _dcEncryptionEnabled;
  final Map<String, int> _keyIndices = {};
  final List<Uint8List> encryptedPayloads = [];
  final List<Uint8List> decryptedPayloads = [];

  Room? _room;
  bool _enabled = true;

  @override
  BaseKeyProvider get keyProvider => _keyProvider;

  @override
  bool get isDataChannelEncryptionEnabled => _enabled && _dcEncryptionEnabled;

  @override
  Future<rtc.EncryptedPacket> encryptData({required Uint8List data}) async {
    encryptedPayloads.add(Uint8List.fromList(data));
    final inverted = Uint8List.fromList(data.reversed.toList());
    final iv = Uint8List.fromList(List<int>.generate(12, (index) => index));
    return rtc.EncryptedPacket(data: inverted, keyIndex: 0, iv: iv);
  }

  @override
  Future<int> getKeyIndex(String? participantIdentity) async {
    participantIdentity ??= _room?.localParticipant?.identity ?? '';
    return _keyIndices[participantIdentity] ?? 0;
  }

  @override
  Future<Uint8List?> handleEncryptedData({
    required Uint8List data,
    required Uint8List iv,
    required String participantIdentity,
    required int keyIndex,
  }) async {
    decryptedPayloads.add(Uint8List.fromList(data));
    return Uint8List.fromList(data.reversed.toList());
  }

  @override
  Future<void> ratchetKey({String? participantId, int? keyIndex}) async {}

  @override
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
  }

  @override
  Future<void> setKeyIndex(int keyIndex, {String? participantIdentity}) async {
    participantIdentity ??= _room?.localParticipant?.identity ?? '';
    _keyIndices[participantIdentity] = keyIndex;
  }

  @override
  Future<void> setup(Room room) async {
    _room = room;
    await _keyProvider.setSharedKey('test', keyIndex: 0);
  }
}
