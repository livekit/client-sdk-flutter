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

/// End to end through the Rust core: the SDK's mock signal / peer connection,
/// telemetry configured against a local OTLP collector that writes every batch
/// as one OTLP/JSON line to [collectorOutput] (`otelcol-contrib`; see the Swift
/// SDK's `Tests/LiveKitCoreTests/Telemetry/otelcol.yaml`).
@TestOn('vm')
@Timeout(Duration(seconds: 60))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import 'package:livekit_client/src/telemetry/telemetry.dart';
import '../core/signal_client_test.dart';
import '../mock/e2e_container.dart';
import '../mock/media_stream_mock.dart';
import '../mock/peerconnection_mock.dart';
import '../mock/test_data.dart';

const collectorOutput = '/tmp/livekit-telemetry-otlp.jsonl';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The test binding answers every HttpClient request with a 400; the
  // transport needs the real collector.
  HttpOverrides.global = null;

  test('a session with telemetry reaches the collector', () async {
    // Not truncated: the collector keeps its write offset, which would leave a
    // hole of NUL bytes. Records are filtered by time instead, like Swift's OTLPFile.
    final start = DateTime.now().microsecondsSinceEpoch * 1000;
    resetMockDataChannels();
    final marker = 'telemetry e2e ${DateTime.now().microsecondsSinceEpoch}';

    // Process-wide, configured before the Room exists, like an app would at launch.
    await Telemetry.configure(
      TelemetryOptions(
        endpoint: Uri.parse('http://127.0.0.1:4319/v1/logs'),
        flushInterval: const Duration(seconds: 1),
        statsWindow: const Duration(seconds: 2),
      ),
    );
    Telemetry.setAttribute('acme.tenant', marker);

    final container = E2EContainer();
    final room = container.room;
    final ws = container.wsConnector;
    await container.connectRoom();
    final traceId = room.telemetryTraceId!;
    expect(traceId, hasLength(32), reason: 'the Room has a printable session trace id');

    // Publish a microphone track through the mock peer connection: the SDK
    // sends AddTrack and waits for the server's TrackPublished answer.
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
    final publication = await publishing;
    expect(publication.sid, localAudioTrack.sid);

    // A warn record logged inside a span lands in that Room's trace, on that
    // span; one logged outside any span belongs to the process scope.
    final op = room.telemetry!.custom('e2e.op')!;
    await op.run(() async => logger.warning(marker));
    op.end();
    logger.warning('$marker outside');
    room.emitTelemetryEvent('e2e.checkpoint', attributes: {'e2e.marker': marker});

    // A quick reconnect: the socket drops, the SDK resumes, the server answers.
    final handlers = ws.handlers;
    ws.onDispose();
    for (var i = 0; i < 200 && identical(ws.handlers, handlers); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(identical(ws.handlers, handlers), isFalse, reason: 'the SDK re-opened the signal connection');
    expect(ws.uri!.queryParameters['reconnect'], '1', reason: 'a resume, not a re-join');
    ws.onData(lk_rtc.SignalResponse(reconnect: lk_rtc.ReconnectResponse()).writeToBuffer());
    await room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 5));

    // Stats windows: the monitor polls every 2 s, the core windows at 2 s.
    await Future<void>.delayed(const Duration(seconds: 7));

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

    // The disconnect flush (1 s cadence) and the collector's write, which lag
    // under load: poll for the session's last record rather than sleep.
    Future<OtlpFile> settled(bool Function(OtlpFile) done) async {
      var otlp = OtlpFile(collectorOutput, since: start);
      for (var i = 0; i < 100 && !done(otlp); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        otlp = OtlpFile(collectorOutput, since: start);
      }
      return otlp;
    }

    await settled((o) => o.logs.any((l) => l.eventName == 'lk.room.disconnected' && l.traceId == traceId));
    final diagnostics = Telemetry.diagnostics();
    print('telemetry diagnostics: $diagnostics');
    await Telemetry.configure(null); // drains what is left (open stats windows included)
    final otlp = await settled(
      (o) =>
          o.spans.any((s) => s.name == 'e2e.op' && s.traceId == traceId) &&
          o.logs.any((l) => l.body == marker) &&
          o.logs.any((l) => l.eventName == 'lk.rtc.stats.sample' && l.traceId == traceId),
    );
    final spans = otlp.spans.where((s) => s.traceId == traceId).toList();
    final logs = otlp.logs;

    final connects = spans.where((s) => s.name == 'lk.connect').toList();
    expect(connects, hasLength(1), reason: 'one lk.connect per session');
    expect(
      connects.single.events,
      containsAll([
        'ws_open',
        'signal',
        'join_recv',
        'pc_created',
        'answer_sent',
        'engine',
        'pc_connected',
        'room_connected',
      ]),
    );
    expect(connects.single.attributes['lk.outcome'], 'ok');

    final publishes = spans.where((s) => s.name == 'lk.publish').toList();
    expect(publishes, hasLength(1));
    expect(publishes.single.attributes['lk.track.kind'], 'audio');
    expect(publishes.single.attributes['lk.track.source'], 'microphone');
    expect(publishes.single.attributes['lk.track.sid'], localAudioTrack.sid);
    expect(publishes.single.attributes['lk.outcome'], 'ok');

    final reconnects = spans.where((s) => s.name == 'lk.reconnect').toList();
    expect(reconnects, hasLength(1), reason: 'one quick reconnect cycle');
    expect(reconnects.single.attributes['lk.reconnect.reason'], 'signal_disconnected');
    expect(reconnects.single.attributes['lk.reconnect.mode'], 'quick');
    expect(reconnects.single.attributes['lk.outcome'], 'ok');
    expect(reconnects.single.events, contains('attempt 1 quick'));

    final opSpan = spans.singleWhere((s) => s.name == 'e2e.op');
    final inSpan = logs.singleWhere((l) => l.body == marker);
    expect(inSpan.severity, greaterThanOrEqualTo(13));
    // Span ids above 2^63 cannot be sent back by the generated bindings yet
    // (see TraceSpan.spanId): the record then lands in the process scope.
    if (op.spanId == null) {
      print('e2e.op span id ${opSpan.spanId} is not representable in Dart; skipping correlation');
    } else {
      expect(inSpan.spanId, opSpan.spanId, reason: 'the record points at the span it was emitted in');
      expect(inSpan.traceId, traceId, reason: '...and therefore lands in the Room\'s trace');
      expect(inSpan.attributes['lk.room.name'], joinResponse.join.room.name, reason: 'scope attributes attached');
      expect(inSpan.attributes['lk.participant.identity'], localParticipantData.identity);
    }
    final outside = logs.singleWhere((l) => l.body == '$marker outside');
    expect(outside.spanId, isEmpty);
    expect(outside.traceId, isNot(traceId), reason: 'no ambient span: the process scope');

    expect(logs.any((l) => l.eventName == 'custom.e2e.checkpoint' && l.attributes['e2e.marker'] == marker), isTrue);
    for (final event in ['lk.device.thermal.changed', 'lk.device.memory.changed', 'lk.device.network.changed']) {
      expect(logs.any((l) => l.eventName == event), isTrue, reason: '$event initial value');
    }

    final windows = logs.where((l) => l.eventName == 'lk.rtc.stats.sample' && l.traceId == traceId).toList();
    expect(windows, isNotEmpty, reason: 'outbound audio stats windows from the mock sender');
    expect(
      windows.every(
        (w) => w.attributes['lk.track.kind'] == 'audio' && w.attributes['lk.track.direction'] == 'outbound',
      ),
      isTrue,
    );
    expect(
      windows.every((w) => w.attributes['lk.room.name'] != null),
      isTrue,
      reason: 'every window carries the room scope',
    );
    expect(windows.first.attributes['lk.rtc.codec'], 'audio/opus');

    final ended = logs.where((l) => l.eventName == 'lk.room.disconnected' && l.traceId == traceId).toList();
    expect(ended, hasLength(1));
    expect(ended.single.attributes['lk.disconnect.reason'], 'client_initiated');

    final tenant = logs.where((l) => l.attributes['acme.tenant'] == marker).map((l) => l.traceId).toSet();
    expect(tenant, contains(traceId), reason: 'the pipeline-wide attribute reaches the Room scope');
    expect(logs.every((l) => (l.body ?? '').isNotEmpty), isTrue, reason: 'every record has a body');
    expect(
      logs.where((l) => l.eventName.isEmpty).every((l) => l.severity >= 13),
      isTrue,
      reason: 'log records are warn/error only',
    );

    expect(diagnostics, contains('lost 0'), reason: diagnostics);
  });
}

/// What the collector wrote: OTLP/JSON, one export request per line; only the
/// records stamped at or after [since] (unix nanoseconds).
class OtlpFile {
  final logs = <OtlpLog>[];
  final spans = <OtlpSpan>[];

  OtlpFile(String path, {required int since}) {
    for (final line in File(path).readAsLinesSync()) {
      if (!line.startsWith('{')) continue;
      final request = jsonDecode(line) as Map<String, dynamic>;
      for (final resource in request['resourceLogs'] as List? ?? []) {
        for (final scope in resource['scopeLogs'] as List? ?? []) {
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
      }
      for (final resource in request['resourceSpans'] as List? ?? []) {
        for (final scope in resource['scopeSpans'] as List? ?? []) {
          for (final span in scope['spans'] as List? ?? []) {
            if (_nanos(span['startTimeUnixNano']) < since) continue;
            spans.add(
              OtlpSpan(
                name: span['name'] as String? ?? '',
                traceId: span['traceId'] as String? ?? '',
                spanId: span['spanId'] as String? ?? '',
                attributes: _attributes(span['attributes']),
                events: [for (final event in span['events'] as List? ?? []) event['name'] as String],
              ),
            );
          }
        }
      }
    }
  }

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
  final String spanId;
  final Map<String, String> attributes;

  /// Span event names: the steps (`ws_open`, `attempt 1 quick`, ...).
  final List<String> events;
  OtlpSpan({
    required this.name,
    required this.traceId,
    required this.spanId,
    required this.attributes,
    required this.events,
  });
}
