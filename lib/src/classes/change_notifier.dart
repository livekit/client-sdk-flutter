import 'package:flutter/material.dart';
import 'package:livekit_client/src/logger.dart';

// dispose safe change notifier
abstract class LKChangeNotifier extends ChangeNotifier {
  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void addListener(VoidCallback listener) {
    if (_disposed) {
      logger.warning('calling addListener on a disposed ChangeNotifier');
      return;
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    if (_disposed) {
      logger.warning('calling removeListener on a disposed ChangeNotifier');
      return;
    }
    super.removeListener(listener);
  }
}
