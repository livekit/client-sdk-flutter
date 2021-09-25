import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart' as sync;

import '../support/disposable.dart';
import '../exceptions.dart';
import '../extensions.dart';
import '../logger.dart';
import '../types.dart';

// Type-safe, multi-listenable, dispose safe event handling
// TODO: Move to a separate package

class EventsEmitter<T> extends EventsListenable<T> {
  // suppport for multiple event listeners
  final streamCtrl = StreamController<T>.broadcast(sync: false);

  EventsEmitter({
    bool listenSynchronized = false,
  }) : super(synchronized: listenSynchronized);

  @override
  EventsEmitter<T> get emitter => this;

  void emit(T event) {
    // do nothing if already closed
    if (streamCtrl.isClosed) return;
    // emit the event
    streamCtrl.add(event);
  }

  @override
  @mustCallSuper
  Future<void> dispose() async {
    // mark as disposed
    await super.dispose();
    await streamCtrl.close();
  }
}

// for listening only
class EventsListener<T> extends EventsListenable<T> {
  @override
  final EventsEmitter<T> emitter;

  EventsListener(
    this.emitter, {
    bool synchronized = false,
  }) : super(
          synchronized: synchronized,
        );
}

// ensures all listeners will close on dispose
abstract class EventsListenable<T> extends Disposable {
  // the emitter to listen to
  EventsEmitter<T> get emitter;

  bool synchronized;
  // keep track of listeners to cancel later
  final _listeners = <StreamSubscription<T>>[];
  final _syncLock = sync.Lock();

  EventsListenable({
    required this.synchronized,
  });

  @override
  @mustCallSuper
  Future<void> dispose() async {
    // mark as disposed
    super.dispose();
    // Stop listening to all events
    logger.fine('${objectId} dispose() cancelling ${_listeners.length} event(s)');
    for (final listener in _listeners) {
      await listener.cancel();
    }
  }

  // listens to all events, guaranteed to be cancelled on dispose
  CancelListenFunc listen(FutureOr<void> Function(T) onEvent) {
    //
    FutureOr<void> Function(T) _func = onEvent;
    if (synchronized) {
      // ensure `onEvent` will trigger one by one (waits for previous `onEvent` to complete)
      _func = (event) async {
        await _syncLock.synchronized(() async {
          await onEvent(event);
        });
      };
    }

    final listener = emitter.streamCtrl.stream.listen(_func);
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
  CancelListenFunc on<E>(
    FutureOr<void> Function(E) then, {
    bool Function(E)? filter,
  }) =>
      listen((event) async {
        // event must be E
        if (event is! E) return;
        // filter must be true (if filter is used)
        if (filter != null && !filter(event)) return;
        // cast to E
        await then(event);
      });

  // waits for a specific event type
  Future<E> waitFor<E>({
    required Duration duration,
    bool Function(E)? filter,
    FutureOr<E> Function()? onTimeout,
  }) async {
    final completer = Completer<E>();

    final _cancelFunc = on<E>(
      (event) => completer.complete(event),
      filter: filter,
    );

    try {
      // wait to complete with timeout
      return await completer.future.timeout(
        duration,
        onTimeout: onTimeout ?? () => throw TimeoutException(),
      );
      // do not catch exceptions and pass it up
    } finally {
      // always clean-up listener
      await _cancelFunc.call();
    }
  }
}
