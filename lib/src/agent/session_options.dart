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
import '../e2ee/key_provider.dart';

/// Encryption key configuration for a [Session].
///
/// Use one of the named constructors to specify either a shared passphrase
/// or a pre-configured [BaseKeyProvider].
sealed class SessionEncryptionKey {
  const SessionEncryptionKey();

  /// Use a shared passphrase string.
  ///
  /// A [BaseKeyProvider] is created internally using the string as a shared
  /// key (recommended for maximum compatibility across SDKs).
  const factory SessionEncryptionKey.sharedKey(String key) = SharedKeyEncryption;

  /// Use a pre-configured [BaseKeyProvider] for custom key management.
  const factory SessionEncryptionKey.keyProvider(BaseKeyProvider provider) =
      KeyProviderEncryption;
}

/// A shared passphrase used to derive encryption keys.
class SharedKeyEncryption extends SessionEncryptionKey {
  final String sharedKey;
  const SharedKeyEncryption(this.sharedKey);
}

/// A pre-configured [BaseKeyProvider] instance.
class KeyProviderEncryption extends SessionEncryptionKey {
  final BaseKeyProvider keyProvider;
  const KeyProviderEncryption(this.keyProvider);
}

/// Encryption configuration for a [Session].
class SessionEncryptionOptions {
  /// The encryption key — either a shared passphrase or a custom key provider.
  final SessionEncryptionKey key;

  const SessionEncryptionOptions({required this.key});
}

/// Options for creating a [Session].
class SessionOptions {
  /// The underlying [Room] used by the session.
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

  /// Optional encryption configuration for end-to-end encryption.
  ///
  /// When provided, the session will configure E2EE on the room before
  /// connecting. Use [Session.setEncryptionEnabled] to toggle encryption
  /// after the session has started.
  final SessionEncryptionOptions? encryption;

  SessionOptions({
    Room? room,
    this.preConnectAudio = true,
    this.agentConnectTimeout = const Duration(seconds: 20),
    this.encryption,
  }) : room = room ?? Room();

  SessionOptions copyWith({
    Room? room,
    bool? preConnectAudio,
    Duration? agentConnectTimeout,
    SessionEncryptionOptions? encryption,
  }) {
    return SessionOptions(
      room: room ?? this.room,
      preConnectAudio: preConnectAudio ?? this.preConnectAudio,
      agentConnectTimeout: agentConnectTimeout ?? this.agentConnectTimeout,
      encryption: encryption ?? this.encryption,
    );
  }
}
