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

import 'package:meta/meta.dart';

import '../../core/engine.dart';
import '../../core/room.dart';
import '../../core/signal_client.dart';
import '../../events.dart';
import '../../exceptions.dart';
import '../../internal/events.dart';
import '../../managers/event.dart';
import '../../options.dart';
import '../../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../../support/disposable.dart';
import '../../support/websocket.dart';
import '../../types/internal.dart';
import '../../types/other.dart';
import '../events.dart';

/// Status of a [Checker].
enum CheckStatus {
  idle,
  running,
  skipped,
  success,
  failed,
}

/// Severity of a single [CheckLog] entry.
enum CheckLogLevel {
  info,
  warning,
  error,
}

/// Connection protocols compared by the connection protocol check.
enum CheckProtocol {
  udp,
  tcp,
}

/// A single log line produced while a [Checker] runs.
class CheckLog {
  const CheckLog({
    required this.level,
    required this.message,
  });

  final CheckLogLevel level;
  final String message;

  @override
  String toString() => '[${level.name}] $message';
}

/// A snapshot of a [Checker]'s state.
class CheckInfo {
  const CheckInfo({
    required this.name,
    required this.description,
    required this.status,
    required this.logs,
    this.data,
  });

  /// Name of the check, defaults to the [Checker]'s class name.
  final String name;

  /// Human readable description of what the check verifies.
  final String description;

  final CheckStatus status;

  final List<CheckLog> logs;

  /// Check specific data, e.g. `ProtocolStats` for the connection protocol
  /// check or `RegionStats` for the cloud region check.
  final Object? data;

  @override
  String toString() => '$runtimeType(name: $name, status: ${status.name}, logs: ${logs.length})';
}

/// Options shared by all [Checker]s of a `ConnectionCheck` run.
class CheckerOptions {
  CheckerOptions({
    this.errorsAsWarnings = false,
    this.roomOptions,
    this.connectOptions,
    this.protocol,
  });

  /// When true, errors are logged as warnings and don't fail the check.
  bool errorsAsWarnings;

  /// Options for the [Room] instances created by each check.
  RoomOptions? roomOptions;

  /// Options used when connecting to the LiveKit server.
  ConnectOptions? connectOptions;

  /// Preferred connection protocol. Set by the connection protocol check so
  /// that subsequent checks (e.g. cloud region) use the better protocol.
  CheckProtocol? protocol;
}

/// Exception thrown when a check cannot complete.
class CheckException implements Exception {
  const CheckException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Base class for a single connection diagnostic, a Dart port of the
/// `Checker` class from client-sdk-js' `ConnectionCheck` utility.
///
/// Subclasses implement [perform] and report progress through
/// [appendMessage], [appendWarning] and [appendError]. Any log entry with
/// [CheckLogLevel.error] (including uncaught exceptions thrown from
/// [perform]) marks the check as [CheckStatus.failed].
///
/// A [Checker] is single-use: [run] may only be called once, and the checker
/// should be disposed with [dispose] afterwards.
abstract class Checker extends Disposable with EventsEmittable<CheckerEvent> {
  Checker(
    this.url,
    this.token, {
    CheckerOptions? options,
    Room? room,
  })  : options = options ?? CheckerOptions(),
        connectOptions = options?.connectOptions,
        _ownsRoom = room == null,
        room = room ?? Room(roomOptions: options?.roomOptions ?? const RoomOptions()) {
    onDispose(() async {
      await events.dispose();
      if (_ownsRoom) {
        await this.room.dispose();
      }
    });
  }

  /// URL of the LiveKit server to run the check against.
  ///
  /// Not final because some checks (e.g. TURN) resolve a region specific URL.
  String url;

  /// Access token used for the check.
  final String token;

  /// The room instance used by this check.
  final Room room;

  /// Whether [room] was created (and is therefore disposed) by this checker.
  final bool _ownsRoom;

  final CheckerOptions options;

  ConnectOptions? connectOptions;

  CheckStatus status = CheckStatus.idle;

  final List<CheckLog> logs = [];

  /// WebSocket connector used by [signalJoin], exposed for testing.
  @visibleForTesting
  WebSocketConnector? wsConnector;

  /// Name of this check, defaults to the class name.
  String get name => '$runtimeType';

  /// Human readable description of what this check verifies.
  String get description;

  /// Check specific data included in [getInfo], null by default.
  Object? get data => null;

  /// The actual check logic, implemented by subclasses.
  @protected
  Future<void> perform();

  @protected
  Engine get engine => room.engine;

  @protected
  NetworkOptions get networkOptions => options.roomOptions?.networkOptions ?? const NetworkOptions();

  /// Runs the check once and returns the final [CheckInfo].
  Future<CheckInfo> run() async {
    if (status != CheckStatus.idle) {
      throw StateError('check is running already');
    }
    setStatus(CheckStatus.running);

    try {
      await perform();
    } catch (err) {
      if (options.errorsAsWarnings) {
        appendWarning(messageFor(err));
      } else {
        appendError(messageFor(err));
      }
    }

    try {
      await disconnect();
    } catch (err) {
      // don't let a failing disconnect (e.g. after a connect that failed
      // mid-handshake) prevent the check from reporting its result
      appendWarning('failed to disconnect: ${messageFor(err)}');
    }

    // sleep for a bit to ensure disconnect
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (status != CheckStatus.skipped) {
      setStatus(isSuccess() ? CheckStatus.success : CheckStatus.failed);
    }

    return getInfo();
  }

  @protected
  bool isSuccess() => !logs.any((log) => log.level == CheckLogLevel.error);

  /// Connects [room] to [url] (or the checker's default URL) unless it is
  /// already connected.
  @protected
  Future<Room> connect([String? url]) async {
    if (room.connectionState == ConnectionState.connected) {
      return room;
    }
    await room.connect(url ?? this.url, token, connectOptions: connectOptions);
    return room;
  }

  @protected
  Future<void> disconnect() async {
    if (room.connectionState != ConnectionState.disconnected) {
      await room.disconnect();
      // wait for it to go through
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Marks this check as skipped (e.g. not applicable to the server).
  @protected
  void skip() => setStatus(CheckStatus.skipped);

  /// Asks the server to restrict ICE candidates to [protocol] and forces a
  /// full reconnect so the switch takes effect. Mirrors
  /// `simulateScenario('force-tcp')` from client-sdk-js.
  ///
  /// [CheckProtocol.udp] is a no-op since fresh connections already prefer
  /// UDP (this matches the JS SDK, which has no `force-udp` scenario).
  @protected
  Future<void> switchProtocol(CheckProtocol protocol) async {
    if (protocol == CheckProtocol.udp) {
      return;
    }
    final listener = room.createListener();
    try {
      // unlike client-sdk-js, the reconnect is always triggered explicitly
      // below, so simply wait for it to complete
      final reconnected = listener.waitFor<RoomReconnectedEvent>(
        duration: const Duration(seconds: 10),
        onTimeout: () => throw CheckException('Could not reconnect using ${protocol.name} protocol after 10 seconds'),
      );
      reconnected.ignore();
      engine.signalClient.sendSimulateScenario(switchCandidate: true);
      engine.fullReconnectOnNext = true;
      await engine.handleReconnect(ClientDisconnectReason.leaveReconnect);
      await reconnected;
    } finally {
      await listener.dispose();
    }
  }

  /// Performs a signal-level join (WebSocket only, no peer connections) and
  /// returns the server's join response.
  @protected
  Future<lk_rtc.JoinResponse> signalJoin(String url) async {
    final signalClient = SignalClient(wsConnector ?? LiveKitWebSocket.connect);
    final listener = signalClient.createListener();
    try {
      final joinCompleter = Completer<lk_rtc.JoinResponse>();
      listener.once<SignalJoinResponseEvent>((event) {
        if (!joinCompleter.isCompleted) {
          joinCompleter.complete(event.response);
        }
      });
      await signalClient.connect(
        url,
        token,
        connectOptions: connectOptions ?? const ConnectOptions(),
        roomOptions: options.roomOptions ?? const RoomOptions(),
      );
      return await joinCompleter.future.timeout(
        (connectOptions ?? const ConnectOptions()).timeouts.connection,
        onTimeout: () => throw const CheckException('Did not receive a join response'),
      );
    } finally {
      await listener.dispose();
      await signalClient.dispose();
    }
  }

  /// Extracts a human readable message from [error].
  @protected
  String messageFor(Object error) {
    if (error is LiveKitException) {
      return error.message;
    }
    return error.toString();
  }

  @protected
  void appendMessage(String message) {
    logs.add(CheckLog(level: CheckLogLevel.info, message: message));
    events.emit(CheckerUpdateEvent(info: getInfo()));
  }

  @protected
  void appendWarning(String message) {
    logs.add(CheckLog(level: CheckLogLevel.warning, message: message));
    events.emit(CheckerUpdateEvent(info: getInfo()));
  }

  @protected
  void appendError(String message) {
    logs.add(CheckLog(level: CheckLogLevel.error, message: message));
    events.emit(CheckerUpdateEvent(info: getInfo()));
  }

  @protected
  void setStatus(CheckStatus newStatus) {
    status = newStatus;
    events.emit(CheckerUpdateEvent(info: getInfo()));
  }

  /// The current snapshot of this check.
  CheckInfo getInfo() => CheckInfo(
        name: name,
        description: description,
        status: status,
        logs: List.unmodifiable(logs),
        data: data,
      );
}
