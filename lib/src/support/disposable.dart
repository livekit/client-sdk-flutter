import 'package:meta/meta.dart';

import '../extensions.dart';
import '../logger.dart';

abstract class DisposeAware {
  // Should be true when is disposing or already disposed
  bool get isDisposed;
  @mustCallSuper
  void dispose();
}

abstract class Disposable extends DisposeAware {
  //
  bool _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  @override
  @mustCallSuper
  void dispose() {
    logger.fine('[${objectId}] dispose()');
    _isDisposed = true;
  }
}
