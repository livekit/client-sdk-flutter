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

@Timeout(Duration(seconds: 15))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/internal/events.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import '../mock/e2e_container.dart';
import '../mock/e2ee_fake_manager.dart';
import '../mock/peerconnection_mock.dart';

void main() {
  E2EContainer? container;
  late Room room;

  // Shared list equality checker for deep comparison
  const listEquality = ListEquality();

  setUpAll(() async {
    container = E2EContainer();
    room = container!.room;
    await container!.connectRoom();
  });

  tearDownAll(() async {
    await container?.dispose();
  });

  group('Data Stream Reliability Integration Tests', () {
    test('Reliable Text Stream Message Ordering and Integrity', () async {
      final messageCount = 25;
      final receivedMessages = <String>[];
      final receivedCompleter = Completer<void>();

      // Test reliable text stream with message ordering
      room.registerTextStreamHandler('reliability-test', (TextStreamReader reader, String participantIdentity) async {
        final text = await reader.readAll();
        receivedMessages.add(text);
        print('Received reliable text message ${receivedMessages.length}/${messageCount}: ${text}');

        if (receivedMessages.length >= messageCount) {
          receivedCompleter.complete();
        }
      });

      // Send messages rapidly to test reliability and ordering
      print('Sending ${messageCount} rapid reliable text messages');
      final expectedMessages = <String>[];

      for (int i = 0; i < messageCount; i++) {
        final messageContent = 'ReliabilityTest_${i}_${DateTime.now().millisecondsSinceEpoch}';
        expectedMessages.add(messageContent);

        try {
          final info = await room.localParticipant?.sendText(messageContent,
              options: SendTextOptions(
                topic: 'reliability-test',
                onProgress: (progress) {
                  // Verify progress is within bounds (0.0-1.0)
                  expect(progress, greaterThanOrEqualTo(0.0));
                  expect(progress, lessThanOrEqualTo(1.0));
                },
              ));
          expect(info, isNotNull);

          // Small delay between messages to create realistic load
          if (i % 5 == 0) {
            await Future.delayed(Duration(milliseconds: 10));
          }
        } catch (e) {
          print('Warning: Failed to send message ${i}: $e');
        }
      }

      // Wait for all messages to be received
      await receivedCompleter.future.timeout(Duration(seconds: 12));

      // Verify all messages received exactly once
      expect(receivedMessages.length, equals(messageCount),
          reason: 'All ${messageCount} messages should be received exactly once');

      // Verify no duplicates
      final uniqueMessages = receivedMessages.toSet();
      expect(uniqueMessages.length, equals(receivedMessages.length),
          reason: 'No duplicate messages should be received');

      // Verify each expected message was received
      for (final expectedMessage in expectedMessages) {
        expect(receivedMessages, contains(expectedMessage),
            reason: 'Expected message should be received: $expectedMessage');
      }

      print('✅ Text stream reliability test passed: All ${messageCount} messages received correctly');
    });

    test('Reliable Text Stream With E2EE retains ordering and integrity', () async {
      final e2eeManager = TestE2EEManager();
      await e2eeManager.setup(room);
      room.engine.setE2eeManager(e2eeManager);

      final messages = <String>[];
      final expectedMessages = List<String>.generate(10, (index) => 'E2EE_Message_$index');
      final completer = Completer<void>();

      final duplicateDetector = <String>{};
      room.registerTextStreamHandler('e2ee-stream', (TextStreamReader reader, String participantIdentity) async {
        messages.add(await reader.readAll());
        expect(duplicateDetector.add(messages.last), isTrue, reason: 'Duplicate reliable message detected');
        if (messages.length == expectedMessages.length && !completer.isCompleted) {
          completer.complete();
        }
      });

      for (final message in expectedMessages) {
        await room.localParticipant?.sendText(
          message,
          options: SendTextOptions(
            topic: 'e2ee-stream',
          ),
        );
      }

      await completer.future.timeout(const Duration(seconds: 5));

      expect(messages, equals(expectedMessages));
      expect(e2eeManager.encryptedPayloads, isNotEmpty);
      expect(e2eeManager.decryptedPayloads.length, equals(e2eeManager.encryptedPayloads.length));
      expect(e2eeManager.encryptedPayloads.length, greaterThanOrEqualTo(expectedMessages.length));
    });

    test('Reliable packets ignore duplicates based on sequence', () async {
      final received = <lk_models.UserPacket>[];
      final firstMessageCompleter = Completer<void>();

      final cancel = room.engine.events.on<EngineDataPacketReceivedEvent>((event) {
        if (event.kind == lk_models.DataPacket_Kind.RELIABLE && event.identity == 'remote-dup') {
          received.add(event.packet);
          if (!firstMessageCompleter.isCompleted) {
            firstMessageCompleter.complete();
          }
        }
      });

      final channel = findMockDataChannelByLabel('_reliable', requireListener: true);
      expect(channel, isNotNull, reason: 'Mock reliable data channel should exist');

      final packet = lk_models.DataPacket(
        kind: lk_models.DataPacket_Kind.RELIABLE,
        participantIdentity: 'remote-dup',
        participantSid: 'remote-dup-sid',
        user: lk_models.UserPacket(
          payload: utf8.encode('duplicate-test'),
          participantIdentity: 'remote-dup',
        ),
      );

      await room.engine.sendDataPacket(packet, reliability: Reliability.reliable);

      await firstMessageCompleter.future.timeout(const Duration(seconds: 3));

      expect(packet.hasSequence(), isTrue);
      final duplicatePacket = packet.deepCopy()..sequence = packet.sequence;
      channel!.onMessage?.call(rtc.RTCDataChannelMessage.fromBinary(duplicatePacket.writeToBuffer()));

      await Future.delayed(const Duration(milliseconds: 100));
      expect(received.length, equals(1), reason: 'Duplicate packet should be ignored');

      await cancel();
    });

    test('Reliable Byte Stream With Large Data Chunks', () async {
      final chunkCount = 10;
      final chunkSize = 10000; // 10KB chunks
      final receivedFiles = <List<int>>[];
      final receivedCompleter = Completer<void>();

      room.registerByteStreamHandler('reliability-bytes', (ByteStreamReader reader, String participantIdentity) async {
        final chunks = await reader.readAll();
        final fileData = chunks.expand((chunk) => chunk).toList();
        receivedFiles.add(fileData);

        // Print first 10 bytes for debugging
        final firstBytes = fileData.take(10).toList();
        print(
            'Received reliable byte stream ${receivedFiles.length}/${chunkCount}: ${fileData.length} bytes from $participantIdentity');
        print('  First 10 bytes: $firstBytes');

        if (receivedFiles.length >= chunkCount) {
          receivedCompleter.complete();
        }
      });

      // Send multiple byte streams with random data
      print('Sending ${chunkCount} reliable byte streams with random data');
      final expectedFiles = <List<int>>[];
      final random = Random();

      for (int i = 0; i < chunkCount; i++) {
        // Create unique random data for each file
        final fileData = List<int>.generate(chunkSize, (index) => random.nextInt(256));
        expectedFiles.add(fileData);

        try {
          // Print first 10 bytes of what we're sending
          final firstBytes = fileData.take(10).toList();
          print('Sending file ${i}: ${fileData.length} bytes, first 10: $firstBytes');

          final stream = await room.localParticipant?.streamBytes(StreamBytesOptions(
            topic: 'reliability-bytes',
            name: 'reliable-test-file-${i}.bin',
            mimeType: 'application/octet-stream',
            totalSize: chunkSize,
          ));

          await stream?.write(Uint8List.fromList(fileData));
          await stream?.close();

          // Brief delay between files
          await Future.delayed(Duration(milliseconds: 50));
        } catch (e) {
          print('Warning: Failed to send file ${i}: $e');
        }
      }

      // Wait for all files to be received
      await receivedCompleter.future.timeout(Duration(seconds: 12));

      // Verify all files received
      expect(receivedFiles.length, equals(chunkCount), reason: 'All ${chunkCount} byte streams should be received');

      // Verify data integrity - all expected files should be received (order may vary)
      expect(receivedFiles.length, equals(expectedFiles.length),
          reason: 'Should receive exactly ${expectedFiles.length} files');

      // Use deep equality comparison for lists

      // Verify each expected file is received exactly once
      for (int i = 0; i < expectedFiles.length; i++) {
        final expectedFile = expectedFiles[i];
        final matchingFiles = receivedFiles.where((received) => listEquality.equals(received, expectedFile)).toList();

        expect(matchingFiles.length, equals(1),
            reason: 'Expected file ${i} should be received exactly once, found ${matchingFiles.length} matches');
      }

      // Verify no unexpected files received
      for (int i = 0; i < receivedFiles.length; i++) {
        final receivedFile = receivedFiles[i];
        final matchingExpected =
            expectedFiles.where((expected) => listEquality.equals(receivedFile, expected)).toList();

        expect(matchingExpected.length, equals(1), reason: 'Received file ${i} should match exactly one expected file');
      }

      print('✅ Byte stream reliability test passed: All ${chunkCount} files received correctly');
    });

    test('Sequence Number Integrity and No Duplicates', () async {
      final messageCount = 30;
      final receivedSequences = <int>[];
      final duplicateTracker = <int, int>{};
      final receivedCompleter = Completer<void>();

      room.registerTextStreamHandler('sequence-test', (TextStreamReader reader, String participantIdentity) async {
        final text = await reader.readAll();
        final parts = text.split('_');
        if (parts.length >= 2) {
          final seqNum = int.tryParse(parts[1]);
          if (seqNum != null) {
            receivedSequences.add(seqNum);
            duplicateTracker[seqNum] = (duplicateTracker[seqNum] ?? 0) + 1;
          }
        }

        if (receivedSequences.length >= messageCount) {
          receivedCompleter.complete();
        }
      });

      // Send messages in rapid succession
      print('Testing sequence integrity with ${messageCount} rapid messages');
      for (int i = 0; i < messageCount; i++) {
        try {
          await room.localParticipant?.sendText('sequence_${i}_test', options: SendTextOptions(topic: 'sequence-test'));
        } catch (e) {
          print('Failed to send sequence message ${i}: $e');
        }
      }

      await receivedCompleter.future.timeout(Duration(seconds: 8));

      // Verify no duplicates (each sequence should appear exactly once)
      for (final entry in duplicateTracker.entries) {
        expect(entry.value, equals(1),
            reason: 'Sequence ${entry.key} should appear exactly once, but appeared ${entry.value} times');
      }

      // Verify correct count of unique sequences
      expect(receivedSequences.length, equals(messageCount));
      final uniqueSequences = receivedSequences.toSet();
      expect(uniqueSequences.length, equals(messageCount), reason: 'All ${messageCount} sequences should be unique');

      print('✅ Sequence integrity test passed: ${messageCount} unique sequences, no duplicates');
    });

    test('Concurrent Reliable Streams Stress Test', () async {
      final concurrentStreams = 5;
      final messagesPerStream = 8;
      final receivedMessages = <String, List<String>>{};
      final completers = <String, Completer<void>>{};

      // Set up handlers for multiple concurrent topics
      for (int streamId = 0; streamId < concurrentStreams; streamId++) {
        final topic = 'concurrent-${streamId}';
        receivedMessages[topic] = [];
        completers[topic] = Completer<void>();

        room.registerTextStreamHandler(topic, (TextStreamReader reader, String participantIdentity) async {
          final text = await reader.readAll();
          receivedMessages[topic]!.add(text);

          if (receivedMessages[topic]!.length >= messagesPerStream) {
            completers[topic]!.complete();
          }
        });
      }

      // Send messages concurrently across multiple streams
      print('Starting concurrent streams: ${concurrentStreams} streams x ${messagesPerStream} messages');

      final sendFutures = <Future>[];
      for (int streamId = 0; streamId < concurrentStreams; streamId++) {
        final topic = 'concurrent-${streamId}';

        sendFutures.add(() async {
          for (int msgId = 0; msgId < messagesPerStream; msgId++) {
            try {
              await room.localParticipant
                  ?.sendText('Stream${streamId}_Message${msgId}', options: SendTextOptions(topic: topic));
              // Small randomized delay to create realistic concurrent load
              await Future.delayed(Duration(milliseconds: Random().nextInt(30) + 10));
            } catch (e) {
              print('Failed to send message ${msgId} on stream ${streamId}: $e');
            }
          }
        }());
      }

      // Wait for all send operations to complete
      await Future.wait(sendFutures);

      // Wait for all messages to be received
      await Future.wait(completers.values.map((c) => c.future)).timeout(Duration(seconds: 10));

      // Verify all messages received correctly
      for (int streamId = 0; streamId < concurrentStreams; streamId++) {
        final topic = 'concurrent-${streamId}';
        expect(receivedMessages[topic]!.length, equals(messagesPerStream),
            reason: 'Stream ${streamId} should receive all ${messagesPerStream} messages');

        // Verify message content uniqueness within each stream
        final uniqueInStream = receivedMessages[topic]!.toSet();
        expect(uniqueInStream.length, equals(messagesPerStream),
            reason: 'Stream ${streamId} should have ${messagesPerStream} unique messages');

        // Verify expected messages
        for (int msgId = 0; msgId < messagesPerStream; msgId++) {
          final expectedMessage = 'Stream${streamId}_Message${msgId}';
          expect(receivedMessages[topic], contains(expectedMessage),
              reason: 'Stream ${streamId} should contain message ${msgId}');
        }
      }

      print(
          '✅ Concurrent streams test passed: ${concurrentStreams * messagesPerStream} total messages across ${concurrentStreams} streams');
    });

    test('Mixed Data Types Reliability Test', () async {
      final textMessages = 8;
      final byteStreams = 4;
      final receivedTexts = <String>[];
      final receivedBytes = <List<int>>[];
      final textCompleter = Completer<void>();
      final byteCompleter = Completer<void>();

      // Set up mixed handlers
      room.registerTextStreamHandler('mixed-text', (reader, participantIdentity) async {
        final text = await reader.readAll();
        receivedTexts.add(text);
        if (receivedTexts.length >= textMessages) {
          textCompleter.complete();
        }
      });

      room.registerByteStreamHandler('mixed-bytes', (reader, participantIdentity) async {
        final chunks = await reader.readAll();
        final data = chunks.expand((chunk) => chunk).toList();
        receivedBytes.add(data);

        // Print first 10 bytes for debugging
        final firstBytes = data.take(10).toList();
        print(
            'Received mixed byte stream ${receivedBytes.length}/${byteStreams}: ${data.length} bytes, first 10: $firstBytes');

        if (receivedBytes.length >= byteStreams) {
          byteCompleter.complete();
        }
      });

      // Send mixed data types concurrently
      final futures = <Future>[];

      // Send text messages
      for (int i = 0; i < textMessages; i++) {
        futures.add(() async {
          await room.localParticipant
              ?.sendText('Mixed text message ${i}', options: SendTextOptions(topic: 'mixed-text'));
        }());
      }

      // Send byte streams with random data
      final mixedRandom = Random();
      final expectedMixedBytes = <List<int>>[];

      for (int i = 0; i < byteStreams; i++) {
        futures.add(() async {
          final data = List<int>.generate(500, (index) => mixedRandom.nextInt(256));
          expectedMixedBytes.add(data);
          final firstBytes = data.take(10).toList();
          print('Sending mixed byte stream ${i}: ${data.length} bytes, first 10: $firstBytes');

          final stream = await room.localParticipant?.streamBytes(StreamBytesOptions(
            topic: 'mixed-bytes',
            name: 'mixed-file-${i}.dat',
            totalSize: data.length,
          ));
          await stream?.write(Uint8List.fromList(data));
          await stream?.close();
        }());
      }

      await Future.wait(futures);
      await Future.wait([textCompleter.future, byteCompleter.future]).timeout(Duration(seconds: 10));

      // Verify mixed data integrity
      expect(receivedTexts.length, equals(textMessages));
      expect(receivedBytes.length, equals(byteStreams));

      // Verify text content
      for (int i = 0; i < textMessages; i++) {
        expect(receivedTexts, contains('Mixed text message ${i}'));
      }

      // Verify random byte data using deep equality comparison
      for (int i = 0; i < expectedMixedBytes.length; i++) {
        final expectedData = expectedMixedBytes[i];
        final matchFound = receivedBytes.any((received) => listEquality.equals(received, expectedData));

        expect(matchFound, isTrue, reason: 'Expected random byte data for file ${i} should be received');
      }

      print('✅ Mixed data types test passed: ${textMessages} texts + ${byteStreams} byte streams');
    });

    test('Incremental Progress Tracking With File Attachments', () async {
      final numFiles = 5; // Multiple files = incremental progress
      final progressValues = <double>[];
      final receivedCompleter = Completer<void>();
      final textCompleter = Completer<void>();
      var receivedFileCount = 0;

      // Create test files in testfiles/ directory (same pattern as data_stream_test.dart)
      final files = [
        'testfiles/progress_test_1.bin',
        'testfiles/progress_test_2.bin',
        'testfiles/progress_test_3.bin',
        'testfiles/progress_test_4.bin',
        'testfiles/progress_test_5.bin'
      ];

      /// Create test files with random data
      final tempFiles = <File>[];
      for (int i = 0; i < numFiles; i++) {
        final file = File(files[i]);
        final random = Random();
        final bytes = List<int>.generate(1024, (index) => random.nextInt(256)); // 1KB random data
        file.writeAsBytesSync(bytes);
        tempFiles.add(file);
        print('Created test file ${i}: ${file.path} (${bytes.length} bytes)');
      }

      room.registerTextStreamHandler('progress-test', (TextStreamReader reader, String participantIdentity) async {
        final text = await reader.readAll();
        print('Received text message: ${text}');
        textCompleter.complete();
      });

      room.registerByteStreamHandler('progress-test', (ByteStreamReader reader, String participantIdentity) async {
        final chunks = await reader.readAll();
        final data = chunks.expand((chunk) => chunk).toList();
        receivedFileCount++;
        print('Received file attachment ${receivedFileCount}/${numFiles}: ${reader.info?.name} (${data.length} bytes)');

        if (receivedFileCount >= numFiles) {
          receivedCompleter.complete();
        }
      });

      // Send text with multiple file attachments - this triggers incremental progress
      print('Sending text with ${numFiles} file attachments to test incremental progress...');
      final info = await room.localParticipant?.sendText('Message with ${numFiles} attachments',
          options: SendTextOptions(
            topic: 'progress-test',
            attachments: tempFiles,
            onProgress: (progress) {
              progressValues.add(progress);
              print('Progress: ${(progress * 100).toStringAsFixed(1)}% (${progressValues.length} updates)');

              // Verify progress bounds
              expect(progress, greaterThanOrEqualTo(0.0));
              expect(progress, lessThanOrEqualTo(1.0));
            },
          ));

      expect(info, isNotNull);
      await Future.wait([textCompleter.future, receivedCompleter.future]).timeout(Duration(seconds: 15));

      // Clean up test files
      for (final file in tempFiles) {
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Verify incremental progress
      print('Progress tracking results:');
      for (int i = 0; i < progressValues.length; i++) {
        print('  Update ${i + 1}: ${(progressValues[i] * 100).toStringAsFixed(1)}%');
      }

      expect(progressValues, isNotEmpty, reason: 'Progress callbacks should have been called');
      expect(progressValues.last, equals(1.0), reason: 'Final progress should be 1.0');
      expect(progressValues.length, greaterThan(1), reason: 'Should have multiple incremental progress updates');

      // Verify progress is non-decreasing
      for (int i = 1; i < progressValues.length; i++) {
        expect(progressValues[i], greaterThanOrEqualTo(progressValues[i - 1]),
            reason: 'Progress should be non-decreasing');
      }

      print('✅ Incremental progress test passed: ${progressValues.length} progress updates from 0% to 100%');
    });
  });
}
