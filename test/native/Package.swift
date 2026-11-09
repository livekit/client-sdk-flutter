// swift-tools-version: 5.9
//
// Unit tests for the pure audio-session policy decisions in
// `shared_swift/AudioSessionPolicyResolver.swift`, which the plugin's
// `LKAudioEngineObserver` drives. The resolver carries no Flutter, WebRTC or
// AVFoundation dependency, so this package builds and runs on the host with
// plain `swift test` -- no simulator, device or pod install needed:
//
//     swift test --package-path test/native
//
// The source is symlinked rather than copied, matching how
// `ios/livekit_client/Sources` references `shared_swift`.

import PackageDescription

let package = Package(
    name: "LiveKitAudioSessionPolicy",
    targets: [
        .target(name: "LiveKitAudioSessionPolicy"),
        .testTarget(
            name: "LiveKitAudioSessionPolicyTests",
            dependencies: ["LiveKitAudioSessionPolicy"]
        ),
    ]
)
