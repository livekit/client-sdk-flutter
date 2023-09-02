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

import 'package:flutter/foundation.dart';

import 'package:collection/collection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../../events.dart';
import '../../logger.dart';
import '../../proto/livekit_models.pb.dart' as lk_models;
import '../../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../../support/platform.dart';
import '../../types/other.dart';
import '../options.dart';
import '../stats.dart';
import 'audio.dart';
import 'local.dart';

class SimulcastTrackInfo {
  String codec;

  rtc.MediaStreamTrack mediaStreamTrack;

  rtc.RTCRtpSender? sender;

  List<rtc.RTCRtpEncoding>? encodings;

  SimulcastTrackInfo(
      {required this.codec,
      this.encodings,
      required this.mediaStreamTrack,
      this.sender});
}

/// A video track from the local device. Use static methods in this class to create
/// video tracks.
class LocalVideoTrack extends LocalTrack with VideoTrack {
  // Options used for this track
  @override
  covariant VideoCaptureOptions currentOptions;

  num? _currentBitrate;
  get currentBitrate => _currentBitrate;
  Map<String, VideoSenderStats>? prevStats;
  final Map<String, num> _bitrateFoLayers = {};

  Map<String, SimulcastTrackInfo> simulcastCodecs = {};

  List<lk_rtc.SubscribedCodec> subscribedCodecs = [];

  @override
  Future<bool> monitorStats() async {
    if (sender == null || events.isDisposed) {
      _currentBitrate = 0;
      return false;
    }
    List<VideoSenderStats> stats = [];
    try {
      stats = await getSenderStats();
    } catch (e) {
      logger.warning('Failed to get sender stats: $e');
      return false;
    }
    Map<String, VideoSenderStats> statsMap = {};

    for (var s in stats) {
      statsMap[s.rid ?? 'f'] = s;
    }

    if (prevStats != null) {
      num totalBitrate = 0;
      statsMap.forEach((key, s) {
        final prev = prevStats![key];
        var bitRateForlayer = computeBitrateForSenderStats(s, prev).toInt();
        _bitrateFoLayers[key] = bitRateForlayer;
        totalBitrate += bitRateForlayer;
      });
      _currentBitrate = totalBitrate;
      events.emit(VideoSenderStatsEvent(
        stats: statsMap,
        currentBitrate: currentBitrate,
        bitrateForLayers: _bitrateFoLayers,
      ));
    }

    prevStats = statsMap;
    return true;
  }

  Future<List<VideoSenderStats>> getSenderStats() async {
    if (sender == null) {
      return [];
    }

    final stats = await sender!.getStats();
    List<VideoSenderStats> items = [];
    for (var v in stats) {
      if (v.type == 'outbound-rtp') {
        VideoSenderStats vs = VideoSenderStats(v.id, v.timestamp);
        vs.frameHeight = getNumValFromReport(v.values, 'frameHeight');
        vs.frameWidth = getNumValFromReport(v.values, 'frameWidth');
        vs.framesPerSecond = getNumValFromReport(v.values, 'framesPerSecond');
        vs.firCount = getNumValFromReport(v.values, 'firCount');
        vs.pliCount = getNumValFromReport(v.values, 'pliCount');
        vs.nackCount = getNumValFromReport(v.values, 'nackCount');
        vs.packetsSent = getNumValFromReport(v.values, 'packetsSent');
        vs.bytesSent = getNumValFromReport(v.values, 'bytesSent');
        vs.framesSent = getNumValFromReport(v.values, 'framesSent');
        vs.rid = getStringValFromReport(v.values, 'rid');
        vs.encoderImplementation =
            getStringValFromReport(v.values, 'encoderImplementation');
        vs.retransmittedPacketsSent =
            getNumValFromReport(v.values, 'retransmittedPacketsSent');
        vs.qualityLimitationReason =
            getStringValFromReport(v.values, 'qualityLimitationReason');
        vs.qualityLimitationResolutionChanges =
            getNumValFromReport(v.values, 'qualityLimitationResolutionChanges');

        // locate the appropriate remote-inbound-rtp item
        final remoteId = getStringValFromReport(v.values, 'remoteId');
        final r = stats.firstWhereOrNull((element) => element.id == remoteId);
        if (r != null) {
          vs.jitter = getNumValFromReport(r.values, 'jitter');
          vs.packetsLost = getNumValFromReport(r.values, 'packetsLost');
          vs.roundTripTime = getNumValFromReport(r.values, 'roundTripTime');
        }
        final c = stats.firstWhereOrNull((element) => element.type == 'codec');
        if (c != null) {
          vs.mimeType = getStringValFromReport(c.values, 'mimeType');
          vs.payloadType = getNumValFromReport(c.values, 'payloadType');
          vs.channels = getNumValFromReport(c.values, 'channels');
          vs.clockRate = getNumValFromReport(c.values, 'clockRate');
        }
        items.add(vs);
      }
    }
    return items;
  }

  // Private constructor
  LocalVideoTrack._(
    TrackSource source,
    rtc.MediaStream stream,
    rtc.MediaStreamTrack track,
    this.currentOptions,
  ) : super(
          lk_models.TrackType.VIDEO,
          source,
          stream,
          track,
        );

  /// Creates a LocalVideoTrack from camera input.
  static Future<LocalVideoTrack> createCameraTrack([
    CameraCaptureOptions? options,
  ]) async {
    options ??= const CameraCaptureOptions();

    final stream = await LocalTrack.createStream(options);
    return LocalVideoTrack._(
      TrackSource.camera,
      stream,
      stream.getVideoTracks().first,
      options,
    );
  }

  /// Creates a LocalVideoTrack from the display.
  ///
  /// Note: Android requires a foreground service to be started prior to
  /// creating a screen track. Refer to the example app for an implementation.
  static Future<LocalVideoTrack> createScreenShareTrack([
    ScreenShareCaptureOptions? options,
  ]) async {
    options ??= const ScreenShareCaptureOptions();

    final stream = await LocalTrack.createStream(options);
    return LocalVideoTrack._(
      TrackSource.screenShareVideo,
      stream,
      stream.getVideoTracks().first,
      options,
    );
  }

  /// Creates a LocalTracks(audio/video) from the display.
  ///
  /// The current API is mainly used to capture audio when chrome captures tab,
  /// but in the future it can also be used for flutter native to open audio
  /// capture device when capturing screen
  static Future<List<LocalTrack>> createScreenShareTracksWithAudio([
    ScreenShareCaptureOptions? options,
  ]) async {
    if (options == null) {
      options = const ScreenShareCaptureOptions(captureScreenAudio: true);
    } else {
      options = options.copyWith(captureScreenAudio: true);
    }
    final stream = await LocalTrack.createStream(options);

    List<LocalTrack> tracks = [
      LocalVideoTrack._(
        TrackSource.screenShareVideo,
        stream,
        stream.getVideoTracks().first,
        options,
      )
    ];

    if (stream.getAudioTracks().isNotEmpty) {
      tracks.add(LocalAudioTrack(TrackSource.screenShareAudio, stream,
          stream.getAudioTracks().first, const AudioCaptureOptions()));
    }
    return tracks;
  }
}

//
// Convenience extensions
//
extension LocalVideoTrackExt on LocalVideoTrack {
  // Calls restartTrack under the hood
  Future<void> setCameraPosition(CameraPosition position) async {
    final options = currentOptions;
    if (options is! CameraCaptureOptions) {
      logger.warning('Not a camera track');
      return;
    }
    final newOptions = CameraCaptureOptions(
        cameraPosition: position,
        deviceId: null,
        maxFrameRate: options.maxFrameRate,
        params: options.params);
    await restartTrack(newOptions);
    await replaceTrackForMultiCodecSimulcast(mediaStreamTrack);
    currentOptions = newOptions;
  }

  Future<void> switchCamera(String deviceId, {bool fastSwitch = false}) async {
    final options = currentOptions;
    if (options is! CameraCaptureOptions) {
      logger.warning('Not a camera track');
      return;
    }

    if (fastSwitch) {
      currentOptions = options.copyWith(deviceId: deviceId);
      await rtc.Helper.switchCamera(mediaStreamTrack, deviceId, mediaStream);
      return;
    }

    await restartTrack(
      options.copyWith(deviceId: deviceId),
    );

    await replaceTrackForMultiCodecSimulcast(mediaStreamTrack);
  }

  Future<void> replaceTrackForMultiCodecSimulcast(
      rtc.MediaStreamTrack newTrack) async {
    simulcastCodecs.forEach((key, simulcastTrack) async {
      await simulcastTrack.sender?.replaceTrack(newTrack);
      simulcastTrack.mediaStreamTrack = mediaStreamTrack;
    });
  }

  Future<List<String>> setPublishingCodecs(
      List<lk_rtc.SubscribedCodec> codecs, LocalTrack track) async {
    logger.fine('setPublishingCodecs $codecs');

    // only enable simulcast codec for preference codec setted
    if (codec == null && codecs.isNotEmpty) {
      await updatePublishingLayers(track, codecs[0].qualities);
      return [];
    }

    subscribedCodecs = codecs;

    List<String> newCodecs = [];

    for (var codec in codecs) {
      if (this.codec?.toLowerCase() == codec.codec.toLowerCase()) {
        await updatePublishingLayers(track, codec.qualities);
      } else {
        final simulcastCodecInfo = simulcastCodecs[codec.codec];
        logger.fine('setPublishingCodecs $codecs');
        if (simulcastCodecInfo == null) {
          for (var q in codec.qualities) {
            if (q.enabled) {
              newCodecs.add(codec.codec.toLowerCase());
              break;
            }
          }
        } else if (simulcastCodecInfo.encodings != null &&
            simulcastCodecInfo.sender != null) {
          logger.fine('setPublishingCodecs $codecs');
          await setPublishingLayersForSender(
            simulcastCodecInfo.sender!,
            simulcastCodecInfo.encodings!,
            codec.qualities,
          );
        }
      }
    }
    return newCodecs;
  }

  Future<void> updatePublishingLayers(
      LocalTrack? track, List<lk_rtc.SubscribedQuality> layers) async {
    logger.fine('Update publishing layers: $layers');

    if (track?.sender == null) {
      logger.fine('Update publishing layers: sender is null');
      return;
    }

    final params = track?.sender?.parameters;
    if (params == null) {
      logger.fine('Update publishing layers: sender params are null');
      return;
    }

    final encodings = params.encodings;
    if (encodings == null) {
      logger.fine('Update publishing layers: encodings are null');
      return;
    }

    return setPublishingLayersForSender(track!.sender!, encodings, layers);
  }

  lk_models.VideoQuality videoQualityForRid(String rid) {
    switch (rid) {
      case 'f':
        return lk_models.VideoQuality.HIGH;
      case 'h':
        return lk_models.VideoQuality.MEDIUM;
      case 'q':
        return lk_models.VideoQuality.LOW;
      default:
        return lk_models.VideoQuality.HIGH;
    }
  }

  Future<void> setPublishingLayersForSender(
      rtc.RTCRtpSender sender,
      List<rtc.RTCRtpEncoding> encodings,
      List<lk_rtc.SubscribedQuality> layers) async {
    logger.fine('Update publishing layers: $layers');

    final params = sender.parameters;

    var hasChanged = false;

    /* disable closable spatial layer as it has video blur / frozen issue with current server / client
    1. chrome 113: when switching to up layer with scalability Mode change, it will generate a
          low resolution frame and recover very quickly, but noticable
    2. livekit sfu: additional pli request cause video frozen for a few frames, also noticable */

    /* @ts-ignore */
    if (encodings[0].scalabilityMode != null) {
      // svc dynacast encodings
      var encoding = encodings[0];
      /* @ts-ignore */
      // const mode = new ScalabilityMode(encoding.scalabilityMode);
      var maxQuality = lk_models.VideoQuality.OFF;
      for (var q in layers) {
        if (q.enabled &&
            (maxQuality == lk_models.VideoQuality.OFF ||
                q.quality.value > maxQuality.value)) {
          maxQuality = q.quality;
        }
      }

      if (maxQuality == lk_models.VideoQuality.OFF) {
        if (encoding.active) {
          encoding.active = false;
          hasChanged = true;
        }
      } else if (!encoding.active /* || mode.spatial !== maxQuality + 1*/) {
        hasChanged = true;
        encoding.active = true;
        /*
        var originalMode = new ScalabilityMode(senderEncodings[0].scalabilityMode)
        mode.spatial = maxQuality + 1;
        mode.suffix = originalMode.suffix;
        if (mode.spatial === 1) {
          // no suffix for L1Tx
          mode.suffix = undefined;
        }
        encoding.scalabilityMode = mode.toString();
        encoding.scaleResolutionDownBy = 2 ** (2 - maxQuality);
      */
      }
    } else {
      // simulcast dynacast encodings
      var idx = 0;
      for (var encoding in encodings) {
        var rid = encoding.rid ?? '';
        if (rid == '') {
          rid = 'q';
        }
        var quality = videoQualityForRid(rid);
        var subscribedQuality =
            layers.firstWhereOrNull((q) => q.quality == quality);
        if (subscribedQuality == null) {
          continue;
        }
        if (encoding.active != subscribedQuality.enabled) {
          hasChanged = true;
          encoding.active = subscribedQuality.enabled;
          logger.fine(
            'setting layer ${subscribedQuality.quality} to ${encoding.active ? 'enabled' : 'disabled'}',
          );

          // FireFox does not support setting encoding.active to false, so we
          // have a workaround of lowering its bitrate and resolution to the min.
          if (kIsWeb && lkBrowser() == BrowserType.firefox) {
            if (subscribedQuality.enabled) {
              encoding.scaleResolutionDownBy =
                  encodings[idx].scaleResolutionDownBy;
              encoding.maxBitrate = encodings[idx].maxBitrate;
              encoding.maxFramerate = encodings[idx].maxBitrate;
            } else {
              encoding.scaleResolutionDownBy = 4;
              encoding.maxBitrate = 10;
              encoding.maxFramerate = 2;
            }
          }
        }
        idx++;
      }
    }

    if (hasChanged) {
      params.encodings = encodings;
      final result = await sender.setParameters(params);
      if (result == false) {
        logger.warning('Failed to update sender parameters');
      }
    }
  }

  SimulcastTrackInfo addSimulcastTrack(
      String codec, List<rtc.RTCRtpEncoding> encodings) {
    if (simulcastCodecs[codec] != null) {
      throw Exception('$codec already added');
    }
    SimulcastTrackInfo simulcastCodecInfo = SimulcastTrackInfo(
      codec: codec,
      encodings: encodings,
      mediaStreamTrack: mediaStreamTrack,
    );

    simulcastCodecs[codec] = simulcastCodecInfo;
    return simulcastCodecInfo;
  }
}
