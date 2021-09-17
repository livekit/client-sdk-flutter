//
//
//
class LiveKitException implements Exception {
  final String message;
  const LiveKitException._(this.message);

  @override
  String toString() => 'LiveKit Exception $runtimeType $message';
}

class ConnectException extends LiveKitException {
  ConnectException([String msg = 'Failed to connect to server']) : super._(msg);
}

class UnexpectedStateException extends LiveKitException {
  UnexpectedStateException([String msg = 'Unexpected connection state']) : super._(msg);
}

class TrackCreateException extends LiveKitException {
  TrackCreateException([String msg = 'Failed to create track']) : super._(msg);
}

class TrackPublishException extends LiveKitException {
  TrackPublishException([String msg = 'Failed to publish track']) : super._(msg);
}

class DataPublishException extends LiveKitException {
  DataPublishException([String msg = 'Failed to publish data']) : super._(msg);
}

class TimeoutException extends LiveKitException {
  TimeoutException([String msg = 'Timeout']) : super._(msg);
}
