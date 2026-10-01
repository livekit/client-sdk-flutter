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

import '../core/room.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../publication/remote.dart';
import '../publication/track_publication.dart';
import '../track/local/local.dart';
import '../track/options.dart';
import '../types/internal.dart';
import 'telemetry_io.dart' if (dart.library.js_interop) 'telemetry_web.dart' as impl;

// Client telemetry, internal to the SDK. The pipeline — destination, token, batching, retries,
// cache, holds, stats mapping, span state — lives in the Rust core, one per process; Dart installs
// it with the first Room, feeds it OS signals and moves its bytes. A compiled no-op on web.

/// Checkpoints of the `lk.connect` span, in the core's vocabulary.
enum ConnectStep { wsOpen, signal, joinRecv, pcCreated, offerSent, answerSent, engine, pcConnected, roomConnected }

/// One Room's telemetry session: its trace, spans, RTC instrument and destination.
abstract interface class RoomTelemetry {
  /// A new Room's session, installing the process pipeline first if this is the first Room;
  /// null on web and after [disable].
  static RoomTelemetry? create(Room room) => impl.createRoomTelemetry(room);

  /// Opt-out for the rest of the process; see `LiveKitClient.disableTelemetry`.
  static Future<void> disable() => impl.disableTelemetry();

  /// A capture device failed to start (getUserMedia / getDisplayMedia threw).
  static void captureFailed(LocalTrackOptions options, Object error) => impl.captureFailed(options, error);

  /// One `Room.connect` attempt as the `lk.connect` span; hands the core the server and token.
  Future<void> connect(String url, String token, Future<void> Function() body);

  /// A checkpoint of the open `lk.connect` span, if any.
  void step(ConnectStep step);

  /// One reconnect cycle as the `lk.reconnect` span; attempts are its checkpoints.
  TraceSpan? reconnect(ClientDisconnectReason reason, lk_models.ReconnectReason? protoReason);

  /// One publish attempt as the `lk.publish` span, under the ambient span or the open connect span.
  Future<T> publish<T extends TrackPublication>(LocalTrack track, Future<T> Function() body);

  /// Intent to subscribe to a track manually: the core opens its `lk.subscribe` span.
  void subscribeStarted(RemoteTrackPublication publication);

  /// See `Room.emitTelemetryEvent`.
  void emitCustom(String name, Map<String, String> attributes);

  /// See `Room.setTelemetryAttribute`.
  void setAttribute(String key, String? value);
}

/// A span the SDK drives across several steps (a reconnect cycle).
abstract interface class TraceSpan {
  /// `attempt N quick|full`.
  void attempt(int number, {required bool full});

  void end();

  /// End on an error; its type becomes `error.type`.
  void fail(Object error);

  void cancel();
}

/// Zone keys of the ambient span and Room: warn/error records logged inside point at that span or
/// land in that Room's session (`LogRecord.zone`); a publish nests under the ambient span.
const Symbol telemetrySpanKey = #livekitTelemetrySpan;
const Symbol telemetryRoomKey = #livekitTelemetryRoom;

extension TraceSpanZone on TraceSpan? {
  /// Run [body] with this span as the ambient one (a no-op when null).
  Future<T> run<T>(Future<T> Function() body) =>
      this == null ? body() : runZoned(body, zoneValues: {telemetrySpanKey: this});
}

extension RoomTelemetryZone on RoomTelemetry? {
  /// Run [body] with this Room as the ambient one (a no-op when null); stream listeners
  /// subscribed inside keep running in it.
  T run<T>(T Function() body) => this == null ? body() : runZoned(body, zoneValues: {telemetryRoomKey: this});
}
