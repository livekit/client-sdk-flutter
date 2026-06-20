# Audio session management

LiveKit owns the platform audio session on iOS and Android through a single process-wide entry point, `AudioManager`. By default it manages a communication session for you, choosing the right native category, mode, focus, and routing. When you need more control you switch to manual mode and apply typed options yourself. On macOS, `AudioManager` reports native audio-engine state but does not configure a platform audio session.

`AudioManager` is a singleton, reached through `AudioManager.instance`. It is also where you read back the engine-wide audio processing state, so one object covers both the audio session and the signal processing applied to your audio.

## Defaults if you do nothing

With no configuration, LiveKit manages the session automatically with the `communication` intent, which is meant for calls. A call needs no setup. On iOS this resolves to a `playAndRecord` session while the microphone is active and a `playback` session for listen only playout. On Android it resolves to communication mode with voice call routing and audio focus.

LiveKit disables flutter_webrtc's own native audio management automatically when the plugin loads, so it owns the session without any setup from you.

Speaker output is preferred by default, but a wired or Bluetooth headset still wins over the speaker. Forced speaker output is off, so the speaker is never forced over a connected headset unless you ask for it.

The media playback preset (`AudioSessionOptions.mediaPlayback()`) is for playback-first experiences such as viewer-only live streams. On Android, pass it to `LiveKitClient.initialize` before WebRTC initializes when you need the WebRTC audio device module to use media mode and media volume. This also seeds LiveKit's automatic runtime session policy until you explicitly replace it with `AudioManager.instance.setAudioSessionOptions(...)`. Runtime session updates apply LiveKit's platform session policy, but WebRTC playout `AudioAttributes` are currently initialized when the audio device module is created.

The default audio capture options apply standard voice processing, so echo cancellation, noise suppression, and auto gain control are on and the high pass filter is off. You can change this per track with `AudioProcessingOptions`.

On macOS the audio engine state is reported but no `AVAudioSession` is configured. On web, Windows, and Linux the session APIs do not configure native audio. Speaker switching is available only on iOS and Android, where `AudioManager.instance.canSwitchSpeakerphone` is true.

## Quick start

For a call you do not need to configure anything. LiveKit manages a communication session automatically.

To take control of the session yourself, apply options. This switches `AudioManager` to manual mode, where your app owns the session and LiveKit stops managing it from room and engine lifecycle.

```dart
import 'package:livekit_client/livekit_client.dart';

// Take manual control and apply a media playback session.
await AudioManager.instance.setAudioSessionOptions(
  const AudioSessionOptions.mediaPlayback(),
);
```

On Android, media output type has one WebRTC initialization-time piece and one LiveKit runtime-session piece. For playback-first apps, initialize WebRTC with the media intent before connecting:

```dart
await LiveKitClient.initialize(
  initialAudioSessionOptions: const AudioSessionOptions.mediaPlayback(),
);
```

This seeds both WebRTC's initialization-time playout attributes and LiveKit's automatic runtime session policy. See the next section for the full rule. Apply options before connecting when you can.

## Configuration timing

`AudioSessionOptions` are used in two places on Android:

| API | Timing | What it can update |
| --- | --- | --- |
| `LiveKitClient.initialize(initialAudioSessionOptions: ...)` | Before WebRTC initializes. | WebRTC audio device module playout `AudioAttributes`, and LiveKit's initial automatic runtime session policy. Today WebRTC uses the Android `usageType` and `contentType` fields, for example `USAGE_MEDIA` and `CONTENT_TYPE_UNKNOWN` from `AudioSessionOptions.mediaPlayback()`. |
| `AudioManager.instance.setAudioSessionOptions(...)` | Runtime. | Explicitly replaces the stored session options, switches to manual management, and applies LiveKit's platform session policy: Android audio mode, audio focus mode, stream type, focus ownership, routing handler policy, and iOS category/options/mode. |

Most fields in `AudioSessionOptions` are runtime session policy and can be applied again with `AudioManager.instance.setAudioSessionOptions(...)`. The exception is Android WebRTC playout attributes: changing `AndroidAudioSessionConfiguration.usageType` or `contentType` at runtime updates LiveKit's session/focus handler, but it does not change the `AudioAttributes` of an already-created WebRTC audio device module. Pass those options to `LiveKitClient.initialize(...)` before WebRTC initializes when they must affect playout volume/routing. You do not need to call `setAudioSessionOptions(...)` with the same options just to make LiveKit use them during automatic session management.

We plan to make Android WebRTC playout attributes runtime-updatable in a future SDK/WebRTC integration if the native layer can safely update the stored attributes and recreate playout with acceptable behavior. Until then, treat WebRTC playout `AudioAttributes` as initialization-time configuration.

## Automatic vs manual mode

The two modes differ in who owns the session lifecycle.

In automatic mode (the default) LiveKit manages the session from room, connect, and engine lifecycle. On iOS it derives the active category/mode from the current audio engine state. On Android it uses the current session intent, defaulting to communication and optionally seeded by `LiveKitClient.initialize(initialAudioSessionOptions: ...)`.

In manual mode LiveKit does not touch the session on its own, and your app owns it. Enter manual mode when you need to apply a fixed platform configuration or deactivate the session yourself.

```dart
// Apply a fixed config. This enters manual mode.
await AudioManager.instance.setAudioSessionOptions(
  const AudioSessionOptions.mediaPlayback(),
);

// Later, hand control back to LiveKit.
await AudioManager.instance.setAudioSessionManagementMode(
  AudioSessionManagementMode.automatic,
);
```

You can also enter manual mode without applying a new config:

```dart
await AudioManager.instance.setAudioSessionManagementMode(
  AudioSessionManagementMode.manual,
);
```

To release the active session, call `deactivateAudioSession`. It also enters manual mode if needed, so LiveKit does not immediately reactivate the session from engine lifecycle.

```dart
// Release the active session when your manual lifecycle no longer needs it.
await AudioManager.instance.deactivateAudioSession();
```

Prefer setting the mode before connecting to a room.

## Speaker routing

```dart
// Prefer the speaker. A wired or Bluetooth headset still takes priority.
await AudioManager.instance.setSpeakerOutputPreferred(true);

// Force the speaker even when a headset is connected.
await AudioManager.instance.setSpeakerOutputPreferred(true, force: true);

// Route back to the earpiece or the connected headset when supported by the
// active platform session.
await AudioManager.instance.setSpeakerOutputPreferred(false);
```

Speaker routing is independent of the management mode and does not switch it. In Android communication/call sessions and in iOS automatic mode, LiveKit applies the preference through its managed route policy. In iOS manual mode, the fixed Apple config you apply owns non-forced receiver vs speaker behavior. `force: true` still uses Apple's speaker override when the active category is `playAndRecord`. Read the current preference through `AudioManager.instance.isSpeakerOutputPreferred` and `AudioManager.instance.isSpeakerOutputForced`. `AudioManager.instance.canSwitchSpeakerphone` is true on iOS and Android.

On Android, LiveKit speaker routing is a communication/call routing policy. Media sessions use Android's normal media routing. Pass `AudioSessionOptions.mediaPlayback()` to `LiveKitClient.initialize` before WebRTC initializes when the WebRTC audio device module should use media attributes.

`Room.setSpeakerOn(...)` is deprecated and forwards to `AudioManager.instance.setSpeakerOutputPreferred`. You can also set an initial preference through `RoomOptions` (`defaultAudioOutputOptions.speakerOn`) before connecting, which LiveKit applies when the session starts.

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

## Audio processing

Session management is one half of the audio stack. The other half is audio processing, the signal processing applied to captured audio such as echo cancellation, noise suppression, auto gain control, and the high pass filter. `AudioManager` is the home for both, and they compose cleanly.

The session intent decides how the platform treats audio. Capture options decide what happens to local microphone audio:

- A call usually uses the automatic `communication` session. The default `AudioCaptureOptions` enable echo cancellation, noise suppression, and auto gain control, while leaving the high pass filter off.
- Use `AudioProcessingOptions.communication()` when you want all four voice filters on for an existing local audio track.
- Use `AudioProcessingOptions.noProcessing()` for local capture where you want minimal processing, such as high quality recording or app-managed audio effects.

Create-time processing is configured through `AudioCaptureOptions`. `LocalAudioTrack.create(...)` stores these options, and LiveKit prepares them when local recording starts, such as during publish or preconnect. If the exposed native platform API reports that capture-time setup failed, the start path throws `AudioProcessingException` before publish creates a server-side publication.

```dart
final track = await LocalAudioTrack.create(
  const AudioCaptureOptions(
    echoCancellation: true,
    noiseSuppression: true,
    autoGainControl: true,
    highPassFilter: false,
  ),
);
```

For an existing local audio track, call `setAudioProcessingOptions`. It returns when the native layer applies or stores the options. If the request is invalid, unsupported, or cannot be applied, it throws `AudioProcessingException` and the track keeps its previous processing options.

```dart
try {
  await localAudioTrack.setAudioProcessingOptions(
    const AudioProcessingOptions.noProcessing(),
  );
} on AudioProcessingException catch (error) {
  print('audio processing not applied: ${error.reason.name} ${error.message}');
}
```

The processing module is owned by the native peer connection factory and shared across the whole engine, so the resolved state is read back through `AudioManager` rather than from a single track:

```dart
final state = await AudioManager.instance.getAudioProcessingState();
print('echo cancellation in effect: ${state?.echoCancellation.effective}');
```

## Per platform overrides

When the preset constructors are not enough you can pin exact platform values. Supplying options through `setAudioSessionOptions` switches to manual mode, so these configs are a manual-mode tool. `AudioSessionOptions.communication()` and `AudioSessionOptions.mediaPlayback()` pre-fill Apple and Android configs. Passing `apple` or `android` replaces that platform config rather than merging with the preset.

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

For an `apple` config, your exact category, options, and mode are applied as written. For an `android` config, any field you leave null is omitted so the native manager keeps its current value for that field.

### Updating options with copyWith

`AudioSessionOptions.copyWith` uses `ValueOrAbsent` to replace the Apple or Android config as a whole. A bare `copyWith()` keeps the existing config, and `ValueOrAbsent.value(x)` sets a new config. The Apple and Android config objects have their own `copyWith` methods for clearing nullable native fields with `ValueOrAbsent.value(null)`.

```dart
const base = AudioSessionOptions.communication();

// Use the media Android config, keep the Apple config.
final updated = base.copyWith(
  android: const ValueOrAbsent.value(AndroidAudioSessionConfiguration.media),
);

// Clear just the Apple mode field inside the Apple config.
final clearedMode = updated.copyWith(
  apple: ValueOrAbsent.value(
    updated.apple.copyWith(mode: const ValueOrAbsent.value(null)),
  ),
);
```

Create a new `AudioSessionOptions.communication()` or `AudioSessionOptions.mediaPlayback()` when you want to start from a different preset config.

## Platform support

| Platform | Audio session | Speaker routing | Engine state |
| --- | --- | --- | --- |
| iOS | Automatic mode follows live engine state. Manual mode applies your Apple config verbatim. | Yes. Normal preference respects wired and Bluetooth devices. Forced speaker uses Apple's speaker override while the active category is `playAndRecord`. | Yes, from native WebRTC engine events. |
| macOS | Not configured. There is no `AVAudioSession`. | No. `canSwitchSpeakerphone` is false. | Yes, the same engine events are reported. |
| Android | Automatic mode uses the current session intent, seeded by `LiveKitClient.initialize(initialAudioSessionOptions: ...)` and defaulting to communication. Pass media options before WebRTC initializes when the WebRTC audio device module should use media mode/volume. | Yes for communication/call routing. Media playback follows Android media routing. | Not reported, the Dart state stays idle. |
| Web, Windows, Linux | Not configured. | No. `canSwitchSpeakerphone` is false. | Not reported. |

On iOS automatic mode, listen only playout uses `playback`. When recording starts, LiveKit reapplies the session as `playAndRecord`. In manual mode, non-forced receiver vs speaker behavior comes from the Apple config you applied.

Dart track counting no longer drives the session. The native audio engine delegate drives it from real lifecycle events, which removes the timing races and missed deactivations of the older counting approach.

## Migrating from the old APIs

The legacy `Hardware` audio members still work but are deprecated and forward to `AudioManager`.

| Old | New |
| --- | --- |
| `Hardware.instance.setSpeakerphoneOn(true)` | `AudioManager.instance.setSpeakerOutputPreferred(true)` |
| `room.setSpeakerOn(true)` | `AudioManager.instance.setSpeakerOutputPreferred(true)` |
| `Hardware.instance.speakerOn` | `AudioManager.instance.isSpeakerOutputPreferred` |
| `Hardware.instance.preferSpeakerOutput` | `AudioManager.instance.isSpeakerOutputPreferred` |
| `Hardware.instance.forceSpeakerOutput` | `AudioManager.instance.isSpeakerOutputForced` |
| `Hardware.instance.setAutomaticConfigurationEnabled(enable: false)` | `AudioManager.instance.setAudioSessionManagementMode(AudioSessionManagementMode.manual)` |

The old `onConfigureNativeAudio` hook (a deep src import) is removed. Replace a custom configuration function with explicit options, which run in manual mode.

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

## API reference

The full generated API reference for these types lives at [pub.dev](https://pub.dev/documentation/livekit_client/latest/). Start from `AudioManager`, `AudioSessionOptions`, `AppleAudioSessionConfiguration`, `AndroidAudioSessionConfiguration`, and `AudioProcessingOptions`.
