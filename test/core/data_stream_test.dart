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

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart' show Uuid;

import 'package:livekit_client/livekit_client.dart';
import '../mock/e2e_container.dart';

void main() {
  E2EContainer? container;
  late Room room;

  group('data stream tests', () {
    test('data stream handler register', () async {
      container = E2EContainer();
      room = container!.room;
      await container!.connectRoom();

      room.registerTextStreamHandler(
          'chat', (TextStreamReader reader, String participantIdentity) {});

      room.registerByteStreamHandler(
          'file', (ByteStreamReader reader, String participantIdentity) {});

      expect(room.textStreamHandlers.keys.first, 'chat');

      expect(room.byteStreamHandlers.keys.first, 'file');

      room.unregisterTextStreamHandler('chat');
      room.unregisterByteStreamHandler('file');

      expect(room.textStreamHandlers.keys.length, 0);
      expect(room.byteStreamHandlers.keys.length, 0);
    });
  });

  test('send text test', () async {
    room.registerTextStreamHandler('chat',
        (TextStreamReader reader, String participantIdentity) async {
      var text = await reader.readAll();
      print('received chat message from $participantIdentity: $text');
      expect('some text !!!', text);
    });
    var info = await room.localParticipant?.sendText('some text !!!',
        options: SendTextOptions(
          topic: 'chat',
        ));
    expect(info, isNotNull);
  });

  test('send long text test', () async {
    var longText = 'a' * 100000;

    room.registerTextStreamHandler('chat-long-text',
        (TextStreamReader reader, String participantIdentity) async {
      var text = await reader.readAll();
      print(
          'received chat message from $participantIdentity: long text length: ${text.length}');
      expect(longText, text);
    });

    var info = await room.localParticipant?.sendText(longText,
        options: SendTextOptions(
          topic: 'chat-long-text',
          onProgress: (p0) {
            print('progress: $p0');
          },
        ));
    expect(info, isNotNull);
  });

  test('stream text test', () async {
    room.registerTextStreamHandler('chat-stream',
        (TextStreamReader reader, String participantIdentity) async {
      reader.listen((chunk) {
        print(
            'received chunk: ${chunk.content.length}, total: ${reader.info?.size}, progress: ${utf8.decode(chunk.content)}');
      });
    });

    final streamId = Uuid().v4();
    var stream = await room.localParticipant?.streamText(StreamTextOptions(
      topic: 'chat-stream',
      streamId: streamId,
      totalSize: 10000,
      attachedStreamIds: [],
    ));
    await stream?.write('a' * 10);
    await stream?.write('b' * 10);
    await stream?.write('c' * 10);
    await stream?.close();
  });

  test('file send/recv test', () async {
    var filePath = 'testfile.bin';

    /// create random file
    var randomFile = File(filePath);
    var random = Random();
    var bytes = List<int>.generate(100000, (index) => random.nextInt(256));
    randomFile.writeAsBytesSync(bytes);

    room.registerByteStreamHandler('file',
        (ByteStreamReader reader, String participantIdentity) async {
      var file = await reader.readAll();
      var fileName = 'copy-${reader.info!.name}';
      print('received file from $participantIdentity: ${file.length}');
      var received = file.expand((element) => element).toList();
      var writeFile = File(fileName);
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

  test('send text with filestest', () async {
    var longText = 'a' * 100000;

    var files = [
      'testfile.bin',
      'testfile2.bin',
      'testfile3.bin',
      'testfile4.bin'
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
      var receivedText = await reader.readAll();
      print(
          'received chat message from $participantIdentity: long text length: ${receivedText.length}');
      expect(longText, receivedText);
    });

    room.registerByteStreamHandler('chat-stream-with-files',
        (ByteStreamReader reader, String participantIdentity) async {
      var file = await reader.readAll();
      var fileName = 'copy-${reader.info!.name}';
      print('received file from $participantIdentity: ${fileName}');
      var received = file.expand((element) => element).toList();
      var writeFile = File(fileName);
      writeFile.writeAsBytesSync(received);
    });

    var attachmentsFiles = files.map((e) => File(e)).toList();

    var info = await room.localParticipant?.sendText(longText,
        options: SendTextOptions(
          topic: 'chat-stream-with-files',
          attachments: attachmentsFiles,
          onProgress: (p0) {
            print('file from chat-stream-with-files: progress: $p0');
          },
        ));
    expect(info, isNotNull);
  });

  test('stream bytes test', () async {
    room.registerByteStreamHandler('bytes-stream',
        (ByteStreamReader reader, String participantIdentity) async {
      var chunks = await reader.readAll();
      var content = chunks.expand((element) => element).toList();
      print(
          'bytes content = ${content}, \n string content = ${utf8.decode(content)}');
    });

    final streamId = Uuid().v4();
    var stream = await room.localParticipant?.streamBytes(StreamBytesOptions(
      topic: 'bytes-stream',
      streamId: streamId,
      totalSize: 30,
    ));
    await stream?.write(utf8.encode('a' * 10));
    await stream?.write(utf8.encode('b' * 10));
    await stream?.write(utf8.encode('c' * 10));
    await stream?.close();
  });
}
