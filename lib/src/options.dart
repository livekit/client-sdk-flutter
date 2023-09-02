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

import 'constants.dart';
import 'e2ee/options.dart';
import 'proto/livekit_models.pb.dart';
import 'publication/remote.dart';
import 'track/local/audio.dart';
import 'track/local/video.dart';
import 'track/options.dart';
import 'track/track.dart';
import 'types/other.dart';
import 'types/video_encoding.dart';
import 'types/video_parameters.dart';

class TrackOption<E extends Object, T extends Object> {
  final E? enabled;
  final T? track;
  const TrackOption({this.enabled, this.track});
}

/// This will enable the local participant to publish tracks on connect,
/// instead of having to explicitly publish them.
/// Defaults to false for all three tracks: microphone, camera, and screen.
/// You can also create LocalAudio/VideoTrack on your `PreJoin` page
/// (preview camera or select audio device), Automatically publish these
/// tracks after the room is connected.
class FastConnectOptions {
  FastConnectOptions({
    this.microphone = const TrackOption(enabled: false),
    this.camera = const TrackOption(enabled: false),
    this.screen = const TrackOption(enabled: false),
  });
  final TrackOption<bool, LocalAudioTrack> microphone;
  final TrackOption<bool, LocalVideoTrack> camera;
  final TrackOption<bool, LocalVideoTrack> screen;
}

/// Options used when connecting to the server.
class ConnectOptions {
  /// Auto-subscribe to existing and new [RemoteTrackPublication]s after
  /// successfully connecting to the [Room].
  /// Defaults to true.
  final bool autoSubscribe;

  /// The default [RTCConfiguration] to be used.
  final RTCConfiguration rtcConfiguration;

  /// The protocol version to be used. Usually this doesn't need to be modified.
  final ProtocolVersion protocolVersion;

  final Timeouts timeouts;

  const ConnectOptions({
    this.autoSubscribe = true,
    this.rtcConfiguration = const RTCConfiguration(),
    this.protocolVersion = ProtocolVersion.v9,
    this.timeouts = Timeouts.defaultTimeouts,
  });
}

/// Options used to modify the behavior of the [Room].
/// {@category Room}
class RoomOptions {
  /// Default options used for [LocalVideoTrack.createCameraTrack].
  final CameraCaptureOptions defaultCameraCaptureOptions;

  /// Default options used for [LocalVideoTrack.createScreenShareTrack].
  final ScreenShareCaptureOptions defaultScreenShareCaptureOptions;

  /// Default options used when capturing video for a [LocalAudioTrack].
  final AudioCaptureOptions defaultAudioCaptureOptions;

  /// Default options used when publishing a [LocalVideoTrack].
  final VideoPublishOptions defaultVideoPublishOptions;

  /// Default options used when publishing a [LocalAudioTrack].
  final AudioPublishOptions defaultAudioPublishOptions;

  final AudioOutputOptions defaultAudioOutputOptions;

  /// AdaptiveStream lets LiveKit automatically manage quality of subscribed
  /// video tracks to optimize for bandwidth and CPU.
  /// When attached video elements are visible, it'll choose an appropriate
  /// resolution based on the size of largest video element it's attached to.
  ///
  /// When none of the video elements are visible, it'll temporarily pause
  /// the data flow until they are visible again.
  final bool adaptiveStream;

  /// enable Dynacast, off by default. With Dynacast dynamically pauses
  /// video layers that are not being consumed by any subscribers, significantly
  /// reducing publishing CPU and bandwidth usage.
  /// Dynacast will be enabled if SVC codecs (VP9/AV1) are used. Multi-codec
  /// simulcast requires dynacast
  final bool dynacast;

  /// Set this to false in case you would like to stop the track yourself.
  /// If you set this to false, make sure you call [Track.stop].
  /// Defaults to true.
  final bool stopLocalTrackOnUnpublish;

  /// Options for end-to-end encryption.
  final E2EEOptions? e2eeOptions;

  const RoomOptions({
    this.defaultCameraCaptureOptions = const CameraCaptureOptions(),
    this.defaultScreenShareCaptureOptions = const ScreenShareCaptureOptions(),
    this.defaultAudioCaptureOptions = const AudioCaptureOptions(),
    this.defaultVideoPublishOptions = const VideoPublishOptions(),
    this.defaultAudioPublishOptions = const AudioPublishOptions(),
    this.defaultAudioOutputOptions = const AudioOutputOptions(),
    this.adaptiveStream = false,
    this.dynacast = false,
    this.stopLocalTrackOnUnpublish = true,
    this.e2eeOptions,
  });

  RoomOptions copyWith({
    CameraCaptureOptions? defaultCameraCaptureOptions,
    ScreenShareCaptureOptions? defaultScreenShareCaptureOptions,
    AudioCaptureOptions? defaultAudioCaptureOptions,
    VideoPublishOptions? defaultVideoPublishOptions,
    AudioPublishOptions? defaultAudioPublishOptions,
    AudioOutputOptions? defaultAudioOutputOptions,
    bool? adaptiveStream,
    bool? dynacast,
    bool? stopLocalTrackOnUnpublish,
    E2EEOptions? e2eeOptions,
  }) {
    return RoomOptions(
      defaultCameraCaptureOptions:
          defaultCameraCaptureOptions ?? this.defaultCameraCaptureOptions,
      defaultScreenShareCaptureOptions: defaultScreenShareCaptureOptions ??
          this.defaultScreenShareCaptureOptions,
      defaultAudioCaptureOptions:
          defaultAudioCaptureOptions ?? this.defaultAudioCaptureOptions,
      defaultVideoPublishOptions:
          defaultVideoPublishOptions ?? this.defaultVideoPublishOptions,
      defaultAudioPublishOptions:
          defaultAudioPublishOptions ?? this.defaultAudioPublishOptions,
      defaultAudioOutputOptions:
          defaultAudioOutputOptions ?? this.defaultAudioOutputOptions,
      adaptiveStream: adaptiveStream ?? this.adaptiveStream,
      dynacast: dynacast ?? this.dynacast,
      stopLocalTrackOnUnpublish:
          stopLocalTrackOnUnpublish ?? this.stopLocalTrackOnUnpublish,
      e2eeOptions: e2eeOptions ?? this.e2eeOptions,
    );
  }
}

class BackupVideoCodec {
  BackupVideoCodec({
    this.codec = 'vp8',
    this.encoding,
    this.simulcast = true,
  });
  String codec;
  // optional, when unset, it'll be computed based on dimensions and codec
  VideoEncoding? encoding;
  bool simulcast;
}

/// Options used when publishing video.
class VideoPublishOptions {
  static const defaultCameraName = 'camera';
  static const defaultScreenShareName = 'screenshare';

  /// The video codec to use.
  final String videoCodec;

  /// If provided, this will be used instead of the SDK's suggested encodings.
  /// Usually you don't need to provide this.
  /// Defaults to null.
  final VideoEncoding? videoEncoding;

  /// Whether to enable simulcast or not.
  /// https://blog.livekit.io/an-introduction-to-webrtc-simulcast-6c5f1f6402eb
  /// Defaults to true.
  final bool simulcast;

  /// Name of the video track.
  final String? name;

  final List<VideoParameters> videoSimulcastLayers;

  final List<VideoParameters> screenShareSimulcastLayers;

  final String? scalabilityMode;

  final BackupVideoCodec? backupCodec;

  const VideoPublishOptions({
    this.videoCodec = 'H264',
    this.videoEncoding,
    this.simulcast = true,
    this.videoSimulcastLayers = const [],
    this.screenShareSimulcastLayers = const [],
    this.name,
    this.backupCodec,
    this.scalabilityMode,
  });

  VideoPublishOptions copyWith({
    VideoEncoding? videoEncoding,
    bool? simulcast,
    List<VideoParameters>? videoSimulcastLayers,
    List<VideoParameters>? screenShareSimulcastLayers,
    String? videoCodec,
    BackupVideoCodec? backupCodec,
    String? scalabilityMode,
  }) =>
      VideoPublishOptions(
        videoEncoding: videoEncoding ?? this.videoEncoding,
        simulcast: simulcast ?? this.simulcast,
        videoSimulcastLayers: videoSimulcastLayers ?? this.videoSimulcastLayers,
        screenShareSimulcastLayers:
            screenShareSimulcastLayers ?? this.screenShareSimulcastLayers,
        videoCodec: videoCodec ?? this.videoCodec,
        backupCodec: backupCodec ?? this.backupCodec,
        scalabilityMode: scalabilityMode ?? this.scalabilityMode,
      );

  @override
  String toString() =>
      '${runtimeType}(videoEncoding: ${videoEncoding}, simulcast: ${simulcast})';
}

class AudioPreset {
  static const telephone = 12000;
  static const speech = 20000;
  static const music = 32000;
  static const musicStereo = 48000;
  static const musicHighQuality = 64000;
  static const musicHighQualityStereo = 96000;
}

/// Options used when publishing audio.
class AudioPublishOptions {
  static const defaultMicrophoneName = 'microphone';

  /// Whether to enable DTX (Discontinuous Transmission) or not.
  /// https://en.wikipedia.org/wiki/Discontinuous_transmission
  /// Defaults to true.
  final bool dtx;

  /// max audio bitrate
  final int audioBitrate;

  /// Turn off the audio track when muted, to avoid the microphone
  /// indicator light on.
  @Deprecated('Mic indicator will always turn off now when muted.')
  final bool stopMicTrackOnMute;

  /// Name of the audio track.
  final String? name;

  const AudioPublishOptions(
      {this.dtx = true,
      this.audioBitrate = AudioPreset.music,
      this.stopMicTrackOnMute = true,
      this.name});

  @override
  String toString() => '${runtimeType}(dtx: ${dtx})';
}

final backupCodecs = ['vp8', 'h264'];

final videoCodecs = ['vp8', 'h264', 'vp9', 'av1'];

bool isBackupCodec(String codec) {
  return backupCodecs.contains(codec.toLowerCase());
}
