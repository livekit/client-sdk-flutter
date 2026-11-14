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

// Exhaustive and randomized coverage of the audio-session policy.
//
// The example-based tests next door pin down the cases we reasoned about. The
// bugs that actually shipped in review were in the bookkeeping *between* those
// calls -- state committed before the operation that justified it, a failure
// that left the flag in a state where the retry did nothing. So this file
// drives the same decisions as a state machine over long random sequences and
// asserts invariants that must hold at every step, rather than checking
// individual answers.

@testable import LiveKitAudioSessionPolicy
import XCTest

/// Reproducible generator: a failing seed is replayable from the message.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407 }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

/// Mirrors the observer's state and the order it mutates it in, so the model
/// and the shipped code can diverge only in the parts that touch AVAudioSession.
private struct ObserverModel {
    var isPlayoutEnabled = false
    var isRecordingEnabled = false
    var hasRecorded = false
    var isPlatformVoiceProcessingExpected = true
    var needsVoiceProcessingSessionUpdate = false
    var isAutomaticManagementEnabled = true

    var sessionActive: Bool { isPlayoutEnabled || isRecordingEnabled }

    var decision: LKAudioSessionDecision {
        LKAudioSessionPolicyResolver.decision(
            resolvesByEngineState: true,
            isRecordingEnabled: isRecordingEnabled,
            hasRecorded: hasRecorded,
            isPlatformVoiceProcessingExpected: isPlatformVoiceProcessingExpected
        )
    }

    /// `recordEngineState` plus the engine-lifecycle configuration that follows.
    mutating func engineTransition(playout: Bool, recording: Bool, applySucceeds: Bool) {
        let appliedExpectation = isPlatformVoiceProcessingExpected
        isPlayoutEnabled = playout
        isRecordingEnabled = recording
        hasRecorded = LKAudioSessionPolicyResolver.stickyHasRecorded(
            previous: hasRecorded, isPlayoutEnabled: playout, isRecordingEnabled: recording
        )
        guard isAutomaticManagementEnabled, sessionActive, applySucceeds else { return }
        if isPlatformVoiceProcessingExpected == appliedExpectation {
            needsVoiceProcessingSessionUpdate = false
        }
    }

    /// `setPlatformVoiceProcessingExpected`. Returns whether it configured.
    @discardableResult
    mutating func setExpected(_ expected: Bool, applySucceeds: Bool) -> Bool {
        let update = LKAudioSessionPolicyResolver.voiceProcessingSessionUpdate(
            expectationChanged: isPlatformVoiceProcessingExpected != expected,
            isUpdatePending: needsVoiceProcessingSessionUpdate,
            isAutomaticManagementEnabled: isAutomaticManagementEnabled,
            isSessionActive: sessionActive
        )
        isPlatformVoiceProcessingExpected = expected
        needsVoiceProcessingSessionUpdate = update.isPending
        guard update.shouldApplyNow else { return false }
        guard applySucceeds else { return true }
        if isPlatformVoiceProcessingExpected == expected {
            needsVoiceProcessingSessionUpdate = false
        }
        return true
    }
}

final class AudioSessionPolicyExhaustiveTests: XCTestCase {
    private let bools = [true, false]

    func testEveryDecisionInputCombinationHoldsItsInvariants() {
        for resolvesByEngineState in bools {
            for isRecordingEnabled in bools {
                for hasRecorded in bools {
                    for expectsPlatform in bools {
                        let decision = LKAudioSessionPolicyResolver.decision(
                            resolvesByEngineState: resolvesByEngineState,
                            isRecordingEnabled: isRecordingEnabled,
                            hasRecorded: hasRecorded,
                            isPlatformVoiceProcessingExpected: expectsPlatform
                        )
                        let context = "engineState=\(resolvesByEngineState) recording=\(isRecordingEnabled) "
                            + "hasRecorded=\(hasRecorded) platform=\(expectsPlatform)"

                        if !resolvesByEngineState {
                            XCTAssertEqual(decision, .pushedVerbatim, "app-owned session must be verbatim: \(context)")
                            continue
                        }
                        // A session that has captured never drops back to the
                        // playback preset: that flip is what moved playback
                        // between the volume registers on every mute.
                        if isRecordingEnabled || hasRecorded {
                            XCTAssertNotEqual(decision, .playbackPreset, "capturing session must not use playback: \(context)")
                        } else {
                            XCTAssertEqual(decision, .playbackPreset, "listener must use playback: \(context)")
                        }
                        // The media mode exists only to replace a chat mode that
                        // has no VPIO behind it.
                        if decision == .recordingMediaMode {
                            XCTAssertFalse(expectsPlatform, "media mode with VPIO expected: \(context)")
                        }
                    }
                }
            }
        }
    }

    func testEveryStickyRecordingInputCombinationHoldsItsInvariants() {
        for previous in bools {
            for playout in bools {
                for recording in bools {
                    let result = LKAudioSessionPolicyResolver.stickyHasRecorded(
                        previous: previous, isPlayoutEnabled: playout, isRecordingEnabled: recording
                    )
                    let context = "previous=\(previous) playout=\(playout) recording=\(recording)"
                    if recording {
                        XCTAssertTrue(result, "capture must mark the session recorded: \(context)")
                    } else if !playout {
                        XCTAssertFalse(result, "a stopped engine must reset: \(context)")
                    } else {
                        XCTAssertEqual(result, previous, "a muted call must hold its state: \(context)")
                    }
                }
            }
        }
    }

    func testEverySessionUpdateInputCombinationHoldsItsInvariants() {
        for expectationChanged in bools {
            for isUpdatePending in bools {
                for automatic in bools {
                    for active in bools {
                        let update = LKAudioSessionPolicyResolver.voiceProcessingSessionUpdate(
                            expectationChanged: expectationChanged,
                            isUpdatePending: isUpdatePending,
                            isAutomaticManagementEnabled: automatic,
                            isSessionActive: active
                        )
                        let context = "changed=\(expectationChanged) pending=\(isUpdatePending) "
                            + "automatic=\(automatic) active=\(active)"

                        if update.shouldApplyNow {
                            XCTAssertTrue(automatic, "manual mode must never reconfigure: \(context)")
                            XCTAssertTrue(active, "no session to configure: \(context)")
                            XCTAssertTrue(update.isPending, "applying something not pending: \(context)")
                        }
                        // Work is never dropped: anything outstanding stays
                        // outstanding until a configuration succeeds.
                        if expectationChanged || isUpdatePending {
                            XCTAssertTrue(update.isPending, "pending work was lost: \(context)")
                        }
                    }
                }
            }
        }
    }

    func testOnlyAnAppliedRequestMovesTheExpectation() {
        for outcome in LKAudioProcessingRequestOutcome.allCases {
            XCTAssertEqual(
                LKAudioSessionPolicyResolver.commitsExpectation(for: outcome),
                outcome == .applied,
                "outcome \(outcome) must not move the session unless it governs the engine"
            )
        }
    }
}

final class AudioSessionPolicyStressTests: XCTestCase {
    /// Drives the model through long random operation sequences, asserting the
    /// invariants that the review bugs violated.
    func testRandomOperationSequencesHoldTheirInvariants() {
        for seed in UInt64(1) ... 200 {
            var rng = SeededGenerator(seed: seed)
            var model = ObserverModel()
            var history: [String] = []

            for _ in 0 ..< 60 {
                switch Int.random(in: 0 ..< 4, using: &rng) {
                case 0:
                    let playout = Bool.random(using: &rng)
                    let recording = Bool.random(using: &rng)
                    let succeeds = Int.random(in: 0 ..< 10, using: &rng) != 0
                    history.append("engine(playout:\(playout) recording:\(recording) ok:\(succeeds))")
                    model.engineTransition(playout: playout, recording: recording, applySucceeds: succeeds)
                case 1:
                    let expected = Bool.random(using: &rng)
                    let succeeds = Int.random(in: 0 ..< 3, using: &rng) != 0
                    history.append("setExpected(\(expected) ok:\(succeeds))")
                    let configured = model.setExpected(expected, applySucceeds: succeeds)
                    // Manual mode must never reach the session.
                    if !model.isAutomaticManagementEnabled {
                        XCTAssertFalse(configured, "manual mode configured the session\n\(history.joined(separator: "\n"))")
                    }
                    // A failed configuration must leave the work outstanding,
                    // or an identical retry would report success against a
                    // session still in the old mode.
                    if configured, !succeeds {
                        XCTAssertTrue(
                            model.needsVoiceProcessingSessionUpdate,
                            "failed configuration cleared the pending flag\n\(history.joined(separator: "\n"))"
                        )
                    }
                case 2:
                    let automatic = Bool.random(using: &rng)
                    history.append("management(automatic:\(automatic))")
                    model.isAutomaticManagementEnabled = automatic
                default:
                    history.append("decision=\(model.decision)")
                }

                let trace = history.joined(separator: "\n")
                // A session that has captured never falls back to the playback
                // preset while the engine is alive.
                if model.hasRecorded {
                    XCTAssertNotEqual(model.decision, .playbackPreset, "seed \(seed)\n\(trace)")
                }
                // The media mode is only ever chosen without VPIO behind it.
                if model.decision == .recordingMediaMode {
                    XCTAssertFalse(model.isPlatformVoiceProcessingExpected, "seed \(seed)\n\(trace)")
                }
                // A stopped engine always resets, so the next call starts clean.
                if !model.isPlayoutEnabled, !model.isRecordingEnabled {
                    XCTAssertFalse(model.hasRecorded, "seed \(seed)\n\(trace)")
                }
            }
        }
    }

    /// The specific sequence behind the review bug, as a regression guard:
    /// disallow, fail to configure, then repeat the identical request.
    func testRetryAfterAFailedConfigurationReachesTheSession() {
        var model = ObserverModel()
        model.engineTransition(playout: true, recording: true, applySucceeds: true)

        XCTAssertTrue(model.setExpected(false, applySucceeds: false), "first attempt should configure")
        XCTAssertTrue(model.needsVoiceProcessingSessionUpdate, "the failure must stay outstanding")

        XCTAssertTrue(model.setExpected(false, applySucceeds: true), "the identical retry must reconfigure")
        XCTAssertFalse(model.needsVoiceProcessingSessionUpdate, "success must settle it")

        XCTAssertFalse(model.setExpected(false, applySucceeds: true), "a settled expectation is a no-op")
    }

    /// Work deferred by manual mode is not lost: it applies when LiveKit takes
    /// the session back.
    func testManualModeDefersRatherThanDropsTheUpdate() {
        var model = ObserverModel()
        model.engineTransition(playout: true, recording: true, applySucceeds: true)
        model.isAutomaticManagementEnabled = false

        XCTAssertFalse(model.setExpected(false, applySucceeds: true), "manual mode must not configure")
        XCTAssertTrue(model.needsVoiceProcessingSessionUpdate, "the update must survive manual mode")

        model.isAutomaticManagementEnabled = true
        XCTAssertTrue(model.setExpected(false, applySucceeds: true), "returning to automatic must apply it")
        XCTAssertFalse(model.needsVoiceProcessingSessionUpdate)
    }

    /// The reported user journey, end to end, asserting the volume register
    /// implied by each decision rather than the decision alone.
    func testReportedJourneyNeverReturnsToTheCallRegisterOnceOptedOut() {
        var model = ObserverModel()
        func register() -> String {
            switch model.decision {
            case .playbackPreset: return "media"
            case .recordingMediaMode: return "media"
            case .pushedVerbatim: return model.hasRecorded || model.isRecordingEnabled ? "call" : "media"
            }
        }

        model.engineTransition(playout: true, recording: false, applySucceeds: true) // join muted
        XCTAssertEqual(register(), "media")
        model.engineTransition(playout: true, recording: true, applySucceeds: true) // unmute
        XCTAssertEqual(register(), "call")

        model.setExpected(false, applySucceeds: true) // opt out of VPIO
        XCTAssertEqual(register(), "media")

        // Muting, unmuting and a route-driven reconfigure must all stay media.
        model.engineTransition(playout: true, recording: false, applySucceeds: true)
        XCTAssertEqual(register(), "media")
        model.engineTransition(playout: true, recording: true, applySucceeds: true)
        XCTAssertEqual(register(), "media")
        model.setExpected(false, applySucceeds: true)
        XCTAssertEqual(register(), "media")
    }
}
