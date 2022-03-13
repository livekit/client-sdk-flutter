import 'package:flutter/foundation.dart' show kIsWeb;

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
  /// The deviceId of the capture device to use.
  /// Available deviceIds can be obtained through `flutter_webrtc`:
  /// <pre>
  /// import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
  ///
  /// List<MediaDeviceInfo> devices = await rtc.navigator.mediaDevices.enumerateDevices();
  /// </pre>
  final String? deviceId;
  final CameraPosition cameraPosition;

  const CameraCaptureOptions({
    this.deviceId,
    this.cameraPosition = CameraPosition.front,
    VideoParameters params = VideoParametersPresets.h540_169,
  }) : super(params: params);

  CameraCaptureOptions.from({required VideoCaptureOptions captureOptions})
      : deviceId = null,
        cameraPosition = CameraPosition.front,
        super(params: captureOptions.params);

  @override
  Map<String, dynamic> toMediaConstraintsMap() {
    var constraints = <String, dynamic>{
      ...super.toMediaConstraintsMap(),
      'facingMode':
          cameraPosition == CameraPosition.front ? 'user' : 'environment',
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
    return constraints;
  }

  // Returns new options with updated properties
  CameraCaptureOptions copyWith({
    VideoParameters? params,
    CameraPosition? cameraPosition,
  }) =>
      CameraCaptureOptions(
        params: params ?? this.params,
        cameraPosition: cameraPosition ?? this.cameraPosition,
      );
}

/// Options used when creating a [LocalVideoTrack] that captures the screen.
class ScreenShareCaptureOptions extends VideoCaptureOptions {
  const ScreenShareCaptureOptions({
    VideoParameters params = VideoParametersPresets.screenShareH720FPS15,
  }) : super(params: params);

  ScreenShareCaptureOptions.from({required VideoCaptureOptions captureOptions})
      : super(params: captureOptions.params);
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

  const VideoCaptureOptions({
    this.params = VideoParametersPresets.h540_169,
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
    var constraints = <String, dynamic>{
      'optional': <Map<String, dynamic>>[
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
      ],
    };

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
}
