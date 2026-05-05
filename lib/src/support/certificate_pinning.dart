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

  void validateTrustedCertificate({
    required Uri uri,
    required List<int>? certificateDer,
  }) {
    if (!isEnabled || (!uri.isScheme('https') && !uri.isScheme('wss'))) {
      return;
    }

    final host = uri.host.toLowerCase();
    final trustedCertificates = rulesForHost(host)
        .where((rule) => rule.hasTrustedCertificates)
        .expand((rule) => rule.trustedCertificateBytes)
        .expand(certificateDerCertificates)
        .toList();
    if (trustedCertificates.isEmpty) {
      return;
    }

    if (certificateDer == null) {
      throw CertificatePinningException(
        'No peer certificate was available for $host',
        host: host,
      );
    }

    if (!trustedCertificates.any((trustedCertificate) => _bytesEqual(trustedCertificate, certificateDer))) {
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
  final pemMatches = RegExp(
    r'-----BEGIN CERTIFICATE-----(.*?)-----END CERTIFICATE-----',
    dotAll: true,
  ).allMatches(text);
  var foundPem = false;
  for (final match in pemMatches) {
    foundPem = true;
    yield base64Decode(match.group(1)!.replaceAll(RegExp(r'\s'), ''));
  }
  if (!foundPem) {
    yield certificateBytes;
  }
}

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
  final certificateReader = _DerReader(certificateDer);
  final certificate = certificateReader.readElement();
  certificate.expectTag(0x30, 'certificate');

  final certificateContent = _DerReader(
    certificateDer,
    start: certificate.valueStart,
    end: certificate.valueEnd,
  );
  final tbsCertificate = certificateContent.readElement();
  tbsCertificate.expectTag(0x30, 'TBSCertificate');

  final tbsContent = _DerReader(
    certificateDer,
    start: tbsCertificate.valueStart,
    end: tbsCertificate.valueEnd,
  );

  final first = tbsContent.readElement();
  if (first.tag != 0xa0) {
    tbsContent.offset = first.start;
  }

  for (var i = 0; i < 5; i++) {
    tbsContent.readElement();
  }

  final subjectPublicKeyInfo = tbsContent.readElement();
  subjectPublicKeyInfo.expectTag(0x30, 'SubjectPublicKeyInfo');
  return Uint8List.sublistView(
    certificateDer,
    subjectPublicKeyInfo.start,
    subjectPublicKeyInfo.end,
  );
}

class _DerReader {
  final Uint8List bytes;
  final int end;
  int offset;

  _DerReader(
    this.bytes, {
    int start = 0,
    int? end,
  })  : offset = start,
        end = end ?? bytes.length;

  _DerElement readElement() {
    final start = offset;
    if (start >= end) {
      throw const FormatException('Unexpected end of DER data');
    }

    final tag = bytes[offset++];
    if (offset >= end) {
      throw const FormatException('Missing DER length');
    }

    final firstLengthByte = bytes[offset++];
    final length = _readLength(firstLengthByte);
    final valueStart = offset;
    final valueEnd = valueStart + length;
    if (valueEnd > end) {
      throw const FormatException('DER length exceeds container length');
    }

    offset = valueEnd;
    return _DerElement(
      tag: tag,
      start: start,
      valueStart: valueStart,
      valueEnd: valueEnd,
    );
  }

  int _readLength(int firstLengthByte) {
    if ((firstLengthByte & 0x80) == 0) {
      return firstLengthByte;
    }

    final byteCount = firstLengthByte & 0x7f;
    if (byteCount == 0) {
      throw const FormatException('Indefinite DER lengths are not supported');
    }
    if (byteCount > 4 || offset + byteCount > end) {
      throw const FormatException('Invalid DER length');
    }

    var length = 0;
    for (var i = 0; i < byteCount; i++) {
      length = (length << 8) | bytes[offset++];
    }
    return length;
  }
}

class _DerElement {
  final int tag;
  final int start;
  final int valueStart;
  final int valueEnd;

  const _DerElement({
    required this.tag,
    required this.start,
    required this.valueStart,
    required this.valueEnd,
  });

  int get end => valueEnd;

  void expectTag(int expectedTag, String name) {
    if (tag != expectedTag) {
      throw FormatException(
          'Expected $name DER tag 0x${expectedTag.toRadixString(16)}, got 0x${tag.toRadixString(16)}');
    }
  }
}
