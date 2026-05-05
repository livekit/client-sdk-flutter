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
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:crypto/crypto.dart';

import '../exceptions.dart';
import '../options.dart';

class CertificatePinValidator {
  final CertificatePinningOptions? _options;

  const CertificatePinValidator(this._options);

  bool get isEnabled => _options?.isEnabled ?? false;

  void validate({
    required Uri uri,
    required List<int>? certificateDer,
  }) {
    if (!isEnabled || (!uri.isScheme('https') && !uri.isScheme('wss'))) {
      return;
    }

    final host = uri.host.toLowerCase();
    final acceptedPins = rulesForHost(host)
        .where((rule) => rule.hasSpkiPins)
        .expand((rule) => rule.allPins)
        .map(_normalizeSha256Pin)
        .where((pin) => pin.isNotEmpty)
        .toSet();
    if (acceptedPins.isEmpty) {
      return;
    }

    if (certificateDer == null) {
      throw CertificatePinningException(
        'No peer certificate was available for $host',
        host: host,
      );
    }

    late final String presentedPin;
    try {
      presentedPin = certificateSpkiSha256Pin(certificateDer);
    } catch (error) {
      throw CertificatePinningException(
        'Could not parse peer certificate for $host: $error',
        host: host,
      );
    }

    if (!acceptedPins.contains(presentedPin)) {
      throw CertificatePinningException(
        'Certificate pin mismatch for $host',
        host: host,
        presentedPin: presentedPin,
      );
    }
  }

  void validatePinnedCertificate({
    required Uri uri,
    required List<int>? certificateDer,
  }) {
    if (!isEnabled || (!uri.isScheme('https') && !uri.isScheme('wss'))) {
      return;
    }

    final host = uri.host.toLowerCase();
    final pinnedCertificates = rulesForHost(host)
        .where((rule) => rule.hasPinnedCertificates)
        .expand((rule) => rule.pinnedCertificateBytes)
        .expand(certificateDerCertificates)
        .toList();
    if (pinnedCertificates.isEmpty) {
      return;
    }

    if (certificateDer == null) {
      throw CertificatePinningException(
        'No peer certificate was available for $host',
        host: host,
      );
    }

    if (!pinnedCertificates.any((pinnedCertificate) => _bytesEqual(pinnedCertificate, certificateDer))) {
      throw CertificatePinningException(
        'Certificate mismatch for $host',
        host: host,
      );
    }
  }

  List<CertificatePinningRule> rulesForHost(String host) => [
        for (final rule in _options?.rules ?? const <CertificatePinningRule>[])
          if (rule.hosts.isEmpty || rule.hosts.any((pattern) => _hostMatches(host.toLowerCase(), pattern))) rule,
      ];
}

String certificateSpkiSha256Pin(List<int> certificateDer) {
  final subjectPublicKeyInfo = _extractSubjectPublicKeyInfo(Uint8List.fromList(certificateDer));
  final digest = sha256.convert(subjectPublicKeyInfo);
  return 'sha256/${base64Encode(digest.bytes)}';
}

Iterable<List<int>> certificateDerCertificates(List<int> certificateBytes) sync* {
  final text = utf8.decode(certificateBytes, allowMalformed: true);
  final pemMatches = _certificatePemPattern.allMatches(text);
  var foundPem = false;
  for (final match in pemMatches) {
    foundPem = true;
    yield base64Decode(match.group(1)!.replaceAll(RegExp(r'\s'), ''));
  }
  if (!foundPem) {
    yield certificateBytes;
  }
}

List<int> certificatePemBytes(List<int> certificateBytes) {
  final text = utf8.decode(certificateBytes, allowMalformed: true);
  if (_certificatePemPattern.hasMatch(text)) {
    return certificateBytes;
  }

  final base64Certificate = base64Encode(certificateBytes);
  final lines = <String>[];
  for (var offset = 0; offset < base64Certificate.length; offset += 64) {
    final end = offset + 64;
    lines.add(base64Certificate.substring(offset, end > base64Certificate.length ? base64Certificate.length : end));
  }
  return ascii.encode('-----BEGIN CERTIFICATE-----\n${lines.join('\n')}\n-----END CERTIFICATE-----\n');
}

final _certificatePemPattern = RegExp(
  r'-----BEGIN CERTIFICATE-----(.*?)-----END CERTIFICATE-----',
  dotAll: true,
);

String _normalizeSha256Pin(String pin) {
  final trimmed = pin.trim();
  final lower = trimmed.toLowerCase();
  if (lower.startsWith('sha256/')) {
    return 'sha256/${trimmed.substring(7).trim()}';
  }
  if (lower.startsWith('sha256:')) {
    return 'sha256/${trimmed.substring(7).trim()}';
  }
  return trimmed.isEmpty ? '' : 'sha256/$trimmed';
}

bool _hostMatches(String host, String pattern) {
  final normalizedPattern = pattern.trim().toLowerCase();
  if (normalizedPattern == '*') {
    return true;
  }
  if (normalizedPattern.startsWith('*.')) {
    final suffix = normalizedPattern.substring(2);
    if (host == suffix || !host.endsWith('.$suffix')) {
      return false;
    }
    final prefix = host.substring(0, host.length - suffix.length - 1);
    return !prefix.contains('.');
  }
  return host == normalizedPattern;
}

bool _bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

Uint8List _extractSubjectPublicKeyInfo(Uint8List certificateDer) {
  final certificate = _asn1Sequence(
    ASN1Parser(certificateDer).nextObject(),
    'certificate',
  );
  final tbsCertificate = _asn1Sequence(
    _asn1Element(certificate, 0, 'TBSCertificate'),
    'TBSCertificate',
  );

  var fieldIndex = 0;
  if (_asn1Element(tbsCertificate, fieldIndex, 'TBSCertificate first field').tag == 0xa0) {
    fieldIndex++;
  }

  final subjectPublicKeyInfo = _asn1Sequence(
    _asn1Element(tbsCertificate, fieldIndex + 5, 'SubjectPublicKeyInfo'),
    'SubjectPublicKeyInfo',
  );
  return subjectPublicKeyInfo.encodedBytes;
}

ASN1Object _asn1Element(ASN1Sequence sequence, int index, String name) {
  if (index >= sequence.elements.length) {
    throw FormatException('Missing $name');
  }
  return sequence.elements[index];
}

ASN1Sequence _asn1Sequence(ASN1Object object, String name) {
  if (object is! ASN1Sequence) {
    throw FormatException('Expected $name sequence, got tag 0x${object.tag.toRadixString(16)}');
  }
  return object;
}
