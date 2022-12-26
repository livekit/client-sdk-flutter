import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';

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

  Future<void> setSharedKey(Uint8List key) async {
    if (key.length != 32) {
      throw Exception('Shared key must be 32 bytes');
    }
    _sharedKey.setAll(0, key);
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
