//
//
//

import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'options.dart';
import 'track/options.dart';

enum ProtocolVersion {
  protocol2,
  protocol3,
}

extension LKProtocolVersionExt on ProtocolVersion {
  String toStringValue() => {
        ProtocolVersion.protocol2: '2',
        ProtocolVersion.protocol3: '3',
      }[this]!;
}

extension LKUriExt on Uri {
  bool get isSecureScheme => ['https', 'wss'].contains(scheme);
}

// Collection of state-less static methods
class Utils {
  static Uri buildUri(
    String uriOrString, {
    required String token,
    ConnectOptions? options,
    bool reconnect = false,
    bool validate = false,
    bool forceSecure = false,
    required ProtocolVersion protocol,
  }) {
    final Uri uri = Uri.parse(uriOrString);

    final useSecure = uri.isSecureScheme || forceSecure;
    final httpScheme = useSecure ? 'https' : 'http';
    final wsScheme = useSecure ? 'wss' : 'ws';

    return uri.replace(
      scheme: validate ? httpScheme : wsScheme,
      path: validate ? 'validate' : 'rtc',
      queryParameters: <String, String>{
        'access_token': token,
        if (options != null) 'auto_subscribe': options.autoSubscribe ? '1' : '0',
        if (reconnect) 'reconnect': '1',
        'protocol': protocol.toStringValue(),
      },
    );
  }

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

    // Not simulcast
    if (!options.simulcast) return [videoEncoding.toRTCRtpEncoding()];

    // Compute for simulcast
    final midPreset = presets[1];
    final lowPreset = presets[0];
    return [
      videoEncoding.toRTCRtpEncoding(
        rid: 'f',
      ),
      // if resolution is high enough, we would send both h and q res..
      // otherwise only send h
      if (width >= 960) ...[
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

  // makes a debounce func
  static Function debounce(Function f, int ms, Function(Timer) onCreate) {
    Timer? t;
    return () {
      t?.cancel();
      t = Timer(Duration(milliseconds: ms), () {
        t = null;
        f();
      });
      // keep timer instance so we can cancel it when no longer needed
      onCreate(t!);
    };
  }
}
