import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

enum LocalVideoTrackType {
  camera,
  display,
}

enum CameraPosition {
  front,
  back,
}

extension CameraPositionExt on CameraPosition {
  CameraPosition swap() => {
        CameraPosition.front: CameraPosition.back,
        CameraPosition.back: CameraPosition.front,
      }[this]!;
}

class CameraTrackOptions extends LocalVideoTrackOptions {
  final CameraPosition cameraPosition;

  const CameraTrackOptions({
    this.cameraPosition = CameraPosition.front,
    VideoParameters params = VideoParameters.presetQHD169,
  }) : super(params: params);

  @override
  Map<String, dynamic> toMediaConstraintsMap() => <String, dynamic>{
        ...super.toMediaConstraintsMap(),
        'facingMode':
            cameraPosition == CameraPosition.front ? 'user' : 'environment',
      };

  // Returns new options with updated properties
  CameraTrackOptions copyWith({
    VideoParameters? params,
    CameraPosition? cameraPosition,
  }) =>
      CameraTrackOptions(
        params: params ?? this.params,
        cameraPosition: cameraPosition ?? this.cameraPosition,
      );
}

class ScreenTrackOptions extends LocalVideoTrackOptions {
  const ScreenTrackOptions();
}

/// Options when creating a LocalVideoTrack.
abstract class LocalVideoTrackOptions {
  // final LocalVideoTrackType type;
  final VideoParameters params;

  const LocalVideoTrackOptions({
    this.params = VideoParameters.presetQHD169,
  });

  Map<String, dynamic> toMediaConstraintsMap() => <String, dynamic>{
        'mandatory': params.toMediaConstraintsMap(),
      };
}

class VideoEncoding {
  final int maxFramerate;
  final int? maxBitrate;

  const VideoEncoding({
    required this.maxFramerate,
    this.maxBitrate,
  });

  @override
  String toString() =>
      '${runtimeType}(maxFramerate: ${maxFramerate}, maxBitrate: ${maxBitrate})';
}

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
  final String description;
  final int width;
  final int height;
  final VideoEncoding encoding;

  const VideoParameters({
    required this.description,
    required this.width,
    required this.height,
    required this.encoding,
  });

  //
  // TODO: Make sure the resolutions are correct
  //

  static const presetQVGA169 = VideoParameters(
    description: 'QVGA(320x180) 16:9',
    width: 320,
    height: 180,
    encoding: VideoEncoding(
      maxBitrate: 125000,
      maxFramerate: 15,
    ),
  );

  static const presetVGA169 = VideoParameters(
    description: 'VGA(640x360) 16:9',
    width: 640,
    height: 360,
    encoding: VideoEncoding(
      maxBitrate: 400000,
      maxFramerate: 30,
    ),
  );

  static const presetQHD169 = VideoParameters(
    description: 'QHD(960x540) 16:9',
    width: 960,
    height: 540,
    encoding: VideoEncoding(
      maxBitrate: 800000,
      maxFramerate: 30,
    ),
  );

  static const presetHD169 = VideoParameters(
    description: 'HD(1280x720) 16:9',
    width: 1280,
    height: 720,
    encoding: VideoEncoding(
      maxBitrate: 2500000,
      maxFramerate: 30,
    ),
  );

  static const presetFHD169 = VideoParameters(
    description: 'FHD(1920x1080) 16:9',
    width: 1920,
    height: 1080,
    encoding: VideoEncoding(
      maxBitrate: 4000000,
      maxFramerate: 30,
    ),
  );

  static const presetQVGA43 = VideoParameters(
    description: 'QVGA(240x180) 4:3',
    width: 240,
    height: 180,
    encoding: VideoEncoding(
      maxBitrate: 100000,
      maxFramerate: 15,
    ),
  );

  static const presetVGA43 = VideoParameters(
    description: 'VGA(480x360) 4:3',
    width: 480,
    height: 360,
    encoding: VideoEncoding(
      maxBitrate: 320000,
      maxFramerate: 30,
    ),
  );

  static const presetQHD43 = VideoParameters(
    description: 'QHD(720x540) 4:3',
    width: 720,
    height: 540,
    encoding: VideoEncoding(
      maxBitrate: 640000,
      maxFramerate: 30,
    ),
  );

  static const presetHD43 = VideoParameters(
    description: 'HD(960x720) 4:3',
    width: 960,
    height: 720,
    encoding: VideoEncoding(
      maxBitrate: 2000000,
      maxFramerate: 30,
    ),
  );

  static const presetFHD43 = VideoParameters(
    description: 'FHD(1440x1080) 4:3',
    width: 1440,
    height: 1080,
    encoding: VideoEncoding(
      maxBitrate: 3200000,
      maxFramerate: 30,
    ),
  );

  static final List<VideoParameters> presets169 = [
    presetQVGA169,
    presetVGA169,
    presetQHD169,
    presetHD169,
    presetFHD169,
  ];

  static final List<VideoParameters> presets43 = [
    presetQVGA43,
    presetVGA43,
    presetQHD43,
    presetHD43,
    presetFHD43,
  ];

  //
  // TODO: Return constraints that will work for all platforms (Web & Mobile)
  // https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia
  //
  Map<String, dynamic> toMediaConstraintsMap() => <String, dynamic>{
        'maxWidth': width,
        'maxHeight': height,
        'maxFrameRate': encoding.maxFramerate,
      };
}

/// Options when creating an LocalAudioTrack. Placeholder for now.
class LocalAudioTrackOptions {
  const LocalAudioTrackOptions();
}
