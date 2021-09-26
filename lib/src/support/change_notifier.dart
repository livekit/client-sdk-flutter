import 'package:flutter/foundation.dart';

import '../logger.dart';
import '../extensions.dart';
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
    logger.fine('[${objectId}] dispose()');
    if (!_isDisposed) {
      _isDisposed = true;
      super.dispose();
    }
  }

  @override
  void addListener(VoidCallback listener) {
    if (_isDisposed) {
      logger.warning('called addListener() on a disposed ChangeNotifier');
      return;
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    if (_isDisposed) {
      logger.warning('called removeListener() on a disposed ChangeNotifier');
      return;
    }
    super.removeListener(listener);
  }

  @override
  void notifyListeners() {
    if (_isDisposed) {
      logger.warning('called notifyListeners() on a disposed ChangeNotifier');
      return;
    }
    super.notifyListeners();
  }
}
