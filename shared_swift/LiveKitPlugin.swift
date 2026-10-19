/*
 * Copyright 2025 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import AVFoundation
import flutter_webrtc
import WebRTC

#if os(macOS)
import Cocoa
import FlutterMacOS
#else
import Combine
import Flutter
import UIKit
#endif

let trackIdKey = "trackId"
let visualizerIdKey = "visualizerId"
let rendererIdKey = "rendererId"
let formatKey = "format"

let commonFormatKey = "commonFormat"
let sampleRateKey = "sampleRate"
let channelsKey = "channels"

class AudioProcessors {
    var track: AudioTrack
    var visualizers: [String: Visualizer] = [:]
    var renderers: [String: AudioRenderer] = [:]

    init(track: AudioTrack) {
        self.track = track
    }
}

@available(iOS 13.0, *)
public class LiveKitPlugin: NSObject, FlutterPlugin {
    // TrackId: AudioProcessors
    var audioProcessors: [String: AudioProcessors] = [:]

    var binaryMessenger: FlutterBinaryMessenger?

    // Retained strong reference to the audio-engine delegate. flutter_webrtc and
    // the audio device module both hold it weakly, so LiveKit must keep it alive.
    var channel: FlutterMethodChannel?
    var audioEngineObserver: LKAudioEngineObserver?
    // Process-wide engine observer, kept across plugin registrations so a
    // second Flutter engine does not wipe the pushed policy / management mode.
    private static var sharedAudioEngineObserver: LKAudioEngineObserver?

    #if os(iOS)
    var cancellable = Set<AnyCancellable>()
    #endif

    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(macOS)
        let messenger = registrar.messenger
        #else
        let messenger = registrar.messenger()
        #endif

        let channel = FlutterMethodChannel(name: "livekit_client", binaryMessenger: messenger)
        let instance = LiveKitPlugin()
        instance.binaryMessenger = messenger
        registrar.addMethodCallDelegate(instance, channel: channel)

        // LiveKit owns the platform audio session, so disable flutter_webrtc's
        // own native audio management. Set at registration, before any audio op.
        FlutterWebRTCPlugin.setAudioSessionManagementEnabled(false)

        // Own the audio device module's engine-lifecycle delegate so LiveKit
        // drives the audio session from real engine events (configure + activate
        // on enable, deactivate on disable) instead of track counting. The
        // engine emits these events on both iOS and macOS. macOS has no
        // AVAudioSession to configure, so there it only surfaces engine state.
        // Set before the peer connection factory is created.
        //
        // The observer is shared across plugin registrations: its state (the
        // pushed policy and management mode) describes the process-wide audio
        // session, so a later registration (e.g. a second Flutter engine in
        // the same process) must not reset it. Only the notification channel
        // is rebound to the latest registration.
        instance.channel = channel
        let audioEngineObserver = sharedAudioEngineObserver ?? LKAudioEngineObserver(channel: channel)
        audioEngineObserver.updateChannel(channel)
        sharedAudioEngineObserver = audioEngineObserver
        instance.audioEngineObserver = audioEngineObserver
        FlutterWebRTCPlugin.setAudioDeviceModuleObserver(audioEngineObserver)

        // An AppDelegate may have gated engine availability before the Flutter
        // engine existed (CallKit killed-state wake). Apply it now, before any
        // audio operation can start the engine. This must run after the engine
        // observer above, since applying forces creation of the peer
        // connection factory, which attaches the observer.
        applyPendingEngineAvailabilityIfNeeded()

        #if os(iOS)
        BroadcastManager.shared.isBroadcastingPublisher
            .sink { isBroadcasting in
                channel.invokeMethod("broadcastStateChanged", arguments: isBroadcasting)
            }
            .store(in: &instance.cancellable)
        #endif
    }

    #if !os(macOS)
    // https://developer.apple.com/documentation/avfaudio/avaudiosession/category
    let categoryMap: [String: AVAudioSession.Category] = [
        "ambient": .ambient,
        "multiRoute": .multiRoute,
        "playAndRecord": .playAndRecord,
        "playback": .playback,
        "record": .record,
        "soloAmbient": .soloAmbient,
    ]

    // https://developer.apple.com/documentation/avfaudio/avaudiosession/categoryoptions
    let categoryOptionsMap: [String: AVAudioSession.CategoryOptions] = [
        "mixWithOthers": .mixWithOthers,
        "duckOthers": .duckOthers,
        "interruptSpokenAudioAndMixWithOthers": .interruptSpokenAudioAndMixWithOthers,
        "allowBluetooth": .allowBluetooth,
        "allowBluetoothA2DP": .allowBluetoothA2DP,
        "allowAirPlay": .allowAirPlay,
        "defaultToSpeaker": .defaultToSpeaker,
        //        @available(iOS 14.5, *)
        //        "overrideMutedMicrophoneInterruption": .overrideMutedMicrophoneInterruption,
    ]

    // https://developer.apple.com/documentation/avfaudio/avaudiosession/mode
    let modeMap: [String: AVAudioSession.Mode] = [
        "default": .default,
        "gameChat": .gameChat,
        "measurement": .measurement,
        "moviePlayback": .moviePlayback,
        "spokenAudio": .spokenAudio,
        "videoChat": .videoChat,
        "videoRecording": .videoRecording,
        "voiceChat": .voiceChat,
        "voicePrompt": .voicePrompt,
    ]

    private func categoryOptions(fromFlutter options: [String]) -> AVAudioSession.CategoryOptions {
        var result: AVAudioSession.CategoryOptions = []
        for option in categoryOptionsMap {
            if options.contains(option.key) {
                result.insert(option.value)
            }
        }
        return result
    }
    #endif

    private func audioProcessors(for trackId: String) -> AudioProcessors? {
        if let existing = audioProcessors[trackId] {
            return existing
        }

        let webrtc = FlutterWebRTCPlugin.sharedSingleton()

        var audioTrack: AudioTrack?
        if let track = webrtc?.localTracks![trackId] as? LocalAudioTrack {
            audioTrack = LKLocalAudioTrack(name: trackId, track: track)
        } else if let track = webrtc?.remoteTrack(forId: trackId) as? RTCAudioTrack {
            audioTrack = LKRemoteAudioTrack(name: trackId, track: track)
        }

        guard let audioTrack else {
            return nil
        }

        let processor = AudioProcessors(track: audioTrack)
        audioProcessors[trackId] = processor
        return processor
    }

    public func handleStartAudioVisualizer(args: [String: Any?], result: @escaping FlutterResult) {
        // Required params
        let trackId = args[trackIdKey] as? String
        let visualizerId = args[visualizerIdKey] as? String

        guard let trackId else {
            result(FlutterError(code: trackIdKey, message: "\(trackIdKey) is required", details: nil))
            return
        }

        guard let visualizerId else {
            result(FlutterError(code: visualizerIdKey, message: "\(visualizerIdKey) is required", details: nil))
            return
        }

        // Optional params
        let barCount = args["barCount"] as? Int ?? 7
        let isCentered = args["isCentered"] as? Bool ?? true
        let smoothTransition = args["smoothTransition"] as? Bool ?? true

        guard let processors = audioProcessors(for: trackId) else {
            result(FlutterError(code: trackIdKey, message: "No such track", details: nil))
            return
        }

        // Already exists
        if processors.visualizers[visualizerId] != nil {
            result(true)
            return
        }

        let visualizer = Visualizer(track: processors.track,
                                    binaryMessenger: binaryMessenger!,
                                    bandCount: barCount,
                                    isCentered: isCentered,
                                    smoothTransition: smoothTransition,
                                    visualizerId: visualizerId)
        // Retain
        processors.visualizers[visualizerId] = visualizer

        result(true)
    }

    public func handleStopAudioVisualizer(args: [String: Any?], result: @escaping FlutterResult) {
        // let trackId = args["trackId"] as? String
        let visualizerId = args[visualizerIdKey] as? String

        guard let visualizerId else {
            result(FlutterError(code: visualizerIdKey, message: "\(visualizerIdKey) is required", details: nil))
            return
        }

        for processors in audioProcessors.values {
            processors.visualizers[visualizerId]?.stop()
            processors.visualizers.removeValue(forKey: visualizerId)
        }

        result(true)
    }

    public func parseAudioFormat(args: [String: Any?]) -> AVAudioFormat? {
        guard let commonFormatString = args[commonFormatKey] as? String,
              let sampleRate = args[sampleRateKey] as? Int,
              let channels = args[channelsKey] as? Int
        else {
            return nil
        }

        let commonFormat: AVAudioCommonFormat
        switch commonFormatString {
        case "float32":
            commonFormat = .pcmFormatFloat32
        case "int16":
            commonFormat = .pcmFormatInt16
        default:
            return nil
        }

        return AVAudioFormat(commonFormat: commonFormat,
                             sampleRate: Double(sampleRate),
                             channels: AVAudioChannelCount(channels),
                             interleaved: false)
    }

    public func handleStartAudioRenderer(args: [String: Any?], result: @escaping FlutterResult) {
        // Required params
        let trackId = args[trackIdKey] as? String
        let rendererId = args[rendererIdKey] as? String

        let formatMap = args[formatKey] as? [String: Any?]

        guard let formatMap else {
            result(FlutterError(code: formatKey, message: "\(formatKey) is required", details: nil))
            return
        }

        guard let format = parseAudioFormat(args: formatMap) else {
            result(FlutterError(code: formatKey, message: "Failed to parse format", details: nil))
            return
        }

        guard let trackId else {
            result(FlutterError(code: trackIdKey, message: "\(trackIdKey) is required", details: nil))
            return
        }

        guard let rendererId else {
            result(FlutterError(code: rendererIdKey, message: "\(rendererIdKey) is required", details: nil))
            return
        }

        guard let processors = audioProcessors(for: trackId) else {
            result(FlutterError(code: trackIdKey, message: "No such track", details: nil))
            return
        }

        // Already exists
        if processors.renderers[rendererId] != nil {
            result(true)
            return
        }

        let renderer = AudioRenderer(track: processors.track,
                                     binaryMessenger: binaryMessenger!,
                                     rendererId: rendererId,
                                     format: format)
        // Retain
        processors.renderers[rendererId] = renderer

        result(true)
    }

    public func handleStopAudioRenderer(args: [String: Any?], result: @escaping FlutterResult) {
        let rendererId = args[rendererIdKey] as? String

        guard let rendererId else {
            result(FlutterError(code: rendererIdKey, message: "\(rendererIdKey) is required", details: nil))
            return
        }

        for processors in audioProcessors.values {
            if let renderer = processors.renderers[rendererId] {
                renderer.detach()
                processors.renderers.removeValue(forKey: rendererId)
            }
        }

        result(true)
    }

    public func handleConfigureNativeAudio(args: [String: Any?], result: @escaping FlutterResult) {
        #if os(macOS)
        result(FlutterMethodNotImplemented)
        #else

        let configuration = RTCAudioSessionConfiguration.webRTC()

        // Category
        if let string = args["appleAudioCategory"] as? String,
           let category = categoryMap[string]
        {
            configuration.category = category.rawValue
        }

        // CategoryOptions
        if let strings = args["appleAudioCategoryOptions"] as? [String] {
            configuration.categoryOptions = categoryOptions(fromFlutter: strings)
        }

        // Mode
        if let string = args["appleAudioMode"] as? String,
           let mode = modeMap[string]
        {
            configuration.mode = mode.rawValue
        }

        // Cache the policy so the audio-engine delegate can (re)apply it on
        // engine lifecycle events. In automatic mode the delegate owns
        // activation timing (configure + activate on engine enable), so here we
        // only apply immediately if the engine is already running. Manual mode
        // (or no `automatic` flag) applies immediately.
        let automatic = args["automatic"] as? Bool ?? false
        let selectCategoryByEngineState = args["selectCategoryByEngineState"] as? Bool ?? false
        let forceSpeakerOutput = args["forceSpeakerOutput"] as? Bool ?? false
        audioEngineObserver?.updatePolicy(configuration,
                                          automaticManagementEnabled: automatic,
                                          selectCategoryByEngineState: selectCategoryByEngineState,
                                          forceSpeakerOutput: forceSpeakerOutput)

        let shouldApplyNow = !automatic || (audioEngineObserver?.isSessionActive ?? false)
        guard shouldApplyNow else {
            result(true)
            return
        }

        // Apply through the observer so the category is resolved from the live
        // engine state (when category selection is enabled), matching what the
        // engine-lifecycle callbacks would apply.
        if let error = audioEngineObserver?.applyCachedConfiguration() {
            print("[LiveKit] Configure audio error: ", error)
            result(FlutterError(code: "configure", message: error.localizedDescription, details: nil))
        } else {
            result(true)
        }
        #endif
    }

    public func handleSetAppleAudioSessionAutomaticManagementEnabled(args: [String: Any?], result: @escaping FlutterResult) {
        #if os(macOS)
        result(FlutterMethodNotImplemented)
        #else
        let enabled = (args["enabled"] as? Bool) ?? true
        let sessionActivationEnabled = (args["sessionActivationEnabled"] as? Bool) ?? true
        audioEngineObserver?.setAutomaticManagementEnabled(enabled, sessionActivationEnabled: sessionActivationEnabled)
        result(true)
        #endif
    }

    public func handleDeactivateAppleAudioSession(result: @escaping FlutterResult) {
        #if os(macOS)
        result(FlutterMethodNotImplemented)
        #else
        if let error = LiveKitPlugin.deactivateAudioSession() {
            print("[LiveKit] Deactivate audio session error: ", error)
            result(FlutterError(code: "deactivateAudioSession", message: error.localizedDescription, details: nil))
        } else {
            result(true)
        }
        #endif
    }

    private static let processInfo = ProcessInfo()

    /// Returns os version as a string.
    /// format: `12.1`, `15.3.1`, `15.0.1`
    private static func osVersionString() -> String {
        let osVersion = processInfo.operatingSystemVersion
        var versions = [osVersion.majorVersion]
        if osVersion.minorVersion != 0 || osVersion.patchVersion != 0 {
            versions.append(osVersion.minorVersion)
        }
        if osVersion.patchVersion != 0 {
            versions.append(osVersion.patchVersion)
        }
        return versions.map { String($0) }.joined(separator: ".")
    }

    public func handleSetAudioProcessingOptions(args: [String: Any?], result: @escaping FlutterResult) {
        guard let trackId = args["trackId"] as? String else {
            result(FlutterError(code: "setAudioProcessingOptions", message: "trackId is required", details: nil))
            return
        }

        let webrtc = FlutterWebRTCPlugin.sharedSingleton()
        guard let localTrack = webrtc?.localTracks?[trackId] as? LocalAudioTrack,
              let audioTrack = localTrack.track() as? RTCAudioTrack
        else {
            result(FlutterError(code: "setAudioProcessingOptions", message: "track is not a local audio track", details: nil))
            return
        }

        let options = LiveKitPlugin.audioProcessingOptions(from: args)
        let processingResult = audioTrack.setAudioProcessingOptions(options)
        result([
            "result": processingResult.isSuccess,
            "code": LiveKitPlugin.audioProcessingResultCodeString(processingResult.code),
            "message": processingResult.message,
        ])
    }

    // MARK: - Engine availability

    private static let engineAvailabilityLock = NSLock()
    private static var pendingEngineAvailability: RTCAudioEngineAvailability?

    /// Sets whether the WebRTC audio engine is allowed to run. This is the
    /// highest-priority gate over anything that may start the engine. Requests
    /// made while unavailable are honored once availability allows.
    ///
    /// Public native API so an AppDelegate can gate audio before the Flutter
    /// engine exists (e.g. a CallKit killed-state wake): when the audio device
    /// module is not created yet, the value is stored and applied at plugin
    /// registration, before any audio operation can start the engine.
    ///
    /// Returns `false` when the value was stored for deferred application,
    /// `true` when it was applied to the live audio device module.
    @objc @discardableResult
    public static func setEngineAvailability(isInputAvailable: Bool, isOutputAvailable: Bool) -> Bool {
        let availability = RTCAudioEngineAvailability(isInputAvailable: ObjCBool(isInputAvailable),
                                                      isOutputAvailable: ObjCBool(isOutputAvailable))
        engineAvailabilityLock.lock()
        pendingEngineAvailability = availability
        engineAvailabilityLock.unlock()

        guard let adm = FlutterWebRTCPlugin.sharedSingleton()?.peerConnectionFactory?.audioDeviceModule else {
            return false
        }
        return adm.setEngineAvailability(availability) == 0
    }

    private static func applyPendingEngineAvailabilityIfNeeded() {
        engineAvailabilityLock.lock()
        let pending = pendingEngineAvailability
        engineAvailabilityLock.unlock()
        guard let pending else { return }

        // Accessing peerConnectionFactory creates it (and the audio device
        // module) if needed. That is intentional here, so the gate is in
        // place before anything else can start the engine.
        guard let adm = FlutterWebRTCPlugin.sharedSingleton()?.peerConnectionFactory?.audioDeviceModule else {
            print("[LiveKit] engine availability pending but audio device module is unavailable")
            return
        }
        if adm.setEngineAvailability(pending) != 0 {
            print("[LiveKit] failed to apply pending engine availability")
        }
    }

    public func handleSetEngineAvailability(args: [String: Any?], result: @escaping FlutterResult) {
        let isInputAvailable = (args["isInputAvailable"] as? Bool) ?? true
        let isOutputAvailable = (args["isOutputAvailable"] as? Bool) ?? true

        // Accessing peerConnectionFactory creates the audio device module if
        // needed, so the gate is effective even before any track exists.
        guard let adm = FlutterWebRTCPlugin.sharedSingleton()?.peerConnectionFactory?.audioDeviceModule else {
            result(FlutterError(code: "setEngineAvailability", message: "audio device module is unavailable", details: nil))
            return
        }

        let availability = RTCAudioEngineAvailability(isInputAvailable: ObjCBool(isInputAvailable),
                                                      isOutputAvailable: ObjCBool(isOutputAvailable))

        // Keep the pending value in sync so both the native static and this
        // channel path record the latest intent. A later plugin registration
        // (e.g. a second Flutter engine in the same process) re-applies the
        // pending value, so it must never lag behind a Dart-side update.
        LiveKitPlugin.engineAvailabilityLock.lock()
        LiveKitPlugin.pendingEngineAvailability = availability
        LiveKitPlugin.engineAvailabilityLock.unlock()

        // Availability changes can stop/start the engine, so keep that work
        // off the platform thread.
        DispatchQueue.global(qos: .userInitiated).async {
            let admResult = adm.setEngineAvailability(availability)
            DispatchQueue.main.async {
                if admResult == 0 {
                    result(nil)
                } else {
                    result(LiveKitPlugin.flutterError(forAudioEngineResult: admResult,
                                                      fallbackCode: "setEngineAvailability"))
                }
            }
        }
    }

    // MARK: - Microphone permission

    /// Ensures microphone access is granted before audio capture starts.
    ///
    /// The WebRTC audio device does not request microphone permission itself. It
    /// only checks it and fails with kAudioEngineErrorInsufficientDevicePermission,
    /// so requesting is the SDK's job. On iOS the request is only made while the
    /// app is active: while inactive or in the background the system defers the
    /// alert, and waiting on it would suspend the caller, and the publish queue
    /// behind it, for as long as the app stays there. Failing fast lets the next
    /// attempt prompt normally. macOS can present the prompt regardless.
    ///
    /// Method channel handlers run on the main thread, which UIApplication needs.
    public func handleEnsureMicrophoneAccess(result: @escaping FlutterResult) {
        // With engine input availability disabled (the CallKit flow, see
        // setEngineAvailability) the audio device module defers opening input
        // entirely and runs no permission check, so gating here would turn a
        // working background connect into a deviceAccessDenied failure. The
        // last-set value is tracked by both the channel and native static
        // paths, so it covers gating done before the Flutter engine exists.
        LiveKitPlugin.engineAvailabilityLock.lock()
        let pendingAvailability = LiveKitPlugin.pendingEngineAvailability
        LiveKitPlugin.engineAvailabilityLock.unlock()
        if let pendingAvailability, !pendingAvailability.isInputAvailable.boolValue {
            result(nil)
            return
        }

        let denied = { (message: String) in
            result(FlutterError(code: LiveKitPlugin.deviceAccessDeniedErrorCode, message: message, details: nil))
        }
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            result(nil)
        case .notDetermined:
            #if !os(macOS)
            guard UIApplication.shared.applicationState == .active else {
                denied("Microphone permission could not be requested because the app is not in the foreground. Request it while the app is active before enabling recording.")
                return
            }
            #endif
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    if granted {
                        result(nil)
                    } else {
                        denied("Microphone permission was denied.")
                    }
                }
            }
        case .denied, .restricted:
            denied("Microphone permission is not granted.")
        @unknown default:
            denied("Microphone permission is not granted.")
        }
    }

    // MARK: - Microphone mute mode

    static func muteModeString(_ mode: RTCAudioEngineMuteMode) -> String {
        switch mode {
        case .voiceProcessing: return "voiceProcessing"
        case .restartEngine: return "restart"
        case .inputMixer: return "inputMixer"
        default: return "unknown"
        }
    }

    static func muteMode(from string: String) -> RTCAudioEngineMuteMode {
        switch string {
        case "voiceProcessing": return .voiceProcessing
        case "restart": return .restartEngine
        case "inputMixer": return .inputMixer
        default: return .unknown
        }
    }

    public func handleSetMicrophoneMuteMode(args: [String: Any?], result: @escaping FlutterResult) {
        let modeString = args["mode"] as? String ?? ""
        let mode = LiveKitPlugin.muteMode(from: modeString)
        if mode == .unknown {
            result(FlutterError(code: "setMicrophoneMuteMode", message: "invalid mute mode: \(modeString)", details: nil))
            return
        }

        guard let adm = FlutterWebRTCPlugin.sharedSingleton()?.peerConnectionFactory?.audioDeviceModule else {
            result(FlutterError(code: "setMicrophoneMuteMode", message: "audio device module is unavailable", details: nil))
            return
        }

        // Changing the mode while muted can rebuild the audio engine, so keep
        // that work off the platform thread.
        DispatchQueue.global(qos: .userInitiated).async {
            let admResult = adm.setMuteMode(mode)
            DispatchQueue.main.async {
                if admResult == 0 {
                    result(nil)
                } else {
                    // A mute-mode change can rebuild the engine and hit the same
                    // permission / audio session checks as a recording start.
                    result(LiveKitPlugin.flutterError(forAudioEngineResult: admResult,
                                                      fallbackCode: "setMicrophoneMuteMode"))
                }
            }
        }
    }

    public func handleGetMicrophoneMuteMode(result: @escaping FlutterResult) {
        guard let adm = FlutterWebRTCPlugin.sharedSingleton()?.peerConnectionFactory?.audioDeviceModule else {
            result(FlutterError(code: "getMicrophoneMuteMode", message: "audio device module is unavailable", details: nil))
            return
        }
        result(LiveKitPlugin.muteModeString(adm.muteMode))
    }

    public func handleStartLocalRecording(args: [String: Any?], result: @escaping FlutterResult) {
        guard let adm = FlutterWebRTCPlugin.sharedSingleton()?.peerConnectionFactory?.audioDeviceModule else {
            result(FlutterError(code: "rejectedPlatformUnavailable", message: "audio device module is unavailable", details: nil))
            return
        }

        let options = LiveKitPlugin.audioProcessingOptions(from: args)
        DispatchQueue.global(qos: .userInitiated).async {
            let admResult = adm.initAndStartRecording(audioProcessingOptions: options)
            DispatchQueue.main.async {
                if admResult == 0 {
                    result(nil)
                } else {
                    // Permission and audio session failures get their own codes so
                    // Dart does not report them as audio processing failures.
                    result(LiveKitPlugin.flutterError(forAudioEngineResult: admResult,
                                                      fallbackCode: "applyFailed"))
                }
            }
        }
    }

    public func handleStopLocalRecording(result: @escaping FlutterResult) {
        guard let adm = FlutterWebRTCPlugin.sharedSingleton()?.peerConnectionFactory?.audioDeviceModule else {
            result(FlutterError(code: "stopLocalRecording", message: "audio device module is unavailable", details: nil))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let admResult = adm.stopRecording()
            DispatchQueue.main.async {
                if admResult == 0 {
                    result(nil)
                } else {
                    result(LiveKitPlugin.flutterError(forAudioEngineResult: admResult,
                                                      fallbackCode: "stopLocalRecording"))
                }
            }
        }
    }

    static func audioProcessingOptions(from args: [String: Any?]) -> RTCAudioProcessingOptions {
        RTCAudioProcessingOptions(
            echoCancellationOptions: RTCAudioProcessingComponentOptions(
                enabled: (args["echoCancellation"] as? Bool) ?? true,
                mode: LiveKitPlugin.audioProcessingMode(from: args["echoCancellationMode"] as? String)
            ),
            noiseSuppressionOptions: RTCAudioProcessingComponentOptions(
                enabled: (args["noiseSuppression"] as? Bool) ?? true,
                mode: LiveKitPlugin.audioProcessingMode(from: args["noiseSuppressionMode"] as? String)
            ),
            autoGainControlOptions: RTCAudioProcessingComponentOptions(
                enabled: (args["autoGainControl"] as? Bool) ?? true,
                mode: LiveKitPlugin.audioProcessingMode(from: args["autoGainControlMode"] as? String)
            ),
            highPassFilterOptions: RTCAudioProcessingComponentOptions(
                enabled: (args["highPassFilter"] as? Bool) ?? false,
                mode: LiveKitPlugin.audioProcessingMode(from: args["highPassFilterMode"] as? String)
            )
        )
    }

    static func audioProcessingMode(from string: String?) -> RTCAudioProcessingMode {
        switch string {
        case "platform": return .platform
        case "software": return .software
        default: return .automatic
        }
    }

    static func audioProcessingResultCodeString(_ code: RTCAudioProcessingOptionsResultCode) -> String {
        switch code {
        case .applied: return "applied"
        case .stored: return "stored"
        case .rejectedRemoteTrack: return "unknown"
        case .rejectedInvalidCombination: return "rejectedInvalidCombination"
        case .rejectedPlatformUnavailable: return "rejectedPlatformUnavailable"
        case .applyFailed: return "applyFailed"
        @unknown default: return "unknown"
        }
    }

    public func handleGetAudioProcessingState(result: @escaping FlutterResult) {
        guard let factory = FlutterWebRTCPlugin.sharedSingleton()?.peerConnectionFactory else {
            result(nil)
            return
        }
        result(LiveKitPlugin.toMap(state: factory.audioProcessingState))
    }

    static func audioProcessingModeString(_ mode: RTCAudioProcessingMode) -> String {
        switch mode {
        case .platform: return "platform"
        case .software: return "software"
        default: return "auto"
        }
    }

    static func audioProcessingImplementationString(_ implementation: RTCAudioProcessingImplementation) -> String {
        switch implementation {
        case .disabled: return "disabled"
        case .software: return "software"
        case .platform: return "platform"
        case .softwareAndPlatform: return "softwareAndPlatform"
        default: return "unknown"
        }
    }

    static func toMap(component state: RTCAudioProcessingComponentState) -> [String: Any] {
        var map: [String: Any] = [
            "isSoftwareResolved": state.isSoftwareResolved,
            "isSoftwareActive": state.isSoftwareActive,
            "isPlatformAvailable": state.isPlatformAvailable,
            "isPlatformResolved": state.isPlatformResolved,
            "isPlatformActive": state.isPlatformActive,
            "effective": audioProcessingImplementationString(state.effective),
        ]
        if let requested = state.requested {
            map["requested"] = [
                "enabled": requested.isEnabled,
                "mode": audioProcessingModeString(requested.mode),
            ]
        }
        return map
    }

    static func toMap(state: RTCAudioProcessingState) -> [String: Any] {
        [
            "hasAudioProcessingModule": state.hasAudioProcessingModule,
            "echoCancellation": toMap(component: state.echoCancellation),
            "noiseSuppression": toMap(component: state.noiseSuppression),
            "autoGainControl": toMap(component: state.autoGainControl),
            "highPassFilter": toMap(component: state.highPassFilter),
        ]
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any?] else {
            print("[LiveKit] arguments must be a dictionary")
            result(FlutterMethodNotImplemented)
            return
        }

        switch call.method {
        case "configureNativeAudio":
            handleConfigureNativeAudio(args: args, result: result)
        case "setAppleAudioSessionAutomaticManagementEnabled":
            handleSetAppleAudioSessionAutomaticManagementEnabled(args: args, result: result)
        case "deactivateAppleAudioSession":
            handleDeactivateAppleAudioSession(result: result)
        case "startVisualizer":
            handleStartAudioVisualizer(args: args, result: result)
        case "stopVisualizer":
            handleStopAudioVisualizer(args: args, result: result)
        case "startAudioRenderer":
            handleStartAudioRenderer(args: args, result: result)
        case "stopAudioRenderer":
            handleStopAudioRenderer(args: args, result: result)
        case "setMicrophoneMuteMode":
            handleSetMicrophoneMuteMode(args: args, result: result)
        case "getMicrophoneMuteMode":
            handleGetMicrophoneMuteMode(result: result)
        case "startLocalRecording":
            handleStartLocalRecording(args: args, result: result)
        case "stopLocalRecording":
            handleStopLocalRecording(result: result)
        case "setEngineAvailability":
            handleSetEngineAvailability(args: args, result: result)
        case "ensureMicrophoneAccess":
            handleEnsureMicrophoneAccess(result: result)
        case "setAudioProcessingOptions":
            handleSetAudioProcessingOptions(args: args, result: result)
        case "getAudioProcessingState":
            handleGetAudioProcessingState(result: result)
        case "osVersionString":
            result(LiveKitPlugin.osVersionString())
        #if os(iOS)
        case "broadcastRequestActivation":
            BroadcastManager.shared.requestActivation()
            result(true)
        case "broadcastRequestStop":
            BroadcastManager.shared.requestStop()
            result(true)
        #endif
        default:
            print("[LiveKit] method not found: ", call.method)
            result(FlutterMethodNotImplemented)
        }
    }
}

extension LiveKitPlugin {
    /// SDK-side audio engine error code (mirrors client-sdk-swift): returned
    /// from a delegate callback to make WebRTC abort / roll back the engine
    /// operation when the audio session cannot be configured.
    static let kAudioEngineErrorFailedToConfigureAudioSession = -4100

    /// Error codes originating from the WebRTC AudioEngineDevice. Keep in sync
    /// with `audio_engine_device.h` in the webrtc-sdk fork.
    static let kAudioEngineErrorInsufficientDevicePermission = -9000
    static let kAudioEngineErrorAudioSessionInvalidCategory = -9001

    /// FlutterError code for missing microphone permission. Dart maps it to
    /// TrackCreateException (see audio_engine_error.dart).
    static let deviceAccessDeniedErrorCode = "deviceAccessDenied"

    /// Maps a non-zero audio device module result to a `FlutterError` whose code
    /// the Dart side can act on. Codes with a known cause get their own error
    /// code, mirroring client-sdk-swift's `checkAdmResult`. Anything else falls
    /// back to `fallbackCode` with the raw value in the message.
    static func flutterError(forAudioEngineResult result: Int, fallbackCode: String) -> FlutterError {
        switch result {
        case kAudioEngineErrorInsufficientDevicePermission:
            return FlutterError(code: deviceAccessDeniedErrorCode,
                                message: "Microphone permission is not granted (audio engine error \(result))",
                                details: result)
        case kAudioEngineErrorAudioSessionInvalidCategory:
            return FlutterError(code: "audioSessionInvalidCategory",
                                message: "Audio session category does not support recording (audio engine error \(result))",
                                details: result)
        case kAudioEngineErrorFailedToConfigureAudioSession:
            return FlutterError(code: "audioSessionConfigureFailed",
                                message: "Failed to configure the audio session (audio engine error \(result))",
                                details: result)
        default:
            return FlutterError(code: fallbackCode,
                                message: "Audio engine returned error code: \(result)",
                                details: result)
        }
    }
}

#if !os(macOS)
@available(iOS 13.0, *)
extension LiveKitPlugin {
    /// Applies an `RTCAudioSessionConfiguration` to the shared `RTCAudioSession`.
    /// Returns `nil` on success or the thrown error. Safe to call on any thread.
    static func applyAudioSessionConfiguration(_ configuration: RTCAudioSessionConfiguration,
                                               forceSpeakerOutput: Bool,
                                               isActive: Bool) -> Error? {
        let rtcSession = RTCAudioSession.sharedInstance()
        rtcSession.lockForConfiguration()
        defer { rtcSession.unlockForConfiguration() }
        do {
            if isActive {
                try rtcSession.setConfiguration(configuration, active: true)
            } else {
                // Configure-only variant. setConfiguration(_:active:) always
                // forwards its active flag to setActive, so passing false here
                // would deactivate the session an external call system just
                // activated.
                try rtcSession.setConfiguration(configuration)
            }
            // overrideOutputAudioPort hard-routes to the speaker even over a
            // connected headset. Plain speaker preference is expressed by the
            // selected audio mode/category options, so clear any stale hard
            // override unless the app explicitly forced speaker output.
            // Only valid for the playAndRecord category. Applied regardless of
            // who owns activation, since under an external call system the
            // session is active during a call even though isActive is false.
            if configuration.category == AVAudioSession.Category.playAndRecord.rawValue {
                do {
                    try rtcSession.overrideOutputAudioPort(forceSpeakerOutput ? .speaker : .none)
                } catch {
                    // Before the external call system activates the session the
                    // override can fail. Tolerate it, the configuration itself
                    // succeeded and the override is re-applied on the next
                    // engine lifecycle event.
                    guard !isActive else { throw error }
                    print("[LiveKit] overrideOutputAudioPort skipped, session not active yet: \(error)")
                }
            }
            return nil
        } catch {
            return error
        }
    }

    /// Deactivates the shared `RTCAudioSession`. Returns `nil` on success.
    static func deactivateAudioSession() -> Error? {
        let rtcSession = RTCAudioSession.sharedInstance()
        rtcSession.lockForConfiguration()
        defer { rtcSession.unlockForConfiguration() }
        do {
            try rtcSession.setActive(false)
            return nil
        } catch {
            return error
        }
    }
}
#endif

/// Receives the WebRTC audio device module's engine-lifecycle callbacks and,
/// on iOS, drives the audio session: configure + activate when the engine
/// enables, deactivate when it disables. Replaces the old track-counting
/// trigger. On macOS there is no `AVAudioSession`, so it only surfaces engine
/// state to Dart (keeping engine state the single source of truth there too).
///
/// The engine-lifecycle methods are invoked synchronously on WebRTC's worker
/// thread. The engine blocks on the return value (`0` = proceed, non-zero =
/// abort / roll back), so the session work here is synchronous and never calls
/// back into the audio device module. The Dart notification is dispatched
/// asynchronously and is purely informational. It never blocks the engine.
@available(iOS 13.0, macOS 10.15, *)
class LKAudioEngineObserver: NSObject, RTCAudioDeviceModuleDelegate {
    private let lock = NSLock()
    private weak var channel: FlutterMethodChannel?

    #if !os(macOS)
    // Policy pushed from Dart, if any. It is an override: when nothing has been
    // pushed yet (recording before the room connects, or an engine start driven
    // from native before the Flutter side exists) the observer resolves a
    // built-in preset from engine state instead, so the engine never enables
    // against the app-default soloAmbient category. Mirrors the Swift SDK's
    // AudioSessionEngineObserver, which derives the session from engine state
    // alone.
    private var cachedConfiguration: RTCAudioSessionConfiguration?
    // When true, the category is chosen from the live engine state at apply time
    // (playAndRecord while recording, playback for playout-only) rather than
    // taken from the pushed config. This is what keeps the category correct as
    // recording/playout come and go. The pushed config still supplies the mode,
    // options and speaker preference. False for an explicit per-platform
    // override or manual mode, where the config is applied verbatim.
    private var selectCategoryByEngineState = false
    private var forceSpeakerOutput = false
    private var isAutomaticManagementEnabled = true
    // False when an external call system (CallKit) owns session activation:
    // configurations are applied without activating, and the session is never
    // deactivated from engine lifecycle. CallKit activates/deactivates.
    private var isSessionActivationEnabled = true
    // True when cached policy changes should apply immediately. This includes
    // an engine already running under manual mode, because switching back to
    // automatic should configure the live session without waiting for another
    // engine lifecycle event.
    private var sessionActive = false
    // Last recording state seen, so an immediate re-apply (e.g. speaker toggle
    // while the engine is running) can resolve the category from current state.
    private var lastIsRecordingEnabled = false
    #endif

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }

    /// Rebinds Dart notifications to the given channel. Called on every plugin
    /// registration, since the observer itself outlives registrations.
    func updateChannel(_ channel: FlutterMethodChannel) {
        lock.lock()
        self.channel = channel
        lock.unlock()
    }

    #if !os(macOS)
    var isSessionActive: Bool {
        lock.lock(); defer { lock.unlock() }
        return sessionActive
    }

    func setAutomaticManagementEnabled(_ enabled: Bool, sessionActivationEnabled: Bool = true) {
        lock.lock()
        isAutomaticManagementEnabled = enabled
        isSessionActivationEnabled = sessionActivationEnabled
        lock.unlock()
    }

    /// Stores the audio session policy pushed from Dart. Pure cache, where the
    /// delegate callbacks apply it. Callers decide whether to apply immediately.
    func updatePolicy(_ configuration: RTCAudioSessionConfiguration,
                      automaticManagementEnabled: Bool,
                      selectCategoryByEngineState: Bool,
                      forceSpeakerOutput: Bool) {
        let cachedConfiguration = copyConfiguration(configuration)
        lock.lock()
        self.cachedConfiguration = cachedConfiguration
        self.isAutomaticManagementEnabled = automaticManagementEnabled
        self.selectCategoryByEngineState = selectCategoryByEngineState
        self.forceSpeakerOutput = forceSpeakerOutput
        lock.unlock()
    }

    /// Applies the cached configuration immediately, resolving the category from
    /// the last known engine state when category selection is enabled. Used for
    /// manual mode and for re-applying while the engine is already running.
    func applyCachedConfiguration() -> Error? {
        lock.lock()
        let resolved = effectiveConfigurationLocked(isRecordingEnabled: lastIsRecordingEnabled)
        let forceSpeakerOutput = self.forceSpeakerOutput
        let isActive = isSessionActivationEnabled
        lock.unlock()
        guard let resolved else { return nil }
        return LiveKitPlugin.applyAudioSessionConfiguration(resolved.configuration,
                                                            forceSpeakerOutput: forceSpeakerOutput,
                                                            isActive: isActive)
    }

    private func applyManagedConfiguration(isRecordingEnabled: Bool) -> Error? {
        lock.lock()
        let shouldManageSession = isAutomaticManagementEnabled
        let resolved = effectiveConfigurationLocked(isRecordingEnabled: isRecordingEnabled)
        let forceSpeakerOutput = self.forceSpeakerOutput
        let isActive = isSessionActivationEnabled
        lock.unlock()

        guard shouldManageSession, let resolved else { return nil }
        guard let error = LiveKitPlugin.applyAudioSessionConfiguration(resolved.configuration,
                                                                       forceSpeakerOutput: forceSpeakerOutput,
                                                                       isActive: isActive)
        else { return nil }
        // The built-in preset is best-effort: before it existed, engine starts
        // with nothing pushed proceeded against whatever session the app had,
        // and the ADM's own pre-enable checks still gate recording on an
        // unsuitable category. Only a policy the app actually pushed aborts
        // the engine operation when it cannot be applied.
        if resolved.isDefaultPreset {
            print("[LiveKit] AudioEngine: default audio session preset not applied, continuing: \(error)")
            return nil
        }
        return error
    }

    private func recordEngineState(isPlayoutEnabled: Bool, isRecordingEnabled: Bool) {
        lock.lock()
        lastIsRecordingEnabled = isRecordingEnabled
        sessionActive = isPlayoutEnabled || isRecordingEnabled
        lock.unlock()
    }

    /// Resolves the configuration to apply for a given engine state. Must be
    /// called with `lock` held.
    ///
    /// When category selection is disabled (explicit Apple override or manual
    /// mode) the pushed config is applied verbatim. When enabled, recording
    /// uses the pushed config (resolved as a playAndRecord policy by Dart),
    /// while playout-only uses a coherent playback policy: flipping only the
    /// category would leave playAndRecord-only mode/options (e.g. videoChat,
    /// allowBluetooth) that are invalid for the playback category. Mirrors the
    /// Swift SDK's `.playback` preset (playback + spokenAudio + mixWithOthers).
    ///
    /// With no pushed config and automatic management on, the built-in
    /// recording preset stands in for the Dart policy, so the result is the
    /// same as if the default policy had been pushed. Returns `nil` only in
    /// manual mode with nothing pushed, where the app owns the session.
    private func effectiveConfigurationLocked(isRecordingEnabled: Bool)
        -> (configuration: RTCAudioSessionConfiguration, isDefaultPreset: Bool)?
    {
        let usesDefaultPreset = cachedConfiguration == nil
        guard let configuration = cachedConfiguration
            ?? (isAutomaticManagementEnabled ? defaultRecordingConfigurationLocked() : nil)
        else { return nil }
        // The default preset is always resolved by engine state, like the Dart
        // automatic-mode push it stands in for.
        guard usesDefaultPreset || selectCategoryByEngineState, !isRecordingEnabled else {
            return (configuration, usesDefaultPreset)
        }

        let playback = copyConfiguration(configuration)
        playback.category = AVAudioSession.Category.playback.rawValue
        playback.categoryOptions = [.mixWithOthers]
        playback.mode = AVAudioSession.Mode.spokenAudio.rawValue
        return (playback, usesDefaultPreset)
    }

    /// Built-in playAndRecord preset used until Dart pushes a policy. Must be
    /// called with `lock` held.
    ///
    /// Keep in sync with the automatic-mode branch of
    /// `ResolvedAudioSessionPolicy.appleConfiguration` in
    /// `lib/src/audio/audio_session_policy.dart`, so a later push of the default
    /// policy (on connect) does not change the live session.
    private func defaultRecordingConfigurationLocked() -> RTCAudioSessionConfiguration {
        // `webRTC()` returns the process-wide shared configuration object;
        // mutating it would rewrite WebRTC's defaults for every other consumer
        // (and the result escapes `lock`), so start from a copy.
        let configuration = copyConfiguration(RTCAudioSessionConfiguration.webRTC())
        configuration.category = AVAudioSession.Category.playAndRecord.rawValue
        configuration.categoryOptions = [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay]
        // videoChat routes to the speaker, matching the Dart AudioManager's
        // default speaker preference. A non-default preference always arrives
        // as a pushed policy (its mode carries the preference), which bypasses
        // this preset entirely.
        configuration.mode = AVAudioSession.Mode.videoChat.rawValue
        return configuration
    }

    private func copyConfiguration(_ configuration: RTCAudioSessionConfiguration) -> RTCAudioSessionConfiguration {
        let copy = RTCAudioSessionConfiguration()
        copy.category = configuration.category
        copy.categoryOptions = configuration.categoryOptions
        copy.mode = configuration.mode
        copy.sampleRate = configuration.sampleRate
        copy.ioBufferDuration = configuration.ioBufferDuration
        copy.inputNumberOfChannels = configuration.inputNumberOfChannels
        copy.outputNumberOfChannels = configuration.outputNumberOfChannels
        return copy
    }
    #endif

    // MARK: RTCAudioDeviceModuleDelegate, engine lifecycle

    func audioDeviceModule(_: RTCAudioDeviceModule,
                           willEnableEngine _: AVAudioEngine,
                           isPlayoutEnabled: Bool,
                           isRecordingEnabled: Bool) -> Int {
        var resultCode = 0
        #if !os(macOS)
        if isPlayoutEnabled || isRecordingEnabled {
            if let error = applyManagedConfiguration(isRecordingEnabled: isRecordingEnabled) {
                print("[LiveKit] AudioEngine willEnable: failed to configure audio session: \(error)")
                resultCode = LiveKitPlugin.kAudioEngineErrorFailedToConfigureAudioSession
            }
            if resultCode == 0 {
                recordEngineState(isPlayoutEnabled: isPlayoutEnabled, isRecordingEnabled: isRecordingEnabled)
            }
        }
        #endif
        if resultCode == 0 {
            notifyEngineState(isPlayoutEnabled: isPlayoutEnabled, isRecordingEnabled: isRecordingEnabled)
        }
        return resultCode
    }

    func audioDeviceModule(_: RTCAudioDeviceModule,
                           didDisableEngine _: AVAudioEngine,
                           isPlayoutEnabled: Bool,
                           isRecordingEnabled: Bool) -> Int {
        var resultCode = 0
        #if !os(macOS)
        if isPlayoutEnabled || isRecordingEnabled {
            // A disable event can leave one side of the engine running (for
            // example, mic off while remote playout continues). Re-apply so
            // dynamic category selection follows the new engine state.
            if let error = applyManagedConfiguration(isRecordingEnabled: isRecordingEnabled) {
                print("[LiveKit] AudioEngine didDisable: failed to configure audio session: \(error)")
                resultCode = LiveKitPlugin.kAudioEngineErrorFailedToConfigureAudioSession
            }
        } else {
            lock.lock()
            let shouldManageSession = isAutomaticManagementEnabled && isSessionActivationEnabled
            lock.unlock()

            if shouldManageSession, let error = LiveKitPlugin.deactivateAudioSession() {
                // Leave sessionActive unchanged (still true) so cached state
                // keeps reflecting the live session. Flipping it to false here
                // would make a later configureNativeAudio(automatic:) cache-only
                // while the session is in fact still active.
                print("[LiveKit] AudioEngine didDisable: failed to deactivate audio session: \(error)")
                resultCode = LiveKitPlugin.kAudioEngineErrorFailedToConfigureAudioSession
            }
        }
        if resultCode == 0 {
            recordEngineState(isPlayoutEnabled: isPlayoutEnabled, isRecordingEnabled: isRecordingEnabled)
        }
        #endif
        if resultCode == 0 {
            notifyEngineState(isPlayoutEnabled: isPlayoutEnabled, isRecordingEnabled: isRecordingEnabled)
        }
        return resultCode
    }

    // Remaining callbacks are not needed for session management (proceed / no-op).
    func audioDeviceModule(_: RTCAudioDeviceModule, didCreateEngine _: AVAudioEngine) -> Int { 0 }
    func audioDeviceModule(_: RTCAudioDeviceModule, willStartEngine _: AVAudioEngine, isPlayoutEnabled _: Bool, isRecordingEnabled _: Bool) -> Int { 0 }
    func audioDeviceModule(_: RTCAudioDeviceModule, didStopEngine _: AVAudioEngine, isPlayoutEnabled _: Bool, isRecordingEnabled _: Bool) -> Int { 0 }
    func audioDeviceModule(_: RTCAudioDeviceModule, willReleaseEngine _: AVAudioEngine) -> Int { 0 }
    func audioDeviceModule(_: RTCAudioDeviceModule, engine _: AVAudioEngine, configureInputFromSource _: AVAudioNode?, toDestination _: AVAudioNode, format _: AVAudioFormat, context _: [AnyHashable: Any]) -> Int { 0 }
    func audioDeviceModule(_: RTCAudioDeviceModule, engine _: AVAudioEngine, configureOutputFromSource _: AVAudioNode, toDestination _: AVAudioNode?, format _: AVAudioFormat, context _: [AnyHashable: Any]) -> Int { 0 }
    func audioDeviceModule(_: RTCAudioDeviceModule, didReceiveSpeechActivityEvent _: RTCSpeechActivityEvent) {}
    func audioDeviceModuleDidUpdateDevices(_ audioDeviceModule: RTCAudioDeviceModule) {
        FlutterWebRTCPlugin.sharedSingleton()?.audioDeviceModuleDidUpdateDevices(audioDeviceModule)
    }

    private func notifyEngineState(isPlayoutEnabled: Bool, isRecordingEnabled: Bool) {
        lock.lock()
        let channel = channel
        lock.unlock()
        guard let channel else { return }
        DispatchQueue.main.async {
            channel.invokeMethod("onAudioEngineState", arguments: [
                "isPlayoutEnabled": isPlayoutEnabled,
                "isRecordingEnabled": isRecordingEnabled,
            ])
        }
    }
}
