# LiveKit Flutter SDK

## Commands

Supported platforms: Android, iOS, macOS, Windows, Linux, Web.

```zsh
# Fetch dependencies
flutter pub get

# Analyze
flutter analyze

# Run tests
flutter test

# Format
dart format -l 120 lib test

# Generate protobufs (requires ../protocol/protobufs checkout)
make proto

# Build web E2EE worker
make e2ee
```

## Architecture

```
lib/
├── livekit_client.dart        # Public exports
├── livekit_client_web.dart    # Web-specific entry point
└── src/
    ├── core/                  # Room, Engine, SignalClient, Transport
    ├── participant/           # LocalParticipant, RemoteParticipant
    ├── track/                 # Local/Remote tracks, Web track adapters
    ├── publication/           # TrackPublication types
    ├── data_stream/           # Reliable/unreliable data channels
    ├── e2ee/                  # End-to-end encryption
    ├── agent/                 # AI agent integration (e.g., chat)
    ├── managers/              # Audio/video device and media managers
    ├── support/               # WebSocket, platform shims, utilities
    ├── hardware/              # Device/permission helpers
    ├── token_source/          # TokenSource implementations
    ├── stats/                 # RTC stats models
    ├── proto/                 # Generated protobufs
    ├── widgets/               # Flutter UI widgets (video, controls)
    └── utils/                 # Shared helpers
```

Key components:

- `Room` - main entry point; manages connection state, participants, and tracks
- `Engine` - orchestrates signaling, transports, and media lifecycle
- `SignalClient` - WebSocket signaling with LiveKit server
- `Transport` - WebRTC peer connection wrapper
- `Participant` - local/remote participant state and publications
- `Track`/`TrackPublication` - media track abstractions

## WebRTC

WebRTC provides the underlying media transport. The Flutter SDK wraps native WebRTC via
platform-specific implementations in `android/`, `ios/`, `macOS/`, `windows/`, `linux/`, `web/`,
and shared code in `shared_cpp/` and `shared_swift/`. Dart APIs in `core/` and `track/` shield
consumers from platform differences.

Key files:

- `lib/src/core/transport.dart` - peer connection wrapper and ICE/SDP handling
- `lib/src/core/signal_client.dart` - signaling protocol implementation
- `lib/src/track/` - track bindings and renderers (including `web/`)
- `lib/src/widgets/` - Flutter video rendering widgets

## Testing

- `test/core/` - unit tests for room, signaling, and core models
- `test/integration/` - integration tests (often require local `livekit-server --dev`)
- `test/agent/` - agent feature tests
- `test/token/` - token source tests
- `test/support/` and `test/utils/` - helpers and fixtures
