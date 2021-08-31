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

class VideoPreset {
  //
  int width;
  int height;
  int fps;
  int? bitrate;

  VideoPreset({
    required this.width,
    required this.height,
    required this.fps,
    this.bitrate,
  });

  static final qvga = VideoPreset(width: 320, height: 180, fps: 15);
  static final vga = VideoPreset(width: 640, height: 360, fps: 30);
  static final qhd = VideoPreset(width: 960, height: 540, fps: 30);
  static final hd = VideoPreset(width: 1280, height: 720, fps: 30);
  static final fhd = VideoPreset(width: 1920, height: 1080, fps: 30);

  static final List<VideoPreset> all = [
    qvga,
    vga,
    qhd,
    hd,
    fhd,
  ];

  Map<String, dynamic> toMediaConstraintsMap() => <String, dynamic>{
        'minWidth': width,
        'minHeight': height,
        'minFrameRate': fps,
      };
}

/// Options when creating an LocalAudioTrack. Placeholder for now.
class LocalAudioTrackOptions {}
