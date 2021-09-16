//
//
//

import 'dart:async';

import '../errors.dart';
import '../events.dart';
import '../logger.dart';
import '../extensions.dart';
import '../types.dart';

class LKEventManager<T extends LKEvent> {
  // suppport for multiple event listeners
  final _events = StreamController<T>.broadcast(sync: true);
  final _eventListeners = <StreamSubscription<T>>[];

  LKCancelListen listen(Function(T) onEvent) {
    final listener = _events.stream.listen(onEvent);
    _eventListeners.add(listener);
    // cancel listen and remove from list in 1 call
    cancelFunc() async {
      await listener.cancel();
      _eventListeners.remove(listener);
      logger.fine('${objectId} event was cancelled by func');
    }

    return cancelFunc;
  }

  Future<void> dispose() async {
    // Clean-up events
    logger.fine('${objectId} dispose() cancelling ${_eventListeners.length} event(s)');
    for (final _ in _eventListeners) {
      await _.cancel();
    }
    await _events.close();
  }

  void emit(T event) {
    if (!_events.isClosed) _events.add(event);
  }

  // create a temporary event listener and triggers `filter` closure until
  // it returns true or wait until timeout
  Future<void> waitFor(
    bool Function(T? event) filter, {
    required Duration duration,
  }) async {
    // check if filter is already true
    if (filter(null)) return;

    final completer = Completer<void>();
    final cancelListen = listen((event) {
      if (filter(event)) completer.complete();
    });

    try {
      // wait to complete with timeout
      await completer.future.timeout(
        duration,
        onTimeout: () => throw LKTimeoutException(),
      );
      // do not catch exceptions and pass it up
    } finally {
      // always clean-up listener
      await cancelListen.call();
    }
  }

  // Future<void> waitForCondition
}
