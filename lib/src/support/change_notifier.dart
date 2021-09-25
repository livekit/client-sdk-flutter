import 'package:flutter/foundation.dart';

import '../logger.dart';
import 'disposable.dart';

// dispose safe change notifier
abstract class DisposeAwareChangeNotifier extends ChangeNotifier implements DisposeAware {
  //
  bool _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  // must implement
  @override
  @mustCallSuper
  void dispose() {
    logger.fine('${runtimeType}.dispose()');
    _isDisposed = true;
    super.dispose();
  }

  @override
  void addListener(VoidCallback listener) {
    if (_isDisposed) {
      logger.warning('calling addListener on a disposed ChangeNotifier');
      return;
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    if (_isDisposed) {
      logger.warning('calling removeListener on a disposed ChangeNotifier');
      return;
    }
    super.removeListener(listener);
  }
}
