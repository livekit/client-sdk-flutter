/// Base class for Exceptions thrown by the LiveKit SDK
abstract class E2EEException implements Exception {
  final String message;
  const E2EEException._(this.message);

  @override
  String toString() => 'E2EE Exception: [$runtimeType] $message';
}

class UnsupportedFrameCrypto extends E2EEException {
  UnsupportedFrameCrypto([String msg = 'Device not support frame crypto'])
      : super._(msg);
}

class MissingKeyException extends E2EEException {
  MissingKeyException([String msg = 'Missing key']) : super._(msg);
}

class FrameCryptoInternalErrorException extends E2EEException {
  FrameCryptoInternalErrorException(
      [String msg = 'Internal error, encryption/decryption failed'])
      : super._(msg);
}
