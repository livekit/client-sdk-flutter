[![pub package](https://img.shields.io/pub/v/livekit_client?label=livekit_client&color=blue)](https://pub.dev/packages/livekit_client)

# LiveKit Flutter SDK

Official Flutter SDK for [LiveKit](https://livekit.io). Easily add real-time video and audio to your Flutter apps.

This package is published to pub.dev as [livekit_client](https://pub.dev/packages/livekit_client).

## Docs

More Docs and guides are available at [https://docs.livekit.io](https://docs.livekit.io)

## Current supported features

| Feature | Subscribe/Publish | Simulcast | Background audio | Screen sharing |
| :-----: | :---------------: | :-------: | :--------------: | :------------: |
|   Web   |         🟢         |     🟢     |        🟢         |       🟢        |
|   iOS   |         🟢         |     🟢     |        🟢         |       🔴        |
| Android |         🟢         |     🟢     |        🟢         |       🟢        |
|   Mac   |         🟢         |     🟢     |        🟢         |       🔴        |
| Windows |         🟡         |     🟡     |        🟡         |       🔴        |

🟢 = Available

🟡 = Coming soon (Work in progress)

🔴 = Not currently available (Possibly in the future)


## Example app

We built a multi-user conferencing app as an example in the [example/](example/) folder. You can join the same room from any supported LiveKit clients.

## Installation

Include this package to your `pubspec.yaml`

```yaml
...
dependencies:
  livekit_client: <version>
```

### iOS

Camera and microphone usage need to be declared in your `Info.plist` file.

```xml
<dict>
  ...
  <key>NSCameraUsageDescription</key>
  <string>$(PRODUCT_NAME) uses your camera</string>
  <key>NSMicrophoneUsageDescription</key>
  <string>$(PRODUCT_NAME) uses your microphone</string>
```

Your application can still run the voice call when it is switched to the background if the background mode is enabled. Select the app target in Xcode, click the Capabilities tab, enable Background Modes, and check **Audio, AirPlay, and Picture in Picture**.

Your `Info.plist` should have the following entries.

```xml
<dict>
  ...
  <key>UIBackgroundModes</key>
  <array>
    <string>audio</string>
  </array>
```

### Android

We require a set of permissions that need to be declared in your `AppManifest.xml`. These are required by Flutter WebRTC, which we depend on.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.your.package">
  <uses-feature android:name="android.hardware.camera" />
  <uses-feature android:name="android.hardware.camera.autofocus" />
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
  <uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
  <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
  ...
</manifest>
```

### Desktop support

In order to enable Flutter desktop development, please follow [instructions here](https://docs.flutter.dev/desktop#set-up).

On M1 Macs, you will also need to install x86_64 version of FFI:

```
sudo arch -x86_64 gem install ffi
```

On Windows [VS 2019](https://visualstudio.microsoft.com/thank-you-downloading-visual-studio/?sku=community&rel=16) is needed (link in flutter docs will download VS 2022).

## Usage

### Connecting to a room, publish video & audio

```dart
final roomOptions = RoomOptions(
  adaptiveStream: true,
  dynacast: true,
  // ... your room options 
)

final room = await LiveKitClient.connect(url, token, roomOptions: roomOptions);
try {
  // video will fail when running in ios simulator
  await room.localParticipant.setCameraEnabled(true);
} catch (error) {
  print('Could not publish video, error: $error');
}

await room.localParticipant.setMicrophoneEnabled(true);
```

### Screen sharing

```dart
room.localParticipant.setScreenShareEnabled(true);
```

On Android, you would have to define a foreground service in your AndroidManifest.xml.

```xml title="AndroidManifest.xml"
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <application>
    ...
    <service
        android:name="de.julianassmann.flutter_background.IsolateHolderService"
        android:enabled="true"
        android:exported="false"
        android:foregroundServiceType="mediaProjection" />
  </application>
</manifest>
```

### Advanced track manipulation

The setCameraEnabled/setMicrophoneEnabled helpers are wrappers around the Track API.

You can also manually create and publish tracks:

```dart
var localVideo = await LocalVideoTrack.createCameraTrack();
await room.localParticipant.publishVideoTrack(localVideo);
```

### Rendering video

Each track can be rendered separately with the provided `VideoTrackRenderer` widget.

```dart
VideoTrack? track;

@override
Widget build(BuildContext context) {
  if (track != null) {
    return VideoTrackRenderer(track);
  } else {
    return Container(
      color: Colors.grey,
    );
  }
}
```

### Audio handling

Audio tracks are played automatically as long as you are subscribed to them.

### Handling changes

LiveKit client makes it simple to build declarative UI that reacts to state changes. It notifies changes in two ways

* `ChangeNotifier` - generic notification of changes. This is useful when you are building reactive UI and only care about changes that may impact rendering.
* `EventsListener<Event>` - listener pattern to listen to specific events (see [events.dart](https://github.com/livekit/client-sdk-flutter/blob/main/lib/src/events.dart)).

This example will show you how to use both to react to room events.

```dart
class RoomWidget extends StatefulWidget {
  final Room room;

  RoomWidget(this.room);

  @override
  State<StatefulWidget> createState() {
    return _RoomState();
  }
}

class _RoomState extends State<RoomWidget> {
  late final EventsListener<RoomEvent> _listener = widget.room.createListener();

  @override
  void initState() {
    super.initState();
    // used for generic change updates
    widget.room.addListener(_onChange);

    // used for specific events
    _listener
      ..on<RoomDisconnectedEvent>((_) {
        // handle disconnect
      })
      ..on<ParticipantConnectedEvent>((e) {
        print("participant joined: ${e.participant.identity}");
      })
  }

  @override
  void dispose() {
    // be sure to dispose listener to stop listening to further updates
    _listener.dispose();
    widget.room.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    // perform computations and then call setState
    // setState will trigger a build
    setState(() {
      // your updates here
    });
  }

  @override
  Widget build(BuildContext context) {
    // your build function
  }
}
```

Similarly, you could do the same when rendering participants. Reacting to changes makes it possible to handle tracks published/unpublished or re-ordering participants in your UI.

```dart
class VideoView extends StatefulWidget {
  final Participant participant;

  VideoView(this.participant);

  @override
  State<StatefulWidget> createState() {
    return _VideoViewState();
  }
}

class _VideoViewState extends State<VideoView> {
  TrackPublication? videoPub;

  @override
  void initState() {
    super.initState();
    widget.participant.addListener(this._onParticipantChanged);
    // trigger initial change
    _onParticipantChanged();
  }

  @override
  void dispose() {
    widget.participant.removeListener(this._onParticipantChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VideoView oldWidget) {
    oldWidget.participant.removeListener(_onParticipantChanged);
    widget.participant.addListener(_onParticipantChanged);
    _onParticipantChanged();
    super.didUpdateWidget(oldWidget);
  }

  void _onParticipantChanged() {
    var subscribedVideos = widget.participant.videoTracks.values.where((pub) {
      return pub.kind == TrackType.VIDEO &&
          !pub.isScreenShare &&
          pub.subscribed;
    });

    setState(() {
      if (subscribedVideos.length > 0) {
        var videoPub = subscribedVideos.first;
        // when muted, show placeholder
        if (!videoPub.muted) {
          this.videoPub = videoPub;
          return;
        }
      }
      this.videoPub = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    var videoPub = this.videoPub;
    if (videoPub != null) {
      return VideoTrackRenderer(videoPub.track as VideoTrack);
    } else {
      return Container(
        color: Colors.grey,
      );
    }
  }
}
```

### Mute, unmute local tracks

On `LocalTrackPublication`s, you could control if the track is muted by setting its `muted` property. Changing the mute status will generate an `onTrackMuted` or `onTrack Unmuted` delegate call for the local participant. Other participant will receive the status change as well.

```dart
// mute track
trackPub.muted = true;

// unmute track
trackPub.muted = false;
```

### Subscriber controls

When subscribing to remote tracks, the client has precise control over status of its subscriptions. You could subscribe or unsubscribe to a track, change its quality, or disabling the track temporarily.

These controls are accessible on the `RemoteTrackPublication` object.

For more info, see [Subscriber controls](https://docs.livekit.io/guides/room/receive#subscriber-controls).

## Getting help / Contributing

Please join us on [Slack](https://join.slack.com/t/livekit-users/shared_invite/zt-rrdy5abr-5pZ1wW8pXEkiQxBzFiXPUg) to get help from our [devs](https://github.com/orgs/livekit/teams/devs/members) / community members. We welcome your contributions(PRs) and details can be discussed there.

## License

Apache License 2.0

## Thanks

A huge thank you to [flutter-webrtc](https://github.com/flutter-webrtc/flutter-webrtc) for making it possible to use WebRTC in Flutter.
