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

import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBindingObserver, WidgetsFlutterBinding;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc show StatsReport;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../core/room.dart';
import '../events.dart';
import '../extensions.dart';
import '../hardware/hardware.dart';
import '../livekit.dart';
import '../logger.dart';
import '../participant/remote.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../publication/remote.dart';
import '../support/platform.dart';
import '../track/options.dart';
import '../track/track.dart';
import '../types/internal.dart';
import '../types/other.dart';
import '../uniffi/uniffi_io.dart' as ffi;
import '../utils.dart';
import 'telemetry.dart';

/// Native implementation of the telemetry hooks. See `telemetry.dart`; the Rust
/// core owns every policy, this file moves bytes, feeds OS signals in and maps
/// the SDK's vocabulary onto the core's.

/// The telemetry module's own records are never captured (a loop otherwise).
final _log = Logger('livekit.telemetry');

/// The Rust core's log lines surface under this logger, one child per target.
const _ffiLoggerName = 'livekit.ffi';

TelemetryOptions? _options;

Future<void> configure(TelemetryOptions? options) async {
  _options = options;
  if (options == null) {
    await ffi.telemetryShutdown();
    return;
  }
  _forwardFfiLogs();
  final info = await Utils.clientInfo();
  final config = ffi.TelemetryConfig(
    endpoint: options.endpoint?.toString(),
    headers: options.headers,
    sdk: ffi.TelemetryResource(
      sdk: ffi.Sdk.flutter,
      sdkVersion: LiveKitClient.version,
      osName: (info?.hasOs() ?? false) ? info!.os : lkPlatform().name,
      osVersion: (info?.hasOsVersion() ?? false) ? info!.osVersion : '',
      deviceModel: (info?.hasDeviceModel() ?? false) ? info!.deviceModel : null,
    ),
    storageDir: options.storageDirectory,
    flushIntervalMs: options.flushInterval.inMilliseconds,
    statsWindowMs: options.statsWindow.inMilliseconds,
    logSeverity: _severity(options.logLevel),
    disabledInstruments: [
      for (final instrument in TelemetryInstrument.values)
        if (!options.instruments.contains(instrument)) _instrument(instrument),
    ],
  );
  // Fail-open: the app runs without telemetry rather than not at all.
  try {
    final queue = ffi.telemetryConfigurePulled(
      config: config,
      instruments: [
        if (options.instruments.contains(TelemetryInstrument.device)) _DeviceTelemetry(),
        if (options.instruments.contains(TelemetryInstrument.logs)) _LogCapture(),
      ],
    );
    unawaited(_serve(queue));
  } catch (error) {
    _log.warning('telemetry could not start: $error');
  }
}

void setAttribute(String key, Object? value) =>
    ffi.telemetrySetAttribute(key: key, value: value == null ? null : _attribute(value));

String diagnostics() => ffi.telemetryDiagnostics();

void log(LogRecord record) {
  final options = _options;
  if (options == null || !options.instruments.contains(TelemetryInstrument.logs)) return;
  if (record.level < options.logLevel || record.loggerName.startsWith(_log.fullName)) return;
  final fromCore = record.loggerName.startsWith('$_ffiLoggerName.');
  // The zone the record was emitted in (stream listeners run in their own).
  final span = record.zone?[telemetrySpanKey];
  try {
    ffi.telemetryLog(
      record: ffi.LogRecord(
        severity: _severity(record.level),
        source: fromCore ? ffi.LogSource.ffi : ffi.LogSource.sdk,
        message: record.error == null ? record.message : '${record.message} ${record.error}',
        logger: fromCore ? record.loggerName.substring(_ffiLoggerName.length + 1) : record.loggerName,
        timestampNs: record.time.microsecondsSinceEpoch * 1000,
        spanId: span is TraceSpan ? span.spanId : null,
      ),
    );
  } catch (error) {
    _log.fine('log record not forwarded: $error'); // never let a log line throw
  }
}

/// The server URL the Room connects to: the core derives the Cloud ingest
/// endpoint and the auth header from it when no endpoint was configured.
void telemetrySetServer(String url, String token) => ffi.telemetrySetServer(url: url, token: token);

/// A getUserMedia / getDisplayMedia failure, in the shared capture taxonomy.
void telemetryCaptureFailed(LocalTrackOptions options, Object error) {
  final text = '$error';
  ffi.telemetryDeviceEvent(
    event: ffi.CaptureFailedDeviceEvent(
      device: options is ScreenShareCaptureOptions
          ? ffi.CaptureDevice.screenShare
          : options is VideoCaptureOptions
          ? ffi.CaptureDevice.camera
          : ffi.CaptureDevice.microphone,
      reason: text.contains('NotAllowed') || text.toLowerCase().contains('permission')
          ? ffi.CaptureFailure.permissionDenied
          : text.contains('NotFound')
          ? ffi.CaptureFailure.notFound
          : text.contains('NotReadable') || text.contains('in use')
          ? ffi.CaptureFailure.inUse
          : ffi.CaptureFailure.other,
    ),
  );
}

// MARK: - Transport

/// The host's half of the pipeline: a dumb bytes mover. The core composed URL,
/// headers and body and reads the collector's answer; Dart drains the core's
/// queue from its own thread because uniffi-dart callbacks cannot be invoked
/// from Rust threads. The loop ends when the pipeline is shut down or replaced.
Future<void> _serve(ffi.TelemetryExportQueue queue) async {
  final client = http.Client();
  try {
    while (true) {
      final pending = await queue.next();
      if (pending == null) return;
      final request = pending.request;
      try {
        final response = await client
            .post(Uri.parse(request.url), headers: request.headers, body: request.body)
            .timeout(const Duration(seconds: 10));
        queue.complete(
          id: pending.id,
          response: ffi.ExportResponse(
            status: response.statusCode,
            headers: response.headers,
            body: response.bodyBytes,
          ),
        );
      } catch (error) {
        queue.fail(
          id: pending.id,
          error: ffi.RetryableExportException(reason: '$error', retryAfterMs: null),
        );
      }
    }
  } finally {
    client.close();
  }
}

// MARK: - Instruments

/// SDK log records into the pipeline, from the configured floor up.
class _LogCapture implements ffi.TelemetryInstrument {
  StreamSubscription<LogRecord>? _records;

  @override
  void start() {
    _records = logger.onRecord.listen(log);
  }

  @override
  void stop() {
    unawaited(_records?.cancel());
    _records = null;
  }
}

/// The Rust core's log lines (its telemetry health at debug, `describe()` lines)
/// into the SDK logger, pulled from the core's queue like the exports. Process-
/// wide and started once.
bool _ffiLogsForwarded = false;

void _forwardFfiLogs() {
  if (_ffiLogsForwarded) return;
  _ffiLogsForwarded = true;
  ffi.logForwardBootstrap(level: ffi.LogForwardFilter.debug);
  unawaited(() async {
    while (true) {
      final entry = await ffi.logForwardReceive();
      if (entry == null) return;
      Logger('$_ffiLoggerName.${entry.target}').log(switch (entry.level) {
        ffi.LogForwardLevel.error => Level.SEVERE,
        ffi.LogForwardLevel.warn => Level.WARNING,
        ffi.LogForwardLevel.info => Level.INFO,
        ffi.LogForwardLevel.debug => Level.FINE,
        ffi.LogForwardLevel.trace => Level.FINER,
      }, entry.message);
    }
  }());
}

/// The device instrument: what Flutter can observe of the device, pushed as one
/// `DeviceState` (which stretches the cadence), plus audio route changes.
/// Thermal, low power and battery need platform plugins the SDK does not have;
/// memory pressure has no "relieved" signal on Flutter, so it stays at
/// `warning` once reported.
class _DeviceTelemetry with WidgetsBindingObserver implements ffi.TelemetryInstrument {
  var _appState = ffi.AppState.foreground;
  var _memory = ffi.MemoryPressure.normal;
  var _network = ffi.NetworkType.unknown;
  StreamSubscription<List<ConnectivityResult>>? _connectivity;
  StreamSubscription<List<MediaDevice>>? _devices;
  List<ffi.AudioOutput>? _outputs;

  @override
  void start() {
    WidgetsFlutterBinding.ensureInitialized().addObserver(this);
    _push();
    if (lkPlatformIsTest()) return; // no plugins under `flutter test`
    unawaited(Connectivity().checkConnectivity().then(_networkChanged).catchError((_) {}));
    _connectivity = Connectivity().onConnectivityChanged.listen(_networkChanged);
    _devices = Hardware.instance.onDeviceChange.stream.listen(_devicesChanged);
  }

  @override
  void stop() {
    WidgetsFlutterBinding.ensureInitialized().removeObserver(this);
    unawaited(_connectivity?.cancel());
    unawaited(_devices?.cancel());
  }

  void _push() => ffi.telemetrySetDeviceState(
    state: ffi.DeviceState(
      thermal: ffi.ThermalState.nominal,
      lowPowerMode: false,
      appState: _appState,
      memory: _memory,
      network: _network,
      networkExpensive: _network == ffi.NetworkType.cell,
    ),
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appState = switch (state) {
      AppLifecycleState.resumed || AppLifecycleState.inactive => ffi.AppState.foreground,
      _ => ffi.AppState.background,
    };
    _push();
  }

  @override
  void didHaveMemoryPressure() {
    _memory = ffi.MemoryPressure.warning;
    _push();
  }

  void _networkChanged(List<ConnectivityResult> result) {
    _network = result.contains(ConnectivityResult.none)
        ? ffi.NetworkType.unavailable
        : result.contains(ConnectivityResult.mobile)
        ? ffi.NetworkType.cell
        : result.contains(ConnectivityResult.wifi)
        ? ffi.NetworkType.wifi
        : result.contains(ConnectivityResult.ethernet)
        ? ffi.NetworkType.wired
        : result.contains(ConnectivityResult.bluetooth)
        ? ffi.NetworkType.bluetooth
        : result.contains(ConnectivityResult.vpn)
        ? ffi.NetworkType.vpn
        : result.contains(ConnectivityResult.other)
        ? ffi.NetworkType.other
        : ffi.NetworkType.unknown;
    _push();
  }

  /// Any device change surfaces here; only a change of the audio outputs is a
  /// route change. The platform gives no reason.
  void _devicesChanged(List<MediaDevice> devices) {
    final outputs = [for (final device in devices.where((d) => d.kind == 'audiooutput')) _output(device.label)];
    if (_outputs != null && outputs.join(',') == _outputs!.join(',')) return;
    _outputs = outputs;
    ffi.telemetryDeviceEvent(
      event: ffi.AudioRouteChangedDeviceEvent(outputs: outputs, reason: ffi.AudioRouteReason.unknown),
    );
  }

  static ffi.AudioOutput _output(String label) {
    final l = label.toLowerCase();
    if (l.contains('bluetooth')) return ffi.AudioOutput.bluetooth;
    if (l.contains('headphone') || l.contains('headset') || l.contains('wired')) return ffi.AudioOutput.wiredHeadset;
    if (l.contains('speaker')) return ffi.AudioOutput.speaker;
    if (l.contains('earpiece') || l.contains('receiver')) return ffi.AudioOutput.receiver;
    if (l.contains('hdmi')) return ffi.AudioOutput.hdmi;
    if (l.contains('usb')) return ffi.AudioOutput.usb;
    if (l.contains('airplay')) return ffi.AudioOutput.airPlay;
    if (l.contains('carplay') || l.contains('car audio')) return ffi.AudioOutput.carAudio;
    return ffi.AudioOutput.other;
  }
}

// MARK: - Room scope

/// One Room's telemetry scope: its trace, its identity, its spans and its RTC
/// samples. Created by the Room at construction; null when telemetry is off, so
/// every hook is `telemetry?.…`.
class RoomTelemetry {
  RoomTelemetry._(this._scope);

  final ffi.TelemetryScope _scope;

  static RoomTelemetry? create() {
    final scope = ffi.telemetryScope();
    return scope == null ? null : RoomTelemetry._(scope);
  }

  static bool _enabled(TelemetryInstrument instrument) => _options?.instruments.contains(instrument) ?? false;

  /// The trace id of this Room's scope (32 hex characters).
  String get traceId => _scope.traceId();

  TraceSpan? _start(ffi.SpanName name, {TraceSpan? parent}) =>
      _enabled(TelemetryInstrument.room) ? TraceSpan._(_scope.start(name: name, parent: parent?._span)) : null;

  /// The `lk.connect` span of one connect attempt.
  TraceSpan? connect() => _start(ffi.ConnectSpanName());

  /// The `lk.reconnect` span of one reconnect cycle; attempts are its checkpoints.
  TraceSpan? reconnect(ClientDisconnectReason reason, lk_models.ReconnectReason? protoReason) => _start(
    ffi.ReconnectSpanName(
      protoReason != null && protoReason != lk_models.ReconnectReason.RR_UNKNOWN
          ? ffi.telemetryReconnectReason(proto: protoReason.value)
          : switch (reason) {
              ClientDisconnectReason.signal => ffi.ReconnectReason.signalDisconnected,
              ClientDisconnectReason.peerConnectionClosed ||
              ClientDisconnectReason.peerConnectionFailed ||
              ClientDisconnectReason.negotiationFailed => ffi.ReconnectReason.transportFailed,
              _ => ffi.ReconnectReason.unknown,
            },
    ),
  );

  /// The `lk.publish` span of one publish attempt, nested under [parent] when
  /// any (the connect span for a pre-connect microphone).
  TraceSpan? publish(TrackType kind, TrackSource source, {TraceSpan? parent}) =>
      _start(ffi.PublishSpanName(), parent: parent)?..setTrack(kind, source);

  /// An app-defined span in this Room's trace.
  TraceSpan? custom(String name) => _start(ffi.CustomSpanName(name));

  /// Room and participant identity, on every record of the scope from now on.
  void setRoom(lk_models.Room room, lk_models.ParticipantInfo participant) => _scope.setRoom(
    room: ffi.RoomIdentity(
      sid: room.sid,
      name: room.name,
      participantSid: participant.sid,
      participantIdentity: participant.identity,
    ),
  );

  /// `lk.room.disconnected`, once per real session.
  void disconnected(DisconnectReason? reason) => _scope.disconnected(
    reason: switch (reason) {
      null => ffi.DisconnectReason.unknown,
      DisconnectReason.disconnected => ffi.DisconnectReason.signalClose,
      DisconnectReason.signalingConnectionFailure => ffi.DisconnectReason.joinFailure,
      DisconnectReason.reconnectAttemptsExceeded => ffi.DisconnectReason.reconnectFailed,
      _ => ffi.telemetryDisconnectReason(
        proto: lk_models.DisconnectReason.values
            .firstWhere((p) => p.toSDKType() == reason, orElse: () => lk_models.DisconnectReason.UNKNOWN_REASON)
            .value,
      ),
    },
  );

  void emitCustom(String name, Map<String, Object> attributes) => _scope.emitCustom(
    name: name,
    attributes: [for (final entry in attributes.entries) ffi.Attribute(key: entry.key, value: _attribute(entry.value))],
  );

  /// The RTC instrument: hands every track the Room publishes or subscribes to
  /// this scope (its stats timer then forwards raw `getStats()` reports) and
  /// reports the remote tracks' lifecycle for the core's `lk.subscribe` span.
  void observe(Room room) {
    if (!_enabled(TelemetryInstrument.rtc)) return;
    ffi.SpanTrack spanTrack(RemoteTrackPublication publication, RemoteParticipant participant) => ffi.SpanTrack(
      sid: publication.sid,
      kind: _kind(publication.kind),
      source: _source(publication.source),
      remoteIdentity: participant.identity,
    );
    room.events
      ..on<LocalTrackPublishedEvent>((event) => event.publication.track?.telemetry = this)
      ..on<LocalTrackUnpublishedEvent>((event) => event.publication.track?.telemetry = null)
      ..on<TrackPublishedEvent>((event) {
        // With autoSubscribe the intent exists the moment the track is known.
        if (room.connectOptions.autoSubscribe) {
          _scope.subscribeStarted(track: spanTrack(event.publication, event.participant));
        }
      })
      ..on<TrackSubscribedEvent>((event) {
        _scope.subscribed(track: spanTrack(event.publication, event.participant));
        event.track.telemetry = this;
      })
      ..on<TrackUnsubscribedEvent>((event) {
        _scope.subscribeCancelled(sid: event.publication.sid);
        event.track.telemetry = null;
      })
      ..on<TrackUnpublishedEvent>((event) => _scope.subscribeCancelled(sid: event.publication.sid))
      ..on<TrackSubscriptionExceptionEvent>((event) {
        final sid = event.sid;
        if (sid != null) _scope.subscribeFailed(sid: sid, errorType: event.reason.name);
      });
  }

  /// One raw `getStats()` report of a track; the core picks the RTP streams,
  /// resolves codec and RTT and windows the readings.
  void recordStatsReport(Track track, List<rtc.StatsReport> report, {required bool outbound}) {
    final sid = track.sid;
    if (sid == null) return;
    _scope.recordStatsReport(
      trackSid: sid,
      kind: _kind(track.kind),
      direction: outbound ? ffi.StreamDirection.outbound : ffi.StreamDirection.inbound,
      report: [for (final stat in report) ffi.RtcStat(kind: stat.type, id: stat.id, members: _members(stat.values))],
      timestampNs: null,
    );
  }
}

/// The core's span with the SDK's vocabulary on it; names, timing, attributes,
/// outcome and export live in the core.
class TraceSpan {
  TraceSpan._(this._span);

  final ffi.TelemetrySpan _span;

  /// For log correlation. Null for the half of the ids the generated Dart
  /// bindings cannot send back: `FfiConverterUInt64.read` lifts a u64 above
  /// 2^63 as a negative int, which `lower` then rejects (bindgen defect).
  int? get spanId {
    final id = _span.context()?.spanId;
    return id == null || id < 0 ? null : id;
  }

  void step(ConnectStep step) => _span.step(
    step: switch (step) {
      ConnectStep.wsOpen => ffi.WsOpenSpanStep(),
      ConnectStep.signal => ffi.SignalSpanStep(),
      ConnectStep.joinRecv => ffi.JoinRecvSpanStep(),
      ConnectStep.pcCreated => ffi.PcCreatedSpanStep(),
      ConnectStep.offerSent => ffi.OfferSentSpanStep(),
      ConnectStep.answerSent => ffi.AnswerSentSpanStep(),
      ConnectStep.engine => ffi.EngineSpanStep(),
      ConnectStep.pcConnected => ffi.PcConnectedSpanStep(),
      ConnectStep.roomConnected => ffi.RoomConnectedSpanStep(),
    },
  );

  /// `attempt N quick|full` of a reconnect span.
  void attempt(int number, {required bool full}) => _span.step(
    step: ffi.AttemptSpanStep(number: number, full: full),
  );

  /// The track a publish span is about; call again once the sid is known.
  void setTrack(TrackType kind, TrackSource source, {String? sid}) => _span.setTrack(
    track: ffi.SpanTrack(sid: sid, kind: _kind(kind), source: _source(source)),
  );

  void end() => _span.end(outcome: ffi.SpanOutcome.ok, error: null);

  /// End on an error: its type name becomes `error.type`.
  void fail(Object error) => _span.fail(error: error is String ? error : '${error.runtimeType}');

  void cancel() => _span.cancel();

  /// `lk.connect: ws_open +1.49s, …, total 1.83s, ok`
  String describe() => _span.describe();
}

// MARK: - Vocabulary

ffi.Severity _severity(Level level) => level >= Level.SEVERE
    ? ffi.Severity.error
    : level >= Level.WARNING
    ? ffi.Severity.warn
    : level >= Level.INFO
    ? ffi.Severity.info
    : ffi.Severity.debug;

ffi.Instrument _instrument(TelemetryInstrument instrument) => switch (instrument) {
  TelemetryInstrument.room => ffi.Instrument.room,
  TelemetryInstrument.rtc => ffi.Instrument.rtc,
  TelemetryInstrument.logs => ffi.Instrument.logs,
  TelemetryInstrument.device => ffi.Instrument.device,
};

ffi.TrackKind _kind(TrackType kind) => kind == TrackType.AUDIO ? ffi.TrackKind.audio : ffi.TrackKind.video;

ffi.TrackSource _source(TrackSource source) => switch (source) {
  TrackSource.camera => ffi.TrackSource.camera,
  TrackSource.microphone => ffi.TrackSource.microphone,
  TrackSource.screenShareVideo => ffi.TrackSource.screenShare,
  TrackSource.screenShareAudio => ffi.TrackSource.screenShareAudio,
  TrackSource.unknown => ffi.TrackSource.unknown,
};

ffi.AttributeValue _attribute(Object value) {
  if (value is bool) return ffi.BoolAttributeValue(value);
  if (value is int) return ffi.IntAttributeValue(value);
  if (value is num) return ffi.DoubleAttributeValue(value.toDouble());
  if (value is String) return ffi.StrAttributeValue(value);
  return ffi.StrAttributeValue('$value');
}

/// A stats entry's members as the core takes them; nested maps flattened with a
/// dot (`qualityLimitationDurations.cpu`), sequences dropped.
Map<String, ffi.AttributeValue> _members(Map<dynamic, dynamic> values, [String prefix = '']) {
  final members = <String, ffi.AttributeValue>{};
  values.forEach((key, value) {
    final name = prefix.isEmpty ? '$key' : '$prefix.$key';
    if (value is Map) {
      members.addAll(_members(value, name));
    } else if (value is bool || value is num || value is String) {
      members[name] = _attribute(value as Object);
    }
  });
  return members;
}
