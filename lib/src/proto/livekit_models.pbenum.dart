///
//  Generated code. Do not modify.
//  source: livekit_models.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

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
