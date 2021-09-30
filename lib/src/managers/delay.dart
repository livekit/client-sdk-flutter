import 'package:async/async.dart';

import '../support/disposable.dart';

class CancelableDelayManager extends Disposable {
  //
  final _delays = <CancelableOperation<void>>[];

  CancelableDelayManager() {
    onDispose(() async => await cancelAll());
  }
  // delay but cancelable
  Future<void> waitFor(
    Duration wait, {
    Function? ifNotCancelled,
  }) async {
    final op = CancelableOperation<void>.fromFuture(
      Future<void>.delayed(wait),
    );
    _delays.add(op);
    await op.valueOrCancellation();
    _delays.remove(op);
    // if it was cancelled we probably don't want to execute it
    if (!op.isCanceled) ifNotCancelled?.call();
  }

  // @override
  // Future<bool> dispose() async {
  //   final didDispose = await super.dispose();
  //   if (didDispose) {
  //     await cancelAll();
  //   }
  //   return didDispose;
  // }

  Future<void> cancelAll() async {
    // cancel all delays
    if (_delays.isEmpty) return;
    // make a copy so we don't mutate while iterating
    final snapshot = List<CancelableOperation<void>>.from(_delays);
    for (final op in snapshot) {
      await op.cancel();
    }
  }
}
