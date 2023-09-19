// Copyright 2023 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
import 'track/local/video.dart';
import 'types/other.dart';
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
        if (['i386', 'x86_64', 'arm64'].contains(model)) {
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
    required ConnectOptions connectOptions,
    required RoomOptions roomOptions,
    bool reconnect = false,
    bool validate = false,
    bool forceSecure = false,
    String? sid,
  }) async {
    final Uri uri = Uri.parse(uriString);

    final useSecure = uri.isSecureScheme || forceSecure;
    final httpScheme = useSecure ? 'https' : 'http';
    final wsScheme = useSecure ? 'wss' : 'ws';
    final lastSegments = validate ? ['rtc', 'validate'] : ['rtc'];

    final pathSegments = List<String>.from(uri.pathSegments);

    // strip path segment used for LiveKit if already exists
    pathSegments.removeWhere((e) => e.isEmpty);
    pathSegments.addAll(lastSegments);

    final clientInfo = await _clientInfo();
    final networkType = await getNetworkType();

    return uri.replace(
      scheme: validate ? httpScheme : wsScheme,
      pathSegments: pathSegments,
      queryParameters: <String, String>{
        'access_token': token,
        'auto_subscribe': connectOptions.autoSubscribe ? '1' : '0',
        'adaptive_stream': roomOptions.adaptiveStream ? '1' : '0',
        if (reconnect) 'reconnect': '1',
        if (reconnect && sid != null) 'sid': sid,
        'protocol': connectOptions.protocolVersion.toStringValue(),
        'sdk': 'flutter',
        'version': LiveKitClient.version,
        'network': networkType,
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
    String? codec,
  }) {
    assert(presets.isNotEmpty, 'presets should not be empty');
    VideoEncoding result = presets.first.encoding;

    // handle portrait by swapping dimensions
    final size = dimensions.max();

    for (final preset in presets) {
      result = preset.encoding;
      if (preset.dimensions.width >= size) break;
    }

    // presets are based on the assumption of vp8 as a codec
    // for other codecs we adjust the maxBitrate if no specific videoEncoding has been provided
    // users should override these with ones that are optimized for their use case
    // NOTE: SVC codec bitrates are inclusive of all scalability layers. while
    // bitrate for non-SVC codecs does not include other simulcast layers.
    if (codec != null) {
      switch (codec) {
        case 'av1':
          result =
              result.copyWith(maxBitrate: (result.maxBitrate * 0.7).toInt());
          break;
        case 'vp9':
          result =
              result.copyWith(maxBitrate: (result.maxBitrate * 0.85).toInt());
          break;
        default:
          break;
      }
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
  static FutureOr<String> getNetworkType() async {
    if (!kIsWeb && lkPlatformIsTest()) {
      return 'wifi';
    }
    var connectivityResult = await (Connectivity().checkConnectivity());
    // wifi, wired, cellular, vpn, empty if not known
    String networkType = 'empty';
    switch (connectivityResult) {
      case ConnectivityResult.mobile:
        networkType = 'cellular';
        break;
      case ConnectivityResult.wifi:
        networkType = 'wifi';
        break;
      case ConnectivityResult.bluetooth:
        networkType = 'bluetooth';
        break;
      case ConnectivityResult.ethernet:
        networkType = 'wired';
        break;
      case ConnectivityResult.other:
      case ConnectivityResult.vpn:
        //TODO: will livekit-server handle vpn and other types correctly?
        //  networkType = 'vpn';
        break;
      case ConnectivityResult.none:
        networkType = 'empty';
        break;
    }
    return networkType;
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
    String? codec,
  }) {
    options ??= const VideoPublishOptions();

    VideoEncoding? videoEncoding = options.videoEncoding;
    var scalabilityMode = options.scalabilityMode;

    if ((videoEncoding == null &&
            !options.simulcast &&
            scalabilityMode == null) ||
        dimensions == null) {
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
        codec: codec,
      );

      logger.fine('using video encoding', videoEncoding);
    }

    final original = VideoParameters(
      dimensions: dimensions,
      encoding: videoEncoding,
    );

    if (scalabilityMode != null && isSVCCodec(options.videoCodec)) {
      logger.info('using svc with scalabilityMode ${scalabilityMode}');

      //final sm = ScalabilityMode(scalabilityMode);

      List<rtc.RTCRtpEncoding> encodings = [videoEncoding.toRTCRtpEncoding()];
      /*
      if (sm.spatial > 3) {
        throw Exception('unsupported scalabilityMode: ${scalabilityMode}');
      }
      for (int i = 0; i < sm.spatial; i += 1) {
        encodings.add(rtc.RTCRtpEncoding(
          rid: videoRids[2 - i],
          maxBitrate: videoEncoding.maxBitrate ~/ math.pow(3, i),
          maxFramerate: videoEncoding.maxFramerate,
          scaleResolutionDownBy: null,
          numTemporalLayers: sm.temporal.toInt(),
        ));
      }*/
      encodings[0].scalabilityMode = scalabilityMode;
      logger.fine('encodings $encodings');
      return encodings;
    } else if (!options.simulcast) {
      // not using simulcast
      return [videoEncoding.toRTCRtpEncoding()];
    }

    // compute simulcast encodings
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
  static List<rtc.RTCRtpEncoding>? computeTrackBackupEncodings(
    LocalVideoTrack track,
    BackupVideoCodec backupOpts,
  ) {
    final opts = VideoPublishOptions(
      videoCodec: backupOpts.codec,
      videoEncoding: backupOpts.encoding,
      simulcast: backupOpts.simulcast,
    );
    var encodings = computeVideoEncodings(
      isScreenShare: track.source == TrackSource.screenShareVideo,
      dimensions: track.currentOptions.params.dimensions,
      options: opts,
    );
    return encodings;
  }

  @internal
  static List<lk_models.VideoLayer> computeVideoLayers(
    VideoDimensions dimensions,
    List<rtc.RTCRtpEncoding>? encodings,
    bool isSVC,
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

    if (isSVC) {
      final sm = ScalabilityMode(encodings[0].scalabilityMode ?? 'L3T3_KEY');
      final List<lk_models.VideoLayer> layers = [];
      final maxBitrate = encodings[0].maxBitrate ?? 0;
      for (var i = 0; i < sm.spatial; i++) {
        layers.add(lk_models.VideoLayer(
          quality: lk_models.VideoQuality.valueOf(
              lk_models.VideoQuality.HIGH.value - i),
          width: (dimensions.width / math.pow(2, i)).floor(),
          height: (dimensions.height / math.pow(2, i)).floor(),
          bitrate: (maxBitrate / math.pow(3, i)).ceil(),
        ));
      }
      return layers;
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

const refreshSubscribedCodecAfterNewCodec = 5000;

bool isSVCCodec(String codec) => ['vp9', 'av1'].contains(codec.toLowerCase());

class ScalabilityMode {
  late num spatial;

  late num temporal;

  String? suffix;

  /// 'h' | '_KEY' | '_KEY_SHIFT';

  ScalabilityMode(String scalabilityMode) {
    RegExp exp = RegExp(r'^L(\d)T(\d)(h|_KEY|_KEY_SHIFT){0,1}');
    Iterable<RegExpMatch> matches = exp.allMatches(scalabilityMode);
    if (matches.isEmpty) {
      throw Exception('invalid scalability mode');
    }
    var results = matches.first.groups([1, 2, 3]);
    spatial = int.tryParse(results[0]!) as num;
    temporal = int.tryParse(results[1]!) as num;
    if (results.length > 2) {
      switch (results[2]) {
        case 'h':
        case '_KEY':
        case '_KEY_SHIFT':
          suffix = results[2];
      }
    }
  }

  @override
  String toString() {
    return 'L${spatial}T${temporal}${suffix ?? ''}';
  }
}
