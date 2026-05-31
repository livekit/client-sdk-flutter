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

@Timeout(Duration(seconds: 10))
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/core/engine.dart';
import 'package:livekit_client/src/core/signal_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import 'package:livekit_client/src/support/websocket.dart';

import '../core/signal_client_test.dart';
import '../mock/peerconnection_mock.dart';

/// A websocket that records every outgoing [lk_rtc.SignalRequest] so tests can
/// assert on what the SDK actually sends to the server.
class _CapturingWebSocket extends LiveKitWebSocket {
  final List<lk_rtc.SignalRequest> sent = [];

  @override
  void send(List<int> data) => sent.add(lk_rtc.SignalRequest.fromBuffer(data));
}

class _CapturingConnector {
  final socket = _CapturingWebSocket();
  WebSocketEventHandlers? handlers;

  WebSocketOnData get onData => handlers!.onData!;

  Future<LiveKitWebSocket> connect(
    Uri uri, {
    WebSocketEventHandlers? options,
    Map<String, String>? headers,
  }) async {
    handlers = options;
    return socket;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CapturingConnector connector;
  late Room room;

  setUp(() async {
    connector = _CapturingConnector();
    final client = SignalClient(connector.connect);
    final engine = Engine(
      connectOptions: const ConnectOptions(),
      // adaptiveStream defaults to false, so no visibility timer runs and the
      // emitted settings depend only on the explicit enable/disable preference.
      roomOptions: const RoomOptions(),
      signalClient: client,
      peerConnectionCreate: MockPeerConnection.create,
    );
    room = Room(engine: engine);

    final connectFuture = room.connect(exampleUri, token);
    Future.delayed(const Duration(milliseconds: 1), () {
      connector.onData(joinResponse.writeToBuffer());
      connector.onData(offerResponse.writeToBuffer());
    });
    await connectFuture;

    connector.onData(participantJoinResponse.writeToBuffer());
    await room.events.waitFor<ParticipantConnectedEvent>(duration: const Duration(seconds: 1));
  });

  tearDown(() async {
    await room.dispose();
  });

  /// The most recent [lk_rtc.UpdateTrackSettings] the SDK sent for [sid], if any.
  lk_rtc.UpdateTrackSettings? lastSettingsFor(String sid) {
    final matches = connector.socket.sent
        .where((r) => r.hasTrackSetting() && r.trackSetting.trackSids.contains(sid))
        .toList();
    return matches.isEmpty ? null : matches.last.trackSetting;
  }

  group('enable/disable wiring', () {
    test('disable() then enable() emit the disabled flag through the real publication path', () async {
      final participant = room.remoteParticipants.values.first;
      const sid = 'TR_remote_pub_test';
      final pub = RemoteTrackPublication<RemoteVideoTrack>(
        participant: participant,
        info: lk_models.TrackInfo(
          sid: sid,
          name: 'video',
          type: lk_models.TrackType.VIDEO,
        ),
      );
      addTearDown(() async => await pub.dispose());

      // No explicit preference yet: enabled by default, nothing sent.
      expect(pub.enabled, isTrue);
      expect(lastSettingsFor(sid), isNull);

      await pub.disable();
      final disabled = lastSettingsFor(sid);
      expect(disabled, isNotNull, reason: 'disable() should send an UpdateTrackSettings');
      expect(disabled!.disabled, isTrue);
      expect(disabled.trackSids, [sid]);
      // The default video path resolves to HIGH quality.
      expect(disabled.quality, lk_models.VideoQuality.HIGH);
      expect(pub.enabled, isFalse);

      await pub.enable();
      final enabled = lastSettingsFor(sid);
      expect(enabled!.disabled, isFalse);
      expect(pub.enabled, isTrue);
    });

    test('repeated disable() is a no-op (no duplicate send)', () async {
      final participant = room.remoteParticipants.values.first;
      const sid = 'TR_remote_pub_dedup';
      final pub = RemoteTrackPublication<RemoteVideoTrack>(
        participant: participant,
        info: lk_models.TrackInfo(
          sid: sid,
          name: 'video',
          type: lk_models.TrackType.VIDEO,
        ),
      );
      addTearDown(() async => await pub.dispose());

      await pub.disable();
      final countAfterFirst =
          connector.socket.sent.where((r) => r.hasTrackSetting() && r.trackSetting.trackSids.contains(sid)).length;

      await pub.disable();
      final countAfterSecond =
          connector.socket.sent.where((r) => r.hasTrackSetting() && r.trackSetting.trackSids.contains(sid)).length;

      expect(countAfterFirst, 1);
      expect(countAfterSecond, 1, reason: 'a second disable() with no state change should not re-send');
    });
  });
}
