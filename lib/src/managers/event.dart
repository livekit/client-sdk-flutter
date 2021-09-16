//
//
//

import 'dart:async';

import '../errors.dart';
import '../events.dart';
import '../extensions.dart';
import '../logger.dart';
import '../types.dart';

// Type-safe, multi-listenable, dispose safe event handling

class LKEventsEmitter<T extends LKEvent> {
  // suppport for multiple event listeners
  final streamCtrl = StreamController<T>.broadcast(sync: false);

  void emit(T event) {
    // do nothing if already closed
    if (streamCtrl.isClosed) return;
    // emit the event
    streamCtrl.add(event);
  }

  Future<void> dispose() async {
    await streamCtrl.close();
  }
}

// ensures all listeners will close on dispose
class LKEventsListener<T extends LKEvent> {
  // the emitter to listen to
  final LKEventsEmitter<T> emitter;
  // keep track of listeners to cancel later
  final _listeners = <StreamSubscription<T>>[];

  LKEventsListener({
    required this.emitter,
  });

  Future<void> dispose() async {
    // Stop listening to all events
    logger.fine('${objectId} dispose() cancelling ${_listeners.length} event(s)');
    for (final listener in _listeners) {
      await listener.cancel();
    }
  }

  // listens to all events, guaranteed to be cancelled on dispose
  LKCancelListen listen(Function(T) onEvent) {
    final listener = emitter.streamCtrl.stream.listen(onEvent);
    _listeners.add(listener);

    // make a cancel func to cancel listening and remove from list in 1 call
    _cancelFunc() async {
      await listener.cancel();
      _listeners.remove(listener);
      logger.fine('${objectId} event was cancelled by func');
    }

    return _cancelFunc;
  }

  // convenience method to listen & filter a specific event type
  LKCancelListen on<E>(
    Function(E) then, {
    bool Function(E)? filter,
  }) =>
      listen((event) {
        // event must be E
        if (event is! E) return;
        // filter must be true (if filter is used)
        if (filter != null && !filter(event as E)) return;
        // cast to E
        then(event as E);
      });

  // waits for a specific event type
  Future<void> waitFor<E>({
    required Duration duration,
    bool Function(E)? filter,
    FutureOr<void> Function()? onTimeout,
  }) async {
    final completer = Completer<void>();

    final _cancelFunc = on<E>(
      (event) => completer.complete(),
      filter: filter,
    );

    try {
      // wait to complete with timeout
      await completer.future.timeout(
        duration,
        onTimeout: onTimeout ?? () => throw LKTimeoutException(),
      );
      // do not catch exceptions and pass it up
    } finally {
      // always clean-up listener
      await _cancelFunc.call();
    }
  }
}
