import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cryptography/cryptography.dart';

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
  final Uint8List _sharedKey = Uint8List(32);
  final bool isSharedKey;
  final KeyManager _keyManager;
  @override
  KeyManager get keyManager => _keyManager;

  Uint8List get sharedKey => _sharedKey;

  BaseKeyProvider(this._keyManager, this.isSharedKey);

  static Future<BaseKeyProvider> create({bool sharedKey = true}) async {
    final keyManager =
        await FrameCryptorFactory.instance.createDefaultKeyManager();
    return BaseKeyProvider(keyManager, sharedKey);
  }

  Future<Uint8List> deriveKeyFromString(String password) async {
    final secretKey = SecretKey(password.codeUnits);

    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );

    final newSecretKey = await pbkdf2.deriveKey(
      secretKey: secretKey,
      nonce: defaultRatchetSalt.codeUnits,
    );
    final extractBytes = await newSecretKey.extractBytes();
    return Uint8List.fromList(extractBytes);
  }

  Future<void> setSharedKey(String key) async {
    Uint8List keyBytes = await deriveKeyFromString(key);
    if (keyBytes.length != 32) {
      throw Exception('keyBytes must be 32 bytes, length: ${keyBytes.length}');
    }
    _sharedKey.setAll(0, keyBytes);
  }

  Future<void> setKeyForParticipant(String participantId, String key) async {
    Uint8List keyBytes = await deriveKeyFromString(key);
    if (keyBytes.length != 32) {
      throw Exception('keyBytes must be 32 bytes');
    }
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
