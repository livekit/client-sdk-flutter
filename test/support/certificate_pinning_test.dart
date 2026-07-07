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

  test('computes SHA-256 SPKI certificate pins for a real X.509 certificate', () {
    expect(
      certificateSpkiSha256Pin(_realCertificateDer()),
      'sha256/vt3l7OSChC7JPeBz2uCokjLybmg/Kv+SoBW84d40XdM=',
    );
  });

  test('wraps DER certificates as PEM bytes for SecurityContext', () {
    final pemBytes = certificatePemBytes(CertificateBytes.der(_realCertificateDer()));
    final pemText = ascii.decode(pemBytes);

    expect(pemText, startsWith('-----BEGIN CERTIFICATE-----\n'));
    expect(pemText, endsWith('-----END CERTIFICATE-----\n'));
    expect(certificateDerCertificates(CertificateBytes.pem(pemBytes)).single, _realCertificateDer());
  });

  test('accepts primary and backup pins for matching hosts', () {
    final certificate = _certificate(_subjectPublicKeyInfo([1, 2, 3, 4]));
    final backupCertificate = _certificate(_subjectPublicKeyInfo([5, 6, 7, 8]));
    final secondBackupCertificate = _certificate(
      _subjectPublicKeyInfo([9, 10, 11, 12]),
    );
    final primaryPin = certificateSpkiSha256Pin(certificate);
    final backupPin = certificateSpkiSha256Pin(backupCertificate);
    final secondBackupPin = certificateSpkiSha256Pin(secondBackupCertificate);

    final validator = CertificatePinValidator(CertificatePinningOptions(
      rules: [
        CertificatePinningRule(
          hosts: const ['*.livekit.cloud'],
          primaryPins: [primaryPin],
          backupPins: [backupPin, secondBackupPin],
        ),
      ],
    ));

    expect(
      () => validator.validatePeerCertificate(
        uri: Uri.parse('https://project.livekit.cloud'),
        certificateDer: certificate,
      ),
      returnsNormally,
    );
    expect(
      () => validator.validatePeerCertificate(
        uri: Uri.parse('https://project.livekit.cloud'),
        certificateDer: backupCertificate,
      ),
      returnsNormally,
    );
    expect(
      () => validator.validatePeerCertificate(
        uri: Uri.parse('https://project.livekit.cloud'),
        certificateDer: secondBackupCertificate,
      ),
      returnsNormally,
    );
  });

  test('merges all matching rules by check type', () {
    final certificate = _certificate(_subjectPublicKeyInfo([1, 2, 3, 4]));
    final backupCertificate = _certificate(_subjectPublicKeyInfo([5, 6, 7, 8]));
    final otherCertificate = _certificate(_subjectPublicKeyInfo([9, 10, 11, 12]));
    final validator = CertificatePinValidator(CertificatePinningOptions(
      rules: [
        CertificatePinningRule(
          hosts: const ['*'],
          primaryPins: [certificateSpkiSha256Pin(certificate)],
        ),
        CertificatePinningRule(
          hosts: const ['livekit.example.com'],
          backupPins: [certificateSpkiSha256Pin(backupCertificate)],
        ),
      ],
    ));

    expect(
      () => validator.validatePeerCertificate(
        uri: Uri.parse('https://livekit.example.com'),
        certificateDer: backupCertificate,
      ),
      returnsNormally,
    );
    expect(
      () => validator.validatePeerCertificate(
        uri: Uri.parse('https://livekit.example.com'),
        certificateDer: otherCertificate,
      ),
      throwsA(isA<CertificatePinningException>()),
    );
  });

  test('enforces each configured check type for matching rules', () {
    final certificate = _certificate(_subjectPublicKeyInfo([1, 2, 3, 4]));
    final otherCertificate = _certificate(_subjectPublicKeyInfo([5, 6, 7, 8]));
    final validator = CertificatePinValidator(CertificatePinningOptions(
      rules: [
        CertificatePinningRule(
          hosts: const ['livekit.example.com'],
          pinnedLeafCertificates: [CertificateBytes.der(certificate)],
        ),
        CertificatePinningRule(
          hosts: const ['*.example.com'],
          primaryPins: [certificateSpkiSha256Pin(otherCertificate)],
        ),
      ],
    ));

    // passes the exact leaf check but fails the SPKI check
    expect(
      () => validator.validatePeerCertificate(
        uri: Uri.parse('https://livekit.example.com'),
        certificateDer: certificate,
      ),
      throwsA(isA<CertificatePinningException>()),
    );
    // passes the SPKI check but fails the exact leaf check
    expect(
      () => validator.validatePeerCertificate(
        uri: Uri.parse('https://livekit.example.com'),
        certificateDer: otherCertificate,
      ),
      throwsA(isA<CertificatePinningException>()),
    );
  });

  test('accepts certificates that satisfy every configured check type', () {
    final certificate = _certificate(_subjectPublicKeyInfo([1, 2, 3, 4]));
    final validator = CertificatePinValidator(CertificatePinningOptions(
      rules: [
        CertificatePinningRule(
          hosts: const ['livekit.example.com'],
          pinnedLeafCertificates: [CertificateBytes.der(certificate)],
        ),
        CertificatePinningRule(
          hosts: const ['*.example.com'],
          primaryPins: [certificateSpkiSha256Pin(certificate)],
        ),
      ],
    ));

    expect(
      () => validator.validatePeerCertificate(
        uri: Uri.parse('https://livekit.example.com'),
        certificateDer: certificate,
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
      () => validator.validatePeerCertificate(
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
      () => validator.validatePeerCertificate(
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
      () => validator.validatePeerCertificate(
        uri: Uri.parse('https://project.livekit.cloud'),
        certificateDer: certificate,
      ),
      returnsNormally,
    );
    expect(
      () => validator.validatePeerCertificate(
        uri: Uri.parse('https://a.b.livekit.cloud'),
        certificateDer: _certificate(_subjectPublicKeyInfo([5, 6, 7, 8])),
      ),
      returnsNormally,
    );
  });

  test('multi-label wildcard hosts match any depth', () {
    final certificate = _certificate(_subjectPublicKeyInfo([1, 2, 3, 4]));
    final mismatchedCertificate = _certificate(_subjectPublicKeyInfo([5, 6, 7, 8]));
    final validator = CertificatePinValidator(CertificatePinningOptions(
      rules: [
        CertificatePinningRule(
          hosts: const ['**.livekit.cloud'],
          primaryPins: [certificateSpkiSha256Pin(certificate)],
        ),
      ],
    ));

    // matches one label deep
    expect(
      () => validator.validatePeerCertificate(
        uri: Uri.parse('https://project.livekit.cloud'),
        certificateDer: certificate,
      ),
      returnsNormally,
    );
    // matches regional hosts with multiple labels
    expect(
      () => validator.validatePeerCertificate(
        uri: Uri.parse('https://project.otokyo1a.production.livekit.cloud'),
        certificateDer: certificate,
      ),
      returnsNormally,
    );
    expect(
      () => validator.validatePeerCertificate(
        uri: Uri.parse('https://project.otokyo1a.production.livekit.cloud'),
        certificateDer: mismatchedCertificate,
      ),
      throwsA(isA<CertificatePinningException>()),
    );
    // does not match the bare suffix
    expect(
      () => validator.validatePeerCertificate(
        uri: Uri.parse('https://livekit.cloud'),
        certificateDer: mismatchedCertificate,
      ),
      returnsNormally,
    );
    // anchors on a label boundary
    expect(
      () => validator.validatePeerCertificate(
        uri: Uri.parse('https://other-livekit.cloud'),
        certificateDer: mismatchedCertificate,
      ),
      returnsNormally,
    );
    // does not match when the suffix is embedded in a longer domain
    expect(
      () => validator.validatePeerCertificate(
        uri: Uri.parse('https://livekit.cloud.example.com'),
        certificateDer: mismatchedCertificate,
      ),
      returnsNormally,
    );
    expect(
      () => validator.validatePeerCertificate(
        uri: Uri.parse('https://project.livekit.cloud.example.com'),
        certificateDer: mismatchedCertificate,
      ),
      returnsNormally,
    );
    // matches case-insensitively
    expect(
      () => validator.validatePeerCertificate(
        uri: Uri.parse('https://PROJECT.OTOKYO1A.Production.LiveKit.Cloud'),
        certificateDer: mismatchedCertificate,
      ),
      throwsA(isA<CertificatePinningException>()),
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

List<int> _realCertificateDer() => base64Decode('''
MIIDxzCCAq+gAwIBAgIUGhRL7309IUNTm6hvItsQIT62H2gwDQYJKoZIhvcNAQEL
BQAwVzELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAkNBMRAwDgYDVQQKDAdMaXZlS2l0
MQ0wCwYDVQQLDARUZXN0MRowGAYDVQQDDBFMaXZlS2l0IFRlc3QgQ0EgNjAeFw0y
NjA1MDUwMjA0MzNaFw0yNzA1MDUwMjA0MzNaME8xCzAJBgNVBAYTAlVTMQswCQYD
VQQIDAJDQTEQMA4GA1UECgwHTGl2ZUtpdDENMAsGA1UECwwEVGVzdDESMBAGA1UE
AwwJbG9jYWxob3N0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvYrq
bAiPJeD0XiRzQ5R1sc5nXAkD0H/OetANRi/UzLu7CxyjhqUltGxKuIHLBdDi/s7Y
EYB2rb3ZP83NDVrgwaQo0doMcDg75DxT4/XgLst9yqAVH85UvvKC/RqR4TUtjZm8
omKma7/E8DBk7fswydWigMV9x/xMZmPi3v+U9oTo20xrx33z14DhMS8H5VqAoLf8
cHJRiRv/LU69ZWzSxjRSYlQS95/KmmfWYdEAu+oDmhEBtQ5ipD/7GeUt7QcziGyU
SBrma62Oun6m60UABR4DoMpJh2dhfmEaTF5owYpw5UpwIDDNDecrncbShe/TJGb7
b4Q4PwRbuhKR4IfyiQIDAQABo4GSMIGPMBoGA1UdEQQTMBGCCWxvY2FsaG9zdIcE
fwAAATAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUFBwMBMA4GA1UdDwEB
/wQEAwIFoDAdBgNVHQ4EFgQUuGJ7ZDy7LJqU1pk1gC8ml05KgWcwHwYDVR0jBBgw
FoAUg+7Hk3BurDFOTGImSR9YV2czA74wDQYJKoZIhvcNAQELBQADggEBAELuskBJ
vmvmtwVgQBjV+XP5cMAo9K0niLEtiSTVbIb82Zn8td5paIHLtdCUWo47FsXGcEka
xjHF7F+c+xSmLcmyscwIoueMlMznCMV9pd2Q9VKbGt/2H/YJKFkq151l3+DVrRNN
CxyX1bjWBvpPpwVVVtz9Ydrp5Uvmzd4IrtYJRz/Ty62y2YKmqEVmsfBqBvdxbF5R
/3Ss8AN3k/+SeRj2LFDg+0ekEAkzx08wG2Zhoj6kS98fldpao90JCOiSEn2DHcv6
jOt2XQ4kR0oSVkU+KyVyGtMhNjjQnWjJOuVpo/rdhtEKz4/9B4ofKYgoaeATqoQg
Jioy3puXYIMud+Y=
'''
    .replaceAll(RegExp(r'\s'), ''));

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
