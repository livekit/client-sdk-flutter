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

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:uuid/uuid.dart' show Uuid;
import '../mock/e2e_container.dart';

void main() {
  E2EContainer? container;
  late Room room;

  group('data stream tests', () {
    test('data stream handler register', () async {
      container = E2EContainer();
      room = container!.room;
      await container!.connectRoom();

      room.registerTextStreamHandler('chat', (TextStreamReader reader, String participantIdentity) {
      
      });

      room.registerByteStreamHandler('file', (ByteStreamReader reader, String participantIdentity) {
      
      });

      expect(room.textStreamHandlers.keys.first, 'chat');

      expect(room.byteStreamHandlers.keys.first, 'file');

      room.unregisterTextStreamHandler('chat');
      room.unregisterByteStreamHandler('file');

      expect(room.textStreamHandlers.keys.length, 0);
      expect(room.byteStreamHandlers.keys.length, 0);
    });
  });

  test('send text test', () async {
    room.registerTextStreamHandler('chat', (TextStreamReader reader, String participantIdentity) async {
      var text = await reader.readAll();
      print('received chat message from $participantIdentity: $text');
      expect('some text !!!', text);
    });
    var info = await room.localParticipant?.sendText('some text !!!', options: SendTextOptions(
      topic: 'chat',
    ));
    expect(info, isNotNull);
  });


  test('send long text test', () async {
    var longText = 'a' * 100000;

    room.registerTextStreamHandler('chat-long-text', (TextStreamReader reader, String participantIdentity) async {
      var text = await reader.readAll();
      print('received chat message from $participantIdentity: long text length: ${text.length}');
      expect(longText, text);
    });

    var info = await room.localParticipant?.sendText(longText, options: SendTextOptions(
      topic: 'chat-long-text',
      onProgress: (p0) {
        print('progress: $p0');
      },
    ));
    expect(info, isNotNull);
  });

  test('stream text test', () async {
    room.registerTextStreamHandler('chat-stream', (TextStreamReader reader, String participantIdentity) async {
      var text = await reader.readAll();
      print('received chat message from $participantIdentity: $text');
    });

    final streamId = Uuid().v4();
    var longText = 'a' * 512;
    var stream = await room.localParticipant?.streamText(StreamTextOptions(
      topic: 'chat-stream',
      streamId: streamId,
      totalSize: longText.codeUnits.length,
      attachedStreamIds: [],
    ));
    await stream?.write(longText);
    await stream?.close();
  });
}
