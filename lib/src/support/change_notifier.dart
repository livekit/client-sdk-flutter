import 'package:flutter/foundation.dart';

import '../logger.dart';
import 'disposable.dart';

// A layer to prevent calling ChangeNotifier methods if already disposed
mixin DisposeGuardChangeNotifier on Disposable, ChangeNotifier {
  @override
  bool get hasListeners {
    if (isDisposed) {
      logger.warning('called hasListeners on a disposed ChangeNotifier');
      return false;
    }
    return super.hasListeners;
  }

  @override
  void addListener(VoidCallback listener) {
    if (isDisposed) {
      logger.warning('called addListener() on a disposed ChangeNotifier');
      return;
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    if (isDisposed) {
      logger.warning('called removeListener() on a disposed ChangeNotifier');
      return;
    }
    super.removeListener(listener);
  }

  @override
  void notifyListeners() {
    if (isDisposed) {
      logger.warning('called notifyListeners() on a disposed ChangeNotifier');
      return;
    }
    super.notifyListeners();
  }
}
