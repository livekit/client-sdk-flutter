///
//  Generated code. Do not modify.
//  source: livekit_rtc.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class SignalTarget extends $pb.ProtobufEnum {
  static const SignalTarget PUBLISHER = SignalTarget._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PUBLISHER');
  static const SignalTarget SUBSCRIBER = SignalTarget._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SUBSCRIBER');

  static const $core.List<SignalTarget> values = <SignalTarget> [
    PUBLISHER,
    SUBSCRIBER,
  ];

  static final $core.Map<$core.int, SignalTarget> _byValue = $pb.ProtobufEnum.initByValue(values);
  static SignalTarget? valueOf($core.int value) => _byValue[value];

  const SignalTarget._($core.int v, $core.String n) : super(v, n);
}

class VideoQuality extends $pb.ProtobufEnum {
  static const VideoQuality LOW = VideoQuality._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'LOW');
  static const VideoQuality MEDIUM = VideoQuality._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MEDIUM');
  static const VideoQuality HIGH = VideoQuality._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'HIGH');

  static const $core.List<VideoQuality> values = <VideoQuality> [
    LOW,
    MEDIUM,
    HIGH,
  ];

  static final $core.Map<$core.int, VideoQuality> _byValue = $pb.ProtobufEnum.initByValue(values);
  static VideoQuality? valueOf($core.int value) => _byValue[value];

  const VideoQuality._($core.int v, $core.String n) : super(v, n);
}

