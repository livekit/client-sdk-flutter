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

import 'uniffi_io.dart' if (dart.library.js_interop) 'uniffi_web.dart' as impl;

/// Facade over the Rust core exposed by the `livekit_uniffi` package.
///
/// `livekit_uniffi` reaches Rust through Dart's Native Assets: its build hook
/// bundles a `cdylib` into the host app and the generated bindings call into it
/// with `@Native`. None of that exists on the web, where there is no dynamic
/// library to load, so every entry point here is split native/web through the
/// same conditional-import pattern the rest of the SDK uses (see
/// `support/platform.dart`). Web builds must never reach the generated
/// bindings -- importing them at all would break `dart compile js`/`wasm`.
///
/// Callers get [isAvailable] to branch on, and platform-specific code paths
/// stay out of the public API surface.
abstract final class LiveKitUniffi {
  /// Whether the Rust core can be called on this platform.
  ///
  /// False on web. Every other member throws [UnsupportedError] when this is
  /// false, rather than returning a silently wrong value.
  static bool get isAvailable => impl.isAvailable;

  /// Version string reported by the Rust core.
  ///
  /// The simplest possible round trip -- a synchronous, argument-free call
  /// returning a string -- so it doubles as the smoke test that the whole
  /// chain is wired up: build hook resolved the library, `@Native` bound the
  /// symbol, and a value came back across the FFI boundary.
  ///
  /// Throws [UnsupportedError] on web.
  static String get buildVersion => impl.buildVersion();
}
