///
//  Generated code. Do not modify.
//  source: livekit_models.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'livekit_models.pbenum.dart';

export 'livekit_models.pbenum.dart';

class Room extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Room',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'sid')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..a<$core.int>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'emptyTimeout',
        $pb.PbFieldType.OU3)
    ..a<$core.int>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'maxParticipants',
        $pb.PbFieldType.OU3)
    ..aInt64(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'creationTime')
    ..aOS(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'turnPassword')
    ..pc<Codec>(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'enabledCodecs',
        $pb.PbFieldType.PM,
        subBuilder: Codec.create)
    ..hasRequiredFields = false;

  Room._() : super();
  factory Room({
    $core.String? sid,
    $core.String? name,
    $core.int? emptyTimeout,
    $core.int? maxParticipants,
    $fixnum.Int64? creationTime,
    $core.String? turnPassword,
    $core.Iterable<Codec>? enabledCodecs,
  }) {
    final _result = create();
    if (sid != null) {
      _result.sid = sid;
    }
    if (name != null) {
      _result.name = name;
    }
    if (emptyTimeout != null) {
      _result.emptyTimeout = emptyTimeout;
    }
    if (maxParticipants != null) {
      _result.maxParticipants = maxParticipants;
    }
    if (creationTime != null) {
      _result.creationTime = creationTime;
    }
    if (turnPassword != null) {
      _result.turnPassword = turnPassword;
    }
    if (enabledCodecs != null) {
      _result.enabledCodecs.addAll(enabledCodecs);
    }
    return _result;
  }
  factory Room.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Room.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Room clone() => Room()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Room copyWith(void Function(Room) updates) =>
      super.copyWith((message) => updates(message as Room))
          as Room; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Room create() => Room._();
  Room createEmptyInstance() => create();
  static $pb.PbList<Room> createRepeated() => $pb.PbList<Room>();
  @$core.pragma('dart2js:noInline')
  static Room getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Room>(create);
  static Room? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sid => $_getSZ(0);
  @$pb.TagNumber(1)
  set sid($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasSid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get emptyTimeout => $_getIZ(2);
  @$pb.TagNumber(3)
  set emptyTimeout($core.int v) {
    $_setUnsignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasEmptyTimeout() => $_has(2);
  @$pb.TagNumber(3)
  void clearEmptyTimeout() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get maxParticipants => $_getIZ(3);
  @$pb.TagNumber(4)
  set maxParticipants($core.int v) {
    $_setUnsignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasMaxParticipants() => $_has(3);
  @$pb.TagNumber(4)
  void clearMaxParticipants() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get creationTime => $_getI64(4);
  @$pb.TagNumber(5)
  set creationTime($fixnum.Int64 v) {
    $_setInt64(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasCreationTime() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreationTime() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get turnPassword => $_getSZ(5);
  @$pb.TagNumber(6)
  set turnPassword($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasTurnPassword() => $_has(5);
  @$pb.TagNumber(6)
  void clearTurnPassword() => clearField(6);

  @$pb.TagNumber(7)
  $core.List<Codec> get enabledCodecs => $_getList(6);
}

class Codec extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Codec',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'mime')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fmtpLine')
    ..hasRequiredFields = false;

  Codec._() : super();
  factory Codec({
    $core.String? mime,
    $core.String? fmtpLine,
  }) {
    final _result = create();
    if (mime != null) {
      _result.mime = mime;
    }
    if (fmtpLine != null) {
      _result.fmtpLine = fmtpLine;
    }
    return _result;
  }
  factory Codec.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Codec.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Codec clone() => Codec()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Codec copyWith(void Function(Codec) updates) =>
      super.copyWith((message) => updates(message as Codec))
          as Codec; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Codec create() => Codec._();
  Codec createEmptyInstance() => create();
  static $pb.PbList<Codec> createRepeated() => $pb.PbList<Codec>();
  @$core.pragma('dart2js:noInline')
  static Codec getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Codec>(create);
  static Codec? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get mime => $_getSZ(0);
  @$pb.TagNumber(1)
  set mime($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasMime() => $_has(0);
  @$pb.TagNumber(1)
  void clearMime() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get fmtpLine => $_getSZ(1);
  @$pb.TagNumber(2)
  set fmtpLine($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasFmtpLine() => $_has(1);
  @$pb.TagNumber(2)
  void clearFmtpLine() => clearField(2);
}

class ParticipantInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ParticipantInfo',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'sid')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'identity')
    ..e<ParticipantInfo_State>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'state',
        $pb.PbFieldType.OE,
        defaultOrMaker: ParticipantInfo_State.JOINING,
        valueOf: ParticipantInfo_State.valueOf,
        enumValues: ParticipantInfo_State.values)
    ..pc<TrackInfo>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tracks',
        $pb.PbFieldType.PM,
        subBuilder: TrackInfo.create)
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'metadata')
    ..aInt64(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'joinedAt')
    ..aOB(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hidden')
    ..hasRequiredFields = false;

  ParticipantInfo._() : super();
  factory ParticipantInfo({
    $core.String? sid,
    $core.String? identity,
    ParticipantInfo_State? state,
    $core.Iterable<TrackInfo>? tracks,
    $core.String? metadata,
    $fixnum.Int64? joinedAt,
    $core.bool? hidden,
  }) {
    final _result = create();
    if (sid != null) {
      _result.sid = sid;
    }
    if (identity != null) {
      _result.identity = identity;
    }
    if (state != null) {
      _result.state = state;
    }
    if (tracks != null) {
      _result.tracks.addAll(tracks);
    }
    if (metadata != null) {
      _result.metadata = metadata;
    }
    if (joinedAt != null) {
      _result.joinedAt = joinedAt;
    }
    if (hidden != null) {
      _result.hidden = hidden;
    }
    return _result;
  }
  factory ParticipantInfo.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ParticipantInfo.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ParticipantInfo clone() => ParticipantInfo()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ParticipantInfo copyWith(void Function(ParticipantInfo) updates) =>
      super.copyWith((message) => updates(message as ParticipantInfo))
          as ParticipantInfo; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ParticipantInfo create() => ParticipantInfo._();
  ParticipantInfo createEmptyInstance() => create();
  static $pb.PbList<ParticipantInfo> createRepeated() => $pb.PbList<ParticipantInfo>();
  @$core.pragma('dart2js:noInline')
  static ParticipantInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ParticipantInfo>(create);
  static ParticipantInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sid => $_getSZ(0);
  @$pb.TagNumber(1)
  set sid($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasSid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get identity => $_getSZ(1);
  @$pb.TagNumber(2)
  set identity($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasIdentity() => $_has(1);
  @$pb.TagNumber(2)
  void clearIdentity() => clearField(2);

  @$pb.TagNumber(3)
  ParticipantInfo_State get state => $_getN(2);
  @$pb.TagNumber(3)
  set state(ParticipantInfo_State v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasState() => $_has(2);
  @$pb.TagNumber(3)
  void clearState() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<TrackInfo> get tracks => $_getList(3);

  @$pb.TagNumber(5)
  $core.String get metadata => $_getSZ(4);
  @$pb.TagNumber(5)
  set metadata($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasMetadata() => $_has(4);
  @$pb.TagNumber(5)
  void clearMetadata() => clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get joinedAt => $_getI64(5);
  @$pb.TagNumber(6)
  set joinedAt($fixnum.Int64 v) {
    $_setInt64(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasJoinedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearJoinedAt() => clearField(6);

  @$pb.TagNumber(7)
  $core.bool get hidden => $_getBF(6);
  @$pb.TagNumber(7)
  set hidden($core.bool v) {
    $_setBool(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasHidden() => $_has(6);
  @$pb.TagNumber(7)
  void clearHidden() => clearField(7);
}

class TrackInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TrackInfo',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'sid')
    ..e<TrackType>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type',
        $pb.PbFieldType.OE,
        defaultOrMaker: TrackType.AUDIO, valueOf: TrackType.valueOf, enumValues: TrackType.values)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOB(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'muted')
    ..a<$core.int>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'width',
        $pb.PbFieldType.OU3)
    ..a<$core.int>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'height',
        $pb.PbFieldType.OU3)
    ..aOB(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'simulcast')
    ..hasRequiredFields = false;

  TrackInfo._() : super();
  factory TrackInfo({
    $core.String? sid,
    TrackType? type,
    $core.String? name,
    $core.bool? muted,
    $core.int? width,
    $core.int? height,
    $core.bool? simulcast,
  }) {
    final _result = create();
    if (sid != null) {
      _result.sid = sid;
    }
    if (type != null) {
      _result.type = type;
    }
    if (name != null) {
      _result.name = name;
    }
    if (muted != null) {
      _result.muted = muted;
    }
    if (width != null) {
      _result.width = width;
    }
    if (height != null) {
      _result.height = height;
    }
    if (simulcast != null) {
      _result.simulcast = simulcast;
    }
    return _result;
  }
  factory TrackInfo.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TrackInfo.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TrackInfo clone() => TrackInfo()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TrackInfo copyWith(void Function(TrackInfo) updates) =>
      super.copyWith((message) => updates(message as TrackInfo))
          as TrackInfo; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TrackInfo create() => TrackInfo._();
  TrackInfo createEmptyInstance() => create();
  static $pb.PbList<TrackInfo> createRepeated() => $pb.PbList<TrackInfo>();
  @$core.pragma('dart2js:noInline')
  static TrackInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TrackInfo>(create);
  static TrackInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sid => $_getSZ(0);
  @$pb.TagNumber(1)
  set sid($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasSid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSid() => clearField(1);

  @$pb.TagNumber(2)
  TrackType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(TrackType v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get muted => $_getBF(3);
  @$pb.TagNumber(4)
  set muted($core.bool v) {
    $_setBool(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasMuted() => $_has(3);
  @$pb.TagNumber(4)
  void clearMuted() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get width => $_getIZ(4);
  @$pb.TagNumber(5)
  set width($core.int v) {
    $_setUnsignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasWidth() => $_has(4);
  @$pb.TagNumber(5)
  void clearWidth() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get height => $_getIZ(5);
  @$pb.TagNumber(6)
  set height($core.int v) {
    $_setUnsignedInt32(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasHeight() => $_has(5);
  @$pb.TagNumber(6)
  void clearHeight() => clearField(6);

  @$pb.TagNumber(7)
  $core.bool get simulcast => $_getBF(6);
  @$pb.TagNumber(7)
  set simulcast($core.bool v) {
    $_setBool(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasSimulcast() => $_has(6);
  @$pb.TagNumber(7)
  void clearSimulcast() => clearField(7);
}

enum DataMessage_Value { text, binary, notSet }

class DataMessage extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, DataMessage_Value> _DataMessage_ValueByTag = {
    1: DataMessage_Value.text,
    2: DataMessage_Value.binary,
    0: DataMessage_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DataMessage',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'text')
    ..a<$core.List<$core.int>>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'binary',
        $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  DataMessage._() : super();
  factory DataMessage({
    $core.String? text,
    $core.List<$core.int>? binary,
  }) {
    final _result = create();
    if (text != null) {
      _result.text = text;
    }
    if (binary != null) {
      _result.binary = binary;
    }
    return _result;
  }
  factory DataMessage.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DataMessage.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DataMessage clone() => DataMessage()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DataMessage copyWith(void Function(DataMessage) updates) =>
      super.copyWith((message) => updates(message as DataMessage))
          as DataMessage; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DataMessage create() => DataMessage._();
  DataMessage createEmptyInstance() => create();
  static $pb.PbList<DataMessage> createRepeated() => $pb.PbList<DataMessage>();
  @$core.pragma('dart2js:noInline')
  static DataMessage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DataMessage>(create);
  static DataMessage? _defaultInstance;

  DataMessage_Value whichValue() => _DataMessage_ValueByTag[$_whichOneof(0)]!;
  void clearValue() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get binary => $_getN(1);
  @$pb.TagNumber(2)
  set binary($core.List<$core.int> v) {
    $_setBytes(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasBinary() => $_has(1);
  @$pb.TagNumber(2)
  void clearBinary() => clearField(2);
}

class RecordingInput extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RecordingInput',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'url')
    ..aOM<RecordingTemplate>(
        2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'template',
        subBuilder: RecordingTemplate.create)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'width',
        $pb.PbFieldType.O3)
    ..a<$core.int>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'height',
        $pb.PbFieldType.O3)
    ..a<$core.int>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'depth',
        $pb.PbFieldType.O3)
    ..a<$core.int>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'framerate', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  RecordingInput._() : super();
  factory RecordingInput({
    $core.String? url,
    RecordingTemplate? template,
    $core.int? width,
    $core.int? height,
    $core.int? depth,
    $core.int? framerate,
  }) {
    final _result = create();
    if (url != null) {
      _result.url = url;
    }
    if (template != null) {
      _result.template = template;
    }
    if (width != null) {
      _result.width = width;
    }
    if (height != null) {
      _result.height = height;
    }
    if (depth != null) {
      _result.depth = depth;
    }
    if (framerate != null) {
      _result.framerate = framerate;
    }
    return _result;
  }
  factory RecordingInput.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RecordingInput.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RecordingInput clone() => RecordingInput()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RecordingInput copyWith(void Function(RecordingInput) updates) =>
      super.copyWith((message) => updates(message as RecordingInput))
          as RecordingInput; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RecordingInput create() => RecordingInput._();
  RecordingInput createEmptyInstance() => create();
  static $pb.PbList<RecordingInput> createRepeated() => $pb.PbList<RecordingInput>();
  @$core.pragma('dart2js:noInline')
  static RecordingInput getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RecordingInput>(create);
  static RecordingInput? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get url => $_getSZ(0);
  @$pb.TagNumber(1)
  set url($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearUrl() => clearField(1);

  @$pb.TagNumber(2)
  RecordingTemplate get template => $_getN(1);
  @$pb.TagNumber(2)
  set template(RecordingTemplate v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTemplate() => $_has(1);
  @$pb.TagNumber(2)
  void clearTemplate() => clearField(2);
  @$pb.TagNumber(2)
  RecordingTemplate ensureTemplate() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.int get width => $_getIZ(2);
  @$pb.TagNumber(3)
  set width($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasWidth() => $_has(2);
  @$pb.TagNumber(3)
  void clearWidth() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get height => $_getIZ(3);
  @$pb.TagNumber(4)
  set height($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasHeight() => $_has(3);
  @$pb.TagNumber(4)
  void clearHeight() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get depth => $_getIZ(4);
  @$pb.TagNumber(5)
  set depth($core.int v) {
    $_setSignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasDepth() => $_has(4);
  @$pb.TagNumber(5)
  void clearDepth() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get framerate => $_getIZ(5);
  @$pb.TagNumber(6)
  set framerate($core.int v) {
    $_setSignedInt32(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasFramerate() => $_has(5);
  @$pb.TagNumber(6)
  void clearFramerate() => clearField(6);
}

class RecordingTemplate extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RecordingTemplate',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'wsUrl')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'token')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'roomName')
    ..hasRequiredFields = false;

  RecordingTemplate._() : super();
  factory RecordingTemplate({
    $core.String? type,
    $core.String? wsUrl,
    $core.String? token,
    $core.String? roomName,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (wsUrl != null) {
      _result.wsUrl = wsUrl;
    }
    if (token != null) {
      _result.token = token;
    }
    if (roomName != null) {
      _result.roomName = roomName;
    }
    return _result;
  }
  factory RecordingTemplate.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RecordingTemplate.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RecordingTemplate clone() => RecordingTemplate()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RecordingTemplate copyWith(void Function(RecordingTemplate) updates) =>
      super.copyWith((message) => updates(message as RecordingTemplate))
          as RecordingTemplate; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RecordingTemplate create() => RecordingTemplate._();
  RecordingTemplate createEmptyInstance() => create();
  static $pb.PbList<RecordingTemplate> createRepeated() => $pb.PbList<RecordingTemplate>();
  @$core.pragma('dart2js:noInline')
  static RecordingTemplate getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RecordingTemplate>(create);
  static RecordingTemplate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get wsUrl => $_getSZ(1);
  @$pb.TagNumber(2)
  set wsUrl($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasWsUrl() => $_has(1);
  @$pb.TagNumber(2)
  void clearWsUrl() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get token => $_getSZ(2);
  @$pb.TagNumber(3)
  set token($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearToken() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get roomName => $_getSZ(3);
  @$pb.TagNumber(4)
  set roomName($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasRoomName() => $_has(3);
  @$pb.TagNumber(4)
  void clearRoomName() => clearField(4);
}

class RecordingOutput extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RecordingOutput',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'file')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rtmp')
    ..aOM<RecordingS3Output>(
        3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 's3',
        subBuilder: RecordingS3Output.create)
    ..a<$core.int>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'width',
        $pb.PbFieldType.O3)
    ..a<$core.int>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'height',
        $pb.PbFieldType.O3)
    ..aOS(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'audioBitrate')
    ..aOS(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'audioFrequency')
    ..aOS(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'videoBitrate')
    ..aOS(9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'videoBuffer')
    ..hasRequiredFields = false;

  RecordingOutput._() : super();
  factory RecordingOutput({
    $core.String? file,
    $core.String? rtmp,
    RecordingS3Output? s3,
    $core.int? width,
    $core.int? height,
    $core.String? audioBitrate,
    $core.String? audioFrequency,
    $core.String? videoBitrate,
    $core.String? videoBuffer,
  }) {
    final _result = create();
    if (file != null) {
      _result.file = file;
    }
    if (rtmp != null) {
      _result.rtmp = rtmp;
    }
    if (s3 != null) {
      _result.s3 = s3;
    }
    if (width != null) {
      _result.width = width;
    }
    if (height != null) {
      _result.height = height;
    }
    if (audioBitrate != null) {
      _result.audioBitrate = audioBitrate;
    }
    if (audioFrequency != null) {
      _result.audioFrequency = audioFrequency;
    }
    if (videoBitrate != null) {
      _result.videoBitrate = videoBitrate;
    }
    if (videoBuffer != null) {
      _result.videoBuffer = videoBuffer;
    }
    return _result;
  }
  factory RecordingOutput.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RecordingOutput.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RecordingOutput clone() => RecordingOutput()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RecordingOutput copyWith(void Function(RecordingOutput) updates) =>
      super.copyWith((message) => updates(message as RecordingOutput))
          as RecordingOutput; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RecordingOutput create() => RecordingOutput._();
  RecordingOutput createEmptyInstance() => create();
  static $pb.PbList<RecordingOutput> createRepeated() => $pb.PbList<RecordingOutput>();
  @$core.pragma('dart2js:noInline')
  static RecordingOutput getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RecordingOutput>(create);
  static RecordingOutput? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get file => $_getSZ(0);
  @$pb.TagNumber(1)
  set file($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasFile() => $_has(0);
  @$pb.TagNumber(1)
  void clearFile() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get rtmp => $_getSZ(1);
  @$pb.TagNumber(2)
  set rtmp($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasRtmp() => $_has(1);
  @$pb.TagNumber(2)
  void clearRtmp() => clearField(2);

  @$pb.TagNumber(3)
  RecordingS3Output get s3 => $_getN(2);
  @$pb.TagNumber(3)
  set s3(RecordingS3Output v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasS3() => $_has(2);
  @$pb.TagNumber(3)
  void clearS3() => clearField(3);
  @$pb.TagNumber(3)
  RecordingS3Output ensureS3() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.int get width => $_getIZ(3);
  @$pb.TagNumber(4)
  set width($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasWidth() => $_has(3);
  @$pb.TagNumber(4)
  void clearWidth() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get height => $_getIZ(4);
  @$pb.TagNumber(5)
  set height($core.int v) {
    $_setSignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasHeight() => $_has(4);
  @$pb.TagNumber(5)
  void clearHeight() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get audioBitrate => $_getSZ(5);
  @$pb.TagNumber(6)
  set audioBitrate($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasAudioBitrate() => $_has(5);
  @$pb.TagNumber(6)
  void clearAudioBitrate() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get audioFrequency => $_getSZ(6);
  @$pb.TagNumber(7)
  set audioFrequency($core.String v) {
    $_setString(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasAudioFrequency() => $_has(6);
  @$pb.TagNumber(7)
  void clearAudioFrequency() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get videoBitrate => $_getSZ(7);
  @$pb.TagNumber(8)
  set videoBitrate($core.String v) {
    $_setString(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasVideoBitrate() => $_has(7);
  @$pb.TagNumber(8)
  void clearVideoBitrate() => clearField(8);

  @$pb.TagNumber(9)
  $core.String get videoBuffer => $_getSZ(8);
  @$pb.TagNumber(9)
  set videoBuffer($core.String v) {
    $_setString(8, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasVideoBuffer() => $_has(8);
  @$pb.TagNumber(9)
  void clearVideoBuffer() => clearField(9);
}

class RecordingS3Output extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RecordingS3Output',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'bucket')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'key')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'accessKey')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'secret')
    ..hasRequiredFields = false;

  RecordingS3Output._() : super();
  factory RecordingS3Output({
    $core.String? bucket,
    $core.String? key,
    $core.String? accessKey,
    $core.String? secret,
  }) {
    final _result = create();
    if (bucket != null) {
      _result.bucket = bucket;
    }
    if (key != null) {
      _result.key = key;
    }
    if (accessKey != null) {
      _result.accessKey = accessKey;
    }
    if (secret != null) {
      _result.secret = secret;
    }
    return _result;
  }
  factory RecordingS3Output.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RecordingS3Output.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RecordingS3Output clone() => RecordingS3Output()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RecordingS3Output copyWith(void Function(RecordingS3Output) updates) =>
      super.copyWith((message) => updates(message as RecordingS3Output))
          as RecordingS3Output; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RecordingS3Output create() => RecordingS3Output._();
  RecordingS3Output createEmptyInstance() => create();
  static $pb.PbList<RecordingS3Output> createRepeated() => $pb.PbList<RecordingS3Output>();
  @$core.pragma('dart2js:noInline')
  static RecordingS3Output getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RecordingS3Output>(create);
  static RecordingS3Output? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get bucket => $_getSZ(0);
  @$pb.TagNumber(1)
  set bucket($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasBucket() => $_has(0);
  @$pb.TagNumber(1)
  void clearBucket() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get key => $_getSZ(1);
  @$pb.TagNumber(2)
  set key($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearKey() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get accessKey => $_getSZ(2);
  @$pb.TagNumber(3)
  set accessKey($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasAccessKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearAccessKey() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get secret => $_getSZ(3);
  @$pb.TagNumber(4)
  set secret($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasSecret() => $_has(3);
  @$pb.TagNumber(4)
  void clearSecret() => clearField(4);
}
