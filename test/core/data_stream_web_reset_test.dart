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

// The web implementation is plain Dart, so it runs here too. A stream cut off by a disconnect must
// fail its reader, the way the native implementation aborts open streams.

@Timeout(Duration(seconds: 10))
library;

import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/data_stream/data_streams_web.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import '../mock/e2e_container.dart';

void main() {
  late E2EContainer container;

  setUp(() async {
    container = E2EContainer();
    await container.connectRoom();
  });

  tearDown(() async {
    await container.dispose();
  });

  test('a reset fails a stream that had not ended instead of completing it', () async {
    final streams = WebDataStreams(container.room);
    final delivered = Completer<TextStreamReader>();
    streams.registerTextStreamHandler('chat', (reader, identity) async => delivered.complete(reader));
    streams.handleIncomingPacket(
      lk_models.DataPacket(
        kind: lk_models.DataPacket_Kind.RELIABLE,
        participantIdentity: 'alice',
        streamHeader: lk_models.DataStream_Header(
          streamId: 'cut-1',
          topic: 'chat',
          mimeType: 'text/plain',
          timestamp: Int64(DateTime.timestamp().millisecondsSinceEpoch),
          totalLength: Int64(5),
          textHeader: lk_models.DataStream_TextHeader(),
        ),
      ),
      EncryptionType.kNone,
    );
    final reader = await delivered.future.timeout(const Duration(seconds: 2));
    final outcome = Completer<Object?>();
    reader.listen(
      (_) {},
      onError: (Object e) => outcome.complete(e),
      onDone: () {
        if (!outcome.isCompleted) outcome.complete(null);
      },
    );

    await streams.reset();

    final error = await outcome.future.timeout(const Duration(seconds: 2));
    expect(error, isA<DataStreamError>(), reason: 'the reader completed as if the sender had finished');
    expect((error! as DataStreamError).reason, DataStreamErrorReason.AbnormalEnd);
  });
}
