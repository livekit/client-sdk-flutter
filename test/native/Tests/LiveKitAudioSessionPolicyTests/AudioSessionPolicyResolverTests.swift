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

@testable import LiveKitAudioSessionPolicy
import XCTest

final class AudioSessionDecisionTests: XCTestCase {
    private func decision(
        resolvesByEngineState: Bool = true,
        isRecordingEnabled: Bool = false,
        hasRecorded: Bool = false,
        isPlatformVoiceProcessingExpected: Bool = true
    ) -> LKAudioSessionDecision {
        LKAudioSessionPolicyResolver.decision(
            resolvesByEngineState: resolvesByEngineState,
            isRecordingEnabled: isRecordingEnabled,
            hasRecorded: hasRecorded,
            isPlatformVoiceProcessingExpected: isPlatformVoiceProcessingExpected
        )
    }

    func testManualModeAlwaysAppliesThePushedConfiguration() {
        // Manual mode or an explicit Apple override: the app owns the session,
        // so no engine state may rewrite it.
        for isRecordingEnabled in [true, false] {
            for hasRecorded in [true, false] {
                for expectsPlatform in [true, false] {
                    XCTAssertEqual(
                        decision(
                            resolvesByEngineState: false,
                            isRecordingEnabled: isRecordingEnabled,
                            hasRecorded: hasRecorded,
                            isPlatformVoiceProcessingExpected: expectsPlatform
                        ),
                        .pushedVerbatim,
                        "recording=\(isRecordingEnabled) hasRecorded=\(hasRecorded) platform=\(expectsPlatform)"
                    )
                }
            }
        }
    }

    func testPlayoutOnlyBeforeAnyCaptureUsesThePlaybackPreset() {
        XCTAssertEqual(decision(isRecordingEnabled: false, hasRecorded: false), .playbackPreset)
        // The playback preset does not depend on the voice processing decision:
        // there is no capture to process.
        XCTAssertEqual(
            decision(isRecordingEnabled: false, hasRecorded: false, isPlatformVoiceProcessingExpected: false),
            .playbackPreset
        )
    }

    func testCaptureWithAppleVoiceProcessingKeepsTheChatMode() {
        // VPIO supplies the loudness stage that compensates for iOS's
        // call-tuned output gain, so the chat mode stays.
        XCTAssertEqual(
            decision(isRecordingEnabled: true, isPlatformVoiceProcessingExpected: true),
            .pushedVerbatim
        )
    }

    func testCaptureWithSoftwareVoiceProcessingDropsTheChatMode() {
        // No VPIO means nothing compensates for the reduced playback level, so
        // the session has to move to the media-tuned mode.
        XCTAssertEqual(
            decision(isRecordingEnabled: true, isPlatformVoiceProcessingExpected: false),
            .recordingMediaMode
        )
    }

    func testMutingKeepsTheCapturingSessionShape() {
        // Muting stops the engine's recording side but the call is still a
        // call: the category must not flip back to playback.
        XCTAssertEqual(
            decision(isRecordingEnabled: false, hasRecorded: true, isPlatformVoiceProcessingExpected: true),
            .pushedVerbatim
        )
        XCTAssertEqual(
            decision(isRecordingEnabled: false, hasRecorded: true, isPlatformVoiceProcessingExpected: false),
            .recordingMediaMode
        )
    }
}

final class StickyHasRecordedTests: XCTestCase {
    func testCaptureStartingMarksTheSessionAsRecorded() {
        XCTAssertTrue(
            LKAudioSessionPolicyResolver.stickyHasRecorded(
                previous: false, isPlayoutEnabled: true, isRecordingEnabled: true
            )
        )
    }

    func testMutingPreservesTheRecordedFlag() {
        // Microphone muted, remote playout continues: still in a call.
        XCTAssertTrue(
            LKAudioSessionPolicyResolver.stickyHasRecorded(
                previous: true, isPlayoutEnabled: true, isRecordingEnabled: false
            )
        )
    }

    func testEngineStoppingClearsTheRecordedFlag() {
        // Neither side running: the next engine starts a fresh session.
        XCTAssertFalse(
            LKAudioSessionPolicyResolver.stickyHasRecorded(
                previous: true, isPlayoutEnabled: false, isRecordingEnabled: false
            )
        )
    }

    func testPlayoutOnlyDoesNotInventARecordedFlag() {
        // A listener that never captured must not be pinned to playAndRecord.
        XCTAssertFalse(
            LKAudioSessionPolicyResolver.stickyHasRecorded(
                previous: false, isPlayoutEnabled: true, isRecordingEnabled: false
            )
        )
    }
}

final class VoiceProcessingSessionUpdateTests: XCTestCase {
    private func update(
        expectationChanged: Bool = true,
        isUpdatePending: Bool = false,
        isAutomaticManagementEnabled: Bool = true,
        isSessionActive: Bool = true
    ) -> LKVoiceProcessingSessionUpdate {
        LKAudioSessionPolicyResolver.voiceProcessingSessionUpdate(
            expectationChanged: expectationChanged,
            isUpdatePending: isUpdatePending,
            isAutomaticManagementEnabled: isAutomaticManagementEnabled,
            isSessionActive: isSessionActive
        )
    }

    func testAChangedExpectationConfiguresTheLiveSession() {
        XCTAssertEqual(update(), LKVoiceProcessingSessionUpdate(isPending: true, shouldApplyNow: true))
    }

    func testAnUnchangedExpectationWithNothingPendingDoesNothing() {
        XCTAssertEqual(
            update(expectationChanged: false),
            LKVoiceProcessingSessionUpdate(isPending: false, shouldApplyNow: false)
        )
    }

    func testManualModeRecordsTheExpectationWithoutTouchingTheSession() {
        // The app owns the session in manual mode. Reapplying LiveKit's cached
        // configuration from a capture start would overwrite what it set.
        let result = update(isAutomaticManagementEnabled: false)
        XCTAssertTrue(result.isPending)
        XCTAssertFalse(result.shouldApplyNow)
    }

    func testManualModeKeepsTheUpdatePendingForWhenItGoesBackToAutomatic() {
        let inManual = update(isAutomaticManagementEnabled: false)
        XCTAssertTrue(inManual.isPending)

        // Switching back to automatic: the expectation has not changed again,
        // but the session still has not been configured for it.
        let afterSwitch = update(expectationChanged: false, isUpdatePending: inManual.isPending)
        XCTAssertTrue(afterSwitch.shouldApplyNow)
    }

    func testNoLiveSessionDefersTheUpdate() {
        let result = update(isSessionActive: false)
        XCTAssertTrue(result.isPending)
        XCTAssertFalse(result.shouldApplyNow)
    }

    func testRepeatingARequestAfterAFailedConfigurationRetries() {
        // First attempt changes the expectation and tries to configure.
        let first = update()
        XCTAssertTrue(first.shouldApplyNow)

        // It failed, so the flag stays set. The retry passes the same value, so
        // nothing "changed" -- it must still reapply, or the caller would be
        // told the policy is in effect while playback is still on a chat mode.
        let retry = update(expectationChanged: false, isUpdatePending: true)
        XCTAssertTrue(retry.shouldApplyNow)
        XCTAssertTrue(retry.isPending)
    }

    func testAnUnchangedExpectationAfterASuccessfulConfigurationIsANoOp() {
        // Success clears the pending flag in the observer, so the next
        // identical request resolves to nothing.
        XCTAssertFalse(update(expectationChanged: false, isUpdatePending: false).shouldApplyNow)
    }
}

final class RequestsPlatformEchoNoisePathTests: XCTestCase {
    private func requests(
        echoCancellationEnabled: Bool = true,
        echoCancellationForcesSoftware: Bool = false,
        noiseSuppressionEnabled: Bool = true,
        noiseSuppressionForcesSoftware: Bool = false
    ) -> Bool {
        LKAudioSessionPolicyResolver.requestsPlatformEchoNoisePath(
            echoCancellationEnabled: echoCancellationEnabled,
            echoCancellationForcesSoftware: echoCancellationForcesSoftware,
            noiseSuppressionEnabled: noiseSuppressionEnabled,
            noiseSuppressionForcesSoftware: noiseSuppressionForcesSoftware
        )
    }

    func testDefaultCaptureOptionsRequestThePlatformPath() {
        XCTAssertTrue(requests())
    }

    func testForcingBothEchoAndNoiseToSoftwareGivesUpThePlatformPath() {
        XCTAssertFalse(
            requests(echoCancellationForcesSoftware: true, noiseSuppressionForcesSoftware: true)
        )
    }

    func testEitherComponentOnTheAutomaticModeKeepsThePlatformPath() {
        // AEC and NS are coupled through VPIO: one of them wanting the platform
        // path brings the whole unit along.
        XCTAssertTrue(requests(echoCancellationForcesSoftware: true))
        XCTAssertTrue(requests(noiseSuppressionForcesSoftware: true))
    }

    func testDisabledComponentsDoNotRequestThePlatformPath() {
        XCTAssertFalse(requests(echoCancellationEnabled: false, noiseSuppressionEnabled: false))
        // This is the bypassVoiceProcessing shape: everything off.
        XCTAssertFalse(
            requests(
                echoCancellationEnabled: false,
                echoCancellationForcesSoftware: false,
                noiseSuppressionEnabled: false,
                noiseSuppressionForcesSoftware: false
            )
        )
    }

    func testADisabledComponentDoesNotMaskAnEnabledOne() {
        XCTAssertTrue(requests(echoCancellationEnabled: false))
        XCTAssertTrue(requests(noiseSuppressionEnabled: false))
        XCTAssertFalse(requests(echoCancellationEnabled: false, noiseSuppressionForcesSoftware: true))
    }
}

/// Replays the reported sequence through both decisions, which is where the
/// regression actually lived: the session shape must not oscillate as the
/// microphone is muted and unmuted mid-call.
final class ReportedScenarioTests: XCTestCase {
    private struct Engine {
        var isPlayoutEnabled = false
        var isRecordingEnabled = false
        var hasRecorded = false

        mutating func update(playout: Bool, recording: Bool) {
            isPlayoutEnabled = playout
            isRecordingEnabled = recording
            hasRecorded = LKAudioSessionPolicyResolver.stickyHasRecorded(
                previous: hasRecorded,
                isPlayoutEnabled: playout,
                isRecordingEnabled: recording
            )
        }

        func decision(platformVoiceProcessing: Bool) -> LKAudioSessionDecision {
            LKAudioSessionPolicyResolver.decision(
                resolvesByEngineState: true,
                isRecordingEnabled: isRecordingEnabled,
                hasRecorded: hasRecorded,
                isPlatformVoiceProcessingExpected: platformVoiceProcessing
            )
        }
    }

    func testJoinMutedThenToggleWithAppleVoiceProcessing() {
        var engine = Engine()
        var observed: [LKAudioSessionDecision] = []

        engine.update(playout: true, recording: false) // join muted
        observed.append(engine.decision(platformVoiceProcessing: true))
        engine.update(playout: true, recording: true) // unmute
        observed.append(engine.decision(platformVoiceProcessing: true))
        engine.update(playout: true, recording: false) // mute
        observed.append(engine.decision(platformVoiceProcessing: true))
        engine.update(playout: true, recording: true) // unmute again
        observed.append(engine.decision(platformVoiceProcessing: true))

        // One transition into the call shape, then stable. Before the fix the
        // third entry was .playbackPreset again, which is what moved playback
        // back and forth between the media and call volume registers.
        XCTAssertEqual(observed, [.playbackPreset, .pushedVerbatim, .pushedVerbatim, .pushedVerbatim])
    }

    func testJoinMutedThenToggleWithSoftwareVoiceProcessing() {
        var engine = Engine()
        var observed: [LKAudioSessionDecision] = []

        engine.update(playout: true, recording: false)
        observed.append(engine.decision(platformVoiceProcessing: false))
        engine.update(playout: true, recording: true)
        observed.append(engine.decision(platformVoiceProcessing: false))
        engine.update(playout: true, recording: false)
        observed.append(engine.decision(platformVoiceProcessing: false))

        // Media loudness throughout: the playback preset and the media-mode
        // recording shape both sit on the media volume register.
        XCTAssertEqual(observed, [.playbackPreset, .recordingMediaMode, .recordingMediaMode])
    }

    func testLeavingAndRejoiningStartsFromThePlaybackPreset() {
        var engine = Engine()
        engine.update(playout: true, recording: true) // in a call, capturing
        engine.update(playout: false, recording: false) // left, engine stopped
        XCTAssertFalse(engine.hasRecorded)

        engine.update(playout: true, recording: false) // rejoin muted
        XCTAssertEqual(engine.decision(platformVoiceProcessing: true), .playbackPreset)
    }
}
