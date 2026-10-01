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

/// End to end through the Rust core into a local OpenTelemetry collector: the SDK's mock signal
/// and peer connection, and `otelcol-contrib --config test/telemetry/otelcol.yaml`, which writes
/// every OTLP request as a JSON line. The core reads `LK_TELEMETRY_ENDPOINT` when the pipeline
/// starts, so the story runs only with it set (`LK_TELEMETRY_ENDPOINT=http://127.0.0.1:4319
/// flutter test test/telemetry/`) and skips otherwise. The pipeline is process-wide, hence one story.
@TestOn('vm')
@Timeout(Duration(seconds: 90))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show AppLifecycleState;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/internal/events.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import 'package:livekit_client/src/telemetry/telemetry_io.dart' show exportTimeout, sendExport, storageDirectory;
import 'package:livekit_client/src/uniffi/uniffi_io.dart' as ffi;
import '../core/signal_client_test.dart';
import '../mock/e2e_container.dart';
import '../mock/media_stream_mock.dart';
import '../mock/peerconnection_mock.dart';
import '../mock/test_data.dart';

/// What the file collector writes: test/telemetry/otelcol.yaml's path, or `LK_TELEMETRY_OTLP_FILE`
/// for a collector of your own (another port, another file).
final collectorOutput = Platform.environment['LK_TELEMETRY_OTLP_FILE'] ?? '/tmp/livekit-telemetry-otlp.jsonl';

Future<void> main() async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  // The test binding answers every HttpClient request with a 400; the transport needs the real
  // collector (and the transport tests their local servers).
  HttpOverrides.global = null;

  final endpoint = Platform.environment['LK_TELEMETRY_ENDPOINT'];
  final skip = endpoint == null
      ? 'LK_TELEMETRY_ENDPOINT is not set'
      : await _reachable(Uri.parse(endpoint))
      ? null
      : 'no collector at $endpoint';

  test('a call, from connect to opt-out, reaches the collector', skip: skip, () async {
    final start = DateTime.now().microsecondsSinceEpoch * 1000;
    final marker = 'e2e-${DateTime.now().microsecondsSinceEpoch}';
    resetMockDataChannels();

    final container = E2EContainer();
    final room = container.room;
    final ws = container.wsConnector;
    expect(room.telemetry, isNotNull, reason: 'the native library is bundled and the pipeline installed');
    // Someone published before this Room joined: with autoSubscribe the join is the intent.
    final early = lk_models.ParticipantInfo(
      sid: 'PA_early',
      identity: 'early',
      state: lk_models.ParticipantInfo_State.ACTIVE,
      tracks: [lk_models.TrackInfo(sid: 'TR_early', type: lk_models.TrackType.AUDIO)],
    );
    await container.connectRoom(otherParticipants: [early]);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    mockInboundTracks['TR_early'] = 'audio';
    container.engine.events.emit(
      EngineTrackAddedEvent(
        track: FakeMediaStreamTrack(id: 'TR_early', kind: 'audio'),
        stream: FakeMediaStream('PA_early|early_stream'),
        receiver: null,
      ),
    );
    await room.events.waitFor<TrackSubscribedEvent>(duration: const Duration(seconds: 2));

    // A track unpublished before any media arrived: its subscribe is cancelled.
    lk_rtc.SignalResponse update(List<lk_models.TrackInfo> tracks) => lk_rtc.SignalResponse(
      update: lk_rtc.ParticipantUpdate(participants: [early.deepCopy()..tracks.addAll(tracks)]),
    );
    ws.onData(update([lk_models.TrackInfo(sid: 'TR_gone', type: lk_models.TrackType.VIDEO)]).writeToBuffer());
    await room.events.waitFor<TrackPublishedEvent>(duration: const Duration(seconds: 2));
    ws.onData(update(const []).writeToBuffer());
    await room.events.waitFor<TrackUnpublishedEvent>(duration: const Duration(seconds: 2));

    // App data: a correlation attribute on everything from now on (one set, one removed).
    room.setTelemetryAttribute('app.call_id', marker);
    room.setTelemetryAttribute('app.removed', marker);
    room.setTelemetryAttribute('app.removed', null);

    // Publish a microphone through the mock peer connection: the SDK sends AddTrack and waits for
    // the server's TrackPublished answer. Publishing it again fails: an `lk.publish` error.
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
    await expectLater(room.localParticipant!.publishAudioTrack(track), throwsA(isA<TrackPublishException>()));
    // …and a microphone that cannot be opened (no capture device under `flutter test`).
    await expectLater(LocalAudioTrack.create(), throwsA(anything));

    // Subscribe: a remote participant joins and publishes (autoSubscribe: the intent), its track arrives,
    // and its media flows (the mock reports growing inbound bytes): first media.
    mockInboundTracks[remoteAudioTrack.sid] = 'audio';
    ws.onData(participantJoinResponse.writeToBuffer());
    container.engine.events.emit(
      EngineTrackAddedEvent(
        track: FakeMediaStreamTrack(id: remoteAudioTrack.sid, kind: 'audio'),
        stream: FakeMediaStream('${remoteParticipantData.sid}|remote_stream'),
        receiver: null,
      ),
    );
    await room.events.waitFor<TrackSubscribedEvent>(duration: const Duration(seconds: 2));
    await Future<void>.delayed(const Duration(seconds: 3)); // first media, at the core's 1 s polls

    // A warning from one of the Room's own handlers, with no span open: the Room's session.
    ws.onData(
      lk_rtc.SignalResponse(
        streamStateUpdate: lk_rtc.StreamStateUpdate(
          streamStates: [
            lk_rtc.StreamStateInfo(participantSid: marker, trackSid: 'TR_nobody', state: lk_rtc.StreamState.ACTIVE),
          ],
        ),
      ).writeToBuffer(),
    );
    room.emitTelemetryEvent('e2e.checkpoint', attributes: {'e2e.marker': marker});

    // The server moves the participant to another room: what follows carries the new identity.
    ws.onData(
      lk_rtc.SignalResponse(
        roomMoved: lk_rtc.RoomMovedResponse(
          room: lk_models.Room(sid: 'RM_moved', name: 'moved_room'),
          participant: localParticipantData,
          token: 'moved-$token',
        ),
      ).writeToBuffer(),
    );
    await room.events.waitFor<RoomMovedEvent>(duration: const Duration(seconds: 2));
    room.emitTelemetryEvent('e2e.moved', attributes: {'e2e.marker': marker});

    // Device changes a host never makes on its own.
    binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed)
      ..handleMemoryPressure();

    // A quick reconnect: the socket drops, the SDK resumes, the server answers.
    final handlers = ws.handlers;
    ws.onDispose();
    for (var i = 0; i < 200 && identical(ws.handlers, handlers); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(ws.uri!.queryParameters['reconnect'], '1', reason: 'a resume, not a re-join');
    ws.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());
    await room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));

    // A server-refreshed token is taken over without a hiccup.
    ws.onData(lk_rtc.SignalResponse(refreshToken: 'refreshed-$token').writeToBuffer());

    // The client hangs up: the server acknowledges with a Leave.
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
    await container.dispose();
    mockInboundTracks.clear();

    await _flush();
    final stats = ffi.telemetryStats()!;
    expect(stats.cachedBatches, 0, reason: 'the whole call shipped: ${ffi.telemetryDiagnostics()}');
    expect(stats.dropped, 0, reason: ffi.telemetryDiagnostics());

    // Opt-out: what was not yet sent is deleted, nothing is collected afterwards.
    Room().emitTelemetryEvent('e2e.pending', attributes: {'e2e.marker': marker});
    final purged = LiveKitClient.disableTelemetry();
    expect(Room().telemetry, isNull, reason: 'in effect at once: a Room created afterwards collects nothing');
    await purged;
    await ffi.telemetryFlush(); // waits for the background purge
    final cache = Directory(storageDirectory!);
    expect(cache.existsSync() ? cache.listSync() : const [], isEmpty, reason: 'the on-disk cache is purged');

    // What reached the backend: asserted when it is the file collector (test/telemetry/otelcol.yaml);
    // any other backend (a local LGTM stack) is looked up by the call's marker instead.
    if (Uri.parse(endpoint!).port != 4319 && !Platform.environment.containsKey('LK_TELEMETRY_OTLP_FILE')) {
      print('telemetry e2e: find app.call_id=$marker in the backend');
      return;
    }
    await Future<void>.delayed(const Duration(seconds: 2)); // the collector's file write
    final otlp = OtlpFile(collectorOutput, since: start);
    expect(otlp.logs.where((l) => l.eventName == 'custom.e2e.pending'), isEmpty, reason: 'deleted, never uploaded');
    final checkpoint = otlp.logs.singleWhere(
      (l) => l.eventName == 'custom.e2e.checkpoint' && l.attributes['e2e.marker'] == marker,
    );
    final trace = checkpoint.traceId;
    expect(trace, hasLength(32), reason: 'the Room has its own trace');
    final spans = otlp.spans.where((s) => s.traceId == trace).toList();
    final logs = otlp.logs.where((l) => l.traceId == trace).toList();

    // Connect: one span with this platform's checkpoints; the reconnect is its own span.
    final connect = spans.singleWhere((s) => s.name == 'lk.connect');
    expect(
      connect.events,
      containsAll(['ws_open', 'signal', 'join_recv', 'pc_created', 'answer_sent', 'pc_connected', 'room_connected']),
    );
    expect(connect.attributes, containsPair('lk.outcome', 'ok'));
    expect(connect.attributes, containsPair('lk.connect.attempt', '1'));
    final reconnect = spans.singleWhere((s) => s.name == 'lk.reconnect');
    expect(reconnect.attributes, containsPair('lk.reconnect.reason', 'signal_disconnected'));
    expect(reconnect.attributes, containsPair('lk.outcome', 'ok'));
    expect(reconnect.events, contains('attempt 1 quick'));

    // Publish: one microphone, one duplicate refused; subscribe: intent → first media.
    final publishes = spans.where((s) => s.name == 'lk.publish').toList();
    expect(
      publishes.where((s) => s.attributes['lk.outcome'] == 'ok' && s.attributes['lk.track.sid'] == localAudioTrack.sid),
      hasLength(1),
    );
    expect(publishes.where((s) => s.attributes['error.type'] == 'TrackPublishException'), hasLength(1));
    final subscribes = {for (final s in spans.where((s) => s.name == 'lk.subscribe')) s.attributes['lk.track.sid']: s};
    for (final sid in ['TR_early', remoteAudioTrack.sid]) {
      expect(subscribes[sid]?.attributes, containsPair('lk.outcome', 'ok'), reason: sid);
      expect(subscribes[sid]?.events, containsAll(['subscribed', 'first_media']), reason: sid);
    }
    expect(subscribes['TR_gone']?.attributes, containsPair('lk.outcome', 'cancelled'), reason: 'ended before media');
    final joined = subscribes['TR_early']!;
    expect(
      joined.eventNanos['subscribed']! - joined.startNanos,
      greaterThan(400 * 1000 * 1000),
      reason: 'a track published before the join is wanted from the join on, not from its arrival',
    );

    // RTC windows from one report per peer connection, each track in its direction.
    final windows = logs.where((l) => l.eventName == 'lk.rtc.stats.sample').toList();
    for (final direction in ['outbound', 'inbound']) {
      expect(
        windows.where(
          (w) => w.attributes['lk.track.kind'] == 'audio' && w.attributes['lk.track.direction'] == direction,
        ),
        isNotEmpty,
        reason: '$direction audio window',
      );
    }
    expect(windows.every((w) => w.attributes['app.call_id'] == marker), isTrue, reason: 'windows carry app attributes');

    // App data and SDK records.
    expect(checkpoint.attributes, containsPair('app.call_id', marker));
    expect(otlp.logs.where((l) => l.attributes.containsKey('app.removed')), isEmpty);
    final moved = logs.singleWhere((l) => l.eventName == 'custom.e2e.moved');
    expect(moved.attributes, containsPair('lk.room.name', 'moved_room'));
    expect(moved.attributes, containsPair('lk.room.sid', 'RM_moved'));
    final warning = logs.singleWhere((l) => l.body == 'Participant not found for sid $marker');
    expect(warning.spanId, isEmpty, reason: 'no span open: filed under the Room\'s session');
    // `lk.room.*` is the scope's current identity when the record ships: after the move.
    expect(warning.attributes, containsPair('lk.room.name', 'moved_room'));
    expect(
      otlp.logs.where((l) => l.eventName.isEmpty).every((l) => l.severity >= 13),
      isTrue,
      reason: 'log records are warnings and errors only',
    );

    // The session ends once, never on the reconnect.
    final ended = logs.singleWhere((l) => l.eventName == 'lk.room.disconnected');
    expect(ended.attributes, containsPair('lk.disconnect.reason', 'client_initiated'));

    // Device: the state's initial values and what this platform can post.
    for (final event in ['lk.device.memory.changed', 'lk.device.network.changed', 'lk.device.app_state.changed']) {
      expect(otlp.logs.where((l) => l.eventName == event), isNotEmpty, reason: event);
    }
    for (final event in ['lk.device.thermal.changed', 'lk.device.low_power.changed']) {
      expect(otlp.logs.where((l) => l.eventName == event), isEmpty, reason: '$event: no source, reported unknown');
    }
    expect(otlp.logs.where((l) => l.attributes['lk.device.app_state'] == 'background'), isNotEmpty);
    expect(otlp.logs.where((l) => l.attributes['lk.device.memory.pressure'] == 'warning'), isNotEmpty);
    expect(
      otlp.logs.where(
        (l) => l.eventName == 'lk.device.capture.failed' && l.attributes['lk.device.capture.device'] == 'microphone',
      ),
      isNotEmpty,
    );
  });

  group('transport', () {
    late HttpServer collector;
    final client = http.Client();

    setUp(() async => collector = await HttpServer.bind(InternetAddress.loopbackIPv4, 0));
    tearDown(() => collector.close(force: true));

    ffi.ExportRequest requestTo(int port) => ffi.ExportRequest(
      url: 'http://127.0.0.1:$port/v1/logs',
      headers: {'Authorization': 'Bearer token'},
      body: Uint8List.fromList([1, 2, 3]),
    );

    test('passes the collector\'s answer through untouched', () async {
      collector.listen((request) async {
        final body = await request.fold<List<int>>([], (all, chunk) => all..addAll(chunk));
        request.response
          ..statusCode = body.length == 3 && request.headers.value('authorization') == 'Bearer token' ? 429 : 400
          ..headers.set('Retry-After', '7')
          ..write('quota');
        await request.response.close();
      });
      final response = await sendExport(client, requestTo(collector.port));
      expect(response.status, 429);
      expect(response.headers['retry-after'], '7');
      expect(utf8.decode(response.body), 'quota');
    });

    test('never follows a redirect with the token', () async {
      final elsewhere = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => elsewhere.close(force: true));
      var followed = false;
      elsewhere.listen((request) {
        followed = true;
        unawaited(request.response.close());
      });
      collector.listen((request) async {
        request.response
          ..statusCode = 307
          ..headers.set('Location', 'http://127.0.0.1:${elsewhere.port}/v1/logs');
        await request.response.close();
      });
      final response = await sendExport(client, requestTo(collector.port));
      expect(response.status, 307, reason: 'the redirect is the answer');
      expect(followed, isFalse);
    });

    test('a collector that never answers cannot hold the queue', () async {
      final unanswered = <HttpRequest>[];
      collector.listen(unanswered.add); // accepts, never replies
      exportTimeout = const Duration(milliseconds: 300);
      addTearDown(() => exportTimeout = const Duration(seconds: 10));
      await expectLater(
        sendExport(client, requestTo(collector.port)).timeout(const Duration(seconds: 5)),
        throwsA(isA<http.RequestAbortedException>()),
      );
      expect(unanswered, hasLength(1));
    });

    test('no answer is its only error', () async {
      final port = collector.port;
      await collector.close(force: true);
      await expectLater(sendExport(client, requestTo(port)), throwsA(isA<http.ClientException>()));
    });
  });
}

Future<bool> _reachable(Uri endpoint) async {
  try {
    final socket = await Socket.connect(endpoint.host, endpoint.port, timeout: const Duration(seconds: 1));
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}

/// Ships everything the core holds.
Future<void> _flush() async {
  for (var i = 0; i < 10; i++) {
    await ffi.telemetryFlush(); // drains the whole cache the network allows
    if ((ffi.telemetryStats()?.cachedBatches ?? 0) == 0) break;
  }
}

/// What the collector wrote: OTLP/JSON, one export request per line; only the records stamped at
/// or after `since` (unix nanoseconds).
class OtlpFile {
  final logs = <OtlpLog>[];
  final spans = <OtlpSpan>[];

  OtlpFile(String path, {required int since}) {
    for (final line in File(path).readAsLinesSync()) {
      if (!line.startsWith('{')) continue;
      final request = jsonDecode(line) as Map<String, dynamic>;
      for (final scope in _children(request, 'resourceLogs', 'scopeLogs')) {
        for (final record in scope['logRecords'] as List? ?? []) {
          if (_nanos(record['timeUnixNano']) < since) continue;
          logs.add(
            OtlpLog(
              eventName: record['eventName'] as String? ?? '',
              body: (record['body'] as Map?)?['stringValue'] as String?,
              traceId: record['traceId'] as String? ?? '',
              spanId: record['spanId'] as String? ?? '',
              severity: record['severityNumber'] as int? ?? 0,
              attributes: _attributes(record['attributes']),
            ),
          );
        }
      }
      for (final scope in _children(request, 'resourceSpans', 'scopeSpans')) {
        for (final span in scope['spans'] as List? ?? []) {
          if (_nanos(span['startTimeUnixNano']) < since) continue;
          final events = span['events'] as List? ?? [];
          spans.add(
            OtlpSpan(
              name: span['name'] as String? ?? '',
              traceId: span['traceId'] as String? ?? '',
              startNanos: _nanos(span['startTimeUnixNano']),
              attributes: _attributes(span['attributes']),
              events: [for (final event in events) event['name'] as String],
              eventNanos: {for (final event in events) event['name'] as String: _nanos(event['timeUnixNano'])},
            ),
          );
        }
      }
    }
  }

  static Iterable<Map<String, dynamic>> _children(Map<String, dynamic> request, String resources, String scopes) => [
    for (final resource in request[resources] as List? ?? [])
      for (final scope in resource[scopes] as List? ?? []) scope as Map<String, dynamic>,
  ];

  /// OTLP/JSON writes uint64 as a decimal string.
  static int _nanos(Object? value) => value is int ? value : int.tryParse('$value') ?? 0;

  /// OTLP/JSON attributes (`[{key, value: {stringValue | intValue | boolValue | doubleValue}}]`) as strings.
  static Map<String, String> _attributes(Object? value) => {
    for (final pair in value as List? ?? [])
      if ((pair['value'] as Map).isNotEmpty) pair['key'] as String: '${(pair['value'] as Map).values.first}',
  };
}

class OtlpLog {
  final String eventName;
  final String? body;
  final String traceId;
  final String spanId;
  final int severity;
  final Map<String, String> attributes;
  OtlpLog({
    required this.eventName,
    required this.body,
    required this.traceId,
    required this.spanId,
    required this.severity,
    required this.attributes,
  });
}

class OtlpSpan {
  final String name;
  final String traceId;
  final int startNanos;
  final Map<String, String> attributes;

  /// Span event names: the checkpoints (`ws_open`, `first_media`, `attempt 1 quick`, …).
  final List<String> events;
  final Map<String, int> eventNanos;
  OtlpSpan({
    required this.name,
    required this.traceId,
    required this.startNanos,
    required this.attributes,
    required this.events,
    required this.eventNanos,
  });
}
