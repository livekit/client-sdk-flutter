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
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
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
