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
  kOFF
}

final logger = Logger('livekit');

/// disable logging
void disableLogging() {
  logger.level = Level.OFF;
}

/// set the logging level
void setLoggingLevel(LoggerLevel level) {
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
