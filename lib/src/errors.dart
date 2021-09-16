//
//
//
class LKException implements Exception {
  final String message;
  const LKException._(this.message);

  @override
  String toString() => 'LiveKit Exception $runtimeType $message';
}

class LKConnectException extends LKException {
  LKConnectException([String msg = 'Failed to connect to server']) : super._(msg);
}

class LKUnexpectedStateException extends LKException {
  LKUnexpectedStateException([String msg = 'Unexpected connection state']) : super._(msg);
}

class LKTrackCreateException extends LKException {
  LKTrackCreateException([String msg = 'Failed to create track']) : super._(msg);
}

class LKTrackPublishException extends LKException {
  LKTrackPublishException([String msg = 'Failed to publish track']) : super._(msg);
}

class LKDataPublishException extends LKException {
  LKDataPublishException([String msg = 'Failed to publish data']) : super._(msg);
}

class LKTimeoutException extends LKException {
  LKTimeoutException([String msg = 'Timeout']) : super._(msg);
}
