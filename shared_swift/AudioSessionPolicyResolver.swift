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

/// Outcome of a runtime audio-processing request, mirroring
/// `RTCAudioProcessingOptionsResultCode` without the WebRTC dependency.
enum LKAudioProcessingRequestOutcome: Equatable, CaseIterable {
    /// Applied immediately by the component handling the request: these options
    /// govern the shared engine now.
    case applied
    /// Accepted and stored. Whichever sender is active reapplies them later, so
    /// they do not govern the engine yet.
    case stored
    /// Refused. The previous processing stays in effect.
    case rejected
}

/// The two audio device module callbacks that move the observer's engine
/// bookkeeping.
enum LKEngineLifecycleEvent: Equatable, CaseIterable {
    /// A setup hook. A non-zero result rolls the engine operation back, and no
    /// compensating call follows.
    case willEnable
    /// A teardown hook. The engine has already changed when it fires, and a
    /// non-zero result is only logged. Also delivered as compensation after a
    /// rolled back enable, carrying the state from before that enable.
    case didDisable
}

/// The outcome of applying a configuration for the plugin's activation.
struct LKActivationSettlement: Equatable {
    /// The apply took an activation on top of the one already held, and that
    /// extra one has to be given back.
    let givesOneBack: Bool
    /// Whether the plugin holds its activation afterwards.
    let holdsActivation: Bool
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

    /// Whether an engine lifecycle callback records its engine state, given
    /// whether the session work it did succeeded.
    ///
    /// This follows the audio device module's observer contract (WebRTC
    /// 150.7871.08). A failed `willEnable` rolls the operation back and gets no
    /// `didDisable` afterwards, so it must not record anything. A `didDisable`
    /// cannot fail the operation: the engine is disabled whatever it returns.
    /// Keeping the earlier state after a failed session update would leave the
    /// observer believing in an engine that is gone (a stale `hasRecorded`, and
    /// policy changes applied to an idle session), which is the state a
    /// failed deactivation used to leave behind.
    static func recordsEngineState(after event: LKEngineLifecycleEvent, sessionUpdateSucceeded: Bool) -> Bool {
        switch event {
        case .willEnable: return sessionUpdateSucceeded
        case .didDisable: return true
        }
    }

    // MARK: Activation

    // RTCAudioSession counts every activation and releases the session only
    // when the last one is given back, and it decrements on every
    // deactivation, also below zero. So the plugin holds at most one
    // activation, and gives back exactly what it took.

    /// Whether applying a configuration also asks to activate the session.
    ///
    /// It does when the plugin holds no activation yet. It also does when it
    /// holds one for a session that went inactive, as during an interruption:
    /// waiting for the interruption end is not enough, it can fail to
    /// reactivate or never arrive.
    static func requestsActivation(ownsActivation: Bool, holdsActivation: Bool, isSessionActive: Bool) -> Bool {
        guard ownsActivation else { return false }
        return !holdsActivation || !isSessionActive
    }

    /// What follows an apply, from the activation count before and after it.
    ///
    /// An activation that was taken while one was already held and counted is
    /// given back, which leaves the session active and the count unchanged.
    /// The held activation is never given up first: when the attempt takes
    /// none, the one already held stays, for the interruption end or the full
    /// stop to use.
    static func settleActivation(heldBefore: Bool,
                                 activationsBefore: Int,
                                 activationsAfter: Int) -> LKActivationSettlement
    {
        guard activationsAfter > activationsBefore else {
            return LKActivationSettlement(givesOneBack: false, holdsActivation: heldBefore)
        }
        return LKActivationSettlement(givesOneBack: heldBefore && activationsBefore >= 1, holdsActivation: true)
    }

    /// Whether a full stop gives an activation back: only one the plugin
    /// holds. Giving back more would take the count below zero, and the next
    /// call would then end without releasing the session.
    static func givesActivationBackAtFullStop(holdsActivation: Bool) -> Bool {
        holdsActivation
    }

    /// Whether an explicit deactivation from the app reaches the session: when
    /// the plugin holds an activation, or someone else's is counted.
    static func forwardsExplicitDeactivation(holdsActivation: Bool, activations: Int) -> Bool {
        holdsActivation || activations > 0
    }

    /// Whether a runtime processing request should move the session's voice
    /// processing expectation.
    ///
    /// Only once the request governs the shared engine. A rejected request
    /// leaves the previous processing running (and the caller keeps its previous
    /// options), and a stored one has not taken effect yet, so moving the
    /// session mode for either would point playback at a processing path that
    /// is not running.
    static func commitsExpectation(for outcome: LKAudioProcessingRequestOutcome) -> Bool {
        outcome == .applied
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
    /// AEC and NS are coupled through VPIO, and the audio device module only
    /// creates the unit when both can run on it. A component that is disabled
    /// or forced to software keeps the whole path off, because the unit cannot
    /// run one effect without the other. So the platform path needs both
    /// components enabled and neither forced to software.
    ///
    /// This has to match the coupled resolution in the audio device module.
    /// Expecting VPIO when the module leaves it off puts the session on a chat
    /// mode with nothing to compensate its reduced playback level.
    static func requestsPlatformEchoNoisePath(
        echoCancellationEnabled: Bool,
        echoCancellationForcesSoftware: Bool,
        noiseSuppressionEnabled: Bool,
        noiseSuppressionForcesSoftware: Bool
    ) -> Bool {
        echoCancellationEnabled && !echoCancellationForcesSoftware
            && noiseSuppressionEnabled && !noiseSuppressionForcesSoftware
    }
}
