# LiveKit Flutter SDK

Official Flutter SDK for [LiveKit](https://livekit.io). Easily add real-time video and audio to your Flutter apps.

This package is published to pub.dev as [livekit_client](https://pub.dev/packages/livekit_client).

## Docs

Docs and guides at [https://docs.livekit.io](https://docs.livekit.io)

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
...
<dict>
  <key>NSCameraUsageDescription</key>
  <string>$(PRODUCT_NAME) uses your camera</string>
  <key>NSMicrophoneUsageDescription</key>
  <string>$(PRODUCT_NAME) uses your microphone</string>
</dict>
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

## Example app

We built a multi-user conferencing app as an example in the [example/](example/) folder. You can join the same room from any supported LiveKit clients.

## Usage

### Connecting to a room, publish video & audio

```dart
var room = await LiveKitClient.connect(this.url, this.token);
try {
  // video will fail when running in ios simulator
  var localVideo = await LocalVideoTrack.createCameraTrack();
  await room.localParticipant.publishVideoTrack(localVideo);
} catch (e) {
  print('could not publish video: $e');
}

var localAudio = await LocalAudioTrack.createTrack();
await room.localParticipant.publishAudioTrack(localAudio);
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

Audio tracks are rendered automatically as long as you are subscribed to them.

### Handling changes

LiveKit client makes it simple to build declarative UI that reacts to state changes. It notifies changes in two ways

* `ChangeNotifier` - generic notification of changes
* `RoomDelegate` and `ParticipantDelegate` - notification of specific events.

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

class _RoomState extends State<RoomWidget> with RoomDelegate {
  @override
  void initState() {
    super.initState();
    widget.room.delegate = this;
    widget.room.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.room.delegate = null;
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
  void onDisconnected() {
    // onDisconnected is a RoomDelegate method, handle when disconnected from room
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

class _VideoViewState extends State<VideoView> with ParticipantDelegate {
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
        if (videoPub is RemoteTrackPublication) {
          videoPub.videoQuality = widget.quality;
        }
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

## License

Apache License 2.0

## Thanks

A huge thank you to [flutter-webrtc](https://github.com/flutter-webrtc/flutter-webrtc) for making it possible to use WebRTC in Flutter.
