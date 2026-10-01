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
import 'dart:io';

import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../core/room.dart';
import '../events.dart';
import '../extensions.dart';
import '../hardware/hardware.dart';
import '../internal/events.dart';
import '../livekit.dart';
import '../logger.dart';
import '../participant/participant.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../publication/remote.dart';
import '../publication/track_publication.dart';
import '../support/platform.dart';
import '../support/sdk_logger.dart';
import '../track/local/local.dart';
import '../track/options.dart';
import '../types/internal.dart';
import '../types/other.dart';
import '../uniffi/uniffi_io.dart' as ffi;
import 'telemetry.dart';

// MARK: - Pipeline

bool _installed = false;

/// Opted out: Dart collects nothing more, whatever Room is still connected.
bool _disabled = false;

/// Telemetry never fails the SDK or the app: a core error (a Rust panic surfaces as an exception)
/// is logged and dropped, never thrown into a connect, a publish, a teardown or a log call.
T? _quiet<T>(T Function() body) {
  try {
    return body();
  } catch (error) {
    logger.fine('telemetry: $error');
    return null;
  }
}

/// Stops serving the installed pipeline's export queue.
void Function()? _stopServing;

/// Started and stopped from Dart, never handed to the core: a callback the core holds would
/// point into this isolate after it is gone (hot restart, a recreated engine).
final _instruments = [_DeviceTelemetry(), _LogCapture()];

/// Where a new Room's session comes from: a test can stand in a core that fails.
@visibleForTesting
ffi.TelemetryScope? Function() telemetryScopeFactory = ffi.telemetryScope;

RoomTelemetry? createRoomTelemetry(Room room) {
  try {
    if (!_installed) {
      _installed = true;
      _install();
    }
    final scope = telemetryScopeFactory();
    return scope == null ? null : _RoomTelemetry(room, scope);
  } catch (error) {
    // Fail-open: the app runs without telemetry rather than not at all (e.g. no native library).
    logger.fine('telemetry unavailable: $error');
    return null;
  }
}

/// Installed synchronously with the first Room, so a Room never misses its session. Every tuning
/// value is the core's default.
void _install() {
  // The core creates the cache directory but not its parents (`~/.cache` may not exist yet).
  var storageDir = storageDirectory;
  try {
    if (storageDir != null) Directory(storageDir).parent.createSync(recursive: true);
  } on FileSystemException catch (_) {
    storageDir = null; // batches in memory only
  }
  final queue = ffi.telemetryConfigurePulled(
    config: ffi.TelemetryConfig(
      sdk: ffi.TelemetryResource(
        sdk: ffi.Sdk.flutter,
        sdkVersion: LiveKitClient.version,
        osName: Platform.operatingSystem,
        osVersion: Platform.operatingSystemVersion,
      ),
      storageDir: storageDir,
    ),
    instruments: const [],
  );
  if (ffi.telemetryStats() == null) return; // refused: this process opted out
  _stopServing = _serve(queue);
  for (final instrument in _instruments) {
    instrument.start();
  }
}

/// The app's own temporary directory on mobile (purgeable, never backed up); on desktop a per-user
/// directory named after the app: the user's cache directory on Linux, where the temporary one is
/// shared by every user. Null (batches in memory only) on Linux without an absolute cache home.
@visibleForTesting
final String? storageDirectory = () {
  final base = Platform.isLinux ? _linuxCacheHome() : Directory.systemTemp.path;
  return base == null
      ? null
      : p.join(base, 'livekit-telemetry-${p.basenameWithoutExtension(Platform.resolvedExecutable)}');
}();

/// `$XDG_CACHE_HOME`, else `$HOME/.cache`; relative or empty values are ignored (XDG Base Directory).
String? _linuxCacheHome() {
  final xdg = Platform.environment['XDG_CACHE_HOME'];
  if (xdg != null && p.isAbsolute(xdg)) return xdg;
  final home = Platform.environment['HOME'];
  return home != null && p.isAbsolute(home) ? p.join(home, '.cache') : null;
}

Future<void> disableTelemetry() async {
  // Nothing installs after an opt-out; before the first Room, the cache a previous launch left is
  // this SDK's to delete (the core purges only a pipeline it installed).
  final installed = _installed;
  _installed = true;
  _stopCapture();
  // In effect now; what was not sent is purged in the background. Not awaited through
  // `telemetryFlush`: a pending Rust future would call into this isolate even after it is gone.
  _quiet(ffi.telemetryDisable);
  final storageDir = storageDirectory;
  if (installed || storageDir == null) return;
  try {
    await Directory(storageDir).delete(recursive: true);
  } on FileSystemException catch (_) {} // nothing cached
}

/// Stops everything this isolate collects and serves.
void _stopCapture() {
  _disabled = true;
  // Each step on its own: one that throws never skips the rest.
  for (final instrument in _instruments) {
    _quiet(instrument.stop);
  }
  for (final session in _inCall) {
    session._stats?.cancel();
  }
  final stopServing = _stopServing;
  _stopServing = null;
  _quiet(() => stopServing?.call());
}

/// Opted out, here or in any other isolate of the process (the core keeps the process-wide flag);
/// a core that cannot answer counts as opted out. Learning it from the core stops this isolate's
/// capture too. Synchronous: callers check it right before a read or a submission.
bool _optedOut() {
  if (_disabled) return true;
  if (!(_quiet(ffi.telemetryIsDisabled) ?? true)) return false;
  _stopCapture();
  return true;
}

void captureFailed(LocalTrackOptions options, Object error) {
  final text = '$error';
  try {
    ffi.telemetryDeviceEvent(
      event: ffi.CaptureFailedDeviceEvent(
        device: options is ScreenShareCaptureOptions
            ? ffi.CaptureDevice.screenShare
            : options is VideoCaptureOptions
            ? ffi.CaptureDevice.camera
            : ffi.CaptureDevice.microphone,
        // getUserMedia error names (DOMException on web, the plugin's messages natively).
        reason: text.contains('NotAllowed') || text.toLowerCase().contains('permission')
            ? ffi.CaptureFailure.permissionDenied
            : text.contains('NotFound')
            ? ffi.CaptureFailure.notFound
            : text.contains('NotReadable') || text.contains('in use')
            ? ffi.CaptureFailure.inUse
            : ffi.CaptureFailure.other,
      ),
    );
  } catch (_) {} // no native library: nothing to report to
}

// MARK: - Transport

/// Serves the core's pull queue by polling it: uniffi-dart callbacks cannot run on the core's
/// threads, and a pending Rust future would hold a continuation into this isolate that aborts the
/// VM once the isolate is gone (hot restart, a recreated engine). In the root zone, so no caller's
/// zone (a test's fake clock, a Room's) owns the timer. Every second while a Room is in a call or
/// requests keep coming, else every 5 s: an export nobody picks up within the core's 10 s export
/// timeout is withdrawn and retried later.
// ponytail: polling; a Dart port the core signals would remove the wake-ups.
void Function() _serve(ffi.TelemetryExportQueue queue) {
  final client = http.Client();
  Timer? timer;
  var stopped = false;
  Future<void> poll() async {
    try {
      for (var pending = queue.tryNext(); pending != null; pending = queue.tryNext()) {
        _pollFast();
        try {
          queue.complete(id: pending.id, response: await sendExport(client, pending.request));
        } on FormatException catch (error) {
          queue.fail(id: pending.id, error: ffi.RejectedExportException('invalid url: $error'));
        } catch (error) {
          queue.fail(
            id: pending.id,
            error: ffi.RetryableExportException(reason: '$error', retryAfterMs: null),
          );
        }
      }
    } catch (error) {
      logger.fine('telemetry export not served: $error'); // the next tick tries again
    }
    if (stopped) return;
    final fast = _inCall.isNotEmpty || _clock.elapsed < _fastUntil;
    timer = Timer(Duration(seconds: fast ? 1 : 5), poll);
  }

  timer = Zone.root.run(() => Timer(Duration.zero, poll));
  return () {
    stopped = true;
    timer?.cancel();
    _quiet(queue.finish);
    _quiet(client.close);
  };
}

/// Rooms in a call: their exports are polled for every second.
final _inCall = <_RoomTelemetry>{};
final _clock = Stopwatch()..start(); // monotonic: wall-clock changes cannot stretch the fast window
var _fastUntil = Duration.zero;

/// Poll every second for a while: a call ended, or requests are coming.
void _pollFast() => _fastUntil = _clock.elapsed + const Duration(seconds: 15);

/// The bound on one request, the core's export timeout.
@visibleForTesting
Duration exportTimeout = const Duration(seconds: 10);

/// One request: status, headers and body come back untouched and the core decides what they
/// mean; only a missing answer throws. Never follows a redirect — the request carries the
/// participant token — so a 3xx is the answer.
@visibleForTesting
Future<ffi.ExportResponse> sendExport(http.Client client, ffi.ExportRequest request) async {
  // Aborting closes the socket: a collector that accepts and never answers cannot hold the queue.
  final post = http.AbortableRequest('POST', Uri.parse(request.url), abortTrigger: Future.delayed(exportTimeout))
    ..followRedirects = false
    ..headers.addAll(request.headers)
    ..bodyBytes = request.body;
  final response = await http.Response.fromStream(await client.send(post));
  return ffi.ExportResponse(status: response.statusCode, headers: response.headers, body: response.bodyBytes);
}

// MARK: - Instruments

/// Feeds the pipeline while it runs.
abstract interface class _Instrument {
  void start();
  void stop();
}

/// SDK warnings and errors, next to (never instead of) the app's own log handling: filed under
/// the ambient span, else the Room whose handler logged them, else the process.
/// The Rust core copies its own warnings itself once a log forwarder is installed (the SDK installs
/// none); forwarded Rust entries must never be fed here, or they would count twice.
class _LogCapture implements _Instrument {
  StreamSubscription<LogRecord>? _records;

  // What the logger emits, from its records; what its level filters out (`disableLogging()`, a
  // level above WARNING), from the SDK logger: the console level never decides what telemetry gets.
  @override
  void start() {
    // `onRecord` is the root logger's stream unless logging is hierarchical: keep the SDK's own.
    _records ??= logger.onRecord.where((r) => r.loggerName == logger.name && r.level >= Level.WARNING).listen(_log);
    sdkFilteredWarningCapture = _log;
  }

  @override
  void stop() {
    sdkFilteredWarningCapture = null;
    unawaited(_records?.cancel());
    _records = null;
  }

  static void _log(LogRecord record) {
    // Errors are dropped silently, never logged: this runs inside a log call or the logger's own
    // delivery, which a record logged from here would re-enter.
    try {
      _capture(record);
    } catch (_) {}
  }

  static void _capture(LogRecord record) {
    // A zone outlives its span (listeners and timers created inside keep it): an ended span
    // files the record under its Room instead.
    final ambient = record.zone?[telemetrySpanKey];
    final span = ambient is _TraceSpan && ambient._span?.isEnded() == false ? ambient : null; // no _quiet here
    final room = record.zone?[telemetryRoomKey] ?? (ambient is _TraceSpan ? ambient._session?.target : null);
    final lowered = ffi.LogRecord(
      severity: record.level >= Level.SEVERE ? ffi.Severity.error : ffi.Severity.warn,
      source: ffi.LogSource.sdk,
      body: record.error == null ? record.message : '${record.message} ${record.error}',
      logger: record.loggerName,
      timestampNs: record.time.microsecondsSinceEpoch * 1000,
      spanId: span?._span?.context()?.spanId,
    );
    if (span == null && room is _RoomTelemetry) {
      room._scope.log(record: lowered);
    } else {
      ffi.telemetryLog(record: lowered);
    }
  }
}

/// The device instrument: app lifecycle, memory pressure and network type as one `DeviceState`,
/// audio output changes as events. Every OS callback feeds one change stream, applied in order.
/// Thermal state, low-power mode, battery and audio interruptions need plugins the SDK does not
/// have: reported as unknown.
class _DeviceTelemetry with WidgetsBindingObserver implements _Instrument {
  var _appState = ffi.AppState.foreground;
  var _memory = ffi.MemoryPressure.normal;
  var _network = ffi.NetworkType.unknown;
  List<ffi.AudioOutput>? _outputs;
  StreamController<void Function()>? _changes;
  final _subscriptions = <StreamSubscription<Object?>>[];
  Timer? _memoryRelief;

  @override
  void start() {
    final changes = _changes = StreamController(sync: true);
    changes.stream.listen(
      (apply) => _quiet(() {
        apply();
        ffi.telemetrySetDeviceState(
          state: ffi.DeviceState(
            thermal: ffi.ThermalState.unknown, // no source without a platform plugin; low power too
            appState: _appState,
            memory: _memory,
            network: _network,
            networkExpensive: _network == ffi.NetworkType.cell,
          ),
        );
      }),
    );
    try {
      final state = WidgetsBinding.instance.lifecycleState; // already in the background, say
      if (state != null) _appState = _appStateOf(state);
    } catch (_) {} // no binding (plain Dart tests): foreground
    changes.add(() {}); // the initial state
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {} // no binding (plain Dart tests): no lifecycle to observe
    if (lkPlatformIsTest()) return; // no plugins under `flutter test`
    unawaited(Connectivity().checkConnectivity().then(_networkChanged, onError: (_) {}));
    _subscriptions
      ..add(Connectivity().onConnectivityChanged.listen(_networkChanged))
      ..add(Hardware.instance.onDeviceChange.stream.listen(_devicesChanged));
  }

  @override
  void stop() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    _memoryRelief?.cancel();
    unawaited(_changes?.close());
    _changes = null;
  }

  void _change(void Function() apply) {
    final changes = _changes;
    if (changes != null && !changes.isClosed) changes.add(apply);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _change(() => _appState = _appStateOf(state));

  static ffi.AppState _appStateOf(AppLifecycleState state) =>
      state == AppLifecycleState.resumed || state == AppLifecycleState.inactive
      ? ffi.AppState.foreground
      : ffi.AppState.background;

  /// The OS warns but never says the pressure is over: back to normal after a quiet minute.
  // ponytail: fixed relief delay, tune if the core's cadence stretching needs a better estimate.
  @override
  void didHaveMemoryPressure() {
    _change(() => _memory = ffi.MemoryPressure.warning);
    _memoryRelief?.cancel();
    _memoryRelief = Timer(const Duration(minutes: 1), () => _change(() => _memory = ffi.MemoryPressure.normal));
  }

  void _networkChanged(List<ConnectivityResult> result) => _change(
    () => _network = result.contains(ConnectivityResult.none)
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
        : ffi.NetworkType.unknown,
  );

  /// Any device change surfaces here; only a change of the audio outputs is a route change. The
  /// platform gives no reason.
  void _devicesChanged(List<MediaDevice> devices) => _change(() {
    final outputs = [for (final device in devices.where((d) => d.kind == 'audiooutput')) _output(device.label)];
    if (_outputs != null && outputs.join(',') == _outputs!.join(',')) return;
    _outputs = outputs;
    ffi.telemetryDeviceEvent(
      event: ffi.AudioRouteChangedDeviceEvent(outputs: outputs, reason: ffi.AudioRouteReason.unknown),
    );
  });

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

// MARK: - Room session

/// One Room's session, created with the Room. Also its RTC instrument: reports the tracks'
/// lifecycle, from which the core runs `lk.subscribe` (intent → first media), and hands the core
/// one raw `getStats()` report per peer connection as often as it asks.
class _RoomTelemetry implements RoomTelemetry {
  _RoomTelemetry(this._room, this._scope) {
    // A refreshed token (server refresh, room move): uploads keep this Room's latest. Cancelled on
    // dispose: the SignalClient can outlive the Room (injected, or held by its connectivity
    // subscription).
    final signal = _room.engine.signalClient.events;
    final cancelTokenListener = signal.on<SignalTokenUpdatedEvent>((event) {
      if (_url != null) _quiet(() => _scope.setServer(url: _url!, token: event.token));
    });
    // A late or revised room sid / name.
    final cancelRoomListener = signal.on<SignalRoomUpdateEvent>((event) => _setRoom(event.room, null));
    // `dispose()` without `disconnect()` emits neither closing nor disconnected: the call ends here.
    _room.onDispose(() async {
      await cancelTokenListener();
      await cancelRoomListener();
      _stats?.cancel();
      _connect?.cancel();
      _connect = null;
      if (_inCall.remove(this)) _quiet(() => _scope.disconnected(reason: ffi.DisconnectReason.clientInitiated));
    });
    _room.engine.events
      ..on<EngineJoinResponseEvent>((event) => _setRoom(event.response.room, event.response.participant))
      ..on<EngineRoomMovedEvent>((event) => _setRoom(event.response.room, event.response.participant))
      // The app's `disconnect()` while connecting cancels the attempt; a server-initiated close
      // fails it (through the error the connect then throws).
      ..on<EngineClosingEvent>((event) {
        // Out of the call even when `disconnect()` times out and no RoomDisconnectedEvent follows.
        _inCall.remove(this);
        if (event.reason != DisconnectReason.clientInitiated) return;
        _connect?.cancel();
        _connect = null;
      });
    _room.events
      ..on<RoomConnectedEvent>((_) {
        _inCall.add(this);
        step(ConnectStep.roomConnected);
        // Tracks published before this Room joined: with autoSubscribe the intent is the join.
        if (_room.connectOptions.autoSubscribe) {
          for (final participant in _room.remoteParticipants.values.toList()) {
            for (final publication in participant.trackPublications.values.toList()) {
              if (publication.track == null) subscribeStarted(publication);
            }
          }
        }
        _poll();
      })
      ..on<RoomDisconnectedEvent>((event) {
        _stats?.cancel();
        _inCall.remove(this);
        _pollFast(); // the session's last records ship now
        _quiet(() => _scope.disconnected(reason: _disconnectReason(event.reason)));
      })
      // A new outbound track gets its first reading soon (the core asks for it), not a whole
      // poll interval later.
      ..on<LocalTrackPublishedEvent>((_) => _poll())
      ..on<LocalTrackUnpublishedEvent>((event) => _quiet(() => _scope.trackEnded(sid: event.publication.sid)))
      ..on<TrackPublishedEvent>((event) {
        // With autoSubscribe the intent exists the moment the track is known.
        if (_room.connectOptions.autoSubscribe) subscribeStarted(event.publication);
      })
      ..on<TrackSubscribedEvent>((event) {
        _quiet(() => _scope.subscribed(track: _spanTrack(event.publication)));
        _poll(); // the core polls every second until first media
      })
      ..on<TrackUnsubscribedEvent>((event) => _quiet(() => _scope.trackEnded(sid: event.publication.sid)))
      ..on<TrackUnpublishedEvent>((event) => _quiet(() => _scope.trackEnded(sid: event.publication.sid)))
      ..on<TrackSubscriptionExceptionEvent>((event) {
        if (event.sid != null) _quiet(() => _scope.subscribeFailed(sid: event.sid!, errorType: event.reason.name));
      });
  }

  final Room _room;
  final ffi.TelemetryScope _scope;

  /// The session's room and participant; empty values (a room update without a sid) keep what
  /// the session had.
  void _setRoom(lk_models.Room room, lk_models.ParticipantInfo? participant) {
    String? pick(String? value, String? old) => value == null || value.isEmpty ? old : value;
    final was = _identity;
    final now = _identity = (
      sid: pick(room.sid, was?.sid),
      name: pick(room.name, was?.name),
      participantSid: pick(participant?.sid, was?.participantSid),
      participantIdentity: pick(participant?.identity, was?.participantIdentity),
    );
    if (now == was) return;
    _quiet(
      () => _scope.setRoom(
        room: ffi.RoomIdentity(
          sid: now.sid,
          name: now.name,
          participantSid: now.participantSid,
          participantIdentity: now.participantIdentity,
        ),
      ),
    );
  }

  ({String? sid, String? name, String? participantSid, String? participantIdentity})? _identity;
  String? _url;
  Timer? _stats;

  // The `lk.connect` span ends once both halves are done: the engine's primary peer connection
  // connected (`pc_connected`) and the join response was applied (`room_connected`); they arrive
  // in either order.
  _TraceSpan? _connect;
  final _halves = <ConnectStep>{};

  @override
  Future<void> connect(String url, String token, Future<void> Function() body) async {
    _url = url;
    _quiet(() => _scope.setServer(url: url, token: token));
    final span = _connect = _start(ffi.ConnectSpanName());
    _halves.clear();
    try {
      await span.run(body);
    } catch (error) {
      span?.fail(error);
      if (identical(_connect, span)) _connect = null;
      rethrow;
    }
  }

  @override
  void step(ConnectStep step) {
    final span = _connect;
    if (span == null) return;
    _quiet(() => span._span?.step(step: _step(step)));
    if (step == ConnectStep.pcConnected || step == ConnectStep.roomConnected) _halves.add(step);
    if (_halves.length < 2) return;
    span.end();
    _connect = null;
  }

  static ffi.SpanStep _step(ConnectStep step) => switch (step) {
    ConnectStep.wsOpen => ffi.WsOpenSpanStep(),
    ConnectStep.signal => ffi.SignalSpanStep(),
    ConnectStep.joinRecv => ffi.JoinRecvSpanStep(),
    ConnectStep.pcCreated => ffi.PcCreatedSpanStep(),
    ConnectStep.offerSent => ffi.OfferSentSpanStep(),
    ConnectStep.answerSent => ffi.AnswerSentSpanStep(),
    ConnectStep.engine => ffi.EngineSpanStep(),
    ConnectStep.pcConnected => ffi.PcConnectedSpanStep(),
    ConnectStep.roomConnected => ffi.RoomConnectedSpanStep(),
  };

  @override
  TraceSpan? reconnect(ClientDisconnectReason reason, lk_models.ReconnectReason? protoReason) => _quiet<TraceSpan?>(
    () => _start(
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
    ),
  );

  @override
  Future<T> publish<T extends TrackPublication>(LocalTrack track, Future<T> Function() body) async {
    final ambient = Zone.current[telemetrySpanKey];
    final span = _start(ffi.PublishSpanName(), parent: ambient is _TraceSpan && ambient._live ? ambient : _connect);
    span?._setTrack(ffi.SpanTrack(kind: _kind(track.kind), source: _source(track.source)));
    try {
      final publication = await span.run(body);
      // The sid lets the core poll fast until this track's first outbound reading.
      span?._setTrack(ffi.SpanTrack(sid: publication.sid, kind: _kind(track.kind), source: _source(track.source)));
      span?.end();
      return publication;
    } catch (error) {
      span?.fail(error);
      rethrow;
    }
  }

  @override
  void subscribeStarted(RemoteTrackPublication publication) {
    _quiet(() => _scope.subscribeStarted(track: _spanTrack(publication)));
    _poll(); // the core polls every second until first media
  }

  @override
  void emitCustom(String name, Map<String, String> attributes) =>
      _quiet(() => _scope.emitCustom(name: name, attributes: attributes));

  @override
  void setAttribute(String key, String? value) => _quiet(() => _scope.setAttribute(key: key, value: value));

  _TraceSpan? _start(ffi.SpanName name, {_TraceSpan? parent}) =>
      _quiet(() => _TraceSpan(this, _scope.start(name: name, parent: parent?._span)));

  ffi.SpanTrack _spanTrack(RemoteTrackPublication publication) => ffi.SpanTrack(
    sid: publication.sid,
    kind: _kind(publication.kind),
    source: _source(publication.source),
    remoteIdentity: publication.participant.identity,
  );

  /// Arms the stats timer at the core's current interval, or brings an armed one forward: a track
  /// signal never postpones a poll, and a read in flight re-arms when it is done (one poll at a
  /// time). The loop ends with the session.
  void _poll() {
    if (_reading) return;
    final interval = _disabled ? null : _quiet(_scope.statsPollIntervalMs);
    if (interval == null) return;
    final due = _clock.elapsed + Duration(milliseconds: interval);
    if (_stats?.isActive ?? false) {
      if (_due <= due) return;
      _stats!.cancel();
    }
    _due = due;
    _stats = Timer(due - _clock.elapsed, () async {
      if (_disabled || _room.connectionState == ConnectionState.disconnected) return;
      _reading = true;
      try {
        await _recordPeerStats();
      } finally {
        _reading = false;
      }
      if (_room.connectionState != ConnectionState.disconnected) _poll();
    });
  }

  Duration _due = Duration.zero;
  bool _reading = false;

  /// One `getStats()` report per peer connection, with every track this Room sends or receives.
  Future<void> _recordPeerStats() async {
    final tracks = <String, String>{
      for (final participant in <Participant?>[_room.localParticipant, ..._room.remoteParticipants.values])
        for (final publication in participant?.trackPublications.values ?? <TrackPublication>[])
          ?publication.track?.mediaStreamTrack.id: publication.sid,
    };
    for (final transport in [_room.engine.publisher, _room.engine.subscriber]) {
      if (transport == null) continue;
      if (_optedOut()) return; // every request is gated: the previous one may have failed meanwhile
      try {
        // Bounded: a peer connection that never answers holds no poll (a late answer is dropped).
        final report = await transport.pc.getStats().timeout(const Duration(seconds: 5));
        if (_optedOut()) return; // opted out while reading
        _scope.recordPeerStats(
          report: [
            for (final stat in report) ffi.RtcStat(kind: stat.type, id: stat.id, members: _members(stat.values)),
          ],
          tracks: tracks,
          timestampNs: null,
        );
      } catch (error) {
        logger.fine('telemetry stats not read: $error'); // a peer connection closing meanwhile
      }
    }
  }
}

/// The core's span; names, timing, attributes, outcome and export live in the core.
class _TraceSpan implements TraceSpan {
  _TraceSpan(_RoomTelemetry session, ffi.TelemetrySpan span) : _session = WeakReference(session), _span = span {
    liveSpanHandles++;
  }

  /// Weak, and both released when the span ends: a zone (and every long-lived listener created in
  /// it, like the signal client's connectivity subscription) can outlive the span and its Room,
  /// but then holds only this empty object.
  WeakReference<_RoomTelemetry>? _session;
  ffi.TelemetrySpan? _span;

  /// Not ended yet.
  bool get _live => _span != null && (_quiet(() => !_span!.isEnded()) ?? false);

  void _setTrack(ffi.SpanTrack track) => _quiet(() => _span?.setTrack(track: track));

  /// Ends the core's span with [finish] and lets go of its handle.
  void _finish(void Function(ffi.TelemetrySpan span) finish) {
    final span = _span;
    if (span == null) return;
    _span = _session = null;
    liveSpanHandles--;
    _quiet(() => finish(span));
    _quiet(span.dispose);
  }

  @override
  void attempt(int number, {required bool full}) => _quiet(
    () => _span?.step(
      step: ffi.AttemptSpanStep(number: number, full: full),
    ),
  );

  @override
  void end() => _finish((span) => span.end(outcome: ffi.SpanOutcome.ok, error: null));

  @override
  void fail(Object error) => _finish((span) => span.fail(error: error is String ? error : '${error.runtimeType}'));

  @override
  void cancel() => _finish((span) => span.cancel());
}

/// Spans whose native handle this isolate still holds (open ones).
@visibleForTesting
int liveSpanHandles = 0;

// MARK: - Vocabulary

ffi.DisconnectReason _disconnectReason(DisconnectReason? reason) => switch (reason) {
  null => ffi.DisconnectReason.unknown,
  DisconnectReason.disconnected => ffi.DisconnectReason.signalClose,
  DisconnectReason.signalingConnectionFailure => ffi.DisconnectReason.joinFailure,
  DisconnectReason.reconnectAttemptsExceeded => ffi.DisconnectReason.reconnectFailed,
  _ => ffi.telemetryDisconnectReason(
    proto: lk_models.DisconnectReason.values
        .firstWhere((p) => p.toSDKType() == reason, orElse: () => lk_models.DisconnectReason.UNKNOWN_REASON)
        .value,
  ),
};

ffi.TrackKind _kind(TrackType kind) => kind == TrackType.AUDIO ? ffi.TrackKind.audio : ffi.TrackKind.video;

ffi.TrackSource _source(TrackSource source) => switch (source) {
  TrackSource.camera => ffi.TrackSource.camera,
  TrackSource.microphone => ffi.TrackSource.microphone,
  TrackSource.screenShareVideo => ffi.TrackSource.screenShare,
  TrackSource.screenShareAudio => ffi.TrackSource.screenShareAudio,
  TrackSource.unknown => ffi.TrackSource.unknown,
};

/// A stats entry's members as the core takes them; nested maps flattened with a dot
/// (`qualityLimitationDurations.cpu`), sequences dropped. No member names are known here.
Map<String, ffi.AttributeValue> _members(Map<dynamic, dynamic> values, [String prefix = '']) {
  final members = <String, ffi.AttributeValue>{};
  values.forEach((key, value) {
    final name = prefix.isEmpty ? '$key' : '$prefix.$key';
    if (value is Map) {
      members.addAll(_members(value, name));
    } else if (value is bool) {
      members[name] = ffi.BoolAttributeValue(value);
    } else if (value is int) {
      members[name] = ffi.IntAttributeValue(value);
    } else if (value is num) {
      members[name] = ffi.DoubleAttributeValue(value.toDouble());
    } else if (value is String) {
      members[name] = ffi.StrAttributeValue(value);
    }
  });
  return members;
}
