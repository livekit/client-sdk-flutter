import '../imports.dart';

/// Options when creating a LocalVideoTrack.
class LocalVideoTrackOptions {
  //
  final CameraPosition position;
  final VideoPreset params;

  const LocalVideoTrackOptions({
    this.params = VideoPreset.qhd_169,
    this.position = CameraPosition.front,
  });

  Map<String, dynamic> toMediaConstraintsMap() => <String, dynamic>{
        'mandatory': params.toMediaConstraintsMap(),
        'facingMode': position == CameraPosition.front ? 'user' : 'environment',
      };
}

enum CameraPosition {
  front,
  back,
}

class VideoEncoding {
  //
  final int maxFramerate;
  final int? maxBitrate;

  const VideoEncoding({
    required this.maxFramerate,
    this.maxBitrate,
  });
}

extension VideoEncodingExt on VideoEncoding {
  //
  RTCRtpEncoding toRTCRtpEncoding({
    String? rid,
    double? scaleResolutionDownBy = 1.0,
  }) =>
      RTCRtpEncoding(
        rid: rid,
        scaleResolutionDownBy: scaleResolutionDownBy,
        maxFramerate: maxFramerate,
        maxBitrate: maxBitrate,
      );
}

class VideoPreset {
  //
  final String description;
  final int width;
  final int height;
  final VideoEncoding encoding;

  const VideoPreset({
    required this.description,
    required this.width,
    required this.height,
    required this.encoding,
  });

  //
  // TODO: Make sure the resolutions are correct
  //

  static const qvga_169 = VideoPreset(
    description: 'QVGA(320x180) 16:9',
    width: 320,
    height: 180,
    encoding: VideoEncoding(
      maxBitrate: 125000,
      maxFramerate: 15,
    ),
  );

  static const vga_169 = VideoPreset(
    description: 'VGA(640x360) 16:9',
    width: 640,
    height: 360,
    encoding: VideoEncoding(
      maxBitrate: 400000,
      maxFramerate: 30,
    ),
  );

  static const qhd_169 = VideoPreset(
    description: 'QHD(960x540) 16:9',
    width: 960,
    height: 540,
    encoding: VideoEncoding(
      maxBitrate: 800000,
      maxFramerate: 30,
    ),
  );

  static const hd_169 = VideoPreset(
    description: 'HD(1280x720) 16:9',
    width: 1280,
    height: 720,
    encoding: VideoEncoding(
      maxBitrate: 2500000,
      maxFramerate: 30,
    ),
  );

  static const fhd_169 = VideoPreset(
    description: 'FHD(1920x1080) 16:9',
    width: 1920,
    height: 1080,
    encoding: VideoEncoding(
      maxBitrate: 4000000,
      maxFramerate: 30,
    ),
  );

  static const qvga_43 = VideoPreset(
    description: 'QVGA(240x180) 4:3',
    width: 240,
    height: 180,
    encoding: VideoEncoding(
      maxBitrate: 100000,
      maxFramerate: 15,
    ),
  );

  static const vga_43 = VideoPreset(
    description: 'VGA(480x360) 4:3',
    width: 480,
    height: 360,
    encoding: VideoEncoding(
      maxBitrate: 320000,
      maxFramerate: 30,
    ),
  );

  static const qhd_43 = VideoPreset(
    description: 'QHD(720x540) 4:3',
    width: 720,
    height: 540,
    encoding: VideoEncoding(
      maxBitrate: 640000,
      maxFramerate: 30,
    ),
  );

  static const hd_43 = VideoPreset(
    description: 'HD(960x720) 4:3',
    width: 960,
    height: 720,
    encoding: VideoEncoding(
      maxBitrate: 2000000,
      maxFramerate: 30,
    ),
  );

  static const fhd_43 = VideoPreset(
    description: 'FHD(1440x1080) 4:3',
    width: 1440,
    height: 1080,
    encoding: VideoEncoding(
      maxBitrate: 3200000,
      maxFramerate: 30,
    ),
  );

  static final List<VideoPreset> all_169 = [
    qvga_169,
    vga_169,
    qhd_169,
    hd_169,
    fhd_169,
  ];

  static final List<VideoPreset> all_43 = [
    qvga_43,
    vga_43,
    qhd_43,
    hd_43,
    fhd_43,
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
class LocalAudioTrackOptions {}
