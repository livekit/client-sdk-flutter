import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

bool isE2EESupported() {
  return isInsertableStreamSupported() || isScriptTransformSupported();
}

bool isScriptTransformSupported() {
  return web.window.hasProperty('RTCRtpScriptTransform'.toJS).toDart;
}

bool isInsertableStreamSupported() {
  return web.window.hasProperty('RTCRtpSender'.toJS).toDart &&
      web.window
          .getProperty<web.RTCRtpSender>('RTCRtpSender'.toJS)
          .hasProperty('createEncodedStreams'.toJS)
          .toDart;
}

Future<web.CryptoKey> createKeyMaterialFromString(
    Uint8List keyBytes, String algorithm, String usage) {
  // https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/importKey
  return web.window.crypto.subtle
      .importKey(
        'raw',
        keyBytes.toJS,
        {'name': 'PBKDF2'}.jsify() as web.AlgorithmIdentifier,
        false,
        ['deriveBits', 'deriveKey'].jsify() as JSArray<JSString>,
      )
      .toDart;
}

Map<String, dynamic> getAlgoOptions(String algorithmName, Uint8List salt) {
  switch (algorithmName) {
    case 'HKDF':
      return {
        'name': 'HKDF',
        'salt': salt,
        'hash': 'SHA-256',
        'info': Uint8List(128),
      };
    case 'PBKDF2':
      {
        return {
          'name': 'PBKDF2',
          'salt': salt,
          'hash': 'SHA-256',
          'iterations': 100000,
        };
      }
    default:
      throw Exception('algorithm $algorithmName is currently unsupported');
  }
}
