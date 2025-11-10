import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/src/support/byte_ring_buffer.dart';

void main() {
  group('ByteRingBuffer', () {
    test('accumulates sequential writes without overflow', () {
      final buffer = ByteRingBuffer(8);

      buffer.write(Uint8List.fromList([1, 2, 3]));
      buffer.write(Uint8List.fromList([4, 5]));

      expect(buffer.length, 5);
      expect(buffer.toBytes().toList(), equals([1, 2, 3, 4, 5]));
    });

    test('drops oldest data when capacity exceeded', () {
      final buffer = ByteRingBuffer(5);

      final overflowed1 = buffer.write(Uint8List.fromList([1, 2, 3]));
      final overflowed2 = buffer.write(Uint8List.fromList([4, 5, 6]));

      expect(overflowed1, false);
      expect(overflowed2, true);
      expect(buffer.length, 5);
      expect(buffer.toBytes().toList(), equals([2, 3, 4, 5, 6]));
    });

    test('keeps newest data when chunk larger than capacity', () {
      final buffer = ByteRingBuffer(4);

      final overflowed = buffer.write(Uint8List.fromList([0, 1, 2, 3, 4, 5]));

      expect(overflowed, true);
      expect(buffer.length, 4);
      expect(buffer.toBytes().toList(), equals([2, 3, 4, 5]));
    });

    test('takeBytes returns data and clears buffer', () {
      final buffer = ByteRingBuffer(6);

      buffer.write(Uint8List.fromList([1, 2, 3, 4]));
      final data = buffer.takeBytes();

      expect(data.toList(), equals([1, 2, 3, 4]));
      expect(buffer.length, 0);
      expect(buffer.toBytes(), isEmpty);
    });
  });
}
