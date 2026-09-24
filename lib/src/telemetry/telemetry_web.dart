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

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc show StatsReport;
import 'package:logging/logging.dart';

import '../core/room.dart';
import '../logger.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../track/options.dart';
import '../track/track.dart';
import '../types/internal.dart';
import '../types/other.dart';
import 'telemetry.dart';

/// Web implementation of the telemetry hooks: the Rust core is a native library
/// the web cannot load, so every hook is a no-op and no Room ever gets a scope.
/// See `telemetry.dart`.

Future<void> configure(TelemetryOptions? options) async {
  if (options != null) logger.fine('telemetry is not available on web');
}

void setAttribute(String key, Object? value) {}

String diagnostics() => 'telemetry: unavailable on web';

void log(LogRecord record) {}

void telemetrySetServer(String url, String token) {}

void telemetryCaptureFailed(LocalTrackOptions options, Object error) {}

class RoomTelemetry {
  static RoomTelemetry? create() => null;

  String get traceId => '';

  TraceSpan? connect() => null;

  TraceSpan? reconnect(ClientDisconnectReason reason, lk_models.ReconnectReason? protoReason) => null;

  TraceSpan? publish(TrackType kind, TrackSource source, {TraceSpan? parent}) => null;

  TraceSpan? custom(String name) => null;

  void setRoom(lk_models.Room room, lk_models.ParticipantInfo participant) {}

  void disconnected(DisconnectReason? reason) {}

  void emitCustom(String name, Map<String, Object> attributes) {}

  void observe(Room room) {}

  void recordStatsReport(Track track, List<rtc.StatsReport> report, {required bool outbound}) {}
}

class TraceSpan {
  int? get spanId => null;

  void step(ConnectStep step) {}

  void attempt(int number, {required bool full}) {}

  void setTrack(TrackType kind, TrackSource source, {String? sid}) {}

  void end() {}

  void fail(Object error) {}

  void cancel() {}

  String describe() => '';
}
