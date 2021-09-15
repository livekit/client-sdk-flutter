//
//
//

import 'dart:async';

import 'events.dart';
import 'types.dart';

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
    }

    return cancelFunc;
  }

  Future<void> dispose() async {
    // Clean-up events
    for (final _ in _eventListeners) {
      await _.cancel();
    }
    await _events.close();
  }

  void emit(T event) {
    if (!_events.isClosed) _events.add(event);
  }
}
