import 'package:livekit_client/src/logger.dart';
import 'package:meta/meta.dart';

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
    logger.fine('${runtimeType}.dispose()');
    _isDisposed = true;
  }
}
