// Copyright 2026 LiveKit, Inc.
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

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';

void main() {
  test('loads PEM certificate bytes from an asset by default', () async {
    final certificate = await CertificateBytes.fromAsset(
      'assets/livekit_leaf_cert.pem',
      bundle: _FakeAssetBundle({
        'assets/livekit_leaf_cert.pem': [1, 2, 3],
      }),
    );

    expect(certificate.encoding, CertificateBytesEncoding.pem);
    expect(certificate.bytes, [1, 2, 3]);
  });

  test('loads DER certificate bytes from an asset when requested', () async {
    final certificate = await CertificateBytes.fromAsset(
      'assets/livekit_leaf_cert.der',
      bundle: _FakeAssetBundle({
        'assets/livekit_leaf_cert.der': [4, 5, 6],
      }),
      encoding: CertificateBytesEncoding.der,
    );

    expect(certificate.encoding, CertificateBytesEncoding.der);
    expect(certificate.bytes, [4, 5, 6]);
  });
}

class _FakeAssetBundle extends CachingAssetBundle {
  final Map<String, List<int>> _assets;

  _FakeAssetBundle(this._assets);

  @override
  Future<ByteData> load(String key) async {
    final bytes = _assets[key];
    if (bytes == null) {
      throw StateError('Asset not found: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}
