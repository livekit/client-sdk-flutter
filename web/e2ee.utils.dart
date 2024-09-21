import 'dart:js' as js;
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

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
  return web.window.crypto.subtle
      .importKey(
        'raw',
        keyBytes.toJS,
        {'name': algorithm}.jsify() as JSAny,
        false,
        (usage == 'derive'
                ? ['deriveBits', 'deriveKey']
                : ['encrypt', 'decrypt'])
            .jsify() as JSArray<JSString>,
      )
      .toDart;
}

Future<web.CryptoKey> createKeyMaterialFromString(
    Uint8List keyBytes, String algorithm, String usage) {
  // https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/importKey
  return web.window.crypto.subtle
      .importKey(
        'raw',
        keyBytes.toJS,
        {'name': 'PBKDF2'}.jsify() as JSAny,
        false,
        ['deriveBits', 'deriveKey'].jsify() as JSArray<JSString>,
      )
      .toDart;
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
