# CHANGELOG

## 1.1.11

* Fix: fix connection fails for firefox. (#222, close #221)

## 1.1.10

* Fix: Disconnect from room before app closes.
* Fix: Correctly throws final error when connection fails.

## 1.1.9

* Bump flutter-webrtc to 0.9.17
* Enable BroadCastExtension for iOS in example.

## 1.1.8

* Fix resume/full-reconnect.
* Support stop audio track on mute(turn off the mic indicator).

## 1.1.7

* Fixed ice config issues. (#192).
* Make timeouts configurable.
* Fixed Hardware.setSpeakerphoneOn() not working on iOS.
* Fixed track not being correctly passed to localParticipant in FastConnectOptions,
  causing the camera to apply twice and not be released.
* Clean up pingIntervalTimer when closing SignalClient.

## 1.1.6

* Supports getting the connected remote address.

## 1.1.5

* Make MediaDevice data class.
* Add simulate for candidate protocol switch.
* Fix VideoTrackRenderer for local has been blacked when toggle video status #166

## 1.1.4

* Fixed timestamp type error in ping/pong.

## 1.1.3

* Add sid for reconnecting. (#168)
* Add force relay config. (#169)
* Bump flutter_webrtc version to 0.9.7.

## 1.1.2

* feat: Support for capturing audio for chrome tab.
* Expose dataChannel for e2e testing.
* Expose RTPReceiver for getting track statistics.
* fix: Do not set mandatory & optional parameters, when used in web (#164)
* fix: fix setSpeakerphoneOn, close #167.

## 1.1.1-hotfix

* Fix compilation error caused by webrtc-interface version jumping.

## 1.1.1

* Add hardware api for camera and audio input/output selection.
* Fixed UI stuck when get thumbnails on screen sharing. (#149)

## 1.1.0-hotfix

* Align the version in .podspec with the package version (fix compilation errors under ios/mac).

## 1.1.0

* Set subscription to allowed when subscribed.
* Handle combined participant update.
* Downgrade version settings to support flutter 2.8.0+.
* Fix: camera release.
* Feat: iOS screen share.
* Feat: Screen sharing for desktop.
* Feat: protocol v8.

## 1.0.1

* Re-send tracks permissions after reconnected.
* Add audioBitrate option for publishAudioTrack.
* Bump version for flutter_webrtc (up to 0.8.9).
* Fix: SIGTERM / Crash on connection (Windows) #121
* Fix: Microphone not published on windows build #64

## 1.0.0

* Ready for Flutter 3.
* `mirrorMode` for `VideoTrackRenderer`.
* Fix url building logic for validation mode.
* Changed `AVAudioSessionCategory` switch timing to publish / unpublish.
* Support for Bluetooth on Android 11.

## 0.5.9

* Fix: iOS audio issue which prevents `AVAudioSessionCategory` to switch correctly.

## 0.5.8

* Support for protocol 7, remote unpublish.
* Fixes simulcast issues with Android devices.
* Adds ability to select capture device by id.
* `serverRegion` property on Room.
* Minor optimizations.

## 0.5.7

* Using WebRTC version M97.
* New track subscription permissions API.
* Improvements to reconnect logic.
* Room metadata update event.

## 0.5.6

* Using WebRTC version M93.
* New `dynacast` option to `RoomOptions`. Dynacast dynamically pauses
  video layers that are not being consumed by any subscribers, significantly
  reducing publishing CPU and bandwidth usage. (currently defaults to off)
* Rename `optimizeVideo` to `adaptiveStream` and improve stability.
  AdaptiveStream lets LiveKit automatically manage quality of subscribed 
  video tracks to optimize for bandwidth and CPU.
* Ensure data channel is ready state when `LocalParticipant.publishData` api is called.

## 0.5.5

* Default capture options for setCameraEnabled, setMicrophoneEnabled
* Track stream update events
* Send video layers to server for more video optimization
* Room instance can be created without connecting
* Release Camera/Mic when track is muted
* Better type handling
* Option to unpublish without stopping track
* Fixed RemoteTrackPublication mute events
* Fixed data channel publish bug
* Initial Windows support

## 0.5.4

* Screen sharing support for Android
* Fixed TrackPublication/Track mute status
* Fixed bug with updateTrack
* Fixed being able to apply capture resolution constraints
* Initial macOS support

## 0.5.3

* Connection quality information
* Automatic video optimizations
* Simplified track APIs
* Fix ios camera switch issue
* Looser podspec constraint for WebRTC-SDK to avoid build issues
* Better URL parsing

## 0.5.2

* change ios audio session defaults to support voice isolation
* fix explicit subscribe/unsubscribe issue
* fix WebRTC-SDK resolve issue

## 0.5.1

* include plugins for Android and Web

## 0.5.0

* major update with new event system
* supports simulcast for iOS
* support for background audio for iOS
* support for protocol 3, subscriber as primary connection
* improved audio management for iOS, mic indicator only when audio tracks published
* fires TrackUnpublished for local tracks
* fixed occasional crashes during publishing

## 0.4.1

* fixed video rendering blank after widget changes

## 0.4.0

* fixed audio track playback for web
* fixed publishing tracks for web
* updated constants to be lowerCamelCase
* updated style & formatting guide

## 0.3.0

* `replaceTrack` API to switch camera sources
* example app works on Android

## 0.2.0

* pass more detailed connect error message
* bugfixes with publishing duplicate video tracks
* removed use of media stream during publishing

## 0.1.1

* Minor improvements to error handling

## 0.1.0

* Initial beta release.
