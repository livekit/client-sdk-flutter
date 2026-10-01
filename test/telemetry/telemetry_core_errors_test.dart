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

/// Telemetry never fails or outlives what it observes. A core that fails on every call never fails
/// the SDK: connect, publish (and its error), app events, logging at every level, a reconnect and
/// teardown run as without telemetry (an exception escaping a telemetry listener would fail the
/// test as an uncaught error). A disposed Room leaves no telemetry listener behind.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/core/signal_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import 'package:livekit_client/src/telemetry/telemetry_io.dart' show liveSpanHandles, telemetryScopeFactory;
import 'package:livekit_client/src/uniffi/uniffi_io.dart' as ffi;
import '../mock/e2e_container.dart';
import '../mock/media_stream_mock.dart';
import '../mock/peerconnection_mock.dart';
import '../mock/test_data.dart';
import '../mock/websocket_mock.dart';

void main() {
  test('a failing core never fails a call', () async {
    final real = telemetryScopeFactory;
    final level = Logger.root.level;
    addTearDown(() {
      telemetryScopeFactory = real;
      Logger.root.level = level;
    });
    telemetryScopeFactory = () => real() == null ? null : _BrokenScope();
    // Every level: a diagnostic logged while the logger delivers a record must not re-enter it.
    Logger.root.level = Level.ALL;
    final disposeErrors = <String>[];
    final records = Logger.root.onRecord
        .where((r) => r.message.contains('error during dispose'))
        .listen((r) => disposeErrors.add(r.message));
    addTearDown(records.cancel);

    final container = E2EContainer();
    final room = container.room;
    final ws = container.wsConnector;
    if (room.telemetry == null) {
      markTestSkipped('no native library');
      return;
    }
    await container.connectRoom();
    room
      ..emitTelemetryEvent('app.event')
      ..setTelemetryAttribute('app.key', 'value');

    final track = LocalAudioTrack(
      TrackSource.microphone,
      FakeMediaStream('local_stream'),
      FakeMediaStreamTrack(id: 'mic-1', kind: 'audio'),
      const AudioCaptureOptions(),
    );
    final publishing = room.localParticipant!.publishAudioTrack(track);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    ws.onData(
      lk_rtc.SignalResponse(
        trackPublished: lk_rtc.TrackPublishedResponse(cid: track.getCid(), track: localAudioTrack),
      ).writeToBuffer(),
    );
    expect((await publishing).sid, localAudioTrack.sid);
    await expectLater(
      room.localParticipant!.publishAudioTrack(track),
      throwsA(isA<TrackPublishException>()),
      reason: 'the publish error, not the core\'s',
    );

    // A warning from one of the Room's handlers goes to its (failing) session.
    ws.onData(
      lk_rtc.SignalResponse(
        streamStateUpdate: lk_rtc.StreamStateUpdate(
          streamStates: [lk_rtc.StreamStateInfo(participantSid: 'nobody', trackSid: 'TR_nobody')],
        ),
      ).writeToBuffer(),
    );

    // A quick reconnect, then the client hangs up.
    final handlers = ws.handlers;
    ws.onDispose();
    for (var i = 0; i < 200 && identical(ws.handlers, handlers); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    ws.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());
    await room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));
    final disconnecting = room.disconnect();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    ws.onData(
      lk_rtc.SignalResponse(
        leave: lk_rtc.LeaveRequest(
          reason: lk_models.DisconnectReason.CLIENT_INITIATED,
          action: lk_rtc.LeaveRequest_Action.DISCONNECT,
        ),
      ).writeToBuffer(),
    );
    await disconnecting;
    expect(room.connectionState, ConnectionState.disconnected);
    await container.dispose();

    // A Room disposed while still connected.
    resetMockDataChannels();
    final connected = E2EContainer();
    await connected.connectRoom();
    await connected.dispose();
    expect(disposeErrors, isEmpty, reason: 'telemetry fails no dispose step');
  });

  test('a disposed Room leaves no telemetry listener and no span handle behind', () async {
    // The SignalClient can outlive its Room; a listener left on it would keep the Room alive, and
    // the connect zone its subscriptions keep would hold the connect span.
    final baseline = SignalClient(MockWebSocketConnector().connect).events.listeners.length;
    final spans = liveSpanHandles;
    for (var i = 0; i < 3; i++) {
      resetMockDataChannels();
      final container = E2EContainer();
      if (container.room.telemetry == null) {
        markTestSkipped('no native library');
        return;
      }
      final connecting = container.connectRoom();
      expect(liveSpanHandles, spans + 1, reason: 'the open connect span holds its handle');
      await connecting;
      expect(liveSpanHandles, spans, reason: 'the ended connect span released it');
      expect(container.client.events.listeners.length, greaterThan(baseline));
      await container.dispose();
      expect(container.client.events.listeners.length, baseline, reason: 'round $i');
      expect(liveSpanHandles, spans, reason: 'round $i');
    }
  });
}

/// Every call fails, as a Rust panic surfaces in Dart; spans it starts fail the same way.
class _BrokenScope implements ffi.TelemetryScope {
  @override
  ffi.TelemetrySpan start({required ffi.SpanName name, required ffi.TelemetrySpan? parent}) => _BrokenSpan();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('core panicked');
}

class _BrokenSpan implements ffi.TelemetrySpan {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('core panicked');
}
