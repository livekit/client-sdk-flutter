# LiveKit Flutter SDK

Flutter client SDK for LiveKit (`livekit_client` on pub.dev), built on top of `flutter_webrtc`. Supported platforms: iOS, Android, macOS, Windows, Linux, Web (including WASM).

## Commands

Requires Dart >= 3.6 / Flutter >= 3.27.

```sh
flutter pub get
flutter analyze                                          # static analysis
flutter test                                             # unit tests
dart format . --set-exit-if-changed                      # format (page width 120)
dart run import_sorter:main --no-comments --exit-if-changed  # import order (CI-enforced)
dart run scripts/check_version.dart                      # version consistency (CI-enforced)
dart run build_runner build                              # json_serializable codegen
make proto                                               # regen protobufs (needs ../protocol checkout)
dart compile js ./web/e2ee.worker.dart -o ./example/web/e2ee.worker.dart.js  # E2EE web worker
```

CI (`build.yaml`) runs all of the above plus example-app builds for every platform including web/WASM.

## Repo layout

- `lib/livekit_client.dart` — public API surface; implementation lives in `lib/src/`.
- `lib/src/core/` — `Room`, `Engine`, `SignalClient`, `Transport`; `lib/src/participant/`, `lib/src/track/`, `lib/src/publication/` — participants, tracks, publications; `lib/src/events.dart` + `lib/src/managers/event.dart` — event system.
- `lib/src/proto/` — protoc-generated code (from the sibling `protocol` repo); excluded from analysis/format, never edit by hand. Same goes for `*.g.dart` files (json_serializable output in `lib/src/json/` and `lib/src/token_source/`).
- `lib/src/e2ee/` + top-level `web/` — E2EE; the web worker (`web/e2ee.worker.dart`) must be recompiled to JS (command above) when changed.
- `example/` — example app, built for all platforms in CI.
- `test/` — unit tests with mock infrastructure in `test/mock/` (mock peer connection, data channel, websocket; `e2e_container.dart` for room-level tests).
- Platform code in `android/`, `ios/`, `macos/`, `windows/`, `linux/`, `shared_cpp/`, `shared_swift/`.

Web/native divergence is handled with conditional imports (e.g. `track/processor_native.dart` vs `processor_web.dart`) — new platform-specific code should follow that pattern.

## Common pitfalls (from issue history)

- `flutter_webrtc` is pinned to an exact version on purpose: livekit_client and flutter_webrtc must agree on the same WebRTC-SDK native pods, and mismatches break user builds (CocoaPods conflicts). Bump it only in sync with a matching WebRTC-SDK version.
- iOS `AVAudioSession` handling and reconnection-after-network-loss are the most frequent user-reported problem areas — change that code conservatively.
- Don't hand-edit version numbers: `scripts/create_version.dart` propagates the version to `.version`, `pubspec.yaml`, `README.md`, `lib/src/livekit.dart`, and the podspecs; `check_version.dart` fails CI on mismatch.

## Error-prone areas & anti-patterns (from bug/review history)

Most regressions live in `lib/src/core/` (`room.dart`, `engine.dart`, `signal_client.dart`) and `participant/local.dart` — connection lifecycle and async event plumbing. Recurring mistake classes:

- Un-awaited async state updates: callers observed half-initialized participants/publications because `updateFromInfo()`/`updateTrack()` weren't awaited. The `unawaited_futures`/`discarded_futures` lints exist for exactly this — write `unawaited(...)` only as a deliberate choice. Never emit events from constructors or factories; return data and let the caller sequence emissions.
- Iterating a collection across an `await`: event handlers mutate participants/publications/listener lists mid-iteration (`ConcurrentModificationError` — one fix swept 5 files). Snapshot with `.toList()` before iterating; for queues, copy-then-clear before processing.
- The reconnect/disconnect state machine runs on mutable flags (`_isClosed`, `_isReconnecting`, ...) and has historically produced duplicate or missing lifecycle events (double `DisconnectedEvent`, flags not reset on re-connect). When touching engine/room event flow: use `Room.emitWhenConnected(...)`, `createListener(synchronized: true)`, mind emit-vs-cleanup ordering, and add a regression test (see `test/core/room_e2e_test.dart`).
- Events or media tracks arriving before their dependent state exists: don't throw or drop — queue and flush (see `lib/src/core/pending_track_queue.dart`, TTL'd and flushed on connect/participant updates).
- Use-after-close on `StreamController`s crashed data streams: wrap controllers with `isClosed` guards (see `DataStreamController`), and when erroring a stream out, also close it.
- Don't rely on protobuf field defaults for state: republish-after-reconnect silently unmuted tracks because `muted` defaults to `false`. Pass prior state explicitly and reconcile local flags with server responses.
- Duplicate in-flight async operations: cache the future (`_future ??= ...`) and clear it on failure/disconnect (how `ensurePublisherConnected` is debounced), or use `lib/src/support/reusable_completer.dart`.
- Cleanup: extend `Disposable` and register teardown via `onDispose()` (run LIFO, each guarded so one failing disposer can't abort the rest); create event listeners through `createListener()` so they're cancelled with their owner.
- Native boundary: methods in `Native` swallow errors and `logger.warning` by default — if a failure must propagate (e.g. a mode change the caller depends on), document why. Platform-channel crossings are expensive in hot paths; batch data instead of calling per-frame/per-sample.

## Code style

- Lints: `package:lints/recommended` plus repo rules in `analysis_options.yaml` — single quotes, `prefer_final_locals`, `unawaited_futures`, `discarded_futures`, `avoid_print`.
- `dart format` with `page_width: 120`; imports sorted with `import_sorter`.
- Every source file carries the Apache-2.0 license header.

## Releases

Every PR that affects the published package needs a changeset file in `.changes/` (format: `patch|minor|major type="fixed|added|changed|..." "description"`); CI checks for it and runs `dart-apitool` against `main` to require a `major` changeset for breaking public-API changes. PRs that only touch CI workflows or repo tooling are exempt, a changeset would put noise in the user facing changelog. Releases are tag-driven (`vX.Y.Z`) and publish to pub.dev.
