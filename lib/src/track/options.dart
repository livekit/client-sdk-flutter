class LocalVideoTrackOptions {
  CameraPosition position = CameraPosition.FRONT;
  VideoParameter params;

  LocalVideoTrackOptions({
    VideoParameter? params,
    CameraPosition? position,
  }) : params = VideoPresets.qhd {
    if (params != null) {
      this.params = params;
    }
    if (position != null) {
      this.position = position;
    }
  }

  Map<String, dynamic> get mediaConstraints {
    return {
      "mandatory": params.mediaConstraints,
      "facingMode": position == CameraPosition.FRONT ? "user" : "environment",
    };
  }
}

enum CameraPosition {
  FRONT,
  BACK,
}

class VideoParameter {
  int width;
  int height;
  int fps;
  int? bitrate;

  VideoParameter(
    this.width,
    this.height,
    this.fps, {
    this.bitrate,
  });

  Map<String, dynamic> get mediaConstraints {
    return {
      "minWidth": this.width,
      "minHeight": this.height,
      "minFrameRate": this.fps,
    };
  }
}

class VideoPresets {
  static final qvga = VideoParameter(320, 180, 15);
  static final vga = VideoParameter(640, 360, 30);
  static final qhd = VideoParameter(960, 540, 30);
  static final hd = VideoParameter(1280, 720, 30);
  static final fhd = VideoParameter(1920, 1080, 30);

  static final List<VideoParameter> all = [
    qvga,
    vga,
    qhd,
    hd,
    fhd,
  ];
}

class LocalAudioTrackOptions {}
