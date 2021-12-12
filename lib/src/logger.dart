import 'package:logging/logging.dart';

/// Logger used for the entire SDK. To output logs, configure the logger at the
/// entry point of your app. Adjust the logger output level to your needs.
/// A typical configuration would look like the following:
///
/// Logger.root.level = Level.FINE;
/// Logger.root.onRecord.listen((record) {
///   print('${record.level.name}: ${record.message}');
/// });
final logger = Logger('livekit');
