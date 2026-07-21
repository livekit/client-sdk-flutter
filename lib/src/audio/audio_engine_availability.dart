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

import 'package:meta/meta.dart';

/// Whether the WebRTC audio engine is allowed to run, per direction.
///
/// This is the highest-priority gate over anything that may start the engine
/// (enabling the microphone, starting playback of remote audio). Requests
/// made while a direction is unavailable are not lost: the engine starts as
/// soon as availability allows.
///
/// Used to coordinate with platform call systems that own audio activation
/// timing, such as CallKit on iOS: keep the engine unavailable until
/// `provider(didActivate:)` and make it available inside the
/// activate/deactivate window. See `AudioManager.setEngineAvailability`.
///
/// Experimental: this API may change in a future release.
@experimental
class AudioEngineAvailability {
  /// Whether the engine may run its input (microphone / recording) side.
  final bool isInputAvailable;

  /// Whether the engine may run its output (playout / remote audio) side.
  final bool isOutputAvailable;

  const AudioEngineAvailability({
    required this.isInputAvailable,
    required this.isOutputAvailable,
  });

  /// Both input and output are available (the default).
  static const defaultAvailability = AudioEngineAvailability(isInputAvailable: true, isOutputAvailable: true);

  /// Neither input nor output is available. The engine will not run.
  static const none = AudioEngineAvailability(isInputAvailable: false, isOutputAvailable: false);

  @override
  bool operator ==(Object other) =>
      other is AudioEngineAvailability &&
      other.isInputAvailable == isInputAvailable &&
      other.isOutputAvailable == isOutputAvailable;

  @override
  int get hashCode => Object.hash(isInputAvailable, isOutputAvailable);

  @override
  String toString() =>
      'AudioEngineAvailability(isInputAvailable: $isInputAvailable, isOutputAvailable: $isOutputAvailable)';
}
