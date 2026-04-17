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
  /// A pre-built [BaseKeyProvider], or `null` when this instance was created
  /// via [E2EEOptions.sharedKey].
  final BaseKeyProvider? keyProvider;

  /// A shared passphrase, or `null` when a [keyProvider] was provided.
  final String? sharedKey;

  final EncryptionType encryptionType = EncryptionType.kGcm;

  const E2EEOptions({required BaseKeyProvider this.keyProvider}) : sharedKey = null;

  const E2EEOptions.sharedKey(String key)
      : sharedKey = key,
        keyProvider = null;
}
