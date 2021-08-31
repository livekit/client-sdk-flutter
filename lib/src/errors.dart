//
// `Exception` implies runtime errors while, an `Error` object
// represents a program failure that the programmer
// should have avoided.
//
class LiveKitException implements Exception {
  //
  final String message;
  const LiveKitException._(this.message);

  @override
  String toString() => 'LiveKitException $runtimeType $message';
}

class ConnectError extends LiveKitException {
  ConnectError([String msg = 'Failed to connect to server']) : super._(msg);
}

class UnexpectedConnectionState extends LiveKitException {
  UnexpectedConnectionState([String msg = 'Unexpected connection state']) : super._(msg);
}

class TrackCreateError extends LiveKitException {
  TrackCreateError([String msg = 'Failed to create track']) : super._(msg);
}

class TrackPublishError extends LiveKitException {
  TrackPublishError([String msg = 'Failed to publish track']) : super._(msg);
}

class DataPublishError extends LiveKitException {
  DataPublishError([String msg = 'Failed to publish data']) : super._(msg);
}
