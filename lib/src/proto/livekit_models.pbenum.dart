///
//  Generated code. Do not modify.
//  source: livekit_models.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class TrackType extends $pb.ProtobufEnum {
  static const TrackType AUDIO = TrackType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AUDIO');
  static const TrackType VIDEO = TrackType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'VIDEO');
  static const TrackType DATA = TrackType._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DATA');

  static const $core.List<TrackType> values = <TrackType> [
    AUDIO,
    VIDEO,
    DATA,
  ];

  static final $core.Map<$core.int, TrackType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TrackType? valueOf($core.int value) => _byValue[value];

  const TrackType._($core.int v, $core.String n) : super(v, n);
}

class ParticipantInfo_State extends $pb.ProtobufEnum {
  static const ParticipantInfo_State JOINING = ParticipantInfo_State._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'JOINING');
  static const ParticipantInfo_State JOINED = ParticipantInfo_State._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'JOINED');
  static const ParticipantInfo_State ACTIVE = ParticipantInfo_State._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ACTIVE');
  static const ParticipantInfo_State DISCONNECTED = ParticipantInfo_State._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DISCONNECTED');

  static const $core.List<ParticipantInfo_State> values = <ParticipantInfo_State> [
    JOINING,
    JOINED,
    ACTIVE,
    DISCONNECTED,
  ];

  static final $core.Map<$core.int, ParticipantInfo_State> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ParticipantInfo_State? valueOf($core.int value) => _byValue[value];

  const ParticipantInfo_State._($core.int v, $core.String n) : super(v, n);
}

