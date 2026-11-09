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

import 'package:livekit_client/src/core/transport.dart';

Map<String, dynamic> _section(List<(int, String)> ext) => {
  'type': 'video',
  'ext': [
    for (final (id, uri) in ext) {'value': id, 'uri': uri},
  ],
};

List<int> _ddIds(Map<String, dynamic> media) => [
  for (final e in media['ext'] as List)
    if (e['uri'] == ddExtensionURI) e['value'] as int,
];

void main() {
  group('Transport.ensureVideoDDExtension', () {
    test('picks an id above every id in the bundle, not only in the section', () {
      final send = _section([(1, 'urn:a'), (9, 'urn:b')]);
      final recv = _section([(2, 'urn:a2')]);
      final id = Transport.ensureVideoDDExtension(recv, [send, recv], 0);
      expect(id, 10);
      expect(_ddIds(recv), [10]);
    });

    test('steps over the reserved id 15', () {
      final media = _section([(14, 'urn:a')]);
      expect(Transport.ensureVideoDDExtension(media, [media], 0), 16);
    });

    test('reuses the id the extension already has elsewhere in the bundle', () {
      final send = _section([(1, 'urn:a'), (11, ddExtensionURI)]);
      final recv = _section([(1, 'urn:a')]);
      expect(Transport.ensureVideoDDExtension(recv, [send, recv], 3), 11);
      expect(_ddIds(recv), [11]);
    });

    test('leaves the section alone when the mapped id also stands for another URI', () {
      final send = _section([(4, ddExtensionURI)]);
      final recv = _section([(4, 'urn:other')]);
      expect(Transport.ensureVideoDDExtension(recv, [send, recv], 7), 7);
      expect(_ddIds(recv), isEmpty);
    });

    test('keeps the cached id while it is free, and moves off it once taken', () {
      final free = _section([(1, 'urn:a')]);
      expect(Transport.ensureVideoDDExtension(free, [free], 5), 5);

      final taken = _section([(1, 'urn:a'), (5, 'urn:b')]);
      expect(Transport.ensureVideoDDExtension(taken, [taken], 5), 6);
    });

    test('creates the extension list of a section that has none', () {
      final media = <String, dynamic>{'type': 'video'};
      expect(Transport.ensureVideoDDExtension(media, [media], 0), 1);
      expect(_ddIds(media), [1]);
    });
  });
}
