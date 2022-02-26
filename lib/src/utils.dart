import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

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
import 'types/video_dimensions.dart';
import 'types/video_encoding.dart';
import 'types/video_parameters.dart';

extension UriExt on Uri {
  @internal
  bool get isSecureScheme => ['https', 'wss'].contains(scheme);
}

typedef RetryFuture<T> = Future<T> Function(
  int triesLeft,
  List<Object> errors,
);
typedef RetryCondition = bool Function(
  int triesLeft,
  List<Object> errors,
);

// Collection of state-less static methods
class Utils {
  // order of rids
  static final videoRids = ['q', 'h', 'f'];

  /// Returns a [Future] that will retry [future] while it throws
  /// for a maximum  of [tries] times with [delay] in between.
  /// If all the attempts throws, the future will throw a [List] of the
  /// thrown objects by the [future].
  static Future<T> retry<T>(
    RetryFuture<T> future, {

    /// number of total tries (first try + retries)
    int tries = 1,
    Duration delay = const Duration(seconds: 1),
    RetryCondition? retryCondition,
  }) async {
    List<Object> errors = [];
    while (tries-- > 0) {
      try {
        return await future(tries, errors);
      } catch (error) {
        logger.fine('[Retry] Caught error ${error}...');
        errors.add(error);
        if (!(retryCondition?.call(tries, errors) ?? true)) break;
      }
      if (tries > 0) {
        logger.fine('[Retry] Waiting ${delay}...');
        await Future<dynamic>.delayed(delay);
      }
    }
    throw errors;
  }

  // DeviceInfoPlugin caches internally
  static final _deviceInfoPlugin = DeviceInfoPlugin();

  static Future<lk_models.ClientInfo?> _clientInfo() async {
    if (!kIsWeb && lkPlatformIsTest()) {
      return lk_models.ClientInfo(
        os: 'test',
      );
    }
    switch (lkPlatform()) {
      case PlatformType.web:
        return lk_models.ClientInfo(
          os: defaultTargetPlatform.name,
        );
      case PlatformType.windows:
        return lk_models.ClientInfo(
          os: 'windows',

          /// [WindowsDeviceInfo] does not provide details...
        );

      case PlatformType.macOS:
        final info = await _deviceInfoPlugin.macOsInfo;

        /// [MacOsDeviceInfo.osRelease] returns Darwin version instead of macOS version
        /// So call native code to get os version
        String? osVersionString = await Native.osVersionString();

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
    return null;
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
          if (clientInfo.hasBrowser()) 'browser': clientInfo.browser,
          if (clientInfo.hasBrowserVersion())
            'browser_version': clientInfo.browserVersion,
        },
      },
    );
  }

  static List<VideoParameters> _presetsForDimensions({
    required bool isScreenShare,
    required VideoDimensions dimensions,
  }) {
    if (isScreenShare) {
      return VideoParametersPresets.allScreenShare;
    }

    final a = dimensions.aspect();
    if ((a - VideoDimensionsHelpers.aspect169).abs() <
        (a - VideoDimensionsHelpers.aspect43).abs()) {
      return VideoParametersPresets.all169;
    }

    return VideoParametersPresets.all43;
  }

  static List<VideoParameters> _computeDefaultScreenShareSimulcastParams({
    required VideoParameters original,
  }) {
    final layers = [
      rtc.RTCRtpEncoding(scaleResolutionDownBy: 2, maxFramerate: 3)
    ];
    return layers.map((e) {
      final scale = e.scaleResolutionDownBy ?? 1;
      final fps = e.maxFramerate ?? 3;

      return VideoParameters(
        dimensions: VideoDimensions((original.dimensions.width / scale).floor(),
            (original.dimensions.height / scale).floor()),
        encoding: VideoEncoding(
          maxBitrate: math.max(
            150 * 1000,
            (original.encoding.maxBitrate /
                    (math.pow(scale, 2) *
                        (original.encoding.maxFramerate / fps)))
                .floor(),
          ),
          maxFramerate: fps,
        ),
      );
    }).toList();
  }

  static List<VideoParameters> _computeDefaultSimulcastParams({
    required bool isScreenShare,
    required VideoParameters original,
  }) {
    if (isScreenShare) {
      return _computeDefaultScreenShareSimulcastParams(original: original);
    }
    final a = original.dimensions.aspect();
    if ((a - VideoDimensionsHelpers.aspect169).abs() <
        (a - VideoDimensionsHelpers.aspect43).abs()) {
      return VideoParametersPresets.defaultSimulcast169;
    }

    return VideoParametersPresets.defaultSimulcast43;
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
      final size = dimensions.min();
      final rid = videoRids[i];

      result.add(e.encoding.toRTCRtpEncoding(
        rid: rid,
        scaleResolutionDownBy: math.max(1, size / e.dimensions.min()),
      ));
    });
    return result;
  }

  @internal
  static double findEvenScaleDownBy(
    VideoDimensions sourceDimensions,
    VideoDimensions targetDimensions,
  ) {
    bool isEven(int v) => v % 2 == 0;

    final sourceSize = sourceDimensions.max();
    final targetSize = targetDimensions.max();

    for (int i = 0; i <= 30; i++) {
      final scaleDownBy = sourceSize.toDouble() / (targetSize + i);
      // Internally, WebRTC casts directly to int without rounding.
      // https://github.com/webrtc-sdk/webrtc/blob/8c7139f8e6fa19ddf2c91510c177a19746e1ded3/media/engine/webrtc_video_engine.cc#L3676
      final scaledWidth = sourceDimensions.width ~/ scaleDownBy;
      final scaledHeight = sourceDimensions.height ~/ scaleDownBy;

      if (isEven(scaledWidth) && isEven(scaledHeight)) {
        return scaleDownBy;
      }
    }

    // couldn't find an even scale, just return original scale and hope it works.
    return sourceSize / targetSize;
  }

  @internal
  static List<rtc.RTCRtpEncoding>? computeVideoEncodings({
    required bool isScreenShare,
    VideoDimensions? dimensions,
    VideoPublishOptions? options,
  }) {
    options ??= const VideoPublishOptions();

    VideoEncoding? videoEncoding = options.videoEncoding;

    if ((videoEncoding == null && !options.simulcast) || dimensions == null) {
      // don't set encoding when we are not simulcasting and user isn't restricting
      // encoding parameters
      return [rtc.RTCRtpEncoding()];
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

    if (!options.simulcast) {
      // not using simulcast
      return [videoEncoding.toRTCRtpEncoding()];
    }

    final original = VideoParameters(
      dimensions: dimensions,
      encoding: videoEncoding,
    );

    final userParams = isScreenShare
        ? options.screenShareSimulcastLayers
        : options.videoSimulcastLayers;

    final params = (userParams.isNotEmpty
            ? userParams
            : _computeDefaultSimulcastParams(
                isScreenShare: isScreenShare, original: original))
        .sorted();

    final VideoParameters lowPreset = params.first;
    VideoParameters? midPreset;
    if (params.length > 1) {
      midPreset = params[1];
    }

    final size = dimensions.max();
    List<VideoParameters> computedParams = [original];

    if (size >= 960 && midPreset != null) {
      computedParams = [lowPreset, midPreset, original];
    } else if (size >= 480) {
      computedParams = [lowPreset, original];
    }

    return encodingsFromPresets(
      dimensions,
      presets: computedParams,
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
