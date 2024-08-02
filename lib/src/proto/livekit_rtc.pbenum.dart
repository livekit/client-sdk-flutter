//
//  Generated code. Do not modify.
//  source: livekit_rtc.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class SignalTarget extends $pb.ProtobufEnum {
  static const SignalTarget PUBLISHER =
      SignalTarget._(0, _omitEnumNames ? '' : 'PUBLISHER');
  static const SignalTarget SUBSCRIBER =
      SignalTarget._(1, _omitEnumNames ? '' : 'SUBSCRIBER');

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
  static const StreamState ACTIVE =
      StreamState._(0, _omitEnumNames ? '' : 'ACTIVE');
  static const StreamState PAUSED =
      StreamState._(1, _omitEnumNames ? '' : 'PAUSED');

  static const $core.List<StreamState> values = <StreamState>[
    ACTIVE,
    PAUSED,
  ];

  static final $core.Map<$core.int, StreamState> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static StreamState? valueOf($core.int value) => _byValue[value];

  const StreamState._($core.int v, $core.String n) : super(v, n);
}

class CandidateProtocol extends $pb.ProtobufEnum {
  static const CandidateProtocol UDP =
      CandidateProtocol._(0, _omitEnumNames ? '' : 'UDP');
  static const CandidateProtocol TCP =
      CandidateProtocol._(1, _omitEnumNames ? '' : 'TCP');
  static const CandidateProtocol TLS =
      CandidateProtocol._(2, _omitEnumNames ? '' : 'TLS');

  static const $core.List<CandidateProtocol> values = <CandidateProtocol>[
    UDP,
    TCP,
    TLS,
  ];

  static final $core.Map<$core.int, CandidateProtocol> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static CandidateProtocol? valueOf($core.int value) => _byValue[value];

  const CandidateProtocol._($core.int v, $core.String n) : super(v, n);
}

/// indicates action clients should take on receiving this message
class LeaveRequest_Action extends $pb.ProtobufEnum {
  static const LeaveRequest_Action DISCONNECT =
      LeaveRequest_Action._(0, _omitEnumNames ? '' : 'DISCONNECT');
  static const LeaveRequest_Action RESUME =
      LeaveRequest_Action._(1, _omitEnumNames ? '' : 'RESUME');
  static const LeaveRequest_Action RECONNECT =
      LeaveRequest_Action._(2, _omitEnumNames ? '' : 'RECONNECT');

  static const $core.List<LeaveRequest_Action> values = <LeaveRequest_Action>[
    DISCONNECT,
    RESUME,
    RECONNECT,
  ];

  static final $core.Map<$core.int, LeaveRequest_Action> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static LeaveRequest_Action? valueOf($core.int value) => _byValue[value];

  const LeaveRequest_Action._($core.int v, $core.String n) : super(v, n);
}

class ErrorResponse_Reason extends $pb.ProtobufEnum {
  static const ErrorResponse_Reason UNKNOWN =
      ErrorResponse_Reason._(0, _omitEnumNames ? '' : 'UNKNOWN');
  static const ErrorResponse_Reason NOT_FOUND =
      ErrorResponse_Reason._(1, _omitEnumNames ? '' : 'NOT_FOUND');
  static const ErrorResponse_Reason NOT_ALLOWED =
      ErrorResponse_Reason._(2, _omitEnumNames ? '' : 'NOT_ALLOWED');
  static const ErrorResponse_Reason INVALID_ARGUMENT =
      ErrorResponse_Reason._(3, _omitEnumNames ? '' : 'INVALID_ARGUMENT');

  static const $core.List<ErrorResponse_Reason> values = <ErrorResponse_Reason>[
    UNKNOWN,
    NOT_FOUND,
    NOT_ALLOWED,
    INVALID_ARGUMENT,
  ];

  static final $core.Map<$core.int, ErrorResponse_Reason> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static ErrorResponse_Reason? valueOf($core.int value) => _byValue[value];

  const ErrorResponse_Reason._($core.int v, $core.String n) : super(v, n);
}

const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
