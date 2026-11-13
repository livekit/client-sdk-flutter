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

import Foundation

/// Which audio-session shape to apply for a given engine state.
///
/// The values carry no `AVAudioSession` types on purpose: `AVAudioSession` does
/// not exist on macOS, and keeping the decision free of platform types is what
/// lets `test/native/` unit test it. `LKAudioEngineObserver` maps each case onto
/// a concrete `RTCAudioSessionConfiguration`.
enum LKAudioSessionDecision: Equatable {
    /// Apply the configuration pushed from Dart verbatim. Either the app owns
    /// the session (manual mode / an explicit per-platform override), or the
    /// pushed playAndRecord policy is already correct for this engine state.
    case pushedVerbatim

    /// Playout without capture: playback + spokenAudio + mixWithOthers.
    /// Flipping only the category would leave playAndRecord-only mode/options
    /// (videoChat, allowBluetooth) that are invalid for the playback category.
    case playbackPreset

    /// Capture that does not run through Apple's Voice Processing I/O: the
    /// pushed category and options, with the chat mode replaced by `default`.
    ///
    /// Apple documents that a session using a chat mode without Voice
    /// Processing I/O gets reduced processing and "a lower playback level",
    /// which VPIO would otherwise compensate for. Software voice processing has
    /// no such stage, so the chat mode must go.
    case recordingMediaMode
}

/// What to do with a voice-processing expectation change: whether the session
/// still needs reconfiguring for it, and whether that can happen right now.
struct LKVoiceProcessingSessionUpdate: Equatable {
    /// The session does not yet reflect the expectation. Sticky until a
    /// configuration actually succeeds, so a repeated request after a failed
    /// one reapplies instead of reporting success against a stale session.
    let isPending: Bool

    /// Apply the configuration now. False in manual mode, where the app owns
    /// the session, and while no session is live to configure.
    let shouldApplyNow: Bool
}

/// Pure policy decisions shared by the audio-engine observer. Kept free of
/// Flutter, WebRTC and AVFoundation so the state matrix can be tested directly.
enum LKAudioSessionPolicyResolver {
    /// Resolves the session shape for an engine state.
    ///
    /// - Parameters:
    ///   - resolvesByEngineState: false for manual mode or an explicit Apple
    ///     override, where the pushed configuration is authoritative.
    ///   - hasRecorded: sticky recording state for the current engine, see
    ///     ``stickyHasRecorded(previous:isPlayoutEnabled:isRecordingEnabled:)``.
    ///   - isPlatformVoiceProcessingExpected: whether the capture resolves to
    ///     Apple Voice Processing I/O.
    static func decision(
        resolvesByEngineState: Bool,
        isRecordingEnabled: Bool,
        hasRecorded: Bool,
        isPlatformVoiceProcessingExpected: Bool
    ) -> LKAudioSessionDecision {
        guard resolvesByEngineState else { return .pushedVerbatim }
        guard isRecordingEnabled || hasRecorded else { return .playbackPreset }
        return isPlatformVoiceProcessingExpected ? .pushedVerbatim : .recordingMediaMode
    }

    /// Whether the session should still be treated as a capturing session.
    ///
    /// Sticky from the first capture until the engine stops entirely, so muting
    /// the microphone does not flip the category back to playback. A
    /// mid-session category change tears down Apple's Voice Processing I/O, and
    /// it also moved playback between iOS's media and call volume registers on
    /// every mute toggle.
    static func stickyHasRecorded(
        previous: Bool,
        isPlayoutEnabled: Bool,
        isRecordingEnabled: Bool
    ) -> Bool {
        if isRecordingEnabled { return true }
        // Playout alone keeps the call alive (microphone muted); losing playout
        // too means the engine stopped and the next one starts fresh.
        if !isPlayoutEnabled { return false }
        return previous
    }

    /// Resolves a voice-processing expectation change into session work.
    ///
    /// `isUpdatePending` carries the outcome of previous attempts: tracking
    /// "does the session still need this?" rather than "did the expectation
    /// just change?" is what makes a retry after a failed configuration retry.
    /// Rolling the expectation back instead would be wrong, since the audio
    /// device module policy may already have changed.
    ///
    /// Manual mode records the expectation but never touches the session: the
    /// app owns it there, and reapplying LiveKit's cached configuration from a
    /// capture start would overwrite what the app configured.
    static func voiceProcessingSessionUpdate(
        expectationChanged: Bool,
        isUpdatePending: Bool,
        isAutomaticManagementEnabled: Bool,
        isSessionActive: Bool
    ) -> LKVoiceProcessingSessionUpdate {
        let isPending = isUpdatePending || expectationChanged
        return LKVoiceProcessingSessionUpdate(
            isPending: isPending,
            shouldApplyNow: isPending && isAutomaticManagementEnabled && isSessionActive
        )
    }

    /// Whether capture options resolve to Apple's Voice Processing I/O.
    ///
    /// AEC and NS are coupled through VPIO, so either one that is enabled and
    /// not forced to software keeps the platform path. Mirrors the Swift SDK's
    /// `AudioProcessingOptions.requestsPlatformEchoNoisePath`.
    static func requestsPlatformEchoNoisePath(
        echoCancellationEnabled: Bool,
        echoCancellationForcesSoftware: Bool,
        noiseSuppressionEnabled: Bool,
        noiseSuppressionForcesSoftware: Bool
    ) -> Bool {
        (echoCancellationEnabled && !echoCancellationForcesSoftware)
            || (noiseSuppressionEnabled && !noiseSuppressionForcesSoftware)
    }
}
