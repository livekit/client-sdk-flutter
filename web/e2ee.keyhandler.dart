// Copyright 2023 LiveKit, Inc.
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

const KEYRING_SIZE = 16;

class KeySet {
  KeySet(this.material, this.encryptionKey);
  CryptoKey material;
  CryptoKey encryptionKey;
}

class ParticipantKeyHandler {
  int currentKeyIndex = 0;

  List<KeySet?> cryptoKeyRing = List.filled(KEYRING_SIZE, null);

  bool _hasValidKey = false;

  bool get hasValidKey => _hasValidKey;

  final KeyOptions keyOptions;

  final DedicatedWorkerGlobalScope worker;

  Completer? _ratchetCompleter;

  final String participantIdentity;

  int _decryptionFailureCount = 0;

  ParticipantKeyHandler({
    required this.worker,
    required this.keyOptions,
    required this.participantIdentity,
  });

  void decryptionFailure() {
    if (this.keyOptions.failureTolerance < 0) {
      return;
    }
    _decryptionFailureCount += 1;

    if (_decryptionFailureCount > this.keyOptions.failureTolerance) {
      logger.warning('key for $participantIdentity is being marked as invalid');
      _hasValidKey = false;
    }
  }

  decryptionSuccess() {
    resetKeyStatus();
  }

  /**
   * Call this after user initiated ratchet or a new key has been set in order to make sure to mark potentially
   * invalid keys as valid again
   */
  resetKeyStatus() {
    _decryptionFailureCount = 0;
    _hasValidKey = true;
  }

  Future<void> ratchetKey(int? keyIndex) async {
    if (_ratchetCompleter == null) {
      _ratchetCompleter = Completer<void>();
      var currentMaterial = getKeySet(keyIndex)?.material;
      if (currentMaterial == null) {
        _ratchetCompleter!.complete();
        _ratchetCompleter = null;
        return;
      }
      ratchetMaterial(currentMaterial).then((newMaterial) {
        deriveKeys(newMaterial, keyOptions.ratchetSalt).then((newKeySet) {
          setKeySetFromMaterial(newKeySet, keyIndex ?? currentKeyIndex)
              .then((_) {
            _ratchetCompleter!.complete();
            _ratchetCompleter = null;
          });
        });
      });
    }

    return _ratchetCompleter!.future;
  }

  Future<CryptoKey> ratchetMaterial(CryptoKey currentMaterial) async {
    var newMaterial = await jsutil.promiseToFuture(crypto.importKey(
      'raw',
      crypto.jsArrayBufferFrom(
          await ratchet(currentMaterial, keyOptions.ratchetSalt)),
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
    logger.info('setKeySetFromMaterial: set new key, index: $keyIndex');
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
