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

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'telemetry_io.dart' if (dart.library.js_interop) 'telemetry_web.dart' as impl;
import 'telemetry_io.dart' if (dart.library.js_interop) 'telemetry_web.dart' show RoomTelemetry, TraceSpan;

export 'telemetry_io.dart'
    if (dart.library.js_interop) 'telemetry_web.dart'
    show RoomTelemetry, TraceSpan, telemetrySetServer, telemetryCaptureFailed;

/// The telemetry instruments, by area. Choose which run with
/// [TelemetryOptions.instruments].
enum TelemetryInstrument {
  /// Spans of the Room's operations: `lk.connect`, `lk.reconnect`, `lk.publish`.
  room,

  /// Track statistics windows and the `lk.subscribe` span (time to media).
  rtc,

  /// Warning and error log records from the SDK and the Rust core.
  logs,

  /// Device state (network, memory, app lifecycle) and audio route / capture
  /// failure events.
  device,
}

/// Client telemetry: ships SDK diagnostics (warn/error records, per-track RTC
/// statistics, operation spans, device state) out-of-band to an OTLP/HTTP
/// collector. Process-wide: configure once with [LiveKitClient.setTelemetry]
/// before creating Rooms. A no-op on web, where the Rust core is not available.
class TelemetryOptions {
  /// Full OTLP/HTTP logs URL, e.g. `http://localhost:4318/v1/logs` for a local
  /// collector. `null` (the default) derives it from the server the first Room
  /// connects to and authenticates with the room token; until then everything
  /// is buffered on device.
  final Uri? endpoint;

  /// Extra request headers, e.g. `Authorization`.
  final Map<String, String> headers;

  /// Directory for the on-disk batch cache; `null` keeps batches in memory only.
  final String? storageDirectory;

  /// Export cadence. Stretched automatically under memory / background pressure.
  final Duration flushInterval;

  /// RTC statistics window: one `lk.rtc.stats.sample` per track per window.
  final Duration statsWindow;

  /// Which instruments run; all by default. App-defined events and session
  /// identity are always on.
  final Set<TelemetryInstrument> instruments;

  /// Lowest log level that leaves the device (warnings and errors by default).
  final Level logLevel;

  const TelemetryOptions({
    this.endpoint,
    this.headers = const {},
    this.storageDirectory,
    this.flushInterval = const Duration(seconds: 15),
    this.statsWindow = const Duration(seconds: 15),
    this.instruments = const {
      TelemetryInstrument.room,
      TelemetryInstrument.rtc,
      TelemetryInstrument.logs,
      TelemetryInstrument.device,
    },
    this.logLevel = Level.WARNING,
  });
}

/// Client telemetry. The pipeline lives in the Rust core, one per process like
/// a logger, and so do the instruments it runs: Dart only builds the platform
/// ones and hands them over. Every Room created afterwards gets its own scope
/// (see `Room.telemetryTraceId`).
abstract final class Telemetry {
  /// Set or change the options; `null` turns telemetry off after a final flush.
  /// The pipeline starts now, so pre-connect errors are captured; its
  /// destination waits for the first connect unless the options name an
  /// endpoint.
  static Future<void> configure(TelemetryOptions? options) => impl.configure(options);

  /// Attach an attribute to every record of every scope: an `enduser.id`, a
  /// tenant, a build flavor. [value] is a `String`, `int`, `double` or `bool`;
  /// `null` removes it.
  static void setAttribute(String key, Object? value) => impl.setAttribute(key, value);

  /// A one-line readout of the pipeline's health for a debug console: status,
  /// throughput, backlog and losses.
  static String diagnostics() => impl.diagnostics();

  /// Forward one SDK log record to the pipeline; the logs instrument does this
  /// for every record of the SDK's [logger] at [TelemetryOptions.logLevel] or
  /// above.
  static void log(LogRecord record) => impl.log(record);
}

/// Checkpoints of the `lk.connect` span, in the core's vocabulary.
@internal
enum ConnectStep { wsOpen, signal, joinRecv, pcCreated, offerSent, answerSent, engine, pcConnected, roomConnected }

/// Zone value key of the ambient span: warn/error records logged inside
/// [TraceSpanZone.run] point at that span (via `LogRecord.zone`) and land in
/// its Room's trace.
@internal
const Symbol telemetrySpanKey = #livekitTelemetrySpan;

/// Zone value key of the ambient Room: records logged from a Room's event
/// handlers ([RoomTelemetryZone.run]) with no span land in that Room's session.
@internal
const Symbol telemetryRoomKey = #livekitTelemetryRoom;

@internal
extension TraceSpanZone on TraceSpan? {
  /// Run [body] with this span as the ambient one (a no-op when null).
  Future<T> run<T>(Future<T> Function() body) {
    final span = this;
    return span == null ? body() : runZoned(body, zoneValues: {telemetrySpanKey: span});
  }
}

@internal
extension RoomTelemetryZone on RoomTelemetry? {
  /// Run [body] with this Room as the ambient one (a no-op when null); stream
  /// listeners subscribed inside keep running in it.
  T run<T>(T Function() body) {
    final room = this;
    return room == null ? body() : runZoned(body, zoneValues: {telemetryRoomKey: room});
  }
}
