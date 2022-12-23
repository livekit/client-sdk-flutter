import 'package:flutter/foundation.dart';
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
  final KeyManager _keyManager;
  @override
  KeyManager get keyManager => _keyManager;

  BaseKeyProvider(this._keyManager);

  static Future<BaseKeyProvider> create() async {
    final keyManager =
        await FrameCryptorFactory.instance.createDefaultKeyManager();
    return BaseKeyProvider(keyManager);
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
