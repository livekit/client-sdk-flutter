// Copyright 2024 LiveKit, Inc.
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

import 'package:flutter/services.dart' show PlatformException;

import 'package:collection/collection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../../events.dart';
import '../../internal/events.dart';
import '../../logger.dart';
import '../../options.dart';
import '../../stats/audio_source_stats.dart';
import '../../stats/stats.dart';
import '../../support/native.dart';
import '../../support/platform.dart';
import '../../types/other.dart';
import '../audio_management.dart';
import '../options.dart' as track_options;
import 'local.dart';

class LocalAudioTrack extends LocalTrack with AudioTrack, LocalAudioManagementMixin {
  // Options used for this track
  @override
  covariant track_options.AudioCaptureOptions currentOptions;

  AudioPublishOptions? lastPublishOptions;

  Future<void> setDeviceId(String deviceId) async {
    if (currentOptions.deviceId == deviceId) {
      return;
    }
    currentOptions = currentOptions.copyWith(deviceId: deviceId);
    if (!muted) {
      await restartTrack();
    }
  }

  /// Applies runtime audio processing options to this local audio track.
  ///
  /// On success, updates [currentOptions] and emits
  /// [LocalTrackOptionsUpdatedEvent]. When the native layer cannot apply the
  /// options, throws [track_options.AudioProcessingException] and leaves
  /// [currentOptions] unchanged.
  Future<void> setAudioProcessingOptions(track_options.AudioProcessingOptions options) async {
    final nextOptions = currentOptions.copyWith(processing: options);
    final response = await Native.setAudioProcessingOptions(
      mediaStreamTrack.id!,
      options.toMap(),
    );

    _throwIfAudioProcessingFailed(response);

    currentOptions = nextOptions;
    events.emit(LocalTrackOptionsUpdatedEvent(
      track: this,
      options: currentOptions,
    ));
  }

  num? _currentBitrate;
  num? get currentBitrate => _currentBitrate;

  AudioSenderStats? prevStats;

  @override
  Future<void> startCapture() async {
    await super.startCapture();
    if (lkPlatformSupportsExplicitAudioRecordingStart()) {
      try {
        // Match Swift: start the ADM before publishing so capture-time audio
        // processing options are applied before WebRTC opens the microphone.
        await Native.startLocalRecording(currentOptions.processing.toMap());
      } on PlatformException catch (error) {
        throw track_options.AudioProcessingException(
          _audioProcessingFailureReason(error.code),
          error.message ?? '',
        );
      }
    }
  }

  @override
  Future<bool> monitorStats() async {
    if (events.isDisposed || !isActive) {
      _currentBitrate = 0;
      return false;
    }
    try {
      final stats = await getSenderStats();

      if (stats != null && prevStats != null && sender != null) {
        final bitrate = computeBitrateForSenderStats(stats, prevStats);
        _currentBitrate = bitrate;
        events.emit(AudioSenderStatsEvent(stats: stats, currentBitrate: bitrate));
      }

      prevStats = stats;
    } catch (e) {
      logger.warning('failed to get sender stats: $e');
      return false;
    }
    return true;
  }

  Future<AudioSenderStats?> getSenderStats() async {
    if (sender == null) {
      return null;
    }

    late List<rtc.StatsReport> stats;
    try {
      stats = await sender!.getStats();
    } catch (e) {
      rethrow;
    }

    AudioSenderStats? senderStats;
    for (var v in stats) {
      if (v.type == 'outbound-rtp') {
        senderStats ??= AudioSenderStats(v.id, v.timestamp);
        senderStats.packetsSent = getNumValFromReport(v.values, 'packetsSent');
        senderStats.packetsLost = getNumValFromReport(v.values, 'packetsLost');
        senderStats.bytesSent = getNumValFromReport(v.values, 'bytesSent');
        senderStats.roundTripTime = getNumValFromReport(v.values, 'roundTripTime');
        senderStats.jitter = getNumValFromReport(v.values, 'jitter');

        final c = stats.firstWhereOrNull((element) => element.type == 'codec');
        if (c != null) {
          senderStats.mimeType = getStringValFromReport(c.values, 'mimeType');
          senderStats.payloadType = getNumValFromReport(c.values, 'payloadType');
          senderStats.channels = getNumValFromReport(c.values, 'channels');
          senderStats.clockRate = getNumValFromReport(c.values, 'clockRate');
        }
      } else if (v.type == 'media-source') {
        senderStats ??= AudioSenderStats(v.id, v.timestamp);
        senderStats.audioSourceStats = AudioSourceStats.fromReport(v);
      }
    }
    return senderStats;
  }

  // private constructor
  @internal
  LocalAudioTrack(
    TrackSource source,
    rtc.MediaStream stream,
    rtc.MediaStreamTrack track,
    this.currentOptions,
  ) : super(
          TrackType.AUDIO,
          source,
          stream,
          track,
        );

  /// Creates a new audio track from the default audio input device.
  static Future<LocalAudioTrack> create([
    track_options.AudioCaptureOptions? options,
  ]) async {
    options ??= const track_options.AudioCaptureOptions();
    final stream = await LocalTrack.createStream(options);

    final track = LocalAudioTrack(
      TrackSource.microphone,
      stream,
      stream.getAudioTracks().first,
      options,
    );

    try {
      if (options.processor != null) {
        await track.setProcessor(options.processor);
      }
    } catch (error, stackTrace) {
      try {
        await track.stop();
      } catch (stopError) {
        logger.warning('failed to stop audio track after processor setup failure: $stopError');
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    return track;
  }
}

void _throwIfAudioProcessingFailed(Map<String, dynamic> response) {
  final code = response['code'] as String?;
  final message = (response['message'] as String?) ?? '';

  final reason = _audioProcessingFailureReason(code);
  switch (code) {
    case 'applied':
    case 'stored':
      return;
    case 'rejectedInvalidCombination':
    case 'rejectedPlatformUnavailable':
    case 'applyFailed':
    case 'unknown':
    case 'rejectedRemoteTrack':
      throw track_options.AudioProcessingException(
        reason,
        message,
      );
    default:
      throw track_options.AudioProcessingException(
        track_options.AudioProcessingFailureReason.unknown,
        _unknownAudioProcessingMessage(code, message),
      );
  }
}

track_options.AudioProcessingFailureReason _audioProcessingFailureReason(String? code) {
  switch (code) {
    case 'rejectedInvalidCombination':
      return track_options.AudioProcessingFailureReason.invalidCombination;
    case 'rejectedPlatformUnavailable':
      return track_options.AudioProcessingFailureReason.platformUnavailable;
    case 'applyFailed':
      return track_options.AudioProcessingFailureReason.applyFailed;
    default:
      return track_options.AudioProcessingFailureReason.unknown;
  }
}

String _unknownAudioProcessingMessage(String? code, String message) {
  final trimmed = message.trim();
  if (trimmed.isNotEmpty) {
    return trimmed;
  }
  if (code != null && code.isNotEmpty) {
    return 'Unknown audio processing result code: $code.';
  }
  return '';
}
