// Copyright 2026 LiveKit, Inc.
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

import 'package:livekit_client/src/connection_check/checks/checker.dart';

/// A [Checker] with injectable behavior, to test the [Checker] base class and
/// `ConnectionCheck` orchestration without a server.
class FakeChecker extends Checker {
  FakeChecker({
    Future<void> Function(FakeChecker checker)? onPerform,
    CheckerOptions? options,
  })  : _onPerform = onPerform,
        super('ws://www.example.com', 'token', options: options);

  final Future<void> Function(FakeChecker checker)? _onPerform;

  @override
  String get description => 'Fake check for testing';

  @override
  Future<void> perform() async {
    await _onPerform?.call(this);
  }

  // Re-expose protected members so test callbacks can drive the check.
  void addMessage(String message) => appendMessage(message);

  void addWarning(String message) => appendWarning(message);

  void addError(String message) => appendError(message);

  void doSkip() => skip();
}
