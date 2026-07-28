// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "livekit_client",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "livekit-client", targets: ["livekit_client"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        // Resolved by the Flutter tool to the flutter_webrtc plugin package.
        .package(name: "flutter_webrtc", path: "../flutter_webrtc")
    ],
    targets: [
        .target(
            name: "livekit_client",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "flutter-webrtc", package: "flutter_webrtc"),
                .product(name: "WebRTC", package: "flutter_webrtc")
            ]
        )
    ]
)
