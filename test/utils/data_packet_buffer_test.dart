// Copyright 2024 LiveKit, Inc.
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

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/src/utils/data_packet_buffer.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;

void main() {
  group('DataPacketBuffer', () {
    late DataPacketBuffer buffer;

    setUp(() {
      buffer = DataPacketBuffer(
        maxBufferSize: 1024, // 1KB for testing
        maxPacketCount: 5, // 5 packets for testing
      );
    });

    BufferedDataPacket createTestPacket(int sequence, String data) {
      final userPacket = lk_models.UserPacket()..payload = data.codeUnits;

      final packet = lk_models.DataPacket()
        ..sequence = sequence
        ..kind = lk_models.DataPacket_Kind.RELIABLE
        ..user = userPacket;

      final message = rtc.RTCDataChannelMessage.fromBinary(
        Uint8List.fromList(data.codeUnits),
      );

      return BufferedDataPacket(
        packet: packet,
        message: message,
        sequence: sequence,
      );
    }

    group('Basic Operations', () {
      test('should be empty initially', () {
        expect(buffer.isEmpty, isTrue);
        expect(buffer.isNotEmpty, isFalse);
        expect(buffer.length, equals(0));
        expect(buffer.totalSize, equals(0));
      });

      test('should push and track packets correctly', () {
        final packet1 = createTestPacket(1, 'hello');
        final packet2 = createTestPacket(2, 'world');

        buffer.push(packet1);
        expect(buffer.length, equals(1));
        expect(buffer.totalSize, equals(5)); // 'hello'.length
        expect(buffer.isEmpty, isFalse);
        expect(buffer.isNotEmpty, isTrue);

        buffer.push(packet2);
        expect(buffer.length, equals(2));
        expect(buffer.totalSize, equals(10)); // 'hello' + 'world'
      });

      test('should pop packets correctly', () {
        final packet1 = createTestPacket(1, 'hello');
        final packet2 = createTestPacket(2, 'world');

        buffer.push(packet1);
        buffer.push(packet2);

        final popped = buffer.pop();
        expect(popped, isNotNull);
        expect(popped!.sequence, equals(1));
        expect(buffer.length, equals(1));
        expect(buffer.totalSize, equals(5)); // only 'world' left

        final popped2 = buffer.pop();
        expect(popped2!.sequence, equals(2));
        expect(buffer.isEmpty, isTrue);
        expect(buffer.totalSize, equals(0));

        final popped3 = buffer.pop();
        expect(popped3, isNull);
      });

      test('should clear buffer correctly', () {
        buffer.push(createTestPacket(1, 'hello'));
        buffer.push(createTestPacket(2, 'world'));

        buffer.clear();
        expect(buffer.isEmpty, isTrue);
        expect(buffer.totalSize, equals(0));
        expect(buffer.length, equals(0));
      });

      test('should get all packets correctly', () {
        final packet1 = createTestPacket(1, 'hello');
        final packet2 = createTestPacket(2, 'world');

        buffer.push(packet1);
        buffer.push(packet2);

        final all = buffer.getAll();
        expect(all.length, equals(2));
        expect(all[0].sequence, equals(1));
        expect(all[1].sequence, equals(2));

        // Should be a copy, not the original
        all.clear();
        expect(buffer.length, equals(2));
      });
    });

    group('Sequence Management', () {
      test('should popToSequence correctly (removes acknowledged messages)', () {
        buffer.push(createTestPacket(1, 'a'));
        buffer.push(createTestPacket(2, 'b'));
        buffer.push(createTestPacket(3, 'c'));
        buffer.push(createTestPacket(4, 'd'));

        // This simulates server acknowledging up to sequence 2
        // Should remove packets 1 and 2, keep 3 and 4
        buffer.popToSequence(2);

        final remaining = buffer.getAll();
        expect(remaining.length, equals(2));
        expect(remaining[0].sequence, equals(3));
        expect(remaining[1].sequence, equals(4));
        expect(buffer.totalSize, equals(2)); // 'c' + 'd'
      });

      test('should handle popToSequence with empty buffer', () {
        buffer.popToSequence(5);
        expect(buffer.isEmpty, isTrue);
      });

      test('should handle popToSequence beyond all packets', () {
        buffer.push(createTestPacket(1, 'a'));
        buffer.push(createTestPacket(2, 'b'));

        buffer.popToSequence(10);
        expect(buffer.isEmpty, isTrue);
        expect(buffer.totalSize, equals(0));
      });
    });

    group('Buffer Alignment', () {
      test('should alignBufferedAmount correctly', () {
        buffer.push(createTestPacket(1, 'hello')); // 5 bytes
        buffer.push(createTestPacket(2, 'world')); // 5 bytes
        buffer.push(createTestPacket(3, 'test')); // 4 bytes
        // Total: 14 bytes

        // If bufferedAmount is 6, we should remove packets until
        // totalSize - nextPacketSize <= bufferedAmount
        // Current: 14 bytes, bufferedAmount: 6
        // Check packet 1 (5 bytes): 14 - 5 = 9 > 6, so remove it
        // Check packet 2 (5 bytes): 9 - 5 = 4 <= 6, so keep it
        buffer.alignBufferedAmount(6);

        final remaining = buffer.getAll();
        expect(remaining.length, equals(2)); // packets 2 and 3 remain
        expect(remaining[0].sequence, equals(2));
        expect(remaining[1].sequence, equals(3));
        expect(buffer.totalSize, equals(9)); // 'world' + 'test'
      });

      test('should not remove packets when buffer is already aligned', () {
        buffer.push(createTestPacket(1, 'hi')); // 2 bytes
        buffer.push(createTestPacket(2, 'yo')); // 2 bytes
        // Total: 4 bytes

        buffer.alignBufferedAmount(10);

        expect(buffer.length, equals(2));
        expect(buffer.totalSize, equals(4));
      });

      test('should handle alignBufferedAmount with empty buffer', () {
        buffer.alignBufferedAmount(10);
        expect(buffer.isEmpty, isTrue);
      });

      test('should remove all packets if bufferedAmount is 0', () {
        buffer.push(createTestPacket(1, 'hello'));
        buffer.push(createTestPacket(2, 'world'));

        buffer.alignBufferedAmount(0);
        expect(buffer.isEmpty, isTrue);
        expect(buffer.totalSize, equals(0));
      });
    });

    group('Buffer Limits', () {
      test('should enforce packet count limit', () {
        // Buffer limit is 5 packets
        for (int i = 1; i <= 7; i++) {
          buffer.push(createTestPacket(i, 'x'));
        }

        // Should only keep latest 5 packets
        expect(buffer.length, equals(5));
        final remaining = buffer.getAll();
        expect(remaining[0].sequence, equals(3)); // oldest kept
        expect(remaining[4].sequence, equals(7)); // newest
      });

      test('should enforce size limit', () {
        // Buffer limit is 1024 bytes
        // Create packets with 300 bytes each
        final largeData = 'x' * 300;

        for (int i = 1; i <= 5; i++) {
          buffer.push(createTestPacket(i, largeData));
        }

        // 5 * 300 = 1500 bytes > 1024, so should remove old packets
        expect(buffer.totalSize, lessThanOrEqualTo(1024));
        expect(buffer.length, lessThan(5));
      });

      test('should report limit status correctly', () {
        expect(buffer.isOverSizeLimit, isFalse);
        expect(buffer.isOverCountLimit, isFalse);
        expect(buffer.isOverLimits, isFalse);

        // Add packets to exceed count limit
        for (int i = 1; i <= 6; i++) {
          buffer.push(createTestPacket(i, 'x'));
        }

        // Limits should be enforced automatically, so should not be over limits
        expect(buffer.isOverCountLimit, isFalse);
        expect(buffer.isOverLimits, isFalse);
      });

      test('should report utilization correctly', () {
        expect(buffer.sizeUtilization, equals(0.0));
        expect(buffer.countUtilization, equals(0.0));

        buffer.push(createTestPacket(1, 'x' * 512)); // Half of 1024 byte limit
        expect(buffer.sizeUtilization, closeTo(0.5, 0.01));
        expect(buffer.countUtilization, equals(0.2)); // 1 of 5 packets

        buffer.push(createTestPacket(2, 'x' * 256));
        expect(buffer.sizeUtilization, closeTo(0.75, 0.01));
        expect(buffer.countUtilization, equals(0.4)); // 2 of 5 packets
      });
    });

    group('Edge Cases', () {
      test('should handle single packet larger than buffer limit', () {
        final largeData = 'x' * 2000; // Larger than 1KB limit
        buffer.push(createTestPacket(1, largeData));

        // Should still keep the packet even though it exceeds the limit
        expect(buffer.length, equals(1));
        expect(buffer.totalSize, equals(2000));
      });

      test('should handle multiple operations on empty buffer', () {
        buffer.pop();
        buffer.popToSequence(10);
        buffer.alignBufferedAmount(100);
        buffer.clear();

        expect(buffer.isEmpty, isTrue);
        expect(buffer.totalSize, equals(0));
      });

      test('should maintain consistency after limit enforcement', () {
        // Add many packets to trigger limit enforcement
        for (int i = 1; i <= 10; i++) {
          buffer.push(createTestPacket(i, 'data$i'));
        }

        // Verify buffer is consistent
        final totalSizeCalculated =
            buffer.getAll().map((p) => p.message.binary.length).fold<int>(0, (sum, size) => sum + size);

        expect(buffer.totalSize, equals(totalSizeCalculated));
        expect(buffer.length, equals(buffer.getAll().length));
      });
    });
  });
}
