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

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/src/exceptions.dart';
import 'package:livekit_client/src/options.dart';
import 'package:livekit_client/src/support/certificate_pinning.dart';

void main() {
  test('computes SHA-256 SPKI certificate pins', () {
    final spki = _subjectPublicKeyInfo([1, 2, 3, 4]);
    final certificate = _certificate(spki);
    final expectedPin = 'sha256/${base64Encode(sha256.convert(spki).bytes)}';

    expect(certificateSpkiSha256Pin(certificate), expectedPin);
  });

  test('accepts primary and backup pins for matching hosts', () {
    final certificate = _certificate(_subjectPublicKeyInfo([1, 2, 3, 4]));
    final backupCertificate = _certificate(_subjectPublicKeyInfo([5, 6, 7, 8]));
    final primaryPin = certificateSpkiSha256Pin(certificate);
    final backupPin = certificateSpkiSha256Pin(backupCertificate);

    final validator = CertificatePinValidator(CertificatePinningOptions(
      rules: [
        CertificatePinningRule(
          hosts: const ['*.livekit.cloud'],
          primaryPins: [primaryPin],
          backupPins: [backupPin],
        ),
      ],
    ));

    expect(
      () => validator.validate(
        uri: Uri.parse('https://project.livekit.cloud'),
        certificateDer: certificate,
      ),
      returnsNormally,
    );
    expect(
      () => validator.validate(
        uri: Uri.parse('https://project.livekit.cloud'),
        certificateDer: backupCertificate,
      ),
      returnsNormally,
    );
  });

  test('rejects pin mismatches', () {
    final certificate = _certificate(_subjectPublicKeyInfo([1, 2, 3, 4]));
    final otherCertificate = _certificate(_subjectPublicKeyInfo([5, 6, 7, 8]));
    final validator = CertificatePinValidator(CertificatePinningOptions(
      rules: [
        CertificatePinningRule(
          hosts: const ['livekit.example.com'],
          primaryPins: [certificateSpkiSha256Pin(certificate)],
        ),
      ],
    ));

    expect(
      () => validator.validate(
        uri: Uri.parse('https://livekit.example.com'),
        certificateDer: otherCertificate,
      ),
      throwsA(isA<CertificatePinningException>()),
    );
  });

  test('ignores hosts without a matching rule', () {
    final certificate = _certificate(_subjectPublicKeyInfo([1, 2, 3, 4]));
    final validator = CertificatePinValidator(const CertificatePinningOptions(
      rules: [
        CertificatePinningRule(
          hosts: ['livekit.example.com'],
          primaryPins: ['sha256/not-a-real-pin'],
        ),
      ],
    ));

    expect(
      () => validator.validate(
        uri: Uri.parse('https://other.example.com'),
        certificateDer: certificate,
      ),
      returnsNormally,
    );
  });

  test('wildcard hosts match only a single label', () {
    final certificate = _certificate(_subjectPublicKeyInfo([1, 2, 3, 4]));
    final validator = CertificatePinValidator(CertificatePinningOptions(
      rules: [
        CertificatePinningRule(
          hosts: const ['*.livekit.cloud'],
          primaryPins: [certificateSpkiSha256Pin(certificate)],
        ),
      ],
    ));

    expect(
      () => validator.validate(
        uri: Uri.parse('https://project.livekit.cloud'),
        certificateDer: certificate,
      ),
      returnsNormally,
    );
    expect(
      () => validator.validate(
        uri: Uri.parse('https://a.b.livekit.cloud'),
        certificateDer: _certificate(_subjectPublicKeyInfo([5, 6, 7, 8])),
      ),
      returnsNormally,
    );
  });
}

List<int> _certificate(List<int> subjectPublicKeyInfo) {
  final tbsCertificate = _sequence([
    ..._explicitVersion(),
    ..._integer(1),
    ..._sequence(const []),
    ..._sequence(const []),
    ..._sequence(const []),
    ..._sequence(const []),
    ...subjectPublicKeyInfo,
  ]);

  return _sequence([
    ...tbsCertificate,
    ..._sequence(const []),
    ..._bitString(const [0]),
  ]);
}

List<int> _subjectPublicKeyInfo(List<int> publicKeyBytes) => _sequence([
      ..._sequence(const []),
      ..._bitString(publicKeyBytes),
    ]);

List<int> _explicitVersion() => _element(0xa0, _integer(2));

List<int> _integer(int value) => _element(0x02, [value]);

List<int> _sequence(List<int> value) => _element(0x30, value);

List<int> _bitString(List<int> value) => _element(0x03, [0, ...value]);

List<int> _element(int tag, List<int> value) => [
      tag,
      ..._length(value.length),
      ...value,
    ];

List<int> _length(int length) {
  if (length < 0x80) {
    return [length];
  }
  return [0x81, length];
}
