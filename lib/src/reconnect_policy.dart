import 'dart:math';

class ReconnectContext {
  final int retryCount;
  final int elapsedMs;
  final Error? retryReason;
  ReconnectContext(
      {required this.retryCount, required this.elapsedMs, this.retryReason});
}

abstract class ReconnectPolicy {
  /// Called after disconnect was detected
  ///
  /// @returns {number | null} Amount of time in milliseconds
  /// to delay the next reconnect attempt, `null` signals to stop retrying.
  int? nextRetryDelayInMs(ReconnectContext context);
}

const maxRetryDelay = 7000;

const defaultRetryDelaysInMs = [
  0,
  300,
  2 * 2 * 300,
  3 * 3 * 300,
  4 * 4 * 300,
  maxRetryDelay,
  maxRetryDelay,
  maxRetryDelay,
  maxRetryDelay,
  maxRetryDelay,
];

class DefaultReconnectPolicy implements ReconnectPolicy {
  late List<int> _retryDelays;

  DefaultReconnectPolicy([List<int>? retryDelays]) {
    _retryDelays =
        retryDelays != null ? [...retryDelays] : defaultRetryDelaysInMs;
  }

  @override
  int? nextRetryDelayInMs(ReconnectContext context) {
    if (context.retryCount >= _retryDelays.length) return null;

    final retryDelay = _retryDelays[context.retryCount];
    if (context.retryCount <= 1) return retryDelay;

    return retryDelay + (Random().nextDouble() * 1000) as int;
  }
}
