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
import 'dart:typed_data';
import 'dart:js_util' as jsutil;
import 'dart:html' as html;

import 'package:js/js.dart';

@JS('Promise')
class Promise<T> {
  external factory Promise._();
}

@JS('Algorithm')
class Algorithm {
  external String get name;
}

@JS('crypto.subtle.encrypt')
external Promise<ByteBuffer> encrypt(
  dynamic algorithm,
  html.CryptoKey key,
  ByteBuffer data,
);

@JS('crypto.subtle.decrypt')
external Promise<ByteBuffer> decrypt(
  dynamic algorithm,
  html.CryptoKey key,
  ByteBuffer data,
);

@JS()
@anonymous
class AesGcmParams {
  external factory AesGcmParams({
    required String name,
    required ByteBuffer iv,
    ByteBuffer? additionalData,
    int tagLength = 128,
  });
}

ByteBuffer jsArrayBufferFrom(List<int> data) {
  // Avoid copying if possible
  if (data is Uint8List &&
      data.offsetInBytes == 0 &&
      data.lengthInBytes == data.buffer.lengthInBytes) {
    return data.buffer;
  }
  // Copy
  return Uint8List.fromList(data).buffer;
}

@JS('crypto.subtle.importKey')
external Promise<html.CryptoKey> importKey(
  String format,
  ByteBuffer keyData,
  dynamic algorithm,
  bool extractable,
  List<String> keyUsages,
);

@JS('crypto.subtle.exportKey')
external Promise<ByteBuffer> exportKey(
  String format,
  html.CryptoKey key,
);

@JS('crypto.subtle.deriveKey')
external Promise<html.CryptoKey> deriveKey(
    dynamic algorithm,
    html.CryptoKey baseKey,
    dynamic derivedKeyAlgorithm,
    bool extractable,
    List<String> keyUsages);

@JS('crypto.subtle.deriveBits')
external Promise<ByteBuffer> deriveBits(
  dynamic algorithm,
  html.CryptoKey baseKey,
  int length,
);

Future<html.CryptoKey> impportKeyFromRawData(List<int> secretKeyData,
    {required String webCryptoAlgorithm,
    required List<String> keyUsages}) async {
  return jsutil.promiseToFuture<html.CryptoKey>(importKey(
    'raw',
    jsArrayBufferFrom(secretKeyData),
    jsutil.jsify({'name': webCryptoAlgorithm}),
    false,
    keyUsages,
  ));
}
