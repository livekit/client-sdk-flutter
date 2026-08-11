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
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';

import '../exceptions.dart';
import '../options.dart';

class CertificatePinValidator {
  final CertificatePinningOptions? _options;

  const CertificatePinValidator(this._options);

  bool get isEnabled => _options?.isEnabled ?? false;

  /// Runs every check type configured for the connection host. Check types
  /// are combined, each configured type must pass.
  void validatePeerCertificate({
    required Uri uri,
    required List<int>? certificateDer,
  }) {
    if (!isEnabled || (!uri.isScheme('https') && !uri.isScheme('wss'))) {
      return;
    }

    final host = uri.host.toLowerCase();
    final rules = rulesForHost(host);
    _validatePinnedLeafCertificates(host, rules, certificateDer);
    _validateSpkiPins(host, rules, certificateDer);
  }

  void _validateSpkiPins(String host, List<CertificatePinningRule> rules, List<int>? certificateDer) {
    final acceptedPins = rules
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

  void _validatePinnedLeafCertificates(String host, List<CertificatePinningRule> rules, List<int>? certificateDer) {
    final pinnedCertificates = rules
        .where((rule) => rule.hasPinnedLeafCertificates)
        .expand((rule) => rule.pinnedLeafCertificates)
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

    const bytesEquality = ListEquality<int>();
    if (!pinnedCertificates.any((pinnedCertificate) => bytesEquality.equals(pinnedCertificate, certificateDer))) {
      throw CertificatePinningException(
        'Certificate mismatch for $host',
        host: host,
      );
    }
  }

  List<CertificatePinningRule> rulesForHost(String host) {
    final lowerHost = host.toLowerCase();
    return [
      for (final rule in _options?.rules ?? const <CertificatePinningRule>[])
        if (rule.hosts.isEmpty || rule.hosts.any((pattern) => _hostMatches(lowerHost, pattern))) rule,
    ];
  }
}

String certificateSpkiSha256Pin(List<int> certificateDer) {
  final subjectPublicKeyInfo = _extractSubjectPublicKeyInfo(Uint8List.fromList(certificateDer));
  final digest = sha256.convert(subjectPublicKeyInfo);
  return 'sha256/${base64Encode(digest.bytes)}';
}

Iterable<List<int>> certificateDerCertificates(CertificateBytes certificate) sync* {
  switch (certificate.encoding) {
    case CertificateBytesEncoding.pem:
      yield* _certificateDerCertificatesFromPem(certificate.bytes);
    case CertificateBytesEncoding.der:
      yield certificate.bytes;
  }
}

Iterable<List<int>> _certificateDerCertificatesFromPem(List<int> certificateBytes) sync* {
  final text = utf8.decode(certificateBytes, allowMalformed: true);
  final pemMatches = _certificatePemPattern.allMatches(text);
  var foundPem = false;
  for (final match in pemMatches) {
    foundPem = true;
    yield base64Decode(match.group(1)!.replaceAll(RegExp(r'\s'), ''));
  }
  if (!foundPem) {
    throw const FormatException('No PEM certificates found');
  }
}

List<int> certificatePemBytes(CertificateBytes certificate) {
  switch (certificate.encoding) {
    case CertificateBytesEncoding.pem:
      return certificate.bytes;
    case CertificateBytesEncoding.der:
      return _certificatePemBytesFromDer(certificate.bytes);
  }
}

List<int> _certificatePemBytesFromDer(List<int> certificateBytes) {
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
  if (normalizedPattern.startsWith('**.')) {
    final suffix = normalizedPattern.substring(3);
    // anchor on a label boundary so **.livekit.cloud does not match
    // other-livekit.cloud or livekit.cloud itself
    return host != suffix && host.endsWith('.$suffix');
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
