import 'dart:js' as js;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:js/js_util.dart';
import 'package:web/web.dart' as web;

final crypto = web.window.crypto.subtle;

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

Future<web.CryptoKey> importKey(
    Uint8List keyBytes, String algorithm, String usage) {
  // https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/importKey

  return crypto
      .importKey(
        'raw',
        keyBytes.toJS,
        newObject<JSObject>()..setProperty('name'.toJS, algorithm.toJS),
        false,
        usage == 'derive'
            ? <JSString>['deriveBits'.toJS, 'deriveKey'.toJS].toJS
            : <JSString>['encrypt'.toJS, 'decrypt'.toJS].toJS,
      )
      .toDart;
}

Future<web.CryptoKey> createKeyMaterialFromString(
    Uint8List keyBytes, String algorithm, String usage) {
  // https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/importKey
  return promiseToFuture<web.CryptoKey>(crypto.importKey(
    'raw',
    keyBytes.toJS,
    newObject<JSObject>()..setProperty('name'.toJS, 'PBKDF2'.toJS),
    false,
    <JSString>['deriveBits'.toJS, 'deriveKey'.toJS].toJS,
  ));
}

dynamic getAlgoOptions(String algorithmName, Uint8List salt) {
  switch (algorithmName) {
    case 'HKDF':
      return {
        'name': 'HKDF',
        'salt': salt.toJS,
        'hash': 'SHA-256',
        'info': Uint8List(128).toJS,
      };
    case 'PBKDF2':
      {
        return {
          'name': 'PBKDF2',
          'salt': salt.toJS,
          'hash': 'SHA-256',
          'iterations': 100000,
        };
      }
    default:
      throw Exception('algorithm $algorithmName is currently unsupported');
  }
}
