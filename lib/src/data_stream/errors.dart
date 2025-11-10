enum DataStreamErrorReason {
  // Unable to open a stream with the same ID more than once.
  alreadyOpened,

  // Stream closed abnormally by remote participant.
  abnormalEnd,

  // Incoming chunk data could not be decoded.
  decodeFailed,

  // Read length exceeded total length specified in stream header.
  lengthExceeded,

  // Read length less than total length specified in stream header.
  incomplete,

  // Unable to register a stream handler more than once.
  handlerAlreadyRegistered,

  // Encryption type mismatch.
  encryptionTypeMismatch,
}

class DataStreamError implements Exception {
  final DataStreamErrorReason reason;
  final String message;

  DataStreamError({required this.reason, required this.message});

  @override
  String toString() {
    return 'DataStreamError: $reason, $message';
  }
}
