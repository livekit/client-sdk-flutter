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

import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import 'package:livekit_client/src/support/native.dart';
import '../core/signal_client_test.dart' show joinResponse;
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const webrtcChannel = MethodChannel('FlutterWebRTC.Method');

  late E2EContainer container;

  setUp(() {
    messenger.setMockMethodCallHandler(webrtcChannel, (call) async {
      if (call.method == 'getUserMedia') {
        return <String, dynamic>{
          'streamId': 'stream-1',
          'audioTracks': [
            <String, dynamic>{'id': 'mic-1', 'label': 'mic', 'kind': 'audio', 'enabled': true},
          ],
          'videoTracks': <dynamic>[],
        };
      }
      return null;
    });
    messenger.setMockMethodCallHandler(Native.channel, (call) async => true);
    resetMockDataChannels();
    container = E2EContainer();
  });

  tearDown(() async {
    await container.dispose();
    messenger.setMockMethodCallHandler(webrtcChannel, null);
    messenger.setMockMethodCallHandler(Native.channel, null);
  });

  Future<void> waitUntil(bool Function() condition) async {
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (!condition() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(condition(), isTrue, reason: 'sender was not configured before acknowledgment');
  }

  lk_rtc.SignalResponse accepted(String cid) => lk_rtc.SignalResponse(
    trackPublished: lk_rtc.TrackPublishedResponse(
      cid: cid,
      track: lk_models.TrackInfo(sid: 'TR_accepted', type: lk_models.TrackType.AUDIO),
    ),
  );

  for (final warmUp in [false, true]) {
    for (final fast in [false, true]) {
      test('publication overlap follows codecs ($fast), independently of warm-up ($warmUp)', () async {
        final join = joinResponse.deepCopy();
        join.join.fastPublish = warmUp;
        if (fast) {
          join.join.enabledPublishCodecs.add(lk_models.Codec(mime: 'audio/opus'));
        }
        await container.connectRoom(joinResponseOverride: join);
        final track = await LocalAudioTrack.create();
        final requestSeen = Completer<lk_rtc.AddTrackRequest>();
        container.wsConnector.onSend = (data) {
          final request = lk_rtc.SignalRequest.fromBuffer(data);
          if (request.hasAddTrack() && !requestSeen.isCompleted) requestSeen.complete(request.addTrack);
        };
        var completed = false;
        final publication = container.room.localParticipant!.publishAudioTrack(track).then((pub) {
          completed = true;
          return pub;
        });
        final request = await requestSeen.future.timeout(const Duration(seconds: 2));
        if (fast) {
          await waitUntil(() => track.transceiver != null);
        }
        expect(completed, isFalse, reason: 'publication must wait for server acceptance');
        expect(track.transceiver != null, fast);
        expect(container.room.localParticipant!.trackPublications, isEmpty);
        container.wsConnector.onData(accepted(request.cid).writeToBuffer());
        expect((await publication).sid, 'TR_accepted');
        expect(track.transceiver, isNotNull);
        expect(container.room.localParticipant!.trackPublications.length, 1);
      });
    }
  }

  test('immediate acknowledgment is retained by the registered waiter', () async {
    await container.connectRoom();
    container.wsConnector.onSend = (data) {
      final request = lk_rtc.SignalRequest.fromBuffer(data);
      if (request.hasAddTrack()) {
        container.wsConnector.onData(accepted(request.addTrack.cid).writeToBuffer());
      }
    };
    final info = await container.engine.addTrack(lk_rtc.AddTrackRequest(cid: 'immediate'));
    expect(info.sid, 'TR_accepted');
  });

  test('rejection fails promptly and allows the CID to be retried', () async {
    await container.connectRoom();
    container.wsConnector.onSend = (data) {
      final request = lk_rtc.SignalRequest.fromBuffer(data);
      if (request.hasAddTrack()) {
        container.wsConnector.onData(
          lk_rtc.SignalResponse(
            requestResponse: lk_rtc.RequestResponse(
              addTrack: request.addTrack,
              reason: lk_rtc.RequestResponse_Reason.NOT_ALLOWED,
              message: 'not allowed',
            ),
          ).writeToBuffer(),
        );
      }
    };
    await expectLater(
      container.engine.addTrack(lk_rtc.AddTrackRequest(cid: 'retry')),
      throwsA(isA<TrackPublishException>()),
    );
    container.wsConnector.onSend = (data) {
      final request = lk_rtc.SignalRequest.fromBuffer(data);
      if (request.hasAddTrack()) container.wsConnector.onData(accepted(request.addTrack.cid).writeToBuffer());
    };
    expect((await container.engine.addTrack(lk_rtc.AddTrackRequest(cid: 'retry'))).sid, 'TR_accepted');
  });

  test('duplicate CID cannot replace or cancel the first response waiter', () async {
    await container.connectRoom();
    final pending = container.engine.addTrack(lk_rtc.AddTrackRequest(cid: 'duplicate'));
    await expectLater(
      container.engine.addTrack(lk_rtc.AddTrackRequest(cid: 'duplicate')),
      throwsA(isA<TrackPublishException>()),
    );
    container.wsConnector.onData(accepted('duplicate').writeToBuffer());
    expect((await pending).sid, 'TR_accepted');
  });

  test('cleanup fails pending registration and forgets negotiated fast codecs', () async {
    final join = joinResponse.deepCopy();
    join.join.fastPublish = true;
    join.join.enabledPublishCodecs.add(lk_models.Codec(mime: 'audio/opus'));
    await container.connectRoom(joinResponseOverride: join);
    expect(container.engine.enabledPublishCodecs, isNotEmpty);
    final pending = container.engine.addTrack(lk_rtc.AddTrackRequest(cid: 'cleanup'));
    final failed = expectLater(pending, throwsA(isA<TrackPublishException>()));
    await container.engine.cleanUp();
    await failed;
    expect(container.engine.enabledPublishCodecs, isNull);
  });

  test('disconnect fails pending registration and rejects further publication', () async {
    await container.connectRoom();
    final pending = container.engine.addTrack(lk_rtc.AddTrackRequest(cid: 'pending'));
    final failed = expectLater(pending, throwsA(isA<TrackPublishException>()));
    container.engine.markClosed();
    await failed;
    await expectLater(
      container.engine.addTrack(lk_rtc.AddTrackRequest(cid: 'later')),
      throwsA(isA<TrackPublishException>()),
    );
  });
}
