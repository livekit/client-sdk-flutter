import 'package:meta/meta.dart';

import '../extensions.dart';
import '../logger.dart';

// abstract class DisposeAware {
//   // Should be true when is disposing or already disposed
//   bool get isDisposed;
//   @mustCallSuper
//   void dispose();
// }

typedef OnDisposeFunc = Future<void> Function();
mixin Disposable {
  //
  final _disposeFuncs = <OnDisposeFunc>[];
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  void onDispose(OnDisposeFunc func) => _disposeFuncs.add(func);

  @mustCallSuper
  Future<bool> dispose() async {
    if (!_isDisposed) {
      logger.fine('[${objectId}] dispose()');
      _isDisposed = true;
      if (_disposeFuncs.isNotEmpty) {
        logger.fine('[$objectId] running ${_disposeFuncs.length} dispose funcs...');
        // call dispose funcs in reverse order
        for (final _func in _disposeFuncs.reversed) {
          await _func();
        }
        _disposeFuncs.clear();
        logger.fine('[$objectId] dispose complete.');
      }
      return true;
    }
    return false;
  }
}
