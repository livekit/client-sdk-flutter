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

// Data streams v2 wire behavior, asserted on the packets that actually reach the data channel.
//
// These only apply to the native path, where the Rust core does the framing. Web keeps the v1
// Dart implementation and advertises a pre-v2 clientProtocol, so a v2 sender falls back for it —
// there is nothing v2-shaped to assert there.
@TestOn('vm')
@Timeout(Duration(seconds: 20))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/data_stream/data_streams_native.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';

/// A recipient that understands v2 and can decompress.
const _v2WithCompression = [lk_models.ClientInfo_Capability.CAP_COMPRESSION_DEFLATE_RAW];

void main() {
  late E2EContainer container;
  late Room room;

  setUp(() async {
    resetMockDataChannels();
    container = E2EContainer();
    await container.connectRoom(captureOutbound: true);
    room = container.room;
  });

  tearDown(() async {
    await container.dispose();
  });

  /// The stream packets emitted since the last clear, in order.
  List<lk_models.DataPacket> streamPackets() => container.capturedDataPackets
      .where((p) => p.hasStreamHeader() || p.hasStreamChunk() || p.hasStreamTrailer())
      .toList();

  group('send side', () {
    test('a v2 recipient that can decompress gets one compressed inline packet', () async {
      await container.simulateRemoteParticipantJoin(
        'alice',
        clientProtocol: 2,
        capabilities: _v2WithCompression,
      );
      container.capturedDataPackets.clear();

      const text = 'hello hello compressible world';
      await room.localParticipant!.sendText(
        text,
        options: SendTextOptions(topic: 'chat', destinationIdentities: ['alice']),
      );

      final packets = streamPackets();
      expect(packets, hasLength(1), reason: 'inline send is a single packet');
      final header = packets.single.streamHeader;
      expect(header.hasTextHeader(), isTrue);
      expect(header.compression, lk_models.DataStream_CompressionType.DEFLATE_RAW);
      expect(header.hasInlineContent(), isTrue);
      expect(
        header.inlineContent,
        isNot(equals(utf8.encode(text))),
        reason: 'inline content should be the compressed bytes, not the raw UTF-8',
      );
    });

    test('a v2 recipient without the compression capability gets inline but raw', () async {
      await container.simulateRemoteParticipantJoin('noCompression', clientProtocol: 2);
      container.capturedDataPackets.clear();

      const text = 'hello hello compressible world';
      await room.localParticipant!.sendText(
        text,
        options: SendTextOptions(topic: 'chat', destinationIdentities: ['noCompression']),
      );

      final packets = streamPackets();
      expect(packets, hasLength(1), reason: 'inline is gated on clientProtocol alone');
      final header = packets.single.streamHeader;
      expect(header.compression, lk_models.DataStream_CompressionType.NONE);
      expect(header.inlineContent, equals(utf8.encode(text)));
    });

    test('a pre-v2 recipient gets legacy header + chunk + trailer', () async {
      await container.simulateRemoteParticipantJoin('legacy', clientProtocol: 0);
      container.capturedDataPackets.clear();

      const text = 'hello world';
      await room.localParticipant!.sendText(
        text,
        options: SendTextOptions(topic: 'chat', destinationIdentities: ['legacy']),
      );

      final packets = streamPackets();
      expect(packets, hasLength(3));
      expect(packets[0].hasStreamHeader(), isTrue);
      expect(packets[0].streamHeader.compression, lk_models.DataStream_CompressionType.NONE);
      expect(packets[0].streamHeader.hasInlineContent(), isFalse);
      expect(packets[1].hasStreamChunk(), isTrue);
      expect(packets[1].streamChunk.content, equals(utf8.encode(text)));
      expect(packets[2].hasStreamTrailer(), isTrue);
      expect(packets[2].streamTrailer.streamId, equals(packets[0].streamHeader.streamId));
    });

    test('a broadcast to a mixed room falls back to legacy framing', () async {
      await container.simulateRemoteParticipantJoin('alice', clientProtocol: 2, capabilities: _v2WithCompression);
      await container.simulateRemoteParticipantJoin('legacy', clientProtocol: 0);
      container.capturedDataPackets.clear();

      // No destinationIdentities => every remote participant is a recipient, and one is pre-v2.
      await room.localParticipant!.sendText('hello world', options: SendTextOptions(topic: 'chat'));

      final packets = streamPackets();
      expect(packets, hasLength(3), reason: 'one pre-v2 recipient disables inline for everyone');
      expect(packets[0].streamHeader.hasInlineContent(), isFalse);
    });

    test('compress: false keeps inline but sends raw bytes', () async {
      await container.simulateRemoteParticipantJoin('alice', clientProtocol: 2, capabilities: _v2WithCompression);
      container.capturedDataPackets.clear();

      const text = 'hello hello compressible world';
      await room.localParticipant!.sendText(
        text,
        options: SendTextOptions(topic: 'chat', destinationIdentities: ['alice'], compress: false),
      );

      final header = streamPackets().single.streamHeader;
      expect(header.compression, lk_models.DataStream_CompressionType.NONE);
      expect(header.inlineContent, equals(utf8.encode(text)));
    });

    test('streamText never inlines or compresses', () async {
      await container.simulateRemoteParticipantJoin('alice', clientProtocol: 2, capabilities: _v2WithCompression);
      container.capturedDataPackets.clear();

      final writer = await room.localParticipant!.streamText(
        StreamTextOptions(topic: 'chat', destinationIdentities: ['alice']),
      );
      expect(streamPackets(), hasLength(1), reason: 'the header goes out when the stream opens');
      expect(streamPackets().single.streamHeader.compression, lk_models.DataStream_CompressionType.NONE);

      await writer.write('hello world');
      expect(streamPackets(), hasLength(2));
      expect(streamPackets()[1].streamChunk.content, equals(utf8.encode('hello world')));

      await writer.close();
      expect(streamPackets(), hasLength(3));
      expect(streamPackets()[2].hasStreamTrailer(), isTrue);
    });

    test('streamText declares the total size it was given', () async {
      await container.simulateRemoteParticipantJoin('alice', clientProtocol: 2, capabilities: _v2WithCompression);
      container.capturedDataPackets.clear();

      final writer = await room.localParticipant!.streamText(
        StreamTextOptions(topic: 'chat', destinationIdentities: ['alice'], totalSize: 11),
      );
      expect(writer.info.size, 11, reason: 'the sender sees the size it declared');
      expect(streamPackets().single.streamHeader.totalLength.toInt(), 11, reason: 'the recipient is told the size');
      await writer.close();
    });

    test('sendBytes produces a byte header and defaults name/mimeType', () async {
      await container.simulateRemoteParticipantJoin('alice', clientProtocol: 2, capabilities: _v2WithCompression);
      container.capturedDataPackets.clear();

      final info = await room.localParticipant!.sendBytes(
        utf8.encode('hello hello compressible world'),
        options: SendBytesOptions(topic: 'files', destinationIdentities: ['alice']),
      );

      final header = streamPackets().single.streamHeader;
      expect(header.hasByteHeader(), isTrue);
      expect(header.compression, lk_models.DataStream_CompressionType.DEFLATE_RAW);
      expect(info.name, equals('unknown'));
      expect(info.mimeType, equals('application/octet-stream'));
    });

    test('outbound packets wait for the reliable data channel buffer to drain', () async {
      await container.simulateRemoteParticipantJoin('alice', clientProtocol: 2, capabilities: _v2WithCompression);
      final reliable = mockDataChannels.where((dc) => dc.label == '_reliable').toList();
      for (final dc in reliable) {
        dc.fakeBufferedAmount = 1 << 30;
      }
      Iterable<String> sentTopics() => streamPackets().map((p) => p.streamHeader.topic);

      // The engine samples the buffer after each send, so the first packet goes out and leaves
      // the channel marked as above its low-water mark.
      await room.localParticipant!.sendText('first', options: SendTextOptions(topic: 'first'));
      await _waitUntil(() => sentTopics().contains('first'));

      unawaited(room.localParticipant!.sendText('second', options: SendTextOptions(topic: 'second')));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(sentTopics(), isNot(contains('second')), reason: 'held while the buffer is full');

      for (final dc in reliable) {
        dc.fakeBufferedAmount = null;
        dc.onBufferedAmountLow?.call(0);
      }
      await _waitUntil(() => sentTopics().contains('second'));
    });

    group('MIME type inference', () {
      late Directory dir;
      setUp(() async => dir = await Directory.systemTemp.createTemp('lk_mime'));
      tearDown(() async => dir.delete(recursive: true));

      Future<File> file(String name) async => File('${dir.path}/$name')..writeAsBytesSync([1, 2, 3, 4]);

      test('sendFile infers the MIME type from the file name', () async {
        await room.localParticipant!.sendFile(await file('hello.png'), options: SendFileOptions(topic: 'files'));
        expect(streamPackets().first.streamHeader.mimeType, equals('image/png'));
      });

      test('an explicit MIME type wins over inference', () async {
        await room.localParticipant!.sendFile(
          await file('hello.png'),
          options: SendFileOptions(topic: 'files', mimeType: 'application/x-custom'),
        );
        expect(streamPackets().first.streamHeader.mimeType, equals('application/x-custom'));
      });

      test('sendText attachments infer their MIME type', () async {
        await room.localParticipant!.sendText(
          'see attached',
          options: SendTextOptions(topic: 'chat', attachments: [await file('notes.pdf')]),
        );
        final byteHeaders = streamPackets()
            .where((p) => p.hasStreamHeader() && p.streamHeader.hasByteHeader())
            .map((p) => p.streamHeader);
        expect(byteHeaders.single.mimeType, equals('application/pdf'));
      });
    });
  });

  group('receive side', () {
    /// Feeds a single inline text header, as a v2 sender would emit it.
    void feedInlineText({
      required String streamId,
      required String topic,
      required List<int> inlineContent,
      required int totalLength,
      lk_models.DataStream_CompressionType compression = lk_models.DataStream_CompressionType.NONE,
      Map<String, String> attributes = const {},
    }) {
      container.deliverInboundDataPacket(
        lk_models.DataPacket(
          kind: lk_models.DataPacket_Kind.RELIABLE,
          participantIdentity: 'alice',
          streamHeader: lk_models.DataStream_Header(
            streamId: streamId,
            topic: topic,
            mimeType: 'text/plain',
            timestamp: Int64(DateTime.timestamp().millisecondsSinceEpoch),
            totalLength: Int64(totalLength),
            attributes: attributes.entries,
            inlineContent: Uint8List.fromList(inlineContent),
            compression: compression,
            textHeader: lk_models.DataStream_TextHeader(),
          ),
        ),
      );
    }

    test('an inline uncompressed text stream is delivered whole', () async {
      const text = 'hello inline world';
      final received = Completer<String>();
      final gotInfo = Completer<TextStreamInfo>();

      room.registerTextStreamHandler('inline', (reader, identity) async {
        gotInfo.complete(reader.info!);
        received.complete(await reader.readAll());
      });

      feedInlineText(
        streamId: 'inline-1',
        topic: 'inline',
        inlineContent: utf8.encode(text),
        totalLength: utf8.encode(text).length,
        attributes: {'foo': 'bar'},
      );

      expect(await received.future, equals(text));
      final info = await gotInfo.future;
      expect(info.attributes['foo'], equals('bar'));
      expect(info.sendingParticipantIdentity, equals('alice'));
    });

    test('an inline compressed text stream round-trips through the core', () async {
      // Genuinely compressed bytes are hard to hand-write, so let the send path produce them and
      // read them back over the harness's data-channel loopback — a real compress/decompress pass
      // through the Rust core in both directions.
      await container.simulateRemoteParticipantJoin('alice', clientProtocol: 2, capabilities: _v2WithCompression);
      container.capturedDataPackets.clear();

      final received = Completer<String>();
      room.registerTextStreamHandler('compressed', (reader, identity) async {
        received.complete(await reader.readAll());
      });

      const text = 'hello hello compressible world';
      await room.localParticipant!.sendText(
        text,
        options: SendTextOptions(topic: 'compressed', destinationIdentities: ['alice']),
      );

      expect(
        streamPackets().single.streamHeader.compression,
        lk_models.DataStream_CompressionType.DEFLATE_RAW,
        reason: 'the payload really was compressed on the way out',
      );
      expect(await received.future, equals(text));
    });

    test('trailer attributes are merged into the reader info by the time the stream ends', () async {
      final opened = Completer<void>();
      final done = Completer<TextStreamInfo>();
      room.registerTextStreamHandler('trailered', (reader, identity) async {
        opened.complete();
        expect(await reader.readAll(), equals('hello'));
        done.complete(reader.info!);
      });

      lk_models.DataPacket packet() =>
          lk_models.DataPacket(kind: lk_models.DataPacket_Kind.RELIABLE, participantIdentity: 'alice');
      container.deliverInboundDataPacket(
        packet()
          ..streamHeader = lk_models.DataStream_Header(
            streamId: 'trailered-1',
            topic: 'trailered',
            mimeType: 'text/plain',
            timestamp: Int64(DateTime.timestamp().millisecondsSinceEpoch),
            attributes: {'a': '1'}.entries,
            textHeader: lk_models.DataStream_TextHeader(),
          ),
      );
      // The handler has to see the stream before the trailer lands, or the info it is handed would
      // already include the trailer's attributes and prove nothing.
      await opened.future.timeout(const Duration(seconds: 5));
      container.deliverInboundDataPacket(
        packet()
          ..streamChunk = lk_models.DataStream_Chunk(
            streamId: 'trailered-1',
            chunkIndex: Int64(0),
            content: Uint8List.fromList(utf8.encode('hello')),
          ),
      );
      container.deliverInboundDataPacket(
        packet()
          ..streamTrailer = lk_models.DataStream_Trailer(
            streamId: 'trailered-1',
            attributes: {'b': '2'}.entries,
          ),
      );

      final info = await done.future.timeout(const Duration(seconds: 5));
      expect(info.attributes, equals({'a': '1', 'b': '2'}));
    });

    test('a stream on an unregistered topic is ignored', () async {
      var fired = false;
      room.registerTextStreamHandler('registered', (reader, identity) async {
        fired = true;
      });

      feedInlineText(
        streamId: 'inline-2',
        topic: 'not-registered',
        inlineContent: utf8.encode('nobody wants this'),
        totalLength: 17,
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(fired, isFalse);
    });
  });

  group('encryption', () {
    // Transport encryption is applied and undone in the engine, on the whole packet, either side
    // of the FFI: the core only ever sees plaintext. The SDK passes along how each packet
    // actually arrived, and the core holds every stream to the encryption its header arrived
    // under. Injected at the same seam Room uses, below the engine's decrypt.
    lk_models.DataPacket header(String streamId, String topic, {Int64? totalLength, List<int>? inline}) =>
        lk_models.DataPacket(
          kind: lk_models.DataPacket_Kind.RELIABLE,
          participantIdentity: 'alice',
          streamHeader: lk_models.DataStream_Header(
            streamId: streamId,
            topic: topic,
            mimeType: 'text/plain',
            timestamp: Int64(DateTime.timestamp().millisecondsSinceEpoch),
            totalLength: totalLength,
            inlineContent: inline == null ? null : Uint8List.fromList(inline),
            textHeader: lk_models.DataStream_TextHeader(),
          ),
        );

    test('a chunk that changes encryption fails the reader', () async {
      final outcome = Completer<Object?>();
      room.registerTextStreamHandler('sealed', (reader, identity) async {
        try {
          await reader.readAll();
          outcome.complete(null);
        } catch (e) {
          outcome.complete(e);
        }
      });

      room.dataStreams.handleIncomingPacket(
        header('sealed-1', 'sealed', totalLength: Int64(5)),
        EncryptionType.kGcm,
      );
      room.dataStreams.handleIncomingPacket(
        lk_models.DataPacket(
          kind: lk_models.DataPacket_Kind.RELIABLE,
          participantIdentity: 'alice',
          streamChunk: lk_models.DataStream_Chunk(
            streamId: 'sealed-1',
            chunkIndex: Int64(0),
            content: Uint8List.fromList(utf8.encode('hello')),
          ),
        ),
        EncryptionType.kNone,
      );

      final error = await outcome.future.timeout(const Duration(seconds: 5));
      expect(error, isA<DataStreamError>());
      expect((error as DataStreamError).reason, DataStreamErrorReason.EncryptionTypeMismatch);
      // The core reports which types disagreed.
      expect(error.message, contains('expected'));
    });

    test('stream info reports the encryption the stream arrived under', () async {
      // NOT the room's own setting: a plaintext stream in an encrypted room must be reported as
      // plaintext, and vice versa.
      final received = Completer<TextStreamInfo?>();
      room.registerTextStreamHandler('sealed-info', (reader, identity) async {
        received.complete(reader.info);
      });

      room.dataStreams.handleIncomingPacket(
        header('sealed-2', 'sealed-info', totalLength: Int64(2), inline: utf8.encode('hi')),
        EncryptionType.kGcm,
      );

      final info = await received.future.timeout(const Duration(seconds: 5));
      expect(info?.encryptionType, EncryptionType.kGcm);
    });
  });

  group('open stream accounting', () {
    test('cancelling the subscription ends the stream in the core', () async {
      final ds = room.dataStreams as NativeDataStreams;
      final cancelled = Completer<void>();
      room.registerTextStreamHandler('cancelled', (reader, identity) async {
        late final StreamSubscription<lk_models.DataStream_Chunk> sub;
        sub = reader.listen((_) async {
          await sub.cancel();
          cancelled.complete();
        });
      });

      lk_models.DataPacket packet() =>
          lk_models.DataPacket(kind: lk_models.DataPacket_Kind.RELIABLE, participantIdentity: 'alice');
      room.dataStreams.handleIncomingPacket(
        packet()
          ..streamHeader = lk_models.DataStream_Header(
            streamId: 'cancelled-1',
            topic: 'cancelled',
            mimeType: 'text/plain',
            timestamp: Int64(DateTime.timestamp().millisecondsSinceEpoch),
            textHeader: lk_models.DataStream_TextHeader(),
          ),
        EncryptionType.kNone,
      );
      room.dataStreams.handleIncomingPacket(
        packet()
          ..streamChunk = lk_models.DataStream_Chunk(
            streamId: 'cancelled-1',
            chunkIndex: Int64(0),
            content: Uint8List.fromList(utf8.encode('first')),
          ),
        EncryptionType.kNone,
      );

      await cancelled.future.timeout(const Duration(seconds: 5));
      // The pump is now parked in next() with the sender silent; only closing the reader frees
      // the stream. The close reaches the core's loop asynchronously, so give it a moment.
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (await ds.debugOpenStreamCount() != 0 && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(await ds.debugOpenStreamCount(), 0);
    });

    test('the count follows headers, and reset discards the manager', () async {
      room.registerTextStreamHandler('counted', (reader, identity) async {});
      final ds = room.dataStreams as NativeDataStreams;
      expect(await ds.debugOpenStreamCount(), 0);

      // A header with a declared total and no inline content stays open awaiting chunks. The
      // count query is answered in order with the packet fed before it — no polling.
      room.dataStreams.handleIncomingPacket(
        lk_models.DataPacket(
          kind: lk_models.DataPacket_Kind.RELIABLE,
          participantIdentity: 'alice',
          streamHeader: lk_models.DataStream_Header(
            streamId: 'counted-1',
            topic: 'counted',
            mimeType: 'text/plain',
            timestamp: Int64(DateTime.timestamp().millisecondsSinceEpoch),
            totalLength: Int64(5),
            textHeader: lk_models.DataStream_TextHeader(),
          ),
        ),
        EncryptionType.kNone,
      );
      expect(await ds.debugOpenStreamCount(), 1);

      await room.dataStreams.reset();
      expect(await ds.debugOpenStreamCount(), 0, reason: 'reset discards the manager');
    });
  });

  group('after the room closed', () {
    test('sends and writes fail instead of reporting a stream nobody received', () async {
      await container.simulateRemoteParticipantJoin('alice', clientProtocol: 2);
      final local = room.localParticipant!;
      final writer = await local.streamBytes(StreamBytesOptions(topic: 'open'));
      await writer.write(Uint8List.fromList([1, 2, 3]));

      await container.engine.disconnect();
      container.capturedDataPackets.clear();

      final closed = throwsA(isA<UnexpectedConnectionState>());
      await expectLater(local.sendText('late', options: SendTextOptions(topic: 'late')), closed);
      await expectLater(local.sendBytes([1, 2, 3], options: SendBytesOptions(topic: 'late')), closed);
      await expectLater(local.streamText(StreamTextOptions(topic: 'late')), closed);
      await expectLater(local.streamBytes(StreamBytesOptions(topic: 'late')), closed);
      await expectLater(writer.write(Uint8List.fromList([4, 5, 6])), closed);
      // Closing is still allowed, so cleanup code does not have to care.
      await writer.close();

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(streamPackets().where((p) => !p.hasStreamTrailer()), isEmpty);
    });

    test('a stream packet still on its way in does not open a stream', () async {
      final ds = room.dataStreams as NativeDataStreams;
      var opened = 0;
      room.registerTextStreamHandler('late', (reader, identity) async => opened++);

      // Closes the engine and asks the server to leave. The data channel is still open, so a
      // packet the peer sent before it learned of the leave is still delivered.
      await container.engine.disconnect();
      container.deliverInboundDataPacket(
        lk_models.DataPacket(
          kind: lk_models.DataPacket_Kind.RELIABLE,
          participantIdentity: 'alice',
          streamHeader: lk_models.DataStream_Header(
            streamId: 'late-1',
            topic: 'late',
            mimeType: 'text/plain',
            timestamp: Int64(DateTime.timestamp().millisecondsSinceEpoch),
            totalLength: Int64(5),
            textHeader: lk_models.DataStream_TextHeader(),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(opened, 0, reason: 'a handler was given a stream nothing will ever finish or fail');
      expect(await ds.debugOpenStreamCount(), 0);
    });
  });

  group('unread streams', () {
    lk_models.DataPacket header(String topic, String id) => lk_models.DataPacket(
      kind: lk_models.DataPacket_Kind.RELIABLE,
      participantIdentity: 'alice',
      streamHeader: lk_models.DataStream_Header(
        streamId: id,
        topic: topic,
        mimeType: 'text/plain',
        timestamp: Int64(DateTime.timestamp().millisecondsSinceEpoch),
        totalLength: Int64(5),
        textHeader: lk_models.DataStream_TextHeader(),
      ),
    );

    Future<void> expectNoOpenStreams(NativeDataStreams ds, String reason) async {
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (await ds.debugOpenStreamCount() != 0 && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(await ds.debugOpenStreamCount(), 0, reason: reason);
    }

    test('a stream on a topic without a handler is closed in the core', () async {
      final ds = room.dataStreams as NativeDataStreams;
      room.dataStreams.handleIncomingPacket(header('nobody', 'unhandled-1'), EncryptionType.kNone);
      await expectNoOpenStreams(ds, 'an ignored stream kept buffering in the core');
    });

    test('a reader its handler never listened to fails after a reset', () async {
      final delivered = Completer<TextStreamReader>();
      room.registerTextStreamHandler('unread', (reader, identity) async => delivered.complete(reader));
      room.dataStreams.handleIncomingPacket(header('unread', 'unread-1'), EncryptionType.kNone);
      final reader = await delivered.future.timeout(const Duration(seconds: 2));

      await room.dataStreams.reset();

      final outcome = Completer<Object?>();
      reader.listen(
        (_) {},
        onError: (Object e) => outcome.complete(e),
        onDone: () {
          if (!outcome.isCompleted) outcome.complete(null);
        },
      );
      final error = await outcome.future.timeout(const Duration(seconds: 2));
      expect(error, isA<DataStreamError>(), reason: 'the reader completed as if the stream had ended');
      expect((error! as DataStreamError).reason, DataStreamErrorReason.AbnormalEnd);
    });
  });

  group('maxPayloadByteLength', () {
    test('a stream declaring more than the cap fails its reader', () async {
      // A fresh container so the cap is set at connect time, which is when the native manager
      // reads it.
      resetMockDataChannels();
      final capped = E2EContainer();
      addTearDown(capped.dispose);
      await capped.connectRoom(
        connectOptions: const ConnectOptions(
          dataStream: DataStreamOptions(maxPayloadByteLength: 16),
        ),
      );

      // The handler is still invoked — the core reports the stream opened before applying the
      // cap — and it is the read that fails.
      final outcome = Completer<Object?>();
      capped.room.registerTextStreamHandler('capped', (reader, identity) async {
        try {
          await reader.readAll();
          outcome.complete(null);
        } catch (e) {
          outcome.complete(e);
        }
      });

      capped.deliverInboundDataPacket(
        lk_models.DataPacket(
          kind: lk_models.DataPacket_Kind.RELIABLE,
          participantIdentity: 'alice',
          streamHeader: lk_models.DataStream_Header(
            streamId: 'too-big',
            topic: 'capped',
            mimeType: 'text/plain',
            timestamp: Int64(DateTime.timestamp().millisecondsSinceEpoch),
            totalLength: Int64(1000),
            inlineContent: Uint8List.fromList(utf8.encode('x' * 1000)),
            textHeader: lk_models.DataStream_TextHeader(),
          ),
        ),
      );

      final error = await outcome.future.timeout(const Duration(seconds: 5));
      expect(error, isA<DataStreamError>());
      expect(
        (error as DataStreamError).reason,
        DataStreamErrorReason.LengthExceeded,
        reason: 'the payload exceeds maxPayloadByteLength',
      );
    });

    test('a stream within the cap is delivered', () async {
      resetMockDataChannels();
      final capped = E2EContainer();
      addTearDown(capped.dispose);
      await capped.connectRoom(
        connectOptions: const ConnectOptions(
          dataStream: DataStreamOptions(maxPayloadByteLength: 1000),
        ),
      );

      const text = 'small enough';
      final received = Completer<String>();
      capped.room.registerTextStreamHandler('capped', (reader, identity) async {
        received.complete(await reader.readAll());
      });

      capped.deliverInboundDataPacket(
        lk_models.DataPacket(
          kind: lk_models.DataPacket_Kind.RELIABLE,
          participantIdentity: 'alice',
          streamHeader: lk_models.DataStream_Header(
            streamId: 'small',
            topic: 'capped',
            mimeType: 'text/plain',
            timestamp: Int64(DateTime.timestamp().millisecondsSinceEpoch),
            totalLength: Int64(utf8.encode(text).length),
            inlineContent: Uint8List.fromList(utf8.encode(text)),
            textHeader: lk_models.DataStream_TextHeader(),
          ),
        ),
      );

      expect(await received.future, equals(text));
    });
  });
}

/// Polls [condition] until it holds, failing after [timeout].
Future<void> _waitUntil(bool Function() condition, {Duration timeout = const Duration(seconds: 5)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('condition not met within $timeout');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
