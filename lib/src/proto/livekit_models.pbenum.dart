///
//  Generated code. Do not modify.
//  source: livekit_models.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class AudioCodec extends $pb.ProtobufEnum {
  static const AudioCodec DEFAULT_AC = AudioCodec._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'DEFAULT_AC');
  static const AudioCodec OPUS = AudioCodec._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'OPUS');
  static const AudioCodec AAC = AudioCodec._(
      2,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'AAC');

  static const $core.List<AudioCodec> values = <AudioCodec>[
    DEFAULT_AC,
    OPUS,
    AAC,
  ];

  static final $core.Map<$core.int, AudioCodec> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static AudioCodec? valueOf($core.int value) => _byValue[value];

  const AudioCodec._($core.int v, $core.String n) : super(v, n);
}

class VideoCodec extends $pb.ProtobufEnum {
  static const VideoCodec DEFAULT_VC = VideoCodec._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'DEFAULT_VC');
  static const VideoCodec H264_BASELINE = VideoCodec._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'H264_BASELINE');
  static const VideoCodec H264_MAIN = VideoCodec._(
      2,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'H264_MAIN');
  static const VideoCodec H264_HIGH = VideoCodec._(
      3,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'H264_HIGH');
  static const VideoCodec VP8 = VideoCodec._(
      4,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'VP8');

  static const $core.List<VideoCodec> values = <VideoCodec>[
    DEFAULT_VC,
    H264_BASELINE,
    H264_MAIN,
    H264_HIGH,
    VP8,
  ];

  static final $core.Map<$core.int, VideoCodec> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static VideoCodec? valueOf($core.int value) => _byValue[value];

  const VideoCodec._($core.int v, $core.String n) : super(v, n);
}

class TrackType extends $pb.ProtobufEnum {
  static const TrackType AUDIO = TrackType._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'AUDIO');
  static const TrackType VIDEO = TrackType._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'VIDEO');
  static const TrackType DATA = TrackType._(
      2,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'DATA');

  static const $core.List<TrackType> values = <TrackType>[
    AUDIO,
    VIDEO,
    DATA,
  ];

  static final $core.Map<$core.int, TrackType> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static TrackType? valueOf($core.int value) => _byValue[value];

  const TrackType._($core.int v, $core.String n) : super(v, n);
}

class TrackSource extends $pb.ProtobufEnum {
  static const TrackSource UNKNOWN = TrackSource._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'UNKNOWN');
  static const TrackSource CAMERA = TrackSource._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'CAMERA');
  static const TrackSource MICROPHONE = TrackSource._(
      2,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'MICROPHONE');
  static const TrackSource SCREEN_SHARE = TrackSource._(
      3,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'SCREEN_SHARE');
  static const TrackSource SCREEN_SHARE_AUDIO = TrackSource._(
      4,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'SCREEN_SHARE_AUDIO');

  static const $core.List<TrackSource> values = <TrackSource>[
    UNKNOWN,
    CAMERA,
    MICROPHONE,
    SCREEN_SHARE,
    SCREEN_SHARE_AUDIO,
  ];

  static final $core.Map<$core.int, TrackSource> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static TrackSource? valueOf($core.int value) => _byValue[value];

  const TrackSource._($core.int v, $core.String n) : super(v, n);
}

class VideoQuality extends $pb.ProtobufEnum {
  static const VideoQuality LOW = VideoQuality._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'LOW');
  static const VideoQuality MEDIUM = VideoQuality._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'MEDIUM');
  static const VideoQuality HIGH = VideoQuality._(
      2,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'HIGH');
  static const VideoQuality OFF = VideoQuality._(
      3,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'OFF');

  static const $core.List<VideoQuality> values = <VideoQuality>[
    LOW,
    MEDIUM,
    HIGH,
    OFF,
  ];

  static final $core.Map<$core.int, VideoQuality> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static VideoQuality? valueOf($core.int value) => _byValue[value];

  const VideoQuality._($core.int v, $core.String n) : super(v, n);
}

class ConnectionQuality extends $pb.ProtobufEnum {
  static const ConnectionQuality POOR = ConnectionQuality._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'POOR');
  static const ConnectionQuality GOOD = ConnectionQuality._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'GOOD');
  static const ConnectionQuality EXCELLENT = ConnectionQuality._(
      2,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'EXCELLENT');

  static const $core.List<ConnectionQuality> values = <ConnectionQuality>[
    POOR,
    GOOD,
    EXCELLENT,
  ];

  static final $core.Map<$core.int, ConnectionQuality> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static ConnectionQuality? valueOf($core.int value) => _byValue[value];

  const ConnectionQuality._($core.int v, $core.String n) : super(v, n);
}

class ClientConfigSetting extends $pb.ProtobufEnum {
  static const ClientConfigSetting UNSET = ClientConfigSetting._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'UNSET');
  static const ClientConfigSetting DISABLED = ClientConfigSetting._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'DISABLED');
  static const ClientConfigSetting ENABLED = ClientConfigSetting._(
      2,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'ENABLED');

  static const $core.List<ClientConfigSetting> values = <ClientConfigSetting>[
    UNSET,
    DISABLED,
    ENABLED,
  ];

  static final $core.Map<$core.int, ClientConfigSetting> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static ClientConfigSetting? valueOf($core.int value) => _byValue[value];

  const ClientConfigSetting._($core.int v, $core.String n) : super(v, n);
}

class DisconnectReason extends $pb.ProtobufEnum {
  static const DisconnectReason UNKNOWN_REASON = DisconnectReason._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'UNKNOWN_REASON');
  static const DisconnectReason CLIENT_INITIATED = DisconnectReason._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'CLIENT_INITIATED');
  static const DisconnectReason DUPLICATE_IDENTITY = DisconnectReason._(
      2,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'DUPLICATE_IDENTITY');
  static const DisconnectReason SERVER_SHUTDOWN = DisconnectReason._(
      3,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'SERVER_SHUTDOWN');
  static const DisconnectReason PARTICIPANT_REMOVED = DisconnectReason._(
      4,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'PARTICIPANT_REMOVED');
  static const DisconnectReason ROOM_DELETED = DisconnectReason._(
      5,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'ROOM_DELETED');
  static const DisconnectReason STATE_MISMATCH = DisconnectReason._(
      6,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'STATE_MISMATCH');
  static const DisconnectReason JOIN_FAILURE = DisconnectReason._(
      7,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'JOIN_FAILURE');

  static const $core.List<DisconnectReason> values = <DisconnectReason>[
    UNKNOWN_REASON,
    CLIENT_INITIATED,
    DUPLICATE_IDENTITY,
    SERVER_SHUTDOWN,
    PARTICIPANT_REMOVED,
    ROOM_DELETED,
    STATE_MISMATCH,
    JOIN_FAILURE,
  ];

  static final $core.Map<$core.int, DisconnectReason> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static DisconnectReason? valueOf($core.int value) => _byValue[value];

  const DisconnectReason._($core.int v, $core.String n) : super(v, n);
}

class ReconnectReason extends $pb.ProtobufEnum {
  static const ReconnectReason RR_UNKOWN = ReconnectReason._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'RR_UNKOWN');
  static const ReconnectReason RR_SIGNAL_DISCONNECTED = ReconnectReason._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'RR_SIGNAL_DISCONNECTED');
  static const ReconnectReason RR_PUBLISHER_FAILED = ReconnectReason._(
      2,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'RR_PUBLISHER_FAILED');
  static const ReconnectReason RR_SUBSCRIBER_FAILED = ReconnectReason._(
      3,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'RR_SUBSCRIBER_FAILED');
  static const ReconnectReason RR_SWITCH_CANDIDATE = ReconnectReason._(
      4,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'RR_SWITCH_CANDIDATE');

  static const $core.List<ReconnectReason> values = <ReconnectReason>[
    RR_UNKOWN,
    RR_SIGNAL_DISCONNECTED,
    RR_PUBLISHER_FAILED,
    RR_SUBSCRIBER_FAILED,
    RR_SWITCH_CANDIDATE,
  ];

  static final $core.Map<$core.int, ReconnectReason> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static ReconnectReason? valueOf($core.int value) => _byValue[value];

  const ReconnectReason._($core.int v, $core.String n) : super(v, n);
}

class ParticipantInfo_State extends $pb.ProtobufEnum {
  static const ParticipantInfo_State JOINING = ParticipantInfo_State._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'JOINING');
  static const ParticipantInfo_State JOINED = ParticipantInfo_State._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'JOINED');
  static const ParticipantInfo_State ACTIVE = ParticipantInfo_State._(
      2,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'ACTIVE');
  static const ParticipantInfo_State DISCONNECTED = ParticipantInfo_State._(
      3,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'DISCONNECTED');

  static const $core.List<ParticipantInfo_State> values =
      <ParticipantInfo_State>[
    JOINING,
    JOINED,
    ACTIVE,
    DISCONNECTED,
  ];

  static final $core.Map<$core.int, ParticipantInfo_State> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static ParticipantInfo_State? valueOf($core.int value) => _byValue[value];

  const ParticipantInfo_State._($core.int v, $core.String n) : super(v, n);
}

class Encryption_Type extends $pb.ProtobufEnum {
  static const Encryption_Type NONE = Encryption_Type._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'NONE');
  static const Encryption_Type GCM = Encryption_Type._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'GCM');
  static const Encryption_Type CUSTOM = Encryption_Type._(
      2,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'CUSTOM');

  static const $core.List<Encryption_Type> values = <Encryption_Type>[
    NONE,
    GCM,
    CUSTOM,
  ];

  static final $core.Map<$core.int, Encryption_Type> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static Encryption_Type? valueOf($core.int value) => _byValue[value];

  const Encryption_Type._($core.int v, $core.String n) : super(v, n);
}

class DataPacket_Kind extends $pb.ProtobufEnum {
  static const DataPacket_Kind RELIABLE = DataPacket_Kind._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'RELIABLE');
  static const DataPacket_Kind LOSSY = DataPacket_Kind._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'LOSSY');

  static const $core.List<DataPacket_Kind> values = <DataPacket_Kind>[
    RELIABLE,
    LOSSY,
  ];

  static final $core.Map<$core.int, DataPacket_Kind> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static DataPacket_Kind? valueOf($core.int value) => _byValue[value];

  const DataPacket_Kind._($core.int v, $core.String n) : super(v, n);
}

class ServerInfo_Edition extends $pb.ProtobufEnum {
  static const ServerInfo_Edition Standard = ServerInfo_Edition._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'Standard');
  static const ServerInfo_Edition Cloud = ServerInfo_Edition._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'Cloud');

  static const $core.List<ServerInfo_Edition> values = <ServerInfo_Edition>[
    Standard,
    Cloud,
  ];

  static final $core.Map<$core.int, ServerInfo_Edition> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static ServerInfo_Edition? valueOf($core.int value) => _byValue[value];

  const ServerInfo_Edition._($core.int v, $core.String n) : super(v, n);
}

class ClientInfo_SDK extends $pb.ProtobufEnum {
  static const ClientInfo_SDK UNKNOWN = ClientInfo_SDK._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'UNKNOWN');
  static const ClientInfo_SDK JS = ClientInfo_SDK._(1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'JS');
  static const ClientInfo_SDK SWIFT = ClientInfo_SDK._(
      2,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'SWIFT');
  static const ClientInfo_SDK ANDROID = ClientInfo_SDK._(
      3,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'ANDROID');
  static const ClientInfo_SDK FLUTTER = ClientInfo_SDK._(
      4,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'FLUTTER');
  static const ClientInfo_SDK GO = ClientInfo_SDK._(5,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GO');
  static const ClientInfo_SDK UNITY = ClientInfo_SDK._(
      6,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'UNITY');

  static const $core.List<ClientInfo_SDK> values = <ClientInfo_SDK>[
    UNKNOWN,
    JS,
    SWIFT,
    ANDROID,
    FLUTTER,
    GO,
    UNITY,
  ];

  static final $core.Map<$core.int, ClientInfo_SDK> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static ClientInfo_SDK? valueOf($core.int value) => _byValue[value];

  const ClientInfo_SDK._($core.int v, $core.String n) : super(v, n);
}
