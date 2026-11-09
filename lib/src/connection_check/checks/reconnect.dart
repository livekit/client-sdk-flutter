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

import 'dart:async';

import '../../events.dart';
import '../../types/other.dart';
import 'checker.dart';

/// Verifies that a connection can be resumed after an interruption.
class ReconnectCheck extends Checker {
  ReconnectCheck(super.url, super.token, {super.options, super.room});

  @override
  String get description => 'Resuming connection after interruption';

  @override
  Future<void> perform() async {
    final room = await connect();
    var reconnectingTriggered = false;
    var reconnected = false;

    final reconnectCompleter = Completer<void>();

    final listener = room.createListener();
    listener
      ..on<ReconnectingEvent>((_) => reconnectingTriggered = true)
      ..once<RoomReconnectedEvent>((_) {
        reconnected = true;
        if (!reconnectCompleter.isCompleted) {
          reconnectCompleter.complete();
        }
      });

    try {
      // Forcefully close the underlying signal WebSocket; the engine should
      // notice and resume the session on its own.
      await engine.signalClient.cleanUp();

      await reconnectCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {},
      );

      if (!reconnectingTriggered) {
        throw const CheckException('Did not attempt to reconnect');
      } else if (!reconnected || room.connectionState != ConnectionState.connected) {
        appendWarning('reconnection is only possible in Redis-based configurations');
        throw const CheckException('Not able to reconnect');
      }
    } finally {
      await listener.dispose();
    }
  }
}
