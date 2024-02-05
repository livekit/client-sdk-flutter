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

import 'dart:async';
import 'dart:html';
import 'dart:js_util' as jsutil;
import 'dart:typed_data';

import 'crypto.dart' as crypto;
import 'e2ee.logger.dart';
import 'e2ee.utils.dart';

class KeyOptions {
  KeyOptions({
    required this.sharedKey,
    required this.ratchetSalt,
    required this.ratchetWindowSize,
    this.uncryptedMagicBytes,
    this.failureTolerance = -1,
  });
  bool sharedKey;
  Uint8List ratchetSalt;
  int ratchetWindowSize = 0;
  int failureTolerance;
  Uint8List? uncryptedMagicBytes;

  @override
  String toString() {
    return 'KeyOptions{sharedKey: $sharedKey, ratchetWindowSize: $ratchetWindowSize, failureTolerance: $failureTolerance, uncryptedMagicBytes: $uncryptedMagicBytes, ratchetSalt: $ratchetSalt}';
  }
}

class KeyProvider {
  KeyProvider(this.worker, this.id, this.keyProviderOptions);
  final DedicatedWorkerGlobalScope worker;
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

const KEYRING_SIZE = 16;

class KeySet {
  KeySet(this.material, this.encryptionKey);
  CryptoKey material;
  CryptoKey encryptionKey;
}

class ParticipantKeyHandler {
  ParticipantKeyHandler({
    required this.worker,
    required this.keyOptions,
    required this.participantIdentity,
  });
  int currentKeyIndex = 0;

  List<KeySet?> cryptoKeyRing = List.filled(KEYRING_SIZE, null);

  bool _hasValidKey = false;

  bool get hasValidKey => _hasValidKey;

  final KeyOptions keyOptions;

  final DedicatedWorkerGlobalScope worker;

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
      var key = await jsutil.promiseToFuture<ByteBuffer>(
          crypto.exportKey('raw', currentMaterial));
      return key.asUint8List();
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
    var newMaterial = await ratchetMaterial(
        currentMaterial, crypto.jsArrayBufferFrom(newKey));
    var newKeySet = await deriveKeys(newMaterial, keyOptions.ratchetSalt);
    await setKeySetFromMaterial(newKeySet, keyIndex ?? currentKeyIndex);
    return newKey;
  }

  Future<CryptoKey> ratchetMaterial(
      CryptoKey currentMaterial, ByteBuffer newKeyBuffer) async {
    var newMaterial = await jsutil.promiseToFuture(crypto.importKey(
      'raw',
      newKeyBuffer,
      (currentMaterial.algorithm as crypto.Algorithm).name,
      false,
      ['deriveBits', 'deriveKey'],
    ));
    return newMaterial;
  }

  KeySet? getKeySet(int? keyIndex) {
    return cryptoKeyRing[keyIndex ?? currentKeyIndex];
  }

  Future<void> setKey(Uint8List key, {int keyIndex = 0}) async {
    var keyMaterial = await crypto.impportKeyFromRawData(key,
        webCryptoAlgorithm: 'PBKDF2', keyUsages: ['deriveBits', 'deriveKey']);
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
  Future<KeySet> deriveKeys(CryptoKey material, Uint8List salt) async {
    var algorithmOptions =
        getAlgoOptions((material.algorithm as crypto.Algorithm).name, salt);

    // https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/deriveKey#HKDF
    // https://developer.mozilla.org/en-US/docs/Web/API/HkdfParams
    var encryptionKey =
        await jsutil.promiseToFuture<CryptoKey>(crypto.deriveKey(
      jsutil.jsify(algorithmOptions),
      material,
      jsutil.jsify({'name': 'AES-GCM', 'length': 128}),
      false,
      ['encrypt', 'decrypt'],
    ));

    return KeySet(material, encryptionKey);
  }

  /// Ratchets a key. See
  /// https://tools.ietf.org/html/draft-omara-sframe-00#section-4.3.5.1

  Future<Uint8List> ratchet(CryptoKey material, Uint8List salt) async {
    var algorithmOptions = getAlgoOptions('PBKDF2', salt);

    // https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/deriveBits
    var newKey = await jsutil.promiseToFuture<ByteBuffer>(
        crypto.deriveBits(jsutil.jsify(algorithmOptions), material, 256));
    return newKey.asUint8List();
  }
}
