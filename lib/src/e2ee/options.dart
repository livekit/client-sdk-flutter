// Copyright 2024 LiveKit, Inc.
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

import 'package:meta/meta.dart';

import 'key_provider.dart';

enum EncryptionType {
  kNone,
  kGcm,
  kCustom,
}

/// End-to-end encryption configuration for a [Room].
///
/// Build with either a pre-constructed [BaseKeyProvider] (default constructor)
/// or a shared passphrase ([E2EEOptions.sharedKey]). Resolution of the
/// passphrase into a native key provider is deferred to [E2EEManager.setup].
class E2EEOptions {
  final BaseKeyProvider? _keyProvider;

  /// A shared passphrase, or `null` when a [BaseKeyProvider] was provided.
  final String? sharedKey;

  final EncryptionType encryptionType = EncryptionType.kGcm;

  const E2EEOptions({required BaseKeyProvider keyProvider})
      : _keyProvider = keyProvider,
        sharedKey = null;

  const E2EEOptions.sharedKey(String key)
      : sharedKey = key,
        _keyProvider = null;

  /// The underlying [BaseKeyProvider].
  ///
  /// Available immediately when built via the default constructor. Throws
  /// [StateError] when built via [E2EEOptions.sharedKey] — the provider is
  /// created lazily inside [E2EEManager.setup]; read it from
  /// `room.e2eeManager!.keyProvider` after connect instead.
  BaseKeyProvider get keyProvider =>
      _keyProvider ??
      (throw StateError(
        'E2EEOptions was constructed via E2EEOptions.sharedKey(...); '
        'BaseKeyProvider is built lazily inside E2EEManager.setup(). '
        'Access it via room.e2eeManager!.keyProvider after connect.',
      ));

  /// Internal accessor used by [E2EEManager.setup] to read the pre-built
  /// provider without triggering the throwing [keyProvider] getter.
  @internal
  BaseKeyProvider? get keyProviderOrNull => _keyProvider;
}
