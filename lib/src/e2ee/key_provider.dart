import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

const defaultRatchetSalt = 'LKFrameEncryptionKey';
const defualtMagicBytes = 'LK-ROCKS';
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
  Future<Uint8List> ratchetKey(String participantId, int index);
  rtc.KeyProvider get keyProvider;
}

class BaseKeyProvider implements KeyProvider {
  final Map<String, Map<int, Uint8List>> _keys = {};
  Uint8List? _sharedKey;
  final rtc.KeyProviderOptions options;
  final rtc.KeyProvider _keyProvider;
  @override
  rtc.KeyProvider get keyProvider => _keyProvider;

  Uint8List? get sharedKey => _sharedKey;

  BaseKeyProvider(this._keyProvider, this.options);

  static Future<BaseKeyProvider> create({
    bool sharedKey = false,
    String? ratchetSalt,
    int? ratchetWindowSize,
  }) async {
    rtc.KeyProviderOptions options = rtc.KeyProviderOptions(
      sharedKey: sharedKey,
      ratchetSalt:
          Uint8List.fromList((ratchetSalt ?? defaultRatchetSalt).codeUnits),
      ratchetWindowSize: ratchetWindowSize ?? 16,
      uncryptedMagicBytes: Uint8List.fromList(defualtMagicBytes.codeUnits),
    );
    final keyProvider = await rtc.FrameCryptorFactory.instance
        .createDefaultKeyProvider(options);
    return BaseKeyProvider(keyProvider, options);
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
  Future<Uint8List> ratchetKey(String participantId, int index) =>
      _keyProvider.ratchetKey(participantId: participantId, index: index);

  @override
  Future<void> setKey(KeyInfo keyInfo) async {
    if (!_keys.containsKey(keyInfo.participantId)) {
      _keys[keyInfo.participantId] = {};
    }
    _keys[keyInfo.participantId]![keyInfo.keyIndex] = keyInfo.key;
    await _keyProvider.setKey(
      participantId: keyInfo.participantId,
      index: keyInfo.keyIndex,
      key: keyInfo.key,
    );
  }
}
