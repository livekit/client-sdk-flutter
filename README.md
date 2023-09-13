<!--BEGIN_BANNER_IMAGE-->
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="/.github/banner_dark.png">
    <source media="(prefers-color-scheme: light)" srcset="/.github/banner_light.png">
    <img style="width:100%;" alt="The LiveKit icon, the name of the repository and some sample code in the background." src="/.github/banner_light.png">
  </picture>
  <!--END_BANNER_IMAGE-->

[![pub package](https://img.shields.io/pub/v/livekit_client?label=livekit_client&color=blue)](https://pub.dev/packages/livekit_client)

# LiveKit Flutter SDK

<!--BEGIN_DESCRIPTION-->Use this SDK to add real-time video, audio and data features to your Flutter app. By connecting to a self- or cloud-hosted <a href="https://livekit.io/">LiveKit</a> server, you can quickly build applications like interactive live streaming or video calls with just a few lines of code.<!--END_DESCRIPTION-->

This package is published to pub.dev as [livekit_client](https://pub.dev/packages/livekit_client).

## Docs

More Docs and guides are available at [https://docs.livekit.io](https://docs.livekit.io)

## Current supported features

| Feature | Subscribe/Publish | Simulcast | Background audio | Screen sharing | End to End Encryption | Multi Codec Simulcast |
| :-----: | :---------------: | :-------: | :--------------: | :------------: | :-------------------: | :-------------------: |
|   iOS   |        🟢         |    🟢     |        🟢        |       🟢       |       🟢               |          🟢          |
| Android |        🟢         |    🟢     |        🟢        |       🟢       |       🟢               |          🟢          |
|   Mac   |        🟢         |    🟢     |        🟢        |       🟢       |       🟢               |          🟢          |
| Windows |        🟢         |    🟢     |        🟢        |       🟢       |       🟢               |          🟢          |
| Linux   |        🟢         |    🟢     |        🟢        |       🟢       |       🟢               |          🟢          |

🟢 = Available

🟡 = Coming soon (Work in progress)

🔴 = Not currently available (Possibly in the future)

## Example app

We built a multi-user conferencing app as an example in the [example/](example/) folder. You can join the same room from any supported LiveKit clients.

## Installation

Include this package to your `pubspec.yaml`

```yaml
---
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

#### Notes

Since [xcode 14](https://developer.apple.com/news/upcoming-requirements/?id=06062022a) no longer supports 32bit builds, and our latest version is based on libwebrtc m104+ the iOS framework no longer supports 32bit builds, we strongly recommend upgrading to flutter 3.3.0+. if you are using flutter 3.0.0 or below, there is a high chance that your flutter app cannot be compiled correctly due to the missing i386 and arm 32bit framework [#132](https://github.com/livekit/client-sdk-flutter/issues/132) [#172](https://github.com/livekit/client-sdk-flutter/issues/172).

You can try to modify your `{projects_dir}/ios/Podfile` to fix this issue.

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    target.build_configurations.each do |config|

      # Workaround for https://github.com/flutter/flutter/issues/64502
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES' # <= this line

    end
  end
end
```

For iOS, the minimum supported deployment target is `12.1`. You will need to add the following to your Podfile.

```ruby
platform :ios, '12.1'
```

You may need to delete `Podfile.lock` and re-run `pod install` after updating deployment target.

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
  <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
  <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
  <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
  ...
</manifest>
```

For using the bluetooth headset correctly on the android device, you need to add `permission_handler` to your project.
And call the following code after launching your app for the first time.

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> _checkPermissions() async {
  var status = await Permission.bluetooth.request();
  if (status.isPermanentlyDenied) {
    print('Bluetooth Permission disabled');
  }
  status = await Permission.bluetoothConnect.request();
  if (status.isPermanentlyDenied) {
    print('Bluetooth Connect Permission disabled');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _checkPermissions();
  runApp(MyApp());
}
```

#### Audio Modes

By default, we use the `communication` audio mode on Android which works best for two-way voice communication. 

If your app is media playback oriented and does not need the use of the device's microphone, you can use the `media`
audio mode which will provide better audio quality.

```dart
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

Future<void> _initializeAndroidAudioSettings() async {
  await webrtc.WebRTC.initialize(options: {
    'androidAudioConfiguration': webrtc.AndroidAudioConfiguration.media.toMap()
  });
  webrtc.Helper.setAndroidAudioConfiguration(
      webrtc.AndroidAudioConfiguration.media);
}

void main() async {
  await _initializeAudioSettings();
  runApp(const MyApp());
}
```

Note: the audio routing will become controlled by the system and cannot be manually changed with functions like
`Hardware.selectAudioOutput`.

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

Screen sharing is supported across all platforms. You can enable it with:

```dart
room.localParticipant.setScreenShareEnabled(true);
```

#### Android

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

#### iOS

On iOS, a broadcast extension is needed in order to capture screen content from
other apps. See [setup guide](https://github.com/flutter-webrtc/flutter-webrtc/wiki/iOS-Screen-Sharing#broadcast-extension-quick-setup) for instructions.

#### Desktop(Windows/macOS)

On dekstop you can use `ScreenSelectDialog` to select the window or screen you want to share.

```dart
try {
  final source = await showDialog<DesktopCapturerSource>(
    context: context,
    builder: (context) => ScreenSelectDialog(),
  );
  if (source == null) {
    print('cancelled screenshare');
    return;
  }
  print('DesktopCapturerSource: ${source.id}');
  var track = await LocalVideoTrack.createScreenShareTrack(
    ScreenShareCaptureOptions(
      sourceId: source.id,
      maxFrameRate: 15.0,
    ),
  );
  await room.localParticipant.publishVideoTrack(track);
} catch (e) {
  print('could not publish screen sharing: $e');
}
```

### End to End Encryption

LiveKit supports end-to-end encryption for audio/video data sent over the network.
By default, the native platform can support E2EE without any settings, but for flutter web, you need to use the following steps to create `e2ee.worker.dart.js` file.

```bash
# for example app
dart compile js .\web\e2ee.worker.dart -o .\example\web\e2ee.worker.dart.js
# for your project
export YOU_PROJECT_DIR=your_project_dir
git clone https://github.com/livekit/client-sdk-flutter.git
cd client-sdk-flutter && flutter pub get
dart compile js .\web\e2ee.worker.dart -o ${YOU_PROJECT_DIR}\web\e2ee.worker.dart.js
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

- `ChangeNotifier` - generic notification of changes. This is useful when you are building reactive UI and only care about changes that may impact rendering.
- `EventsListener<Event>` - listener pattern to listen to specific events (see [events.dart](https://github.com/livekit/client-sdk-flutter/blob/main/lib/src/events.dart)).

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

Please join us on [Slack](https://livekit.io/join-slack) to get help from our devs / community members. We welcome your contributions(PRs) and details can be discussed there.

## License

Apache License 2.0

## Thanks

A huge thank you to [flutter-webrtc](https://github.com/flutter-webrtc/flutter-webrtc) for making it possible to use WebRTC in Flutter.

<!--BEGIN_REPO_NAV-->

<br/><table>

<thead><tr><th colspan="2">LiveKit Ecosystem</th></tr></thead>
<tbody>
<tr><td>Client SDKs</td><td><a href="https://github.com/livekit/components-js">Components</a> · <a href="https://github.com/livekit/client-sdk-js">JavaScript</a> · <a href="https://github.com/livekit/client-sdk-swift">iOS/macOS</a> · <a href="https://github.com/livekit/client-sdk-android">Android</a> · <b>Flutter</b> · <a href="https://github.com/livekit/client-sdk-react-native">React Native</a> · <a href="https://github.com/livekit/client-sdk-rust">Rust</a> · <a href="https://github.com/livekit/client-sdk-python">Python</a> · <a href="https://github.com/livekit/client-sdk-unity-web">Unity (web)</a> · <a href="https://github.com/livekit/client-sdk-unity">Unity (beta)</a></td></tr><tr></tr>
<tr><td>Server SDKs</td><td><a href="https://github.com/livekit/server-sdk-js">Node.js</a> · <a href="https://github.com/livekit/server-sdk-go">Golang</a> · <a href="https://github.com/livekit/server-sdk-ruby">Ruby</a> · <a href="https://github.com/livekit/server-sdk-kotlin">Java/Kotlin</a> · <a href="https://github.com/agence104/livekit-server-sdk-php">PHP (community)</a> · <a href="https://github.com/tradablebits/livekit-server-sdk-python">Python (community)</a></td></tr><tr></tr>
<tr><td>Services</td><td><a href="https://github.com/livekit/livekit">Livekit server</a> · <a href="https://github.com/livekit/egress">Egress</a> · <a href="https://github.com/livekit/ingress">Ingress</a></td></tr><tr></tr>
<tr><td>Resources</td><td><a href="https://docs.livekit.io">Docs</a> · <a href="https://github.com/livekit-examples">Example apps</a> · <a href="https://livekit.io/cloud">Cloud</a> · <a href="https://docs.livekit.io/oss/deployment">Self-hosting</a> · <a href="https://github.com/livekit/livekit-cli">CLI</a></td></tr>
</tbody>
</table>
<!--END_REPO_NAV-->
