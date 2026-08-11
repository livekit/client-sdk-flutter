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

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/src/connection_check/checks/webrtc.dart';

void main() {
  group('parseIceCandidate', () {
    test('parses a udp host candidate', () {
      final candidate = parseIceCandidate('candidate:842163049 1 udp 1677729535 203.0.113.5 40183 typ srflx');
      expect(candidate, isNotNull);
      expect(candidate!.protocol, 'udp');
      expect(candidate.address, '203.0.113.5');
      expect(candidate.port, 40183);
      expect(candidate.type, 'srflx');
      expect(candidate.tcpType, isNull);
    });

    test('parses a passive tcp candidate with extensions', () {
      final candidate = parseIceCandidate(
          'candidate:1467250027 1 tcp 1518280447 198.51.100.1 443 typ host tcptype passive generation 0');
      expect(candidate, isNotNull);
      expect(candidate!.protocol, 'tcp');
      expect(candidate.address, '198.51.100.1');
      expect(candidate.port, 443);
      expect(candidate.type, 'host');
      expect(candidate.tcpType, 'passive');
    });

    test('parses a relay candidate with raddr/rport', () {
      final candidate = parseIceCandidate(
          'candidate:3098175849 1 udp 25108223 192.0.2.10 60690 typ relay raddr 203.0.113.5 rport 40183');
      expect(candidate, isNotNull);
      expect(candidate!.type, 'relay');
      expect(candidate.address, '192.0.2.10');
    });

    test('accepts an a= prefixed line', () {
      final candidate = parseIceCandidate('a=candidate:842163049 1 udp 1677729535 203.0.113.5 40183 typ host');
      expect(candidate, isNotNull);
      expect(candidate!.type, 'host');
    });

    test('returns null on malformed input', () {
      expect(parseIceCandidate(''), isNull);
      expect(parseIceCandidate('not a candidate'), isNull);
      expect(parseIceCandidate('candidate:1 1 udp 1 1.2.3.4 notaport typ host'), isNull);
      expect(parseIceCandidate('candidate:1 1 udp 1 1.2.3.4 1234 nottyp host'), isNull);
    });
  });

  group('isIpPrivate', () {
    test('detects private IPv4 ranges', () {
      expect(isIpPrivate('10.0.0.1'), true);
      expect(isIpPrivate('192.168.1.10'), true);
      expect(isIpPrivate('172.16.0.1'), true);
      expect(isIpPrivate('172.31.255.255'), true);
    });

    test('treats public addresses as public', () {
      expect(isIpPrivate('172.15.0.1'), false);
      expect(isIpPrivate('172.32.0.1'), false);
      expect(isIpPrivate('8.8.8.8'), false);
      expect(isIpPrivate('203.0.113.5'), false);
      expect(isIpPrivate('2001:db8::1'), false);
    });
  });
}
