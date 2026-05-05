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

import '../core/room.dart';
import '../e2ee/options.dart';
import '../options.dart';

/// Options for creating a [Session].
class SessionOptions {
  /// The underlying [Room] used by the session.
  ///
  /// If neither [room] nor [encryption] is provided, a default [Room] is
  /// created. Passing both throws [ArgumentError] — configure E2EE on the
  /// [Room] directly if you need a custom [Room] with encryption.
  final Room room;

  /// Whether to enable audio pre-connect with [PreConnectAudioBuffer].
  ///
  /// If enabled, the microphone is activated before connecting to the room.
  /// Ensure microphone permissions are requested early in the app lifecycle so
  /// that pre-connect can succeed without additional prompts.
  final bool preConnectAudio;

  /// The timeout for the agent to connect. If exceeded, the agent transitions
  /// to a failed state.
  final Duration agentConnectTimeout;

  /// Creates [SessionOptions].
  ///
  /// Pass [encryption] to configure end-to-end encryption on the internally
  /// created [Room]. Use [E2EEOptions.sharedKey] for the common shared-key
  /// case. For advanced setups (custom [RoomOptions], per-participant keys),
  /// build a [Room] yourself and pass it via [room] instead.
  ///
  /// Passing both [room] and [encryption] throws [ArgumentError].
  SessionOptions({
    Room? room,
    E2EEOptions? encryption,
    this.preConnectAudio = true,
    this.agentConnectTimeout = const Duration(seconds: 20),
  }) : room = _buildRoom(room, encryption);

  static Room _buildRoom(Room? room, E2EEOptions? encryption) {
    if (room != null && encryption != null) {
      throw ArgumentError(
        'SessionOptions: pass either `room` or `encryption`, not both. '
        'To use encryption with a custom Room, configure E2EE on the Room directly.',
      );
    }
    if (encryption != null) {
      return Room(roomOptions: RoomOptions(encryption: encryption));
    }
    return room ?? Room();
  }

  SessionOptions copyWith({
    Room? room,
    bool? preConnectAudio,
    Duration? agentConnectTimeout,
  }) {
    return SessionOptions(
      room: room ?? this.room,
      preConnectAudio: preConnectAudio ?? this.preConnectAudio,
      agentConnectTimeout: agentConnectTimeout ?? this.agentConnectTimeout,
    );
  }
}
