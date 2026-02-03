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

import 'constants.dart';
import 'e2ee/options.dart';
import 'support/value_or_absent.dart';
import 'track/local/audio.dart';
import 'track/local/video.dart';
import 'track/options.dart';
import 'types/audio_encoding.dart';
import 'types/other.dart';
import 'types/video_encoding.dart';
import 'types/video_parameters.dart';
import 'utils.dart';

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
    this.protocolVersion = ProtocolVersion.v12,
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
  @Deprecated('Use encryption instead')
  final E2EEOptions? e2eeOptions;

  /// @experimental
  /// Options for end-to-end encryption.
  final E2EEOptions? encryption;

  /// fast track publication
  final bool fastPublish;

  /// deprecated, use [createVisualizer] instead
  /// please refer to example/lib/widgets/sound_waveform.dart
  @Deprecated('Use createVisualizer instead')
  final bool? enableVisualizer;

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
    this.encryption,
    this.enableVisualizer = false,
    this.fastPublish = true,
  });

  RoomOptions copyWith({
    ValueOrAbsent<CameraCaptureOptions> defaultCameraCaptureOptions = const Absent(),
    ValueOrAbsent<ScreenShareCaptureOptions> defaultScreenShareCaptureOptions = const Absent(),
    ValueOrAbsent<AudioCaptureOptions> defaultAudioCaptureOptions = const Absent(),
    ValueOrAbsent<VideoPublishOptions> defaultVideoPublishOptions = const Absent(),
    ValueOrAbsent<AudioPublishOptions> defaultAudioPublishOptions = const Absent(),
    ValueOrAbsent<AudioOutputOptions> defaultAudioOutputOptions = const Absent(),
    ValueOrAbsent<bool> adaptiveStream = const Absent(),
    ValueOrAbsent<bool> dynacast = const Absent(),
    ValueOrAbsent<bool> stopLocalTrackOnUnpublish = const Absent(),
    ValueOrAbsent<E2EEOptions?> e2eeOptions = const Absent(),
    ValueOrAbsent<E2EEOptions?> encryption = const Absent(),
    ValueOrAbsent<bool> fastPublish = const Absent(),
  }) {
    return RoomOptions(
      defaultCameraCaptureOptions: defaultCameraCaptureOptions.valueOr(this.defaultCameraCaptureOptions),
      defaultScreenShareCaptureOptions: defaultScreenShareCaptureOptions.valueOr(this.defaultScreenShareCaptureOptions),
      defaultAudioCaptureOptions: defaultAudioCaptureOptions.valueOr(this.defaultAudioCaptureOptions),
      defaultVideoPublishOptions: defaultVideoPublishOptions.valueOr(this.defaultVideoPublishOptions),
      defaultAudioPublishOptions: defaultAudioPublishOptions.valueOr(this.defaultAudioPublishOptions),
      defaultAudioOutputOptions: defaultAudioOutputOptions.valueOr(this.defaultAudioOutputOptions),
      adaptiveStream: adaptiveStream.valueOr(this.adaptiveStream),
      dynacast: dynacast.valueOr(this.dynacast),
      stopLocalTrackOnUnpublish: stopLocalTrackOnUnpublish.valueOr(this.stopLocalTrackOnUnpublish),
      // ignore: deprecated_member_use_from_same_package
      e2eeOptions: e2eeOptions.valueOr(this.e2eeOptions),
      encryption: encryption.valueOr(this.encryption),
      fastPublish: fastPublish.valueOr(this.fastPublish),
    );
  }
}

enum DegradationPreference {
  disabled,
  maintainFramerate,
  maintainResolution,
  balanced,
}

class BackupVideoCodec {
  const BackupVideoCodec({
    this.enabled = true,
    this.codec = defaultVideoCodec,
    this.encoding,
    this.simulcast = true,
  });
  final bool enabled;
  final String codec;
  // optional, when unset, it'll be computed based on dimensions and codec
  final VideoEncoding? encoding;
  final bool simulcast;
  BackupVideoCodec copyWith({
    ValueOrAbsent<bool> enabled = const Absent(),
    ValueOrAbsent<String> codec = const Absent(),
    ValueOrAbsent<VideoEncoding?> encoding = const Absent(),
    ValueOrAbsent<bool> simulcast = const Absent(),
  }) {
    return BackupVideoCodec(
      enabled: enabled.valueOr(this.enabled),
      codec: codec.valueOr(this.codec),
      encoding: encoding.valueOr(this.encoding),
      simulcast: simulcast.valueOr(this.simulcast),
    );
  }
}

class PublishOptions {
  /// Name of the track.
  final String? name;

  ///  Set stream name for the track. Audio and video tracks with the same stream name
  ///  will be placed in the same `MediaStream` and offer better synchronization.
  ///  By default, camera and microphone will be placed in a stream; as would screen_share and screen_share_audio
  final String? stream;

  const PublishOptions({
    this.name,
    this.stream,
  });
}

/// Options used when publishing video.
class VideoPublishOptions extends PublishOptions {
  static const defaultCameraName = 'camera';
  static const defaultScreenShareName = 'screenshare';
  static const defualtBackupVideoCodec = BackupVideoCodec(
    enabled: true,
    codec: defaultVideoCodec,
    simulcast: true,
  );

  /// The video codec to use.
  final String videoCodec;

  /// If provided, this will be used instead of the SDK's suggested encodings.
  /// Usually you don't need to provide this.
  /// Defaults to null.
  final VideoEncoding? videoEncoding;

  final VideoEncoding? screenShareEncoding;

  /// Whether to enable simulcast or not.
  /// https://blog.livekit.io/an-introduction-to-webrtc-simulcast-6c5f1f6402eb
  /// Defaults to true.
  final bool simulcast;

  final DegradationPreference? degradationPreference;

  final List<VideoParameters> videoSimulcastLayers;

  final List<VideoParameters> screenShareSimulcastLayers;

  final String? scalabilityMode;

  final BackupVideoCodec backupVideoCodec;

  const VideoPublishOptions(
      {super.name,
      super.stream,
      this.videoCodec = defaultVideoCodec,
      this.videoEncoding,
      this.screenShareEncoding,
      this.simulcast = true,
      this.videoSimulcastLayers = const [],
      this.screenShareSimulcastLayers = const [],
      this.backupVideoCodec = defualtBackupVideoCodec,
      this.scalabilityMode,
      this.degradationPreference});

  VideoPublishOptions copyWith({
    ValueOrAbsent<VideoEncoding?> videoEncoding = const Absent(),
    ValueOrAbsent<VideoEncoding?> screenShareEncoding = const Absent(),
    ValueOrAbsent<bool> simulcast = const Absent(),
    ValueOrAbsent<List<VideoParameters>> videoSimulcastLayers = const Absent(),
    ValueOrAbsent<List<VideoParameters>> screenShareSimulcastLayers = const Absent(),
    ValueOrAbsent<String> videoCodec = const Absent(),
    ValueOrAbsent<BackupVideoCodec> backupVideoCodec = const Absent(),
    ValueOrAbsent<DegradationPreference?> degradationPreference = const Absent(),
    ValueOrAbsent<String?> scalabilityMode = const Absent(),
    ValueOrAbsent<String?> name = const Absent(),
    ValueOrAbsent<String?> stream = const Absent(),
  }) =>
      VideoPublishOptions(
        videoEncoding: videoEncoding.valueOr(this.videoEncoding),
        screenShareEncoding: screenShareEncoding.valueOr(this.screenShareEncoding),
        simulcast: simulcast.valueOr(this.simulcast),
        videoSimulcastLayers: videoSimulcastLayers.valueOr(this.videoSimulcastLayers),
        screenShareSimulcastLayers: screenShareSimulcastLayers.valueOr(this.screenShareSimulcastLayers),
        videoCodec: videoCodec.valueOr(this.videoCodec),
        backupVideoCodec: backupVideoCodec.valueOr(this.backupVideoCodec),
        degradationPreference: degradationPreference.valueOr(this.degradationPreference),
        scalabilityMode: scalabilityMode.valueOr(this.scalabilityMode),
        name: name.valueOr(this.name),
        stream: stream.valueOr(this.stream),
      );

  @override
  String toString() => '${runtimeType}(videoEncoding: ${videoEncoding}, simulcast: ${simulcast})';
}

/// Options used when publishing audio.
class AudioPublishOptions extends PublishOptions {
  static const defaultMicrophoneName = 'microphone';

  /// Preferred encoding parameters.
  /// Defaults to [AudioEncoding.presetMusic] when not set.
  final AudioEncoding? encoding;

  /// Whether to enable DTX (Discontinuous Transmission) or not.
  /// https://en.wikipedia.org/wiki/Discontinuous_transmission
  /// Defaults to true.
  final bool dtx;

  /// red (Redundant Audio Data)
  final bool? red;

  /// Mark this audio as originating from a pre-connect buffer.
  /// Used to populate protobuf audioFeatures (TF_PRECONNECT_BUFFER).
  final bool preConnect;

  const AudioPublishOptions({
    super.name,
    super.stream,
    this.encoding,
    this.dtx = true,
    this.red = true,
    this.preConnect = false,
  });

  AudioPublishOptions copyWith({
    ValueOrAbsent<AudioEncoding?> encoding = const Absent(),
    ValueOrAbsent<bool> dtx = const Absent(),
    ValueOrAbsent<String?> name = const Absent(),
    ValueOrAbsent<String?> stream = const Absent(),
    ValueOrAbsent<bool?> red = const Absent(),
    ValueOrAbsent<bool> preConnect = const Absent(),
  }) =>
      AudioPublishOptions(
        encoding: encoding.valueOr(this.encoding),
        dtx: dtx.valueOr(this.dtx),
        name: name.valueOr(this.name),
        stream: stream.valueOr(this.stream),
        red: red.valueOr(this.red),
        preConnect: preConnect.valueOr(this.preConnect),
      );

  @override
  String toString() => '${runtimeType}(encoding: ${encoding}, dtx: ${dtx}, red: ${red}, preConnect: ${preConnect})';
}

final backupCodecs = ['vp8', 'h264'];

final videoCodecs = ['vp8', 'h264', 'h265', 'vp9', 'av1'];

bool isBackupCodec(String codec) {
  return backupCodecs.contains(codec.toLowerCase());
}
