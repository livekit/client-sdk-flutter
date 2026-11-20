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

// What a stream writer does when it is closed more than once or written to after it was closed.
// Both implementations run here, the web one is plain Dart.

@TestOn('vm')
@Timeout(Duration(seconds: 20))
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/data_stream/data_streams.dart';
import 'package:livekit_client/src/data_stream/data_streams_web.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';

void main() {
  late E2EContainer container;

  setUp(() async {
    resetMockDataChannels();
    container = E2EContainer();
    await container.connectRoom(captureOutbound: true);
    await container.simulateRemoteParticipantJoin('alice', clientProtocol: 2);
    container.capturedDataPackets.clear();
  });

  tearDown(() async {
    await container.dispose();
  });

  List<lk_models.DataPacket> packets(String streamId) => container.capturedDataPackets
      .where(
        (p) =>
            (p.hasStreamHeader() && p.streamHeader.streamId == streamId) ||
            (p.hasStreamChunk() && p.streamChunk.streamId == streamId) ||
            (p.hasStreamTrailer() && p.streamTrailer.streamId == streamId),
      )
      .toList();

  /// Waits for the stream's trailer, which the native implementation sends after close() returns.
  Future<List<lk_models.DataPacket>> packetsOnceEnded(String streamId) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!packets(streamId).any((p) => p.hasStreamTrailer())) {
      if (DateTime.now().isAfter(deadline)) fail('no trailer for $streamId');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    // Anything sent after the trailer would follow it closely.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return packets(streamId);
  }

  final implementations = <String, DataStreams Function()>{
    'native': () => container.room.dataStreams,
    'web': () => WebDataStreams(container.room),
  };

  for (final MapEntry(key: name, value: streams) in implementations.entries) {
    group(name, () {
      test('closing a text writer twice ends the stream once', () async {
        final writer = await streams().streamText(StreamTextOptions(topic: 'chat'));
        await writer.write('hello');
        await writer.close();
        await writer.close();

        final sent = await packetsOnceEnded(writer.info.id);
        expect(sent.where((p) => p.hasStreamTrailer()), hasLength(1));
      });

      test('closing a byte writer twice ends the stream once', () async {
        final writer = await streams().streamBytes(StreamBytesOptions(topic: 'files'));
        await writer.write(Uint8List.fromList([1, 2, 3]));
        await writer.close();
        await writer.close();

        final sent = await packetsOnceEnded(writer.info.id);
        expect(sent.where((p) => p.hasStreamTrailer()), hasLength(1));
      });

      test('a write after close fails and sends nothing', () async {
        final writer = await streams().streamText(StreamTextOptions(topic: 'chat'));
        await writer.write('hello');
        await writer.close();

        await expectLater(
          writer.write('late'),
          throwsA(isA<DataStreamError>().having((e) => e.reason, 'reason', DataStreamErrorReason.AlreadyClosed)),
        );

        final sent = await packetsOnceEnded(writer.info.id);
        expect(sent.last.hasStreamTrailer(), isTrue, reason: 'a chunk followed the trailer');
        expect(sent.where((p) => p.hasStreamChunk()), hasLength(1));
      });

      test('a close issued while a write is in flight ends the stream after it', () async {
        final writer = await streams().streamBytes(StreamBytesOptions(topic: 'files'));
        // More than one chunk, so the write is still sending when close() is called.
        final write = writer.write(Uint8List(40000));
        final close = writer.close();
        await Future.wait([write, close]);

        final sent = await packetsOnceEnded(writer.info.id);
        expect(sent.last.hasStreamTrailer(), isTrue, reason: 'the trailer was sent before the last chunk');
        expect(sent.where((p) => p.hasStreamTrailer()), hasLength(1));
        expect(sent.where((p) => p.hasStreamChunk()).length, greaterThan(1));
      });
    });
  }
}
