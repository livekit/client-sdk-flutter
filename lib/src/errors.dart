class LiveKitError extends Error {
  String message;

  LiveKitError(this.message);

  @override
  String toString() {
    return message;
  }
}

class ConnectError extends LiveKitError {
  ConnectError([String msg = 'Failed to connect to server']) : super(msg);
}

class TrackCreateError extends LiveKitError {
  TrackCreateError([String msg = 'Failed to create track']) : super(msg);
}

class TrackPublishError extends LiveKitError {
  TrackPublishError([String msg = 'Failed to publish track']) : super(msg);
}

class DataPublishError extends LiveKitError {
  DataPublishError([String msg = 'Failed to publish data']) : super(msg);
}
