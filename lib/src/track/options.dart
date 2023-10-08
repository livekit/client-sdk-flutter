// Copyright 2023 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/foundation.dart' show kIsWeb;

import '../support/platform.dart';
import '../track/local/audio.dart';
import '../track/local/video.dart';
import '../types/video_parameters.dart';

/// A type that represents front or back of the camera.
enum CameraPosition {
  front,
  back,
}

/// Convenience extension for [CameraPosition].
extension CameraPositionExt on CameraPosition {
  /// Return a [CameraPosition] which front and back is switched.
  CameraPosition switched() => {
        CameraPosition.front: CameraPosition.back,
        CameraPosition.back: CameraPosition.front,
      }[this]!;
}

/// Options used when creating a [LocalVideoTrack] that captures the camera.
class CameraCaptureOptions extends VideoCaptureOptions {
  final CameraPosition cameraPosition;

  const CameraCaptureOptions({
    this.cameraPosition = CameraPosition.front,
    String? deviceId,
    double? maxFrameRate,
    VideoParameters params = VideoParametersPresets.h720_169,
  }) : super(params: params, deviceId: deviceId, maxFrameRate: maxFrameRate);

  CameraCaptureOptions.from({required VideoCaptureOptions captureOptions})
      : cameraPosition = CameraPosition.front,
        super(
          params: captureOptions.params,
          deviceId: captureOptions.deviceId,
          maxFrameRate: captureOptions.maxFrameRate,
        );

  @override
  Map<String, dynamic> toMediaConstraintsMap() {
    var constraints = <String, dynamic>{
      ...super.toMediaConstraintsMap(),
      if (deviceId == null)
        'facingMode':
            cameraPosition == CameraPosition.front ? 'user' : 'environment'
    };
    if (deviceId != null) {
      if (kIsWeb) {
        constraints['deviceId'] = deviceId;
      } else {
        constraints['optional'] = [
          {'sourceId': deviceId}
        ];
      }
    }
    if (maxFrameRate != null) {
      constraints['frameRate'] = {'max': maxFrameRate};
    }
    return constraints;
  }

  // Returns new options with updated properties
  CameraCaptureOptions copyWith({
    VideoParameters? params,
    CameraPosition? cameraPosition,
    String? deviceId,
    double? maxFrameRate,
  }) =>
      CameraCaptureOptions(
        params: params ?? this.params,
        cameraPosition: cameraPosition ?? this.cameraPosition,
        deviceId: deviceId ?? this.deviceId,
        maxFrameRate: maxFrameRate ?? this.maxFrameRate,
      );
}

/// Options used when creating a [LocalVideoTrack] that captures the screen.
class ScreenShareCaptureOptions extends VideoCaptureOptions {
  /// iOS only flag: Use Broadcast Extension for screen share capturing.
  /// See instructions on how to setup your Broadcast Extension here:
  /// https://github.com/flutter-webrtc/flutter-webrtc/wiki/iOS-Screen-Sharing#broadcast-extension-quick-setup
  final bool useiOSBroadcastExtension;

  // for browser only, if true, will capture screen audio.
  final bool captureScreenAudio;

  /// for browser only, if true, will capture current tab.
  final bool preferCurrentTab;

  /// for browser only, include or exclude self browser surface.
  final String? selfBrowserSurface;

  const ScreenShareCaptureOptions({
    this.useiOSBroadcastExtension = false,
    this.captureScreenAudio = false,
    this.preferCurrentTab = false,
    this.selfBrowserSurface,
    String? sourceId,
    double? maxFrameRate,
    VideoParameters params = VideoParametersPresets.screenShareH1080FPS15,
  }) : super(params: params, deviceId: sourceId, maxFrameRate: maxFrameRate);

  ScreenShareCaptureOptions.from(
      {this.useiOSBroadcastExtension = false,
      this.captureScreenAudio = false,
      this.preferCurrentTab = false,
      this.selfBrowserSurface,
      required VideoCaptureOptions captureOptions})
      : super(params: captureOptions.params);

  ScreenShareCaptureOptions copyWith({
    bool? useiOSBroadcastExtension,
    bool? captureScreenAudio,
    VideoParameters? params,
    String? sourceId,
    double? maxFrameRate,
    bool? preferCurrentTab,
    String? selfBrowserSurface,
  }) =>
      ScreenShareCaptureOptions(
        useiOSBroadcastExtension:
            useiOSBroadcastExtension ?? this.useiOSBroadcastExtension,
        captureScreenAudio: captureScreenAudio ?? this.captureScreenAudio,
        params: params ?? this.params,
        sourceId: sourceId ?? deviceId,
        maxFrameRate: maxFrameRate ?? this.maxFrameRate,
        preferCurrentTab: preferCurrentTab ?? this.preferCurrentTab,
        selfBrowserSurface: selfBrowserSurface ?? this.selfBrowserSurface,
      );

  @override
  Map<String, dynamic> toMediaConstraintsMap() {
    var constraints = super.toMediaConstraintsMap();
    if (useiOSBroadcastExtension && lkPlatformIs(PlatformType.iOS)) {
      constraints['deviceId'] = 'broadcast';
    }
    if (lkPlatformIsDesktop()) {
      if (deviceId != null) {
        constraints['deviceId'] = {'exact': deviceId};
      }
      if (maxFrameRate != 0.0) {
        constraints['mandatory'] = {'frameRate': maxFrameRate};
      }
    }
    return constraints;
  }
}

/// Base class for track options.
abstract class LocalTrackOptions {
  const LocalTrackOptions();

  // All subclasses must be able to report constraints
  Map<String, dynamic> toMediaConstraintsMap();
}

/// Base class for options when creating a [LocalVideoTrack].
abstract class VideoCaptureOptions extends LocalTrackOptions {
  // final LocalVideoTrackType type;
  final VideoParameters params;

  /// The deviceId of the capture device to use.
  /// Available deviceIds can be obtained through `flutter_webrtc`:
  /// <pre>
  /// import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
  ///
  /// List<MediaDeviceInfo> devices = await rtc.navigator.mediaDevices.enumerateDevices();
  /// // or
  /// List<DesktopCapturerSource> desktopSources = await rtc.desktopCapturer.getSources(types: [rtc.SourceType.Screen, rtc.SourceType.Window]);
  /// </pre>
  final String? deviceId;

  // Limit the maximum frameRate of the capture device.
  final double? maxFrameRate;

  const VideoCaptureOptions({
    this.params = VideoParametersPresets.h540_169,
    this.deviceId,
    this.maxFrameRate,
  });

  @override
  Map<String, dynamic> toMediaConstraintsMap() =>
      params.toMediaConstraintsMap();
}

/// Options used when creating a [LocalAudioTrack].
class AudioCaptureOptions extends LocalTrackOptions {
  /// The deviceId of the capture device to use.
  /// Available deviceIds can be obtained through `flutter_webrtc`:
  /// <pre>
  /// import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
  ///
  /// List<MediaDeviceInfo> devices = await rtc.navigator.mediaDevices.enumerateDevices();
  /// </pre>
  final String? deviceId;

  /// Attempt to use noiseSuppression option (if supported by the platform)
  /// See https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/noiseSuppression
  /// Defaults to true.
  final bool noiseSuppression;

  /// Attempt to use echoCancellation option (if supported by the platform)
  /// See https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/echoCancellation
  /// Defaults to true.
  final bool echoCancellation;

  /// Attempt to use autoGainControl option (if supported by the platform)
  /// See https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackConstraints/autoGainControl
  /// Defaults to true.
  final bool autoGainControl;

  /// Attempt to use highPassFilter options (if supported by the platform)
  /// Defaults to false.
  final bool highPassFilter;

  /// Attempt to use typingNoiseDetection option (if supported by the platform)
  /// Defaults to true.
  final bool typingNoiseDetection;

  const AudioCaptureOptions({
    this.deviceId,
    this.noiseSuppression = true,
    this.echoCancellation = true,
    this.autoGainControl = true,
    this.highPassFilter = false,
    this.typingNoiseDetection = true,
  });

  @override
  Map<String, dynamic> toMediaConstraintsMap() {
    var constraints = <String, dynamic>{};

    /// in we platform it's not possible to provide optional and mandatory parameters.
    /// deviceId is a mandatory parameter
    if (!kIsWeb || (kIsWeb && deviceId == null)) {
      constraints['optional'] = <Map<String, dynamic>>[
        <String, dynamic>{'echoCancellation': echoCancellation},
        <String, dynamic>{'googDAEchoCancellation': echoCancellation},
        <String, dynamic>{'googEchoCancellation': echoCancellation},
        <String, dynamic>{'googEchoCancellation2': echoCancellation},
        <String, dynamic>{'noiseSuppression': noiseSuppression},
        <String, dynamic>{'googNoiseSuppression': noiseSuppression},
        <String, dynamic>{'googNoiseSuppression2': noiseSuppression},
        <String, dynamic>{'googAutoGainControl': autoGainControl},
        <String, dynamic>{'googHighpassFilter': highPassFilter},
        <String, dynamic>{'googTypingNoiseDetection': typingNoiseDetection},
      ];
    }

    if (deviceId != null) {
      if (kIsWeb) {
        constraints['deviceId'] = deviceId;
      } else {
        constraints['optional']
            .cast<Map<String, dynamic>>()
            .add(<String, dynamic>{'sourceId': deviceId});
      }
    }
    return constraints;
  }

  AudioCaptureOptions copyWith({
    String? deviceId,
    bool? noiseSuppression,
    bool? echoCancellation,
    bool? autoGainControl,
    bool? highPassFilter,
    bool? typingNoiseDetection,
  }) {
    return AudioCaptureOptions(
      deviceId: deviceId ?? this.deviceId,
      noiseSuppression: noiseSuppression ?? this.noiseSuppression,
      echoCancellation: echoCancellation ?? this.echoCancellation,
      autoGainControl: autoGainControl ?? this.autoGainControl,
      highPassFilter: highPassFilter ?? this.highPassFilter,
      typingNoiseDetection: typingNoiseDetection ?? this.typingNoiseDetection,
    );
  }
}

class AudioOutputOptions {
  /// The deviceId of the output device to use.
  final String? deviceId;

  /// If true, the audio will be played on the speaker.
  /// for mobile only
  final bool? speakerOn;

  const AudioOutputOptions({this.deviceId, this.speakerOn});

  AudioOutputOptions copyWith({String? deviceId, bool? speakerOn}) {
    return AudioOutputOptions(
      deviceId: deviceId ?? this.deviceId,
      speakerOn: speakerOn ?? this.speakerOn,
    );
  }
}
