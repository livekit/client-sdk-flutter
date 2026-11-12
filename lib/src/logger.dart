// Copyright 2024 LiveKit, Inc.
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

import 'package:logging/logging.dart';

enum LoggerLevel {
  kALL,
  kFINEST,
  kFINER,
  kFINE,
  kCONFIG,
  kINFO,
  kWARNING,
  kSEVERE,
  kSHOUT,
  kOFF,
}

/// The logger every part of the SDK writes to. Its records also reach
/// `Logger.root.onRecord`, which is where an app usually listens.
final logger = Logger('livekit');

/// Stops the SDK from logging. Other loggers are not affected.
///
/// Turns on `hierarchicalLoggingEnabled`, see [setLoggingLevel].
void disableLogging() {
  hierarchicalLoggingEnabled = true;
  logger.level = Level.OFF;
}

/// Sets how much the SDK logs, apart from the level of `Logger.root`. Other
/// loggers are not affected.
///
/// Turns on `hierarchicalLoggingEnabled` of `package:logging`, a process-wide
/// switch. Without it only the root logger has a level, and giving one to any
/// other logger is an error. Loggers that have no level of their own keep
/// following the root logger, so nothing else changes.
void setLoggingLevel(LoggerLevel level) {
  hierarchicalLoggingEnabled = true;
  switch (level) {
    case LoggerLevel.kALL:
      logger.level = Level.ALL;
      break;
    case LoggerLevel.kFINEST:
      logger.level = Level.FINEST;
      break;
    case LoggerLevel.kFINER:
      logger.level = Level.FINER;
      break;
    case LoggerLevel.kFINE:
      logger.level = Level.FINE;
      break;
    case LoggerLevel.kCONFIG:
      logger.level = Level.CONFIG;
      break;
    case LoggerLevel.kINFO:
      logger.level = Level.INFO;
      break;
    case LoggerLevel.kWARNING:
      logger.level = Level.WARNING;
      break;
    case LoggerLevel.kSEVERE:
      logger.level = Level.SEVERE;
      break;
    case LoggerLevel.kSHOUT:
      logger.level = Level.SHOUT;
      break;
    case LoggerLevel.kOFF:
      logger.level = Level.OFF;
      break;
  }
}

/// get the current logging level
Level getLoggingLevel() {
  return logger.level;
}

/// set a custom logging handler
///void setLoggingHandler(Function(LogRecord) handler) {
///  logger.onRecord.listen(handler);
///}
