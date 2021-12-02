# CHANGELOG

## 0.5.4

* Screen sharing support for Android
* Fixed TrackPublication/Track mute status
* Fixed bug with updateTrack
* Fixed being able to apply capture resolution constraints
* initial macOS support

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
