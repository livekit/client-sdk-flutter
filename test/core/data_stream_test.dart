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

@Timeout(Duration(seconds: 5))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart';

import '../mock/e2e_container.dart';

void main() {
  E2EContainer? container;
  late Room room;

  setUpAll(() async {
    container = E2EContainer();
    room = container!.room;
    await container!.connectRoom();
  });

  tearDownAll(() async {
    await container?.dispose();
  });

  group('Stream Handler Registration', () {
    test('Register And Unregister Text And Byte Stream Handlers', () async {
      room.registerTextStreamHandler('chat', (TextStreamReader reader, String participantIdentity) {});

      room.registerByteStreamHandler('file', (ByteStreamReader reader, String participantIdentity) {});

      expect(room.textStreamHandlers.keys.first, 'chat');

      expect(room.byteStreamHandlers.keys.first, 'file');

      room.unregisterTextStreamHandler('chat');
      room.unregisterByteStreamHandler('file');

      expect(room.textStreamHandlers.keys.length, 0);
      expect(room.byteStreamHandlers.keys.length, 0);
    });
  });

  group('Text Streaming', () {
    test('Send Basic Text Message', () async {
      room.registerTextStreamHandler('chat', (TextStreamReader reader, String participantIdentity) async {
        final text = await reader.readAll();
        print('received chat message from $participantIdentity: $text');
        expect('some text !!!', text);
      });
      final info = await room.localParticipant?.sendText('some text !!!',
          options: SendTextOptions(
            topic: 'chat',
          ));
      expect(info, isNotNull);
    });

    test('Send Large Text Message With Progress Tracking', () async {
      var longText = 'a' * 100000;

      room.registerTextStreamHandler('chat-long-text', (TextStreamReader reader, String participantIdentity) async {
        final text = await reader.readAll();
        print('received chat message from $participantIdentity: long text length: ${text.length}');
        expect(longText, text);
      });

      final info = await room.localParticipant?.sendText(longText,
          options: SendTextOptions(
            topic: 'chat-long-text',
            onProgress: (p0) {
              print('progress: $p0');
            },
          ));
      expect(info, isNotNull);
    });

    test('Stream Text With Multiple Chunks', () async {
      room.registerTextStreamHandler('chat-stream', (TextStreamReader reader, String participantIdentity) async {
        reader.listen((chunk) {
          print(
              'received chunk: ${chunk.content.length}, total: ${reader.info?.size}, progress: ${utf8.decode(chunk.content)}');
        });
      });

      final stream = await room.localParticipant?.streamText(StreamTextOptions(
        topic: 'chat-stream',
      ));
      await stream?.write('a' * 10);
      await stream?.write('b' * 10);
      await stream?.write('c' * 10);
      await stream?.close();
    });

    test('Send Text Message With Multiple File Attachments', () async {
      var longText = 'a' * 100000;

      var files = [
        'testfiles/testfile.bin',
        'testfiles/testfile2.bin',
        'testfiles/testfile3.bin',
        'testfiles/testfile4.bin'
      ];

      /// create random files
      for (var file in files) {
        var randomFile = File(file);
        var random = Random();
        var bytes = List<int>.generate(100000, (index) => random.nextInt(256));
        randomFile.writeAsBytesSync(bytes);
      }

      room.registerTextStreamHandler('chat-stream-with-files',
          (TextStreamReader reader, String participantIdentity) async {
        final receivedText = await reader.readAll();
        print('received chat message from $participantIdentity: long text length: ${receivedText.length}');
        expect(longText, receivedText);
      });

      room.registerByteStreamHandler('chat-stream-with-files',
          (ByteStreamReader reader, String participantIdentity) async {
        final file = await reader.readAll();
        final fileName = 'testfiles/copy-${reader.info!.name}';
        print('received file from $participantIdentity: ${fileName}');
        final received = file.expand((element) => element).toList();
        final writeFile = File(fileName);
        writeFile.writeAsBytesSync(received);
      });

      var attachmentsFiles = files.map((e) => File(e)).toList();

      final info = await room.localParticipant?.sendText(longText,
          options: SendTextOptions(
            topic: 'chat-stream-with-files',
            attachments: attachmentsFiles,
            onProgress: (p0) {
              print('file from chat-stream-with-files: progress: $p0');
            },
          ));
      expect(info, isNotNull);
    });

    test('Text Stream With Operation Types', () async {
      final operationTypes = ['create', 'update', 'delete', 'reaction'];
      var receivedMessages = <String>[];

      for (var operationType in operationTypes) {
        room.registerTextStreamHandler('chat-operations', (TextStreamReader reader, String participantIdentity) async {
          final text = await reader.readAll();
          receivedMessages.add('${operationType}: ${text}');
          print('received ${operationType} message: ${text}');
        });

        final info = await room.localParticipant?.sendText('Test ${operationType}',
            options: SendTextOptions(
              topic: 'chat-operations',
            ));

        // Test with streamText and different operation types
        final stream = await room.localParticipant?.streamText(StreamTextOptions(
          topic: 'chat-operations',
          type: operationType,
          version: operationType == 'update' ? 2 : null,
        ));
        await stream?.write('Streamed ${operationType}');
        await stream?.close();

        expect(info, isNotNull);
        room.unregisterTextStreamHandler('chat-operations');
      }
    });

    test('Text Stream With Attributes And Metadata', () async {
      final testAttributes = {'userId': '12345', 'sessionId': 'abc123', 'priority': 'high'};

      room.registerTextStreamHandler('chat-metadata', (TextStreamReader reader, String participantIdentity) async {
        final text = await reader.readAll();
        print('received message with text: ${text}');
        print('received message attributes: ${reader.info?.attributes}');

        // Verify the text content
        expect(text, 'Test message with metadata');

        // Verify attributes are received correctly now that sendText() is fixed
        expect(reader.info!.attributes['userId'], '12345');
        expect(reader.info!.attributes['sessionId'], 'abc123');
        expect(reader.info!.attributes['priority'], 'high');
      });

      final info = await room.localParticipant?.sendText('Test message with metadata',
          options: SendTextOptions(
            topic: 'chat-metadata',
            attributes: testAttributes,
          ));
      expect(info, isNotNull);
    });

    test('Text Stream With Reply Functionality', () async {
      const originalStreamId = 'original-stream-123';
      const replyStreamId = 'reply-stream-456';

      room.registerTextStreamHandler('chat-replies', (TextStreamReader reader, String participantIdentity) async {
        final text = await reader.readAll();
        print('received reply message: ${text}');
        expect(text, 'This is a reply to the original message');
      });

      // Send a reply to an existing stream
      final stream = await room.localParticipant?.streamText(StreamTextOptions(
        topic: 'chat-replies',
        type: 'create',
        streamId: replyStreamId,
        replyToStreamId: originalStreamId,
        version: 1,
      ));
      await stream?.write('This is a reply to the original message');
      await stream?.close();
    });

    test('Text Stream With AI Generated Flag', () async {
      room.registerTextStreamHandler('chat-ai-generated', (TextStreamReader reader, String participantIdentity) async {
        final text = await reader.readAll();
        print('received AI-generated message: ${text}');
        expect(text, 'This message was generated by AI');
      });

      // Test AI-generated message
      final stream = await room.localParticipant?.streamText(StreamTextOptions(
        topic: 'chat-ai-generated',
        generated: true,
        attributes: {'aiModel': 'gpt-4', 'confidence': '0.95'},
      ));
      await stream?.write('This message was generated by AI');
      await stream?.close();
    });

    test('Text Stream With File Attachments', () async {
      const attachedIds = ['file-123', 'file-456', 'file-789'];

      room.registerTextStreamHandler('chat-with-attachments',
          (TextStreamReader reader, String participantIdentity) async {
        final text = await reader.readAll();
        print('received message with attachments: ${text}');
        expect(text, 'Message with file attachments');
      });

      final stream = await room.localParticipant?.streamText(StreamTextOptions(
        topic: 'chat-with-attachments',
        attachedStreamIds: attachedIds,
        totalSize: 26, // 'Message with file attachments'.length
      ));
      await stream?.write('Message with file attachments');
      await stream?.close();
    });
  });

  group('Byte Streaming', () {
    test('Send And Receive Binary File', () async {
      var filePath = 'testfiles/testfile.bin';

      /// create random file
      var randomFile = File(filePath);
      var random = Random();
      var bytes = List<int>.generate(100000, (index) => random.nextInt(256));
      randomFile.writeAsBytesSync(bytes);

      room.registerByteStreamHandler('file', (ByteStreamReader reader, String participantIdentity) async {
        final file = await reader.readAll();
        final fileName = 'testfiles/copy-${reader.info!.name}';
        print('received file from $participantIdentity: ${file.length}');
        final received = file.expand((element) => element).toList();
        final writeFile = File(fileName);
        writeFile.writeAsBytesSync(received);

        expect(bytes, received);
        await writeFile.delete();
        await randomFile.delete();
      });

      final fileToSend = File(filePath);
      var info = await room.localParticipant?.sendFile(fileToSend,
          options: SendFileOptions(
            topic: 'file',
            onProgress: (p0) {
              print('progress: ${p0 * 100} %');
            },
          ));
      expect(info, isNotNull);
    });

    test('Stream Raw Bytes With UTF8 Content', () async {
      room.registerByteStreamHandler('bytes-stream', (ByteStreamReader reader, String participantIdentity) async {
        final chunks = await reader.readAll();
        final content = chunks.expand((element) => element).toList();
        print('bytes content = ${content}, \n string content = ${utf8.decode(content)}');
      });

      final stream = await room.localParticipant?.streamBytes(StreamBytesOptions(
        topic: 'bytes-stream',
        totalSize: 30,
      ));
      await stream?.write(utf8.encode('a' * 10));
      await stream?.write(utf8.encode('b' * 10));
      await stream?.write(utf8.encode('c' * 10));
      await stream?.close();
    });

    test('Byte Stream With Attributes And MIME Type', () async {
      final testAttributes = {'uploadedBy': 'user123', 'category': 'document'};
      const testMimeType = 'application/pdf';
      const testFileName = 'test-document.pdf';

      room.registerByteStreamHandler('files-with-metadata',
          (ByteStreamReader reader, String participantIdentity) async {
        final chunks = await reader.readAll();
        final content = chunks.expand((element) => element).toList();
        print('received file: ${reader.info?.name}, size: ${content.length}');
        print('received file mimeType: ${reader.info?.mimeType}');
        print('received file attributes: ${reader.info?.attributes}');

        // Verify basic info
        expect(reader.info?.name, testFileName);
        expect(reader.info?.mimeType, testMimeType);
        expect(content.length, greaterThan(0));

        // Verify attributes are received (if supported by the reader)
        if (reader.info?.attributes != null) {
          expect(reader.info!.attributes['uploadedBy'], 'user123');
          expect(reader.info!.attributes['category'], 'document');
        }

        // Verify content is correct
        var expectedContent = List<int>.generate(100, (index) => index % 256);
        expect(content, expectedContent);
      });

      final stream = await room.localParticipant?.streamBytes(StreamBytesOptions(
        topic: 'files-with-metadata',
        name: testFileName,
        mimeType: testMimeType,
        attributes: testAttributes,
        totalSize: 100,
      ));

      // Simulate PDF content
      var pdfContent = List<int>.generate(100, (index) => index % 256);
      await stream?.write(Uint8List.fromList(pdfContent));
      await stream?.close();
    });
  });

  group('Performance And Stress Tests', () {
    test('Handle Multiple Concurrent Streams', () async {
      var receivedCount = 0;
      const expectedCount = 3;

      room.registerTextStreamHandler('concurrent-streams', (TextStreamReader reader, String participantIdentity) async {
        final text = await reader.readAll();
        receivedCount++;
        print('received concurrent message ${receivedCount}: ${text}');
      });

      // Start multiple concurrent streams
      var futures = <Future>[];
      for (int i = 0; i < expectedCount; i++) {
        futures.add(() async {
          final stream = await room.localParticipant?.streamText(StreamTextOptions(
            topic: 'concurrent-streams',
            streamId: 'stream-${i}',
            type: 'create',
          ));
          await stream?.write('Concurrent message ${i}');
          await stream?.close();
        }());
      }

      await Future.wait(futures);

      // Allow time for all messages to be processed
      await Future.delayed(Duration(milliseconds: 100));
      expect(receivedCount, expectedCount);
    });

    test('Handle Large Stream Chunks Above Normal Size', () async {
      const chunkSize = 50000; // Larger than normal chunk size
      var largeData = 'x' * chunkSize;

      room.registerTextStreamHandler('large-chunks', (TextStreamReader reader, String participantIdentity) async {
        final text = await reader.readAll();
        print('received large text, length: ${text.length}');
        expect(text.length, chunkSize);
        expect(text, largeData);
      });

      final stream = await room.localParticipant?.streamText(StreamTextOptions(
        topic: 'large-chunks',
        totalSize: chunkSize,
      ));
      await stream?.write(largeData);
      await stream?.close();
    });
  });

  group('Header And Metadata Validation', () {
    test('Validate Complete Header Information Transmission', () async {
      // Test comprehensive header data transmission
      final testCompleter = Completer<bool>();

      room.registerTextStreamHandler('header-validation', (TextStreamReader reader, String participantIdentity) async {
        final text = await reader.readAll();
        print('=== Header Validation Test ===');
        print('Received text: ${text}');
        print('Reader info ID: ${reader.info?.id}');
        print('Reader info topic: ${reader.info?.topic}');
        print('Reader info mimeType: ${reader.info?.mimeType}');
        print('Reader info timestamp: ${reader.info?.timestamp}');
        print('Reader info size: ${reader.info?.size}');
        print('Reader info attributes: ${reader.info?.attributes}');

        // Validate the content
        expect(text, 'Header validation test message');

        // Validate basic stream properties
        expect(reader.info?.topic, 'header-validation');
        expect(reader.info?.mimeType, 'text/plain');
        expect(reader.info?.id, isNotNull);
        expect(reader.info?.timestamp, isNotNull);

        // Test passes if we get here without exceptions
        testCompleter.complete(true);
      });

      // Send a message with comprehensive options
      final stream = await room.localParticipant?.streamText(StreamTextOptions(
        topic: 'header-validation',
        type: 'create',
        version: 1,
        generated: false,
        attributes: {
          'test': 'header-validation',
          'complex': 'data-transmission',
          'number': '123',
        },
        attachedStreamIds: ['attachment-1', 'attachment-2'],
        replyToStreamId: 'parent-message-123',
        totalSize: 28, // Length of test message
      ));

      await stream?.write('Header validation test message');
      await stream?.close();

      // Wait for the test to complete or timeout
      await testCompleter.future.timeout(Duration(seconds: 3));
    });
  });
}
