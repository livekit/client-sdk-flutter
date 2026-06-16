# Audio session management

LiveKit owns the platform audio session on iOS and Android through a single process-wide entry point, `AudioManager`. You configure session intent once with typed options and LiveKit applies the right native category, mode, focus, and routing for you. On macOS, `AudioManager` reports native audio-engine state but does not configure a platform audio session.

`AudioManager` is a singleton, reached through `AudioManager.instance`.

## Quick start

Pick a session intent. `communication` is the default and is meant for calls and rooms where you both send and receive audio. `media` is for one way playback or media capture where communication mode is not wanted.

```dart
import 'package:livekit_client/livekit_client.dart';

// VoIP style call (this is the default, so you only need it to be explicit)
await AudioManager.instance.setAudioSessionOptions(
  const AudioSessionOptions.communication(),
);

// Media playback or live streaming capture
await AudioManager.instance.setAudioSessionOptions(
  const AudioSessionOptions.media(),
);
```

Set this before connecting when you can. The explicit apply path above works in both automatic and manual management modes.

## Speaker routing

```dart
// Prefer the speaker. A wired or Bluetooth headset still takes priority.
await AudioManager.instance.setSpeakerOutputPreferred(true);

// Force the speaker even when a headset is connected.
await AudioManager.instance.setSpeakerOutputPreferred(true, force: true);

// Route back to the earpiece or the connected headset.
await AudioManager.instance.setSpeakerOutputPreferred(false);
```

Read the current preference through `AudioManager.instance.isSpeakerOutputPreferred` and `AudioManager.instance.isSpeakerOutputForced`. `AudioManager.instance.canSwitchSpeakerphone` is true on iOS and Android.

`Room.setSpeakerOn(...)` still works and forwards to the same path, so existing call sites do not need to change.

## Automatic vs manual mode

In automatic mode (the default) LiveKit updates the audio session from room, connect, and engine lifecycle. In manual mode LiveKit does not touch the session on its own, and your app drives it explicitly with `setAudioSessionOptions` and `deactivateAudioSession`.

```dart
// Hand session control to the app.
await AudioManager.instance.setAudioSessionManagementMode(
  AudioSessionManagementMode.manual,
);

// Apply a configuration yourself whenever you need it.
await AudioManager.instance.setAudioSessionOptions(
  const AudioSessionOptions.communication(),
);

// Re-apply the current options, for example after an interruption.
await AudioManager.instance.applyCurrentAudioSessionOptions();

// Release the session when your manual lifecycle no longer needs it.
await AudioManager.instance.deactivateAudioSession();
```

Prefer setting the mode before connecting to a room.

## Per platform overrides

When the presets are not enough you can pin exact platform values. Anything you do not set falls back to the preset behavior.

```dart
await AudioManager.instance.setAudioSessionOptions(
  AudioSessionOptions.communication(
    apple: const AppleAudioSessionConfiguration(
      category: AppleAudioCategory.playAndRecord,
      categoryOptions: {
        AppleAudioCategoryOption.allowBluetooth,
        AppleAudioCategoryOption.mixWithOthers,
      },
      mode: AppleAudioMode.voiceChat,
    ),
    android: AndroidAudioSessionConfiguration.communication,
  ),
);
```

Supplying an explicit `apple` override turns off dynamic category selection, so your configuration is applied as written.

### Updating options with copyWith

`copyWith` uses `Value` and `Absent` so it can tell apart leaving a field alone from setting it to null. A bare `copyWith()` keeps the existing value, `Value(x)` sets a new value, and `Value(null)` clears it.

```dart
final base = AudioSessionOptions.communication(
  apple: const AppleAudioSessionConfiguration(mode: AppleAudioMode.voiceChat),
);

// Change one field, keep the rest.
final updated = base.copyWith(preferSpeakerOutput: const Value(false));

// Clear the Apple override entirely.
final cleared = base.copyWith(apple: const Value(null));
```

If `Value` collides with another package in your imports, alias the import.

```dart
import 'package:livekit_client/livekit_client.dart' as lk;

final cleared = base.copyWith(apple: const lk.Value(null));
```

## Observing audio engine state

On iOS and macOS the native audio engine reports when playout and recording turn on and off. This is the source of truth for audio activity.

```dart
final sub = AudioManager.instance.audioEngineStateStream.listen((state) {
  print('playout ${state.isPlayoutEnabled} recording ${state.isRecordingEnabled}');
  if (state.isIdle) {
    print('engine is idle');
  }
});

// Current snapshot without listening.
final now = AudioManager.instance.audioEngineState;
```

## Initialization

You can optionally call `LiveKitClient.initialize` once at startup. Passing `bypassVoiceProcessing: true` makes the default options media oriented for playback or capture without voice processing. Explicit runtime options that you set with `setAudioSessionOptions` are always preserved.

```dart
await LiveKitClient.initialize(bypassVoiceProcessing: true);
```

flutter_webrtc's own native audio management is disabled automatically when the LiveKit plugin loads, so audio session ownership does not depend on this call.

## Migrating from the old APIs

The legacy `Hardware` audio members still work but are deprecated and forward to `AudioManager`.

| Old | New |
| --- | --- |
| `Hardware.instance.setSpeakerphoneOn(true)` | `AudioManager.instance.setSpeakerOutputPreferred(true)` |
| `Hardware.instance.speakerOn` | `AudioManager.instance.isSpeakerOutputPreferred` |
| `Hardware.instance.preferSpeakerOutput` | `AudioManager.instance.isSpeakerOutputPreferred` |
| `Hardware.instance.forceSpeakerOutput` | `AudioManager.instance.isSpeakerOutputForced` |
| `Hardware.instance.setAutomaticConfigurationEnabled(enable: false)` | `AudioManager.instance.setAudioSessionManagementMode(AudioSessionManagementMode.manual)` |

The old `onConfigureNativeAudio` hook (a deep src import) is removed. Replace a custom configuration function with explicit options.

```dart
// Before: assigning onConfigureNativeAudio with a custom function.
// After:
await AudioManager.instance.setAudioSessionOptions(
  AudioSessionOptions.communication(
    apple: const AppleAudioSessionConfiguration(
      category: AppleAudioCategory.playAndRecord,
      mode: AppleAudioMode.videoChat,
    ),
  ),
);
```

Dart track counting no longer drives the session. The native audio engine delegate drives it from real lifecycle events, which removes the timing races and missed deactivations of the counting approach.

## Platform notes

- **iOS** uses a WebRTC audio engine observer that configures and activates the session when the engine enables, and deactivates when it disables. Category is chosen from live engine state. A listen only or mic muted session uses the playback category until recording starts, and receiver routing from `preferSpeakerOutput` only applies while the effective category is `playAndRecord`.
- **macOS** emits the same engine events but has no `AVAudioSession`, so engine state is reported while no session category is applied.
- **Android** uses an AudioSwitch based manager for audio mode, focus, and routing. The session is activated when LiveKit applies its options (at connect, or on an explicit apply) and released on disconnect.

## API reference

The full generated API reference for these types lives at [pub.dev](https://pub.dev/documentation/livekit_client/latest/). Start from `AudioManager`, `AudioSessionOptions`, `AppleAudioSessionConfiguration`, and `AndroidAudioSessionConfiguration`.
