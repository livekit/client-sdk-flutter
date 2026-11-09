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

import '../events.dart';
import 'checks/checker.dart';

/// Base type for events emitted by `ConnectionCheck`.
mixin ConnectionCheckEvent implements LiveKitEvent {}

/// Base type for events emitted by a [Checker].
mixin CheckerEvent implements LiveKitEvent {}

/// Emitted by `ConnectionCheck` whenever the state of one of its checks
/// changes (status change or a new log entry).
class ConnectionCheckUpdateEvent with ConnectionCheckEvent {
  const ConnectionCheckUpdateEvent({
    required this.checkId,
    required this.info,
  });

  /// Identifies the check within this `ConnectionCheck` run.
  final int checkId;

  /// The latest snapshot of the check.
  final CheckInfo info;

  @override
  String toString() => '$runtimeType(checkId: $checkId, info: $info)';
}

/// Emitted by a [Checker] whenever its state changes (status change or a new
/// log entry).
class CheckerUpdateEvent with CheckerEvent {
  const CheckerUpdateEvent({required this.info});

  /// The latest snapshot of the check.
  final CheckInfo info;

  @override
  String toString() => '$runtimeType(info: $info)';
}
