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

@TestOn('vm')
library;

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_uniffi/livekit_uniffi.dart' as ffi;

import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/uniffi/uniffi.dart';

void main() {
  // Exercises the whole delivery chain rather than any particular API: the
  // build hook resolved a cdylib for this target, Native Assets bundled it,
  // `@Native` bound the symbol, and a value crossed back from Rust. If the
  // bindgen or the hook regresses, this is what fails first.
  group('livekit_uniffi', () {
    test('is available on native platforms', () {
      expect(LiveKitUniffi.isAvailable, isTrue);
    });

    test('buildVersion returns the Rust core version', () {
      final version = LiveKitUniffi.buildVersion;
      expect(version, isNotEmpty);
      // The crate stamps its own semver, so assert the shape rather than a
      // literal that would need bumping on every livekit-uniffi release.
      expect(version, matches(RegExp(r'^\d+\.\d+\.\d+')));
    });

    // Exercises the newer incoming-manager surface end to end: the 2-arg
    // handlePacketReceived, the in-order openStreamCount query, and the
    // stream-closed queue. This is the gate that fails first when the
    // vendored bindings fall behind the Rust crate.
    test('incoming manager accounts for opens, aborts and closes', () async {
      final incoming = ffi.polledIncomingDataStreamManager(maxPayloadByteLength: null);
      final manager = incoming.manager;
      expect(await manager.openStreamCount(), 0);

      final header = lk_models.DataPacket(
        participantIdentity: 'alice',
        streamHeader: lk_models.DataStream_Header(
          streamId: 's1',
          topic: 'topic',
          mimeType: 'text/plain',
          totalLength: Int64(5),
          textHeader: lk_models.DataStream_TextHeader(),
        ),
      );
      manager.handlePacketReceived(
        packet: header.writeToBuffer(),
        encryptionType: ffi.EncryptionType.none,
      );
      // Answered in order with the packet fed above: no polling needed.
      expect(await manager.openStreamCount(), 1);

      manager.abortAllStreams();
      expect(await manager.openStreamCount(), 0);

      // The abort terminated the stream, which the closed queue observed.
      final closed = await incoming.streams.nextClosedStream();
      expect(closed?.streamId, 's1');
      expect(closed?.identity, 'alice');

      // Nothing is awaiting either queue here, so disposing directly is safe.
      incoming.streams.close();
      incoming.streams.dispose();
      manager.dispose();
    });
  });
}
