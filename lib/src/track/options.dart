import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../track/local/audio.dart';
import '../track/local/video.dart';
import '../types.dart';

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
    VideoParameters params = VideoParameters.presetQHD169,
  }) : super(params: params);

  CameraCaptureOptions.from({required VideoCaptureOptions captureOptions})
      : cameraPosition = CameraPosition.front,
        super(params: captureOptions.params);

  @override
  Map<String, dynamic> toMediaConstraintsMap() => <String, dynamic>{
        ...super.toMediaConstraintsMap(),
        'facingMode':
            cameraPosition == CameraPosition.front ? 'user' : 'environment',
      };

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
    VideoParameters params = VideoParameters.presetHD169,
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
    this.params = VideoParameters.presetQHD169,
  });

  @override
  Map<String, dynamic> toMediaConstraintsMap() =>
      params.toMediaConstraintsMap();
}

/// A type that represents video encoding information.
class VideoEncoding {
  final int maxFramerate;
  final int maxBitrate;

  const VideoEncoding({
    required this.maxFramerate,
    required this.maxBitrate,
  });

  @override
  String toString() =>
      '${runtimeType}(maxFramerate: ${maxFramerate}, maxBitrate: ${maxBitrate})';
}

/// Convenience extension for [VideoEncoding].
extension VideoEncodingExt on VideoEncoding {
  rtc.RTCRtpEncoding toRTCRtpEncoding({
    String? rid,
    double? scaleResolutionDownBy = 1.0,
    int? numTemporalLayers,
  }) =>
      rtc.RTCRtpEncoding(
        rid: rid,
        scaleResolutionDownBy: scaleResolutionDownBy,
        maxFramerate: maxFramerate,
        maxBitrate: maxBitrate,
        numTemporalLayers: numTemporalLayers,
      );
}

class VideoParameters {
  // 16:9 Presets
  static const presetH90_169 = VideoParameters(
    dimensions: VideoDimensions.h90_169,
    encoding: VideoEncoding(
      maxBitrate: 60 * 1000,
      maxFramerate: 15,
    ),
  );
  static const presetH180_169 = VideoParameters(
    dimensions: VideoDimensions.h180_169,
    encoding: VideoEncoding(
      maxBitrate: 120 * 1000,
      maxFramerate: 15,
    ),
  );

  static const presetH216_169 = VideoParameters(
    dimensions: VideoDimensions.h216_169,
    encoding: VideoEncoding(
      maxBitrate: 180 * 1000,
      maxFramerate: 15,
    ),
  );

  static const presetH360_169 = VideoParameters(
    dimensions: VideoDimensions.h360_169,
    encoding: VideoEncoding(
      maxBitrate: 300 * 1000,
      maxFramerate: 20,
    ),
  );

  static const presetH540_169 = VideoParameters(
    dimensions: VideoDimensions.h540_169,
    encoding: VideoEncoding(
      maxBitrate: 600 * 1000,
      maxFramerate: 25,
    ),
  );

  static const presetH1080_169 = VideoParameters(
    dimensions: VideoDimensions.h1080_169,
    encoding: VideoEncoding(
      maxBitrate: 3 * 1000 * 1000,
      maxFramerate: 30,
    ),
  );

  static const presetH1440_169 = VideoParameters(
    dimensions: VideoDimensions.h1440_169,
    encoding: VideoEncoding(
      maxBitrate: 5 * 1000 * 1000,
      maxFramerate: 30,
    ),
  );

  static const presetH2160_169 = VideoParameters(
    dimensions: VideoDimensions.h2160_169,
    encoding: VideoEncoding(
      maxBitrate: 8 * 1000 * 1000,
      maxFramerate: 30,
    ),
  );

  static const presetH720_169 = VideoParameters(
    dimensions: VideoDimensions.h540_169,
    encoding: VideoEncoding(
      maxBitrate: 2 * 1000 * 1000,
      maxFramerate: 30,
    ),
  );

  // 4:3 presets

  static const presetH120_43 = VideoParameters(
    dimensions: VideoDimensions.h120_43,
    encoding: VideoEncoding(
      maxBitrate: 80 * 1000,
      maxFramerate: 15,
    ),
  );

  static const presetH180_43 = VideoParameters(
    dimensions: VideoDimensions.h180_43,
    encoding: VideoEncoding(
      maxBitrate: 100 * 1000,
      maxFramerate: 15,
    ),
  );

  static const presetH240_43 = VideoParameters(
    dimensions: VideoDimensions.h240_43,
    encoding: VideoEncoding(
      maxBitrate: 150 * 1000,
      maxFramerate: 15,
    ),
  );

  static const presetH360_43 = VideoParameters(
    dimensions: VideoDimensions.h360_43,
    encoding: VideoEncoding(
      maxBitrate: 225 * 1000,
      maxFramerate: 20,
    ),
  );

  static const presetH480_43 = VideoParameters(
    dimensions: VideoDimensions.h480_43,
    encoding: VideoEncoding(
      maxBitrate: 300 * 1000,
      maxFramerate: 20,
    ),
  );

  static const presetH540_43 = VideoParameters(
    dimensions: VideoDimensions.h540_43,
    encoding: VideoEncoding(
      maxBitrate: 450 * 1000,
      maxFramerate: 25,
    ),
  );

  static const presetH720_43 = VideoParameters(
    dimensions: VideoDimensions.h720_43,
    encoding: VideoEncoding(
      maxBitrate: 1 * 500 * 1000,
      maxFramerate: 30,
    ),
  );

  static const presetH1080_43 = VideoParameters(
    dimensions: VideoDimensions.h1080_43,
    encoding: VideoEncoding(
      maxBitrate: 2 * 500 * 1000,
      maxFramerate: 30,
    ),
  );

  static const presetH1440_43 = VideoParameters(
    dimensions: VideoDimensions.h1440_43,
    encoding: VideoEncoding(
      maxBitrate: 3 * 500 * 1000,
      maxFramerate: 30,
    ),
  );

  // Screen share

  static const presetScreenShareH360FPS3 = VideoParameters(
    dimensions: VideoDimensions.h360_169,
    encoding: VideoEncoding(
      maxBitrate: 200 * 1000,
      maxFramerate: 3,
    ),
  );

  static const presetScreenShareH720FPS5 = VideoParameters(
    dimensions: VideoDimensions.h720_169,
    encoding: VideoEncoding(
      maxBitrate: 400 * 1000,
      maxFramerate: 5,
    ),
  );

  static const presetScreenShareH720FPS15 = VideoParameters(
    dimensions: VideoDimensions.h720_169,
    encoding: VideoEncoding(
      maxBitrate: 1 * 1000 * 1000,
      maxFramerate: 15,
    ),
  );

  static const presetScreenShareH1080FPS15 = VideoParameters(
    dimensions: VideoDimensions.h1080_169,
    encoding: VideoEncoding(
      maxBitrate: 1 * 500 * 1000,
      maxFramerate: 15,
    ),
  );

  static const presetScreenShareH1080FPS30 = VideoParameters(
    dimensions: VideoDimensions.h1080_169,
    encoding: VideoEncoding(
      maxBitrate: 3 * 1000 * 1000,
      maxFramerate: 30,
    ),
  );

  final String? description;
  final VideoDimensions dimensions;
  final VideoEncoding encoding;

  const VideoParameters({
    this.description,
    required this.dimensions,
    required this.encoding,
  });

  static const presetQVGA169 = VideoParameters(
    description: 'QVGA(320x180) 16:9',
    dimensions: VideoDimensions(320, 180),
    encoding: VideoEncoding(
      maxBitrate: 120000,
      maxFramerate: 10,
    ),
  );

  static const presetVGA169 = VideoParameters(
    description: 'VGA(640x360) 16:9',
    dimensions: VideoDimensions(640, 360),
    encoding: VideoEncoding(
      maxBitrate: 300000,
      maxFramerate: 20,
    ),
  );

  static const presetQHD169 = VideoParameters(
    description: 'QHD(960x540) 16:9',
    dimensions: VideoDimensions(960, 540),
    encoding: VideoEncoding(
      maxBitrate: 600000,
      maxFramerate: 25,
    ),
  );

  static const presetHD169 = VideoParameters(
    description: 'HD(1280x720) 16:9',
    dimensions: VideoDimensions(1280, 720),
    encoding: VideoEncoding(
      maxBitrate: 2000000,
      maxFramerate: 30,
    ),
  );

  static const presetFHD169 = VideoParameters(
    description: 'FHD(1920x1080) 16:9',
    dimensions: VideoDimensions(1920, 1080),
    encoding: VideoEncoding(
      maxBitrate: 3000000,
      maxFramerate: 30,
    ),
  );

  static const presetQVGA43 = VideoParameters(
    description: 'QVGA(240x180) 4:3',
    dimensions: VideoDimensions(240, 180),
    encoding: VideoEncoding(
      maxBitrate: 90000,
      maxFramerate: 10,
    ),
  );

  static const presetVGA43 = VideoParameters(
    description: 'VGA(480x360) 4:3',
    dimensions: VideoDimensions(480, 360),
    encoding: VideoEncoding(
      maxBitrate: 225000,
      maxFramerate: 20,
    ),
  );

  static const presetQHD43 = VideoParameters(
    description: 'QHD(720x540) 4:3',
    dimensions: VideoDimensions(720, 540),
    encoding: VideoEncoding(
      maxBitrate: 450000,
      maxFramerate: 25,
    ),
  );

  static const presetHD43 = VideoParameters(
    description: 'HD(960x720) 4:3',
    dimensions: VideoDimensions(960, 720),
    encoding: VideoEncoding(
      maxBitrate: 1500000,
      maxFramerate: 30,
    ),
  );

  static const presetFHD43 = VideoParameters(
    description: 'FHD(1440x1080) 4:3',
    dimensions: VideoDimensions(1440, 1080),
    encoding: VideoEncoding(
      maxBitrate: 2800000,
      maxFramerate: 30,
    ),
  );

  static const presetScreenShareVGA = VideoParameters(
    description: 'ScreenShareVGA(640x360)',
    dimensions: VideoDimensions(640, 360),
    encoding: VideoEncoding(
      maxBitrate: 200000,
      maxFramerate: 3,
    ),
  );

  static const presetScreenShareHD5 = VideoParameters(
    description: 'ScreenShareHD5(1280x720)',
    dimensions: VideoDimensions(1280, 720),
    encoding: VideoEncoding(
      maxBitrate: 400000,
      maxFramerate: 5,
    ),
  );

  static const presetScreenShareHD15 = VideoParameters(
    description: 'ScreenShareHD15(1280x720)',
    dimensions: VideoDimensions(1280, 720),
    encoding: VideoEncoding(
      maxBitrate: 1000000,
      maxFramerate: 15,
    ),
  );

  static const presetScreenShareFHD15 = VideoParameters(
    description: 'ScreenShareFHD15(1920x1080)',
    dimensions: VideoDimensions(1920, 1080),
    encoding: VideoEncoding(
      maxBitrate: 1500000,
      maxFramerate: 15,
    ),
  );

  static const presetScreenShareFHD30 = VideoParameters(
    description: 'ScreenShareFHD30(1920x1080)',
    dimensions: VideoDimensions(1920, 1080),
    encoding: VideoEncoding(
      maxBitrate: 3000000,
      maxFramerate: 30,
    ),
  );

  static final List<VideoParameters> presets169 = [
    presetH90_169,
    presetH180_169,
    presetH216_169,
    presetH360_169,
    presetH540_169,
    presetH720_169,
    presetH1080_169,
    presetH1440_169,
    presetH2160_169,
  ];

  static final List<VideoParameters> presets43 = [
    presetH120_43,
    presetH180_43,
    presetH240_43,
    presetH360_43,
    presetH480_43,
    presetH540_43,
    presetH720_43,
    presetH1080_43,
    presetH1440_43,
  ];

  static final List<VideoParameters> presetsScreenShare = [
    presetScreenShareH360FPS3,
    presetScreenShareH720FPS5,
    presetScreenShareH720FPS15,
    presetScreenShareH1080FPS15,
    presetScreenShareH1080FPS30,
  ];

  //
  // TODO: Return constraints that will work for all platforms (Web & Mobile)
  // https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia
  //
  Map<String, dynamic> toMediaConstraintsMap() => <String, dynamic>{
        'width': dimensions.width,
        'height': dimensions.height,
        'frameRate': encoding.maxFramerate,
      };
}

/// Options used when creating a [LocalAudioTrack].
class AudioCaptureOptions extends LocalTrackOptions {
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
    this.noiseSuppression = true,
    this.echoCancellation = true,
    this.autoGainControl = true,
    this.highPassFilter = false,
    this.typingNoiseDetection = true,
  });

  @override
  Map<String, dynamic> toMediaConstraintsMap() => <String, dynamic>{
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
}
