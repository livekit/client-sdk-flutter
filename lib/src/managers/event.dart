import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart' as sync;

import '../exceptions.dart';
import '../extensions.dart';
import '../logger.dart';
import '../support/disposable.dart';
import '../types/other.dart';

mixin EventsEmittable<T> {
  final events = EventsEmitter<T>();
  EventsListener<T> createListener({bool synchronized = false}) =>
      EventsListener<T>(events, synchronized: synchronized);
}

// Type-safe, multi-listenable, dispose safe event handling
// TODO: Move to a separate package

class EventsEmitter<T> extends EventsListenable<T> {
  // suppport for multiple event listeners
  final streamCtrl = StreamController<T>.broadcast(sync: false);

  bool _queueMode = false;
  final _queue = Queue<T>();

  EventsEmitter({
    bool listenSynchronized = false,
  }) : super(synchronized: listenSynchronized) {
    // clean up
    onDispose(() async => await streamCtrl.close());
  }

  @override
  EventsEmitter<T> get emitter => this;

  @internal
  void emit(T event) {
    // check if already disposed
    if (isDisposed) {
      logger.warning('failed to emit event ${event} on a disposed emitter');
      return;
    }
    // queue mode
    if (_queueMode) {
      _queue.add(event);
      return;
    }
    // emit the event
    streamCtrl.add(event);
  }

  @internal
  void updateQueueMode(bool newValue, {bool shouldEmitQueued = true}) {
    // check if already disposed
    if (isDisposed) {
      logger.warning('failed to update queueMode on a disposed emitter');
      return;
    }
    if (_queueMode == newValue) return;
    _queueMode = newValue;
    if (!_queueMode && shouldEmitQueued) emitQueued();
  }

  @internal
  void emitQueued() {
    while (_queue.isNotEmpty) {
      final event = _queue.removeFirst();
      // emit the event
      streamCtrl.add(event);
    }
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

  final bool synchronized;
  // keep track of listeners to cancel later
  final _listeners = <StreamSubscription<T>>[];
  final _syncLock = sync.Lock();

  List<StreamSubscription<T>> get listeners => _listeners;

  EventsListenable({
    required this.synchronized,
  }) {
    onDispose(() async {
      await cancelAll();
    });
  }

  Future<void> cancelAll() async {
    if (_listeners.isNotEmpty) {
      // Stop listening to all events
      logger.finer('${objectId} cancelling ${_listeners.length} listeners(s)');
      for (final listener in _listeners) {
        await listener.cancel();
      }
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
      (event) {
        if (!completer.isCompleted) {
          completer.complete(event);
        }
      },
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
