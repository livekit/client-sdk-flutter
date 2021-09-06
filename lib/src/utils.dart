//
//
//

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'options.dart';
import 'track/options.dart';

class Utils {
  //
  static List<VideoParameters> _presetsForResolution(
    int width,
    int height,
  ) {
    final double aspect = width / height;
    if ((aspect - 16.0 / 9.0).abs() < (aspect - 4.0 / 3.0).abs()) return VideoParameters.presets169;
    return VideoParameters.presets43;
  }

  static VideoParameters _findPresetForResolution(
    int width,
    int height, {
    required List<VideoParameters> presets,
  }) {
    //
    assert(presets.isNotEmpty, 'presets should not be empty');

    VideoParameters result = presets.first;
    for (final preset in presets) {
      if (width >= preset.width && height >= preset.height) result = preset;
    }

    return result;
  }

  static List<RTCRtpEncoding>? computeVideoEncodings({
    int? width,
    int? height,
    TrackPublishOptions? options,
  }) {
    //
    options ??= const TrackPublishOptions();

    VideoEncoding? videoEncoding = options.videoEncoding;

    if ((videoEncoding == null && !options.simulcast) || width == null || height == null) {
      // don't set encoding when we are not simulcasting and user isn't restricting
      // encoding parameters
      return null;
    }

    final presets = _presetsForResolution(width, height);

    if (videoEncoding == null) {
      // find the right encoding based on width/height
      final preset = _findPresetForResolution(width, height, presets: presets);
      // print('Using preset: ${preset.id}');
      videoEncoding = preset.encoding;
      //   log.debug('using video encoding', videoEncoding);
    }

    //
    // Not simulcast
    //
    if (!options.simulcast) return [videoEncoding.toRTCRtpEncoding()];

    //
    // Compute for simulcast
    //
    final midPreset = presets[1];
    final lowPreset = presets[0];
    return [
      videoEncoding.toRTCRtpEncoding(
        rid: 'f',
      ),
      // if resolution is high enough, we would send both h and q res..
      // otherwise only send h
      if (height * 0.7 >= midPreset.height) ...[
        midPreset.encoding.toRTCRtpEncoding(
          rid: 'h',
          scaleResolutionDownBy: height / midPreset.height,
        ),
        lowPreset.encoding.toRTCRtpEncoding(
          rid: 'q',
          scaleResolutionDownBy: height / lowPreset.height,
        ),
      ] else
        lowPreset.encoding.toRTCRtpEncoding(
          rid: 'h',
          scaleResolutionDownBy: height / lowPreset.height,
        ),
    ];
  }
}
