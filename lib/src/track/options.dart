/// Options when creating a LocalVideoTrack.
class LocalVideoTrackOptions {
  CameraPosition position = CameraPosition.front;
  VideoPreset params;

  LocalVideoTrackOptions({
    VideoPreset? params,
    CameraPosition? position,
  }) : params = VideoPreset.qhd {
    if (params != null) {
      this.params = params;
    }
    if (position != null) {
      this.position = position;
    }
  }

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

class VideoPreset {
  //
  final int width;
  final int height;
  final VideoEncoding encoding;

  const VideoPreset({
    required this.width,
    required this.height,
    required this.encoding,
  });

  static const qvga = VideoPreset(
    width: 320,
    height: 180,
    encoding: VideoEncoding(maxFramerate: 15),
  );

  static const vga = VideoPreset(
    width: 640,
    height: 360,
    encoding: VideoEncoding(maxFramerate: 30),
  );

  static const qhd = VideoPreset(
    width: 960,
    height: 540,
    encoding: VideoEncoding(maxFramerate: 30),
  );

  static const hd = VideoPreset(
    width: 1280,
    height: 720,
    encoding: VideoEncoding(maxFramerate: 30),
  );

  static const fhd = VideoPreset(
    width: 1920,
    height: 1080,
    encoding: VideoEncoding(maxFramerate: 30),
  );

  static final List<VideoPreset> all = [
    qvga,
    vga,
    qhd,
    hd,
    fhd,
  ];

  Map<String, dynamic> toMediaConstraintsMap() => <String, dynamic>{
        'maxWidth': width,
        'maxHeight': height,
        'maxFrameRate': encoding.maxFramerate,
      };
}

/// Options when creating an LocalAudioTrack. Placeholder for now.
class LocalAudioTrackOptions {}
