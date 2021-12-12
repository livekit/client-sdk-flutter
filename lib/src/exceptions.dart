/// Base class for Exceptions thrown by the LiveKit SDK
abstract class LiveKitException implements Exception {
  final String message;
  const LiveKitException._(this.message);

  @override
  String toString() => 'LiveKit Exception $runtimeType $message';
}

/// An exception occured while attempting to connect.
/// Common reasons:
/// - Invalid token (make sure your token is generated correctly)
/// - Network condition is not good
/// - Server not set up correctly (not responding)
class ConnectException extends LiveKitException {
  ConnectException([String msg = 'Failed to connect to server']) : super._(msg);
}

/// An internal state of the SDK is not correct and can not continue to execute.
/// This should not occur frequently.
class UnexpectedStateException extends LiveKitException {
  UnexpectedStateException([String msg = 'Unexpected connection state'])
      : super._(msg);
}

/// Failed to create a local track.
/// Common reasons:
/// - Required permissions not yet granted to the platform.
/// - Constraints(Capture options) rejected by the platform.
class TrackCreateException extends LiveKitException {
  TrackCreateException([String msg = 'Failed to create track']) : super._(msg);
}

/// Failed to publish a local track.
/// Common reasons:
/// - Token does not have track publish permission.
/// - Network condition is not good.
class TrackPublishException extends LiveKitException {
  TrackPublishException([String msg = 'Failed to publish track'])
      : super._(msg);
}

/// Failed to publish data.
/// Common reasons:
/// - Token does not have data publish permission.
/// - Network condition is not good.
class DataPublishException extends LiveKitException {
  DataPublishException([String msg = 'Failed to publish data']) : super._(msg);
}

/// A certain time has passed while attempting to execute an operation.
class TimeoutException extends LiveKitException {
  TimeoutException([String msg = 'Timeout']) : super._(msg);
}
