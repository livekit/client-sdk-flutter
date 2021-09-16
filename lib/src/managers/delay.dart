//
//
//
import 'package:async/async.dart';

class LKCancelableDelayManager {
  //
  final _delays = <CancelableOperation<void>>[];

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

  Future<void> dispose() async {
    // cancel all delays
    if (_delays.isEmpty) return;
    // make a copy so we don't mutate while iterating
    final snapshot = List<CancelableOperation<void>>.from(_delays);
    for (final op in snapshot) {
      await op.cancel();
    }
  }
}
