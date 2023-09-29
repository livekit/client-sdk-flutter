// Copyright 2023 LiveKit, Inc.
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

import 'core/room.dart';
import 'options.dart';
import 'types/other.dart';

/// Main entry point to connect to a room.
/// {@category Room}
class LiveKitClient {
  static const version = '1.5.2';

  /// Convenience method for connecting to a LiveKit server.
  /// Returns a [Room] upon a successful connect or throws when it fails.
  /// Alternatively, it is possible to instantiate [Room] and call [Room.connect] directly.
  @Deprecated(
      'Use `Room.connect` instead, This method is deprecated above Protocol v8.')
  static Future<Room> connect(
    String url,
    String token, {
    ConnectOptions? connectOptions,
    RoomOptions? roomOptions,
  }) async {
    final room = Room();
    ConnectOptions copyOptions = ConnectOptions(
      autoSubscribe:
          connectOptions != null ? connectOptions.autoSubscribe : true,
      rtcConfiguration: connectOptions != null
          ? connectOptions.rtcConfiguration
          : const RTCConfiguration(),
      protocolVersion: ProtocolVersion.v7,
    );
    try {
      await room.connect(
        url,
        token,
        connectOptions: copyOptions,
        roomOptions: roomOptions,
      );
      return room;
    } catch (error) {
      await room.dispose();
      rethrow;
    }
  }
}
