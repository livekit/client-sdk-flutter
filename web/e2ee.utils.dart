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

import 'dart:html';
import 'dart:js' as js;
import 'dart:js_util';
import 'dart:typed_data';

import 'crypto.dart' as crypto;

bool isE2EESupported() {
  return isInsertableStreamSupported() || isScriptTransformSupported();
}

bool isScriptTransformSupported() {
  return js.context['RTCRtpScriptTransform'] != null;
}

bool isInsertableStreamSupported() {
  return js.context['RTCRtpSender'] != null &&
      js.context['RTCRtpSender']['prototype']['createEncodedStreams'] != null;
}

Future<CryptoKey> importKey(
    Uint8List keyBytes, String algorithm, String usage) {
  // https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/importKey
  return promiseToFuture<CryptoKey>(crypto.importKey(
    'raw',
    crypto.jsArrayBufferFrom(keyBytes),
    js.JsObject.jsify({'name': algorithm}),
    false,
    usage == 'derive' ? ['deriveBits', 'deriveKey'] : ['encrypt', 'decrypt'],
  ));
}

Future<CryptoKey> createKeyMaterialFromString(
    Uint8List keyBytes, String algorithm, String usage) {
  // https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/importKey
  return promiseToFuture<CryptoKey>(crypto.importKey(
    'raw',
    crypto.jsArrayBufferFrom(keyBytes),
    js.JsObject.jsify({'name': 'PBKDF2'}),
    false,
    ['deriveBits', 'deriveKey'],
  ));
}

dynamic getAlgoOptions(String algorithmName, Uint8List salt) {
  switch (algorithmName) {
    case 'HKDF':
      return {
        'name': 'HKDF',
        'salt': crypto.jsArrayBufferFrom(salt),
        'hash': 'SHA-256',
        'info': crypto.jsArrayBufferFrom(Uint8List(128)),
      };
    case 'PBKDF2':
      {
        return {
          'name': 'PBKDF2',
          'salt': crypto.jsArrayBufferFrom(salt),
          'hash': 'SHA-256',
          'iterations': 100000,
        };
      }
    default:
      throw Exception('algorithm $algorithmName is currently unsupported');
  }
}
