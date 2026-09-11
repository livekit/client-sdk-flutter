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

/// Web implementation of [LiveKitUniffi]. See `uniffi.dart`.
///
/// Native Assets bundles a `cdylib`, which the web has no way to load, so the
/// Rust core is simply absent here. This file deliberately does not import
/// `package:livekit_uniffi/...` -- doing so would pull `dart:ffi` into a web
/// compile and fail the build.
const bool isAvailable = false;

Never buildVersion() => throw UnsupportedError(
  'LiveKitUniffi.buildVersion is not available on web: the Rust core is '
  'delivered as a native library. Guard calls with '
  'LiveKitUniffi.isAvailable.',
);
