// Copyright 2025 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

/// A manager for Completer instances that provides safe completion and automatic lifecycle management.
///
/// Features:
/// - Safe completion (prevents double completion exceptions)
/// - Automatic timeout handling
/// - Clean state management and reusability
/// - Only exposes Future, not the Completer itself
/// - Thread-safe operations
class CompleterManager<T> {
  Completer<T> _completer;
  Timer? _timeoutTimer;
  bool _isCompleted = false;

  /// Creates a new CompleterManager with an active completer.
  CompleterManager() : _completer = Completer<T>();

  /// Gets the current future. Creates a new completer if previous one was completed.
  Future<T> get future {
    if (_isCompleted) {
      _reset();
    }
    return _completer.future;
  }

  /// Whether the current completer is completed.
  bool get isCompleted => _isCompleted;

  /// Whether there's an active completer waiting for completion.
  bool get isActive => !_isCompleted;

  /// Completes the current completer with the given value.
  /// Returns true if successfully completed, false if already completed.
  bool complete([FutureOr<T>? value]) {
    if (_isCompleted) {
      return false;
    }

    _isCompleted = true;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    _completer.complete(value);
    return true;
  }

  /// Completes the current completer with an error.
  /// Returns true if successfully completed with error, false if already completed.
  bool completeError(Object error, [StackTrace? stackTrace]) {
    if (_isCompleted) {
      return false;
    }

    _isCompleted = true;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    _completer.completeError(error, stackTrace);
    return true;
  }

  /// Sets up a timeout for the current completer.
  /// If the completer is not completed within the timeout, it will be completed with a TimeoutException.
  void setTimer(Duration timeout, {String? timeoutReason}) {
    if (_isCompleted) {
      return;
    }

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(timeout, () {
      if (!_isCompleted) {
        final reason = timeoutReason ?? 'Operation timed out after $timeout';
        completeError(TimeoutException(reason, timeout));
      }
    });
  }

  /// Resets the manager, canceling any pending operations and preparing for reuse.
  void reset() {
    _reset();
  }

  void _reset() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _isCompleted = false;
    _completer = Completer<T>();
  }

  /// Disposes the manager, canceling any pending operations.
  void dispose() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    if (!_isCompleted) {
      _completer.completeError(StateError('CompleterManager disposed'));
      _isCompleted = true;
    }
  }
}
