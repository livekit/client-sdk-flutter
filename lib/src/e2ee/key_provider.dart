import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';

const defaultRatchetSalt = 'LKFrameEncryptionKey';
const defaultKeyLength = 32;

class KeyInfo {
  final String participantId;
  final int keyIndex;
  final Uint8List key;
  KeyInfo({
    required this.participantId,
    required this.keyIndex,
    required this.key,
  });
}

abstract class KeyProvider {
  Future<void> setKey(KeyInfo keyInfo);
  KeyManager get keyManager;
}

class BaseKeyProvider implements KeyProvider {
  final Map<String, Map<int, Uint8List>> _keys = {};
  Uint8List? _sharedKey;
  final KeyProviderOptions options;
  final KeyManager _keyManager;
  @override
  KeyManager get keyManager => _keyManager;

  Uint8List? get sharedKey => _sharedKey;

  BaseKeyProvider(this._keyManager, this.options);

  static Future<BaseKeyProvider> create({
    bool sharedKey = false,
    String? ratchetSalt,
    int? ratchetWindowSize,
  }) async {
    KeyProviderOptions options = KeyProviderOptions(
      sharedKey: sharedKey,
      ratchetSalt:
          Uint8List.fromList((ratchetSalt ?? defaultRatchetSalt).codeUnits),
      ratchetWindowSize: ratchetWindowSize ?? 16,
    );
    final keyManager =
        await FrameCryptorFactory.instance.createDefaultKeyManager(options);
    return BaseKeyProvider(keyManager, options);
  }

  Future<void> setSharedKey(String key) async {
    Uint8List keyBytes = Uint8List.fromList(key.codeUnits);
    _sharedKey = keyBytes;
  }

  Future<void> setKeyForParticipant(String participantId, String key) async {
    Uint8List keyBytes = Uint8List.fromList(key.codeUnits);
    KeyInfo keyInfo = KeyInfo(
      participantId: participantId,
      keyIndex: 0,
      key: keyBytes,
    );
    await setKey(keyInfo);
  }

  @override
  Future<void> setKey(KeyInfo keyInfo) async {
    if (!_keys.containsKey(keyInfo.participantId)) {
      _keys[keyInfo.participantId] = {};
    }
    _keys[keyInfo.participantId]![keyInfo.keyIndex] = keyInfo.key;
    await _keyManager.setKey(
      participantId: keyInfo.participantId,
      index: keyInfo.keyIndex,
      key: keyInfo.key,
    );
  }
}
