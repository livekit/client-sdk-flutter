// Copyright 2024 LiveKit, Inc.
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

import '../support/native.dart';
import '../support/platform.dart';
import '../track/local/audio.dart';
import '../track/local/video.dart';
import '../types/video_parameters.dart';
import 'processor.dart';
import 'processor_native.dart' if (dart.library.js_interop) 'processor_web.dart';

/// A type that represents front or back of the camera.
enum CameraPosition {
  front,
  back,
}

enum CameraFocusMode { auto, locked }

enum CameraExposureMode { auto, locked }

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

  /// set to false to only toggle enabled instead of stop/replaceTrack for muting
  final bool stopCameraCaptureOnMute;

  /// The focus mode to use for the camera.
  final CameraFocusMode focusMode;

  /// The exposure mode to use for the camera.
  final CameraExposureMode exposureMode;

  const CameraCaptureOptions({
    this.cameraPosition = CameraPosition.front,
    this.focusMode = CameraFocusMode.auto,
    this.exposureMode = CameraExposureMode.auto,
    String? deviceId,
    double? maxFrameRate,
    VideoParameters params = VideoParametersPresets.h720_169,
    this.stopCameraCaptureOnMute = true,
    TrackProcessor<VideoProcessorOptions>? processor,
  }) : super(
          params: params,
          deviceId: deviceId,
          maxFrameRate: maxFrameRate,
          processor: processor,
        );

  CameraCaptureOptions.from({required VideoCaptureOptions captureOptions})
      : cameraPosition = CameraPosition.front,
        focusMode = CameraFocusMode.auto,
        exposureMode = CameraExposureMode.auto,
        stopCameraCaptureOnMute = true,
        super(
          params: captureOptions.params,
          deviceId: captureOptions.deviceId,
          maxFrameRate: captureOptions.maxFrameRate,
          processor: captureOptions.processor,
        );

  @override
  Map<String, dynamic> toMediaConstraintsMap() {
    final constraints = <String, dynamic>{
      ...super.toMediaConstraintsMap(),
      if (deviceId == null) 'facingMode': cameraPosition == CameraPosition.front ? 'user' : 'environment'
    };
    if (deviceId != null && deviceId!.isNotEmpty) {
      if (kIsWeb) {
        if (isChrome129OrLater()) {
          constraints['deviceId'] = {'exact': deviceId};
        } else {
          constraints['deviceId'] = {'ideal': deviceId};
        }
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
    CameraPosition? cameraPosition,
    CameraFocusMode? focusMode,
    CameraExposureMode? exposureMode,
    String? deviceId,
    double? maxFrameRate,
    VideoParameters? params,
    bool? stopCameraCaptureOnMute,
    TrackProcessor<VideoProcessorOptions>? processor,
  }) =>
      CameraCaptureOptions(
        cameraPosition: cameraPosition ?? this.cameraPosition,
        focusMode: focusMode ?? this.focusMode,
        exposureMode: exposureMode ?? this.exposureMode,
        deviceId: deviceId ?? this.deviceId,
        maxFrameRate: maxFrameRate ?? this.maxFrameRate,
        params: params ?? this.params,
        stopCameraCaptureOnMute: stopCameraCaptureOnMute ?? this.stopCameraCaptureOnMute,
        processor: processor ?? this.processor,
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
        useiOSBroadcastExtension: useiOSBroadcastExtension ?? this.useiOSBroadcastExtension,
        captureScreenAudio: captureScreenAudio ?? this.captureScreenAudio,
        params: params ?? this.params,
        sourceId: sourceId ?? deviceId,
        maxFrameRate: maxFrameRate ?? this.maxFrameRate,
        preferCurrentTab: preferCurrentTab ?? this.preferCurrentTab,
        selfBrowserSurface: selfBrowserSurface ?? this.selfBrowserSurface,
      );

  @override
  Map<String, dynamic> toMediaConstraintsMap() {
    final constraints = super.toMediaConstraintsMap();
    if (useiOSBroadcastExtension && lkPlatformIs(PlatformType.iOS)) {
      constraints['deviceId'] = 'broadcast-manual';
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
  /// ```dart
  /// import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
  ///
  /// List<MediaDeviceInfo> devices = await rtc.navigator.mediaDevices.enumerateDevices();
  /// // or
  /// List<DesktopCapturerSource> desktopSources = await rtc.desktopCapturer.getSources(types: [rtc.SourceType.Screen, rtc.SourceType.Window]);
  /// ```
  final String? deviceId;

  // Limit the maximum frameRate of the capture device.
  final double? maxFrameRate;

  /// A processor to apply to the video track.
  final TrackProcessor<VideoProcessorOptions>? processor;

  const VideoCaptureOptions({
    this.params = VideoParametersPresets.h540_169,
    this.deviceId,
    this.maxFrameRate,
    this.processor,
  });

  @override
  Map<String, dynamic> toMediaConstraintsMap() => params.toMediaConstraintsMap();
}

/// Selects whether a voice-processing component uses platform or software processing.
enum AudioProcessingMode {
  automatic('auto'),
  platform('platform'),
  software('software');

  const AudioProcessingMode(this.constraintValue);

  final String constraintValue;
}

/// Runtime voice-processing options for a [LocalAudioTrack].
///
/// These values update the native local audio source without restarting
/// capture. When the track is being sent, the native WebRTC sender reapplies
/// the updated processing config. The effective audio processing module config
/// is shared by the native voice engine/channel, so conflicting updates from
/// multiple local tracks are not isolated per track.
class AudioProcessingOptions {
  const AudioProcessingOptions({
    required this.echoCancellation,
    required this.noiseSuppression,
    required this.autoGainControl,
    required this.highPassFilter,
    this.echoCancellationMode = AudioProcessingMode.automatic,
    this.noiseSuppressionMode = AudioProcessingMode.automatic,
    this.autoGainControlMode = AudioProcessingMode.automatic,
    this.highPassFilterMode = AudioProcessingMode.automatic,
  });

  const AudioProcessingOptions.communication()
      : echoCancellation = true,
        noiseSuppression = true,
        autoGainControl = true,
        highPassFilter = true,
        echoCancellationMode = AudioProcessingMode.automatic,
        noiseSuppressionMode = AudioProcessingMode.automatic,
        autoGainControlMode = AudioProcessingMode.automatic,
        highPassFilterMode = AudioProcessingMode.automatic;

  const AudioProcessingOptions.noProcessing()
      : echoCancellation = false,
        noiseSuppression = false,
        autoGainControl = false,
        highPassFilter = false,
        echoCancellationMode = AudioProcessingMode.automatic,
        noiseSuppressionMode = AudioProcessingMode.automatic,
        autoGainControlMode = AudioProcessingMode.automatic,
        highPassFilterMode = AudioProcessingMode.automatic;

  final bool echoCancellation;
  final bool noiseSuppression;
  final bool autoGainControl;
  final bool highPassFilter;
  final AudioProcessingMode echoCancellationMode;
  final AudioProcessingMode noiseSuppressionMode;
  final AudioProcessingMode autoGainControlMode;
  final AudioProcessingMode highPassFilterMode;

  Map<String, dynamic> toMap() => {
        'echoCancellation': echoCancellation,
        'noiseSuppression': noiseSuppression,
        'autoGainControl': autoGainControl,
        'highPassFilter': highPassFilter,
        'echoCancellationMode': echoCancellationMode.constraintValue,
        'noiseSuppressionMode': noiseSuppressionMode.constraintValue,
        'autoGainControlMode': autoGainControlMode.constraintValue,
        'highPassFilterMode': highPassFilterMode.constraintValue,
      };
}

/// Options used when creating a [LocalAudioTrack].
class AudioCaptureOptions extends LocalTrackOptions implements AudioProcessingOptions {
  /// The deviceId of the capture device to use.
  /// Available deviceIds can be obtained through `flutter_webrtc`:
  /// ```
  /// import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
  ///
  /// List<MediaDeviceInfo> devices = await rtc.navigator.mediaDevices.enumerateDevices();
  /// ```
  final String? deviceId;

  /// Attempt to use noiseSuppression option (if supported by the platform)
  /// See https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/noiseSuppression
  /// Defaults to true.
  @override
  final bool noiseSuppression;

  /// Attempt to use echoCancellation option (if supported by the platform)
  /// See https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/echoCancellation
  /// Defaults to true.
  @override
  final bool echoCancellation;

  /// Attempt to use autoGainControl option (if supported by the platform)
  /// See https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackConstraints/autoGainControl
  /// Defaults to true.
  @override
  final bool autoGainControl;

  /// Attempt to use highPassFilter options (if supported by the platform)
  /// Defaults to false.
  @override
  final bool highPassFilter;

  @override
  final AudioProcessingMode echoCancellationMode;

  @override
  final AudioProcessingMode noiseSuppressionMode;

  @override
  final AudioProcessingMode autoGainControlMode;

  @override
  final AudioProcessingMode highPassFilterMode;

  /// Attempt to use typingNoiseDetection option (if supported by the platform)
  /// Defaults to true.
  final bool typingNoiseDetection;

  /// Attempt to use voiceIsolation option (if supported by the platform)
  /// Defaults to true.
  final bool voiceIsolation;

  /// set to false to only toggle enabled instead of stop/replaceTrack for muting
  final bool stopAudioCaptureOnMute;

  /// A processor to apply to the audio track.
  final TrackProcessor<AudioProcessorOptions>? processor;

  const AudioCaptureOptions({
    this.deviceId,
    this.noiseSuppression = true,
    this.echoCancellation = true,
    this.autoGainControl = true,
    this.highPassFilter = false,
    this.echoCancellationMode = AudioProcessingMode.automatic,
    this.noiseSuppressionMode = AudioProcessingMode.automatic,
    this.autoGainControlMode = AudioProcessingMode.automatic,
    this.highPassFilterMode = AudioProcessingMode.automatic,
    this.voiceIsolation = true,
    this.typingNoiseDetection = true,
    this.stopAudioCaptureOnMute = true,
    this.processor,
  });

  AudioProcessingOptions get processing => AudioProcessingOptions(
        echoCancellation: echoCancellation,
        noiseSuppression: noiseSuppression,
        autoGainControl: autoGainControl,
        highPassFilter: highPassFilter,
        echoCancellationMode: echoCancellationMode,
        noiseSuppressionMode: noiseSuppressionMode,
        autoGainControlMode: autoGainControlMode,
        highPassFilterMode: highPassFilterMode,
      );

  @override
  Map<String, dynamic> toMap() => processing.toMap();

  @override
  Map<String, dynamic> toMediaConstraintsMap() {
    final constraints = <String, dynamic>{};

    if (Native.bypassVoiceProcessing) {
      constraints['optional'] = <Map<String, dynamic>>[
        <String, dynamic>{'googEchoCancellation': false},
        <String, dynamic>{'googEchoCancellation2': false},
        <String, dynamic>{'googNoiseSuppression': false},
        <String, dynamic>{'googNoiseSuppression2': false},
        <String, dynamic>{'googAutoGainControl': false},
        <String, dynamic>{'googHighpassFilter': false},
        <String, dynamic>{'googTypingNoiseDetection': false},
        <String, dynamic>{'noiseSuppression': false},
        <String, dynamic>{'echoCancellation': false},
        <String, dynamic>{'autoGainControl': false},
        <String, dynamic>{'voiceIsolation': false},
        <String, dynamic>{'googDAEchoCancellation': false},
      ];
    } else {
      /// in we platform it's not possible to provide optional and mandatory parameters.
      /// deviceId is a mandatory parameter
      if (!kIsWeb || (kIsWeb && deviceId == null)) {
        constraints['optional'] = <Map<String, dynamic>>[
          <String, dynamic>{'echoCancellation': echoCancellation},
          <String, dynamic>{'noiseSuppression': noiseSuppression},
          <String, dynamic>{'autoGainControl': autoGainControl},
          <String, dynamic>{'voiceIsolation': noiseSuppression},
          <String, dynamic>{'googDAEchoCancellation': echoCancellation},
          <String, dynamic>{'googEchoCancellation': echoCancellation},
          <String, dynamic>{'googEchoCancellation2': echoCancellation},
          <String, dynamic>{'googNoiseSuppression': noiseSuppression},
          <String, dynamic>{'googNoiseSuppression2': noiseSuppression},
          <String, dynamic>{'googAutoGainControl': autoGainControl},
          <String, dynamic>{'googHighpassFilter': highPassFilter},
          <String, dynamic>{'googTypingNoiseDetection': typingNoiseDetection},
        ];
      }
    }

    if (deviceId != null && deviceId!.isNotEmpty) {
      if (kIsWeb) {
        if (isChrome129OrLater()) {
          constraints['deviceId'] = {'exact': deviceId};
        } else {
          constraints['deviceId'] = {'ideal': deviceId};
        }
      } else {
        constraints['optional'].cast<Map<String, dynamic>>().add(<String, dynamic>{'sourceId': deviceId});
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
    AudioProcessingMode? echoCancellationMode,
    AudioProcessingMode? noiseSuppressionMode,
    AudioProcessingMode? autoGainControlMode,
    AudioProcessingMode? highPassFilterMode,
    AudioProcessingOptions? processing,
    bool? voiceIsolation,
    bool? typingNoiseDetection,
    bool? stopAudioCaptureOnMute,
    TrackProcessor<AudioProcessorOptions>? processor,
  }) {
    return AudioCaptureOptions(
      deviceId: deviceId ?? this.deviceId,
      noiseSuppression: processing?.noiseSuppression ?? noiseSuppression ?? this.noiseSuppression,
      echoCancellation: processing?.echoCancellation ?? echoCancellation ?? this.echoCancellation,
      autoGainControl: processing?.autoGainControl ?? autoGainControl ?? this.autoGainControl,
      highPassFilter: processing?.highPassFilter ?? highPassFilter ?? this.highPassFilter,
      echoCancellationMode: processing?.echoCancellationMode ?? echoCancellationMode ?? this.echoCancellationMode,
      noiseSuppressionMode: processing?.noiseSuppressionMode ?? noiseSuppressionMode ?? this.noiseSuppressionMode,
      autoGainControlMode: processing?.autoGainControlMode ?? autoGainControlMode ?? this.autoGainControlMode,
      highPassFilterMode: processing?.highPassFilterMode ?? highPassFilterMode ?? this.highPassFilterMode,
      voiceIsolation: voiceIsolation ?? this.voiceIsolation,
      typingNoiseDetection: typingNoiseDetection ?? this.typingNoiseDetection,
      stopAudioCaptureOnMute: stopAudioCaptureOnMute ?? this.stopAudioCaptureOnMute,
      processor: processor ?? this.processor,
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

/// Reason that applying [AudioProcessingOptions] failed.
enum AudioProcessingFailureReason {
  /// The requested mode combination is invalid for the native audio module.
  invalidCombination,

  /// The platform or device cannot provide the requested processing path.
  platformUnavailable,

  /// The native layer attempted to apply the options but failed.
  applyFailed,

  /// The native layer returned an unrecognized or malformed result.
  unknown,
}

String _defaultAudioProcessingMessage(AudioProcessingFailureReason reason) {
  switch (reason) {
    case AudioProcessingFailureReason.invalidCombination:
      return 'The requested audio processing mode combination is invalid.';
    case AudioProcessingFailureReason.platformUnavailable:
      return 'Audio processing options are unavailable on this platform or device.';
    case AudioProcessingFailureReason.applyFailed:
      return 'The native WebRTC audio processing module could not apply the requested options.';
    case AudioProcessingFailureReason.unknown:
      return 'Audio processing options failed for an unknown reason.';
  }
}

String _audioProcessingMessageOrDefault(AudioProcessingFailureReason reason, String message) {
  final trimmed = message.trim();
  return trimmed.isEmpty ? _defaultAudioProcessingMessage(reason) : trimmed;
}

/// Thrown when [AudioProcessingOptions] cannot be applied.
///
/// [reason] is a stable SDK category. [message] carries native details when
/// available, or an SDK-provided fallback when native does not include details.
class AudioProcessingException implements Exception {
  AudioProcessingException(this.reason, String message) : message = _audioProcessingMessageOrDefault(reason, message);

  final AudioProcessingFailureReason reason;
  final String message;

  @override
  String toString() => 'AudioProcessingException(${reason.name}): $message';
}
