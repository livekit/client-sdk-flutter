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

/// Receives the SDK warnings and errors the logger's level filters out (telemetry): those it
/// emits reach its `onRecord` listeners as usual.
void Function(LogRecord record)? sdkFilteredWarningCapture;

/// The SDK's `logger`: the `livekit` [Logger] itself for everything the app sees (level, records,
/// listeners, how a message is evaluated), plus [sdkFilteredWarningCapture] for a warning or
/// error its level drops, so the console level never decides what telemetry gets.
class SdkLogger implements Logger {
  SdkLogger(this._logger);

  final Logger _logger;

  @override
  void log(Level logLevel, Object? message, [Object? error, StackTrace? stackTrace, Zone? zone]) {
    final capture = logLevel >= Level.WARNING ? sdkFilteredWarningCapture : null;
    if (capture == null || _logger.isLoggable(logLevel)) {
      return _logger.log(logLevel, message, error, stackTrace, zone); // exactly as without telemetry
    }
    // Filtered out: the console sees nothing, telemetry gets the record built the way the logger
    // would have. A message that fails to evaluate is dropped, never thrown to the caller.
    try {
      if (message is Function) message = (message as Object? Function())();
      final text = message is String ? message : message.toString();
      capture(
        LogRecord(
          logLevel,
          text,
          fullName,
          error,
          stackTrace,
          zone ?? Zone.current,
          message is String ? null : message,
        ),
      );
    } catch (_) {}
  }

  @override
  void finest(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.FINEST, message, error, stackTrace);
  @override
  void finer(Object? message, [Object? error, StackTrace? stackTrace]) => log(Level.FINER, message, error, stackTrace);
  @override
  void fine(Object? message, [Object? error, StackTrace? stackTrace]) => log(Level.FINE, message, error, stackTrace);
  @override
  void config(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.CONFIG, message, error, stackTrace);
  @override
  void info(Object? message, [Object? error, StackTrace? stackTrace]) => log(Level.INFO, message, error, stackTrace);
  @override
  void warning(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.WARNING, message, error, stackTrace);
  @override
  void severe(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.SEVERE, message, error, stackTrace);
  @override
  void shout(Object? message, [Object? error, StackTrace? stackTrace]) => log(Level.SHOUT, message, error, stackTrace);

  @override
  String get name => _logger.name;
  @override
  String get fullName => _logger.fullName;
  @override
  Logger? get parent => _logger.parent;
  @override
  Map<String, Logger> get children => _logger.children;
  @override
  Level get level => _logger.level;
  @override
  set level(Level? value) => _logger.level = value;
  @override
  Stream<Level?> get onLevelChanged => _logger.onLevelChanged;
  @override
  Stream<LogRecord> get onRecord => _logger.onRecord;
  @override
  void clearListeners() => _logger.clearListeners();
  @override
  bool isLoggable(Level value) => _logger.isLoggable(value);
}
