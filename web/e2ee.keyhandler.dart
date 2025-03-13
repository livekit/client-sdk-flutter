import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'e2ee.logger.dart';
import 'e2ee.utils.dart';

const KEYRING_SIZE = 16;

class KeyOptions {
  KeyOptions({
    required this.sharedKey,
    required this.ratchetSalt,
    required this.ratchetWindowSize,
    this.uncryptedMagicBytes,
    this.failureTolerance = -1,
    this.keyRingSze = KEYRING_SIZE,
    this.discardFrameWhenCryptorNotReady = false,
  });
  bool sharedKey;
  Uint8List ratchetSalt;
  int ratchetWindowSize = 0;
  int failureTolerance;
  Uint8List? uncryptedMagicBytes;
  int keyRingSze;
  bool discardFrameWhenCryptorNotReady;

  @override
  String toString() {
    return 'KeyOptions{sharedKey: $sharedKey, ratchetWindowSize: $ratchetWindowSize, failureTolerance: $failureTolerance, uncryptedMagicBytes: $uncryptedMagicBytes, ratchetSalt: $ratchetSalt}';
  }
}

class KeyProvider {
  KeyProvider(this.worker, this.id, this.keyProviderOptions);
  final web.DedicatedWorkerGlobalScope worker;
  final String id;
  final KeyOptions keyProviderOptions;
  var participantKeys = <String, ParticipantKeyHandler>{};
  ParticipantKeyHandler? sharedKeyHandler;
  var sharedKey = Uint8List(0);

  ParticipantKeyHandler getParticipantKeyHandler(String participantIdentity) {
    if (keyProviderOptions.sharedKey) {
      return getSharedKeyHandler();
    }
    var keys = participantKeys[participantIdentity];
    if (keys == null) {
      keys = ParticipantKeyHandler(
        worker: worker,
        participantIdentity: participantIdentity,
        keyOptions: keyProviderOptions,
      );
      if (sharedKey.isNotEmpty) {
        keys.setKey(sharedKey);
      }
      //keys.on(KeyHandlerEvent.KeyRatcheted, emitRatchetedKeys);
      participantKeys[participantIdentity] = keys;
    }
    return keys;
  }

  ParticipantKeyHandler getSharedKeyHandler() {
    sharedKeyHandler ??= ParticipantKeyHandler(
      worker: worker,
      participantIdentity: 'shared-key',
      keyOptions: keyProviderOptions,
    );
    return sharedKeyHandler!;
  }

  void setSharedKey(Uint8List key, {int keyIndex = 0}) {
    logger.info('setting shared key');
    sharedKey = key;
    getSharedKeyHandler().setKey(key, keyIndex: keyIndex);
  }

  void setSifTrailer(Uint8List sifTrailer) {
    keyProviderOptions.uncryptedMagicBytes = sifTrailer;
  }
}

class KeySet {
  KeySet(this.material, this.encryptionKey);
  web.CryptoKey material;
  web.CryptoKey encryptionKey;
}

class ParticipantKeyHandler {
  ParticipantKeyHandler({
    required this.worker,
    required this.keyOptions,
    required this.participantIdentity,
  }) {
    if (keyOptions.keyRingSze <= 0 || keyOptions.keyRingSze > 255) {
      throw Exception('Invalid key ring size');
    }
    cryptoKeyRing = List.filled(keyOptions.keyRingSze, null);
  }
  int currentKeyIndex = 0;

  late List<KeySet?> cryptoKeyRing;

  bool _hasValidKey = false;

  bool get hasValidKey => _hasValidKey;

  final KeyOptions keyOptions;

  final web.DedicatedWorkerGlobalScope worker;

  final String participantIdentity;

  int _decryptionFailureCount = 0;

  void decryptionFailure() {
    if (keyOptions.failureTolerance < 0) {
      return;
    }
    _decryptionFailureCount += 1;

    if (_decryptionFailureCount > keyOptions.failureTolerance) {
      logger.warning('key for $participantIdentity is being marked as invalid');
      _hasValidKey = false;
    }
  }

  void decryptionSuccess() {
    resetKeyStatus();
  }

  /// Call this after user initiated ratchet or a new key has been set in order
  /// to make sure to mark potentially invalid keys as valid again
  void resetKeyStatus() {
    _decryptionFailureCount = 0;
    _hasValidKey = true;
  }

  Future<Uint8List?> exportKey(int? keyIndex) async {
    var currentMaterial = getKeySet(keyIndex)?.material;
    if (currentMaterial == null) {
      return null;
    }
    try {
      var key = await worker.crypto.subtle
          .exportKey('raw', currentMaterial)
          .toDart as JSArrayBuffer;
      return key.toDart.asUint8List();
    } catch (e) {
      logger.warning('exportKey: $e');
      return null;
    }
  }

  Future<Uint8List?> ratchetKey(int? keyIndex) async {
    var currentMaterial = getKeySet(keyIndex)?.material;
    if (currentMaterial == null) {
      return null;
    }
    var newKey = await ratchet(currentMaterial, keyOptions.ratchetSalt);
    var newMaterial = await ratchetMaterial(currentMaterial, newKey.buffer);
    var newKeySet = await deriveKeys(newMaterial, keyOptions.ratchetSalt);
    await setKeySetFromMaterial(newKeySet, keyIndex ?? currentKeyIndex);
    return newKey;
  }

  Future<web.CryptoKey> ratchetMaterial(
      web.CryptoKey currentMaterial, ByteBuffer newKeyBuffer) async {
    var newMaterial = await worker.crypto.subtle
        .importKey(
          'raw',
          newKeyBuffer.toJS,
          currentMaterial.algorithm.getProperty('name'.toJS),
          false,
          ['deriveBits', 'deriveKey'].jsify() as JSArray<JSString>,
        )
        .toDart;
    return newMaterial;
  }

  KeySet? getKeySet(int? keyIndex) {
    return cryptoKeyRing[keyIndex ?? currentKeyIndex];
  }

  Future<void> setKey(Uint8List key, {int keyIndex = 0}) async {
    var keyMaterial = await worker.crypto.subtle
        .importKey('raw', key.toJS, {'name': 'PBKDF2'.toJS}.jsify() as JSAny,
            false, ['deriveBits', 'deriveKey'].jsify() as JSArray<JSString>)
        .toDart;

    var keySet = await deriveKeys(
      keyMaterial,
      keyOptions.ratchetSalt,
    );
    await setKeySetFromMaterial(keySet, keyIndex);
    resetKeyStatus();
  }

  Future<void> setKeySetFromMaterial(KeySet keySet, int keyIndex) async {
    logger.config('setKeySetFromMaterial: set new key, index: $keyIndex');
    if (keyIndex >= 0) {
      currentKeyIndex = keyIndex % cryptoKeyRing.length;
    }
    cryptoKeyRing[currentKeyIndex] = keySet;
  }

  /// Derives a set of keys from the master key.
  /// See https://tools.ietf.org/html/draft-omara-sframe-00#section-4.3.1
  Future<KeySet> deriveKeys(web.CryptoKey material, Uint8List salt) async {
    var algorithmName = material.algorithm.getProperty('name'.toJS) as JSString;
    var algorithmOptions = getAlgoOptions(algorithmName.toDart, salt);
    // https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/deriveKey#HKDF
    // https://developer.mozilla.org/en-US/docs/Web/API/HkdfParams
    var encryptionKey = await worker.crypto.subtle
        .deriveKey(
          algorithmOptions.jsify() as web.AlgorithmIdentifier,
          material,
          {'name': 'AES-GCM', 'length': 128}.jsify() as web.AlgorithmIdentifier,
          false,
          ['encrypt', 'decrypt'].jsify() as JSArray<JSString>,
        )
        .toDart;

    return KeySet(material, encryptionKey as web.CryptoKey);
  }

  /// Ratchets a key. See
  /// https://tools.ietf.org/html/draft-omara-sframe-00#section-4.3.5.1

  Future<Uint8List> ratchet(web.CryptoKey material, Uint8List salt) async {
    var algorithmOptions = getAlgoOptions('PBKDF2', salt);

    // https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/deriveBits
    var newKey = await worker.crypto.subtle
        .deriveBits(
            algorithmOptions.jsify() as web.AlgorithmIdentifier, material, 256)
        .toDart;
    return newKey.toDart.asUint8List();
  }
}
