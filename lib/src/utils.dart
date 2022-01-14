import 'dart:async';

import 'package:collection/collection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import './proto/livekit_models.pb.dart' as lk_models;
import './support/native.dart';
import 'extensions.dart';
import 'livekit.dart';
import 'logger.dart';
import 'options.dart';
import 'support/platform.dart';
import 'track/options.dart';
import 'types.dart';

extension UriExt on Uri {
  @internal
  bool get isSecureScheme => ['https', 'wss'].contains(scheme);
}

// Collection of state-less static methods
class Utils {
  // DeviceInfoPlugin caches internally
  static final _deviceInfoPlugin = DeviceInfoPlugin();

  static Future<lk_models.ClientInfo?> _clientInfo() async {
    switch (lkPlatform()) {
      // case PlatformType.web:
      //   final info = await _deviceInfoPlugin.webBrowserInfo;
      //
      case PlatformType.windows:
        return lk_models.ClientInfo(
          os: 'windows',
          // details not available...
        );
      case PlatformType.macOS:
        final info = await _deviceInfoPlugin.macOsInfo;

        /// [MacOsDeviceInfo.osRelease] returns Darwin version instead of macOS version
        /// So call native code to get os version
        String? osVersionString = await Native.appleOSVersionString();

        return lk_models.ClientInfo(
          os: 'macOS',
          osVersion: osVersionString,
          // Confirmed
          deviceModel: info.model,
        );
      case PlatformType.android:
        final info = await _deviceInfoPlugin.androidInfo;
        return lk_models.ClientInfo(
          os: 'android',
          osVersion: info.version.release,
          deviceModel: info.model,
        );
      case PlatformType.iOS:
        final info = await _deviceInfoPlugin.iosInfo;
        String? model = info.utsname.machine;
        if (model != null && ['i386', 'x86_64', 'arm64'].contains(model)) {
          model = 'iOSSimulator,${model}';
        }
        return lk_models.ClientInfo(
          os: 'iOS',
          // Confirmed
          osVersion: info.systemVersion,
          deviceModel: model,
        );
      case PlatformType.linux:
        final info = await _deviceInfoPlugin.linuxInfo;
        return lk_models.ClientInfo(
          os: 'linux',
          osVersion: info.versionId,
          deviceModel: info.machineId,
        );
      default:
      // case PlatformType.fuchsia:
    }
  }

  @internal
  static Future<Uri> buildUri(
    String uriString, {
    required String token,
    ConnectOptions? connectOptions,
    bool reconnect = false,
    bool validate = false,
    bool forceSecure = false,
  }) async {
    connectOptions ??= const ConnectOptions();

    final Uri uri = Uri.parse(uriString);

    final useSecure = uri.isSecureScheme || forceSecure;
    final httpScheme = useSecure ? 'https' : 'http';
    final wsScheme = useSecure ? 'wss' : 'ws';
    final lastSegment = validate ? 'validate' : 'rtc';

    final pathSegments = List<String>.from(uri.pathSegments);

    // strip path segment used for LiveKit if already exists
    pathSegments.removeWhere((e) => e.isEmpty);
    if (pathSegments.isNotEmpty &&
        ['rtc', 'validate'].contains(uri.pathSegments.last)) {
      pathSegments.removeLast();
    }
    pathSegments.add(lastSegment);

    final clientInfo = await _clientInfo();

    return uri.replace(
      scheme: validate ? httpScheme : wsScheme,
      pathSegments: pathSegments,
      queryParameters: <String, String>{
        'access_token': token,
        'auto_subscribe': connectOptions.autoSubscribe ? '1' : '0',
        if (reconnect) 'reconnect': '1',
        'protocol': connectOptions.protocolVersion.toStringValue(),
        'sdk': 'flutter',
        'version': LiveKitClient.version,
        // client info
        if (clientInfo != null) ...{
          if (clientInfo.hasOs()) 'os': clientInfo.os,
          if (clientInfo.hasOsVersion()) 'os_version': clientInfo.osVersion,
          if (clientInfo.hasDeviceModel())
            'device_model': clientInfo.deviceModel,
        },
      },
    );
  }

  static List<VideoParameters> _presetsForDimensions({
    required bool isScreenShare,
    required VideoDimensions dimensions,
  }) {
    if (isScreenShare) return VideoParameters.presetsScreenShare;

    final double aspect = dimensions.width > dimensions.height
        ? dimensions.width / dimensions.height
        : dimensions.height / dimensions.width;
    if ((aspect - 16.0 / 9.0).abs() < (aspect - 4.0 / 3.0).abs()) {
      return VideoParameters.presets169;
    }
    return VideoParameters.presets43;
  }

  static VideoEncoding _findAppropriateEncoding({
    required bool isScreenShare,
    required VideoDimensions dimensions,
    required List<VideoParameters> presets,
  }) {
    assert(presets.isNotEmpty, 'presets should not be empty');
    VideoEncoding result = presets.first.encoding;

    // handle portrait by swapping dimensions
    final size = dimensions.max();

    for (final preset in presets) {
      result = preset.encoding;
      if (preset.dimensions.width >= size) break;
    }

    return result;
  }

  static final videoRids = ['q', 'h', 'f'];

  @internal
  static List<rtc.RTCRtpEncoding> encodingsFromPresets(
    VideoDimensions dimensions, {
    required List<VideoParameters> presets,
  }) {
    List<rtc.RTCRtpEncoding> result = [];
    presets.forEachIndexed((i, e) {
      if (i >= videoRids.length) {
        return;
      }
      final size = dimensions.max();
      final rid = videoRids[i];
      result.add(e.encoding.toRTCRtpEncoding(
        rid: rid,
        scaleResolutionDownBy: size / e.dimensions.height,
      ));
    });
    return result;
  }

  @internal
  static List<rtc.RTCRtpEncoding>? computeVideoEncodings({
    required bool isScreenShare,
    VideoDimensions? dimensions,
    VideoPublishOptions? options,
  }) {
    options ??= const VideoPublishOptions();

    VideoEncoding? videoEncoding = options.videoEncoding;

    final useSimulcast = !isScreenShare && options.simulcast;

    if ((videoEncoding == null && !useSimulcast) || dimensions == null) {
      // don't set encoding when we are not simulcasting and user isn't restricting
      // encoding parameters
      return null;
    }

    final presets = _presetsForDimensions(
      isScreenShare: isScreenShare,
      dimensions: dimensions,
    );

    if (videoEncoding == null) {
      // find the right encoding based on width/height
      videoEncoding = _findAppropriateEncoding(
        isScreenShare: isScreenShare,
        dimensions: dimensions,
        presets: presets,
      );
      logger.fine('using video encoding', videoEncoding);
    }

    // Not simulcast
    if (!useSimulcast) return [videoEncoding.toRTCRtpEncoding()];

    final VideoParameters lowPreset = presets.first;
    VideoParameters? midPreset;
    if (presets.length > 1) {
      midPreset = presets[1];
    }
    final original = VideoParameters(
      dimensions: dimensions,
      encoding: videoEncoding,
    );

    final size = dimensions.max();
    List<VideoParameters> computedPresets = [original];

    if (size >= 960 && midPreset != null) {
      computedPresets = [lowPreset, midPreset, original];
    } else if (size >= 500) {
      computedPresets = [lowPreset, original];
    }

    return encodingsFromPresets(
      dimensions,
      presets: computedPresets,
    );
  }

  @internal
  static List<lk_models.VideoLayer> computeVideoLayers(
    VideoDimensions dimensions,
    List<rtc.RTCRtpEncoding>? encodings,
  ) {
    // default to a single layer, HQ
    if (encodings == null) {
      return [
        lk_models.VideoLayer(
          quality: lk_models.VideoQuality.HIGH,
          width: dimensions.width,
          height: dimensions.height,
          bitrate: 0,
        )
      ];
    }

    return encodings.map((e) {
      final scale = e.scaleResolutionDownBy ?? 1;
      var quality = videoQualityForRid(e.rid);
      if (quality == null && encodings.length == 1) {
        quality = lk_models.VideoQuality.HIGH;
      }
      return lk_models.VideoLayer(
        quality: quality,
        width: (dimensions.width.toDouble() / scale).floor(),
        height: (dimensions.height.toDouble() / scale).floor(),
        bitrate: e.maxBitrate ?? 0,
      );
    }).toList();
  }

  @internal
  static lk_models.VideoQuality? videoQualityForRid(String? rid) => {
        'f': lk_models.VideoQuality.HIGH,
        'h': lk_models.VideoQuality.MEDIUM,
        'q': lk_models.VideoQuality.LOW,
      }[rid];

  // makes a debounce func, with 1 param
  @internal
  static Function(T) createDebounceFunc<T>(
    Function(T) f, {
    Function(Function)? cancelFunc,
    required Duration wait,
  }) {
    Timer? t;
    return (p) {
      t?.cancel();
      t = Timer(wait, () {
        t = null;
        f(p);
      });
      // pass back the cancel method so we can cancel it when no longer needed
      cancelFunc?.call(t!.cancel);
    };
  }
}
