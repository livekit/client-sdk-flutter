///
//  Generated code. Do not modify.
//  source: livekit_rtc.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class SignalTarget extends $pb.ProtobufEnum {
  static const SignalTarget PUBLISHER = SignalTarget._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'PUBLISHER');
  static const SignalTarget SUBSCRIBER = SignalTarget._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'SUBSCRIBER');

  static const $core.List<SignalTarget> values = <SignalTarget>[
    PUBLISHER,
    SUBSCRIBER,
  ];

  static final $core.Map<$core.int, SignalTarget> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static SignalTarget? valueOf($core.int value) => _byValue[value];

  const SignalTarget._($core.int v, $core.String n) : super(v, n);
}

class StreamState extends $pb.ProtobufEnum {
  static const StreamState ACTIVE = StreamState._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'ACTIVE');
  static const StreamState PAUSED = StreamState._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'PAUSED');

  static const $core.List<StreamState> values = <StreamState>[
    ACTIVE,
    PAUSED,
  ];

  static final $core.Map<$core.int, StreamState> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static StreamState? valueOf($core.int value) => _byValue[value];

  const StreamState._($core.int v, $core.String n) : super(v, n);
}
