///
//  Generated code. Do not modify.
//  source: livekit_models.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'google/protobuf/timestamp.pb.dart' as $0;

import 'livekit_models.pbenum.dart';

export 'livekit_models.pbenum.dart';

class Room extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'Room',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'sid')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'name')
    ..a<$core.int>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'emptyTimeout',
        $pb.PbFieldType.OU3)
    ..a<$core.int>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'maxParticipants',
        $pb.PbFieldType.OU3)
    ..aInt64(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'creationTime')
    ..aOS(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'turnPassword')
    ..pc<Codec>(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'enabledCodecs',
        $pb.PbFieldType.PM,
        subBuilder: Codec.create)
    ..aOS(
        8,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'metadata')
    ..a<$core.int>(
        9,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'numParticipants',
        $pb.PbFieldType.OU3)
    ..aOB(
        10,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'activeRecording')
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
    $core.String? metadata,
    $core.int? numParticipants,
    $core.bool? activeRecording,
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
    if (metadata != null) {
      _result.metadata = metadata;
    }
    if (numParticipants != null) {
      _result.numParticipants = numParticipants;
    }
    if (activeRecording != null) {
      _result.activeRecording = activeRecording;
    }
    return _result;
  }
  factory Room.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Room.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
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
  static Room getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Room>(create);
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

  @$pb.TagNumber(8)
  $core.String get metadata => $_getSZ(7);
  @$pb.TagNumber(8)
  set metadata($core.String v) {
    $_setString(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasMetadata() => $_has(7);
  @$pb.TagNumber(8)
  void clearMetadata() => clearField(8);

  @$pb.TagNumber(9)
  $core.int get numParticipants => $_getIZ(8);
  @$pb.TagNumber(9)
  set numParticipants($core.int v) {
    $_setUnsignedInt32(8, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasNumParticipants() => $_has(8);
  @$pb.TagNumber(9)
  void clearNumParticipants() => clearField(9);

  @$pb.TagNumber(10)
  $core.bool get activeRecording => $_getBF(9);
  @$pb.TagNumber(10)
  set activeRecording($core.bool v) {
    $_setBool(9, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasActiveRecording() => $_has(9);
  @$pb.TagNumber(10)
  void clearActiveRecording() => clearField(10);
}

class Codec extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'Codec',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'mime')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'fmtpLine')
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
  factory Codec.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
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

class ParticipantPermission extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ParticipantPermission',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOB(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'canSubscribe')
    ..aOB(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'canPublish')
    ..aOB(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'canPublishData')
    ..aOB(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'hidden')
    ..aOB(
        8,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'recorder')
    ..hasRequiredFields = false;

  ParticipantPermission._() : super();
  factory ParticipantPermission({
    $core.bool? canSubscribe,
    $core.bool? canPublish,
    $core.bool? canPublishData,
    $core.bool? hidden,
    $core.bool? recorder,
  }) {
    final _result = create();
    if (canSubscribe != null) {
      _result.canSubscribe = canSubscribe;
    }
    if (canPublish != null) {
      _result.canPublish = canPublish;
    }
    if (canPublishData != null) {
      _result.canPublishData = canPublishData;
    }
    if (hidden != null) {
      _result.hidden = hidden;
    }
    if (recorder != null) {
      _result.recorder = recorder;
    }
    return _result;
  }
  factory ParticipantPermission.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ParticipantPermission.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ParticipantPermission clone() =>
      ParticipantPermission()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ParticipantPermission copyWith(
          void Function(ParticipantPermission) updates) =>
      super.copyWith((message) => updates(message as ParticipantPermission))
          as ParticipantPermission; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ParticipantPermission create() => ParticipantPermission._();
  ParticipantPermission createEmptyInstance() => create();
  static $pb.PbList<ParticipantPermission> createRepeated() =>
      $pb.PbList<ParticipantPermission>();
  @$core.pragma('dart2js:noInline')
  static ParticipantPermission getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ParticipantPermission>(create);
  static ParticipantPermission? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get canSubscribe => $_getBF(0);
  @$pb.TagNumber(1)
  set canSubscribe($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCanSubscribe() => $_has(0);
  @$pb.TagNumber(1)
  void clearCanSubscribe() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get canPublish => $_getBF(1);
  @$pb.TagNumber(2)
  set canPublish($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasCanPublish() => $_has(1);
  @$pb.TagNumber(2)
  void clearCanPublish() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get canPublishData => $_getBF(2);
  @$pb.TagNumber(3)
  set canPublishData($core.bool v) {
    $_setBool(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasCanPublishData() => $_has(2);
  @$pb.TagNumber(3)
  void clearCanPublishData() => clearField(3);

  @$pb.TagNumber(7)
  $core.bool get hidden => $_getBF(3);
  @$pb.TagNumber(7)
  set hidden($core.bool v) {
    $_setBool(3, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasHidden() => $_has(3);
  @$pb.TagNumber(7)
  void clearHidden() => clearField(7);

  @$pb.TagNumber(8)
  $core.bool get recorder => $_getBF(4);
  @$pb.TagNumber(8)
  set recorder($core.bool v) {
    $_setBool(4, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasRecorder() => $_has(4);
  @$pb.TagNumber(8)
  void clearRecorder() => clearField(8);
}

class ParticipantInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ParticipantInfo',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'sid')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'identity')
    ..e<ParticipantInfo_State>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'state',
        $pb.PbFieldType.OE,
        defaultOrMaker: ParticipantInfo_State.JOINING,
        valueOf: ParticipantInfo_State.valueOf,
        enumValues: ParticipantInfo_State.values)
    ..pc<TrackInfo>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'tracks',
        $pb.PbFieldType.PM,
        subBuilder: TrackInfo.create)
    ..aOS(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'metadata')
    ..aInt64(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'joinedAt')
    ..aOS(
        9,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'name')
    ..a<$core.int>(
        10,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'version',
        $pb.PbFieldType.OU3)
    ..aOM<ParticipantPermission>(
        11,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'permission',
        subBuilder: ParticipantPermission.create)
    ..aOS(
        12,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'region')
    ..hasRequiredFields = false;

  ParticipantInfo._() : super();
  factory ParticipantInfo({
    $core.String? sid,
    $core.String? identity,
    ParticipantInfo_State? state,
    $core.Iterable<TrackInfo>? tracks,
    $core.String? metadata,
    $fixnum.Int64? joinedAt,
    $core.String? name,
    $core.int? version,
    ParticipantPermission? permission,
    $core.String? region,
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
    if (name != null) {
      _result.name = name;
    }
    if (version != null) {
      _result.version = version;
    }
    if (permission != null) {
      _result.permission = permission;
    }
    if (region != null) {
      _result.region = region;
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
  static $pb.PbList<ParticipantInfo> createRepeated() =>
      $pb.PbList<ParticipantInfo>();
  @$core.pragma('dart2js:noInline')
  static ParticipantInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ParticipantInfo>(create);
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

  @$pb.TagNumber(9)
  $core.String get name => $_getSZ(6);
  @$pb.TagNumber(9)
  set name($core.String v) {
    $_setString(6, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasName() => $_has(6);
  @$pb.TagNumber(9)
  void clearName() => clearField(9);

  @$pb.TagNumber(10)
  $core.int get version => $_getIZ(7);
  @$pb.TagNumber(10)
  set version($core.int v) {
    $_setUnsignedInt32(7, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasVersion() => $_has(7);
  @$pb.TagNumber(10)
  void clearVersion() => clearField(10);

  @$pb.TagNumber(11)
  ParticipantPermission get permission => $_getN(8);
  @$pb.TagNumber(11)
  set permission(ParticipantPermission v) {
    setField(11, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasPermission() => $_has(8);
  @$pb.TagNumber(11)
  void clearPermission() => clearField(11);
  @$pb.TagNumber(11)
  ParticipantPermission ensurePermission() => $_ensure(8);

  @$pb.TagNumber(12)
  $core.String get region => $_getSZ(9);
  @$pb.TagNumber(12)
  set region($core.String v) {
    $_setString(9, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasRegion() => $_has(9);
  @$pb.TagNumber(12)
  void clearRegion() => clearField(12);
}

class TrackInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'TrackInfo',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'sid')
    ..e<TrackType>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type',
        $pb.PbFieldType.OE,
        defaultOrMaker: TrackType.AUDIO,
        valueOf: TrackType.valueOf,
        enumValues: TrackType.values)
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'name')
    ..aOB(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'muted')
    ..a<$core.int>(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'width',
        $pb.PbFieldType.OU3)
    ..a<$core.int>(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'height',
        $pb.PbFieldType.OU3)
    ..aOB(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'simulcast')
    ..aOB(
        8,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'disableDtx')
    ..e<TrackSource>(
        9,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'source',
        $pb.PbFieldType.OE,
        defaultOrMaker: TrackSource.UNKNOWN,
        valueOf: TrackSource.valueOf,
        enumValues: TrackSource.values)
    ..pc<VideoLayer>(
        10,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'layers',
        $pb.PbFieldType.PM,
        subBuilder: VideoLayer.create)
    ..aOS(
        11,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'mimeType')
    ..aOS(
        12,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'mid')
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
    $core.bool? disableDtx,
    TrackSource? source,
    $core.Iterable<VideoLayer>? layers,
    $core.String? mimeType,
    $core.String? mid,
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
    if (disableDtx != null) {
      _result.disableDtx = disableDtx;
    }
    if (source != null) {
      _result.source = source;
    }
    if (layers != null) {
      _result.layers.addAll(layers);
    }
    if (mimeType != null) {
      _result.mimeType = mimeType;
    }
    if (mid != null) {
      _result.mid = mid;
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

  @$pb.TagNumber(8)
  $core.bool get disableDtx => $_getBF(7);
  @$pb.TagNumber(8)
  set disableDtx($core.bool v) {
    $_setBool(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasDisableDtx() => $_has(7);
  @$pb.TagNumber(8)
  void clearDisableDtx() => clearField(8);

  @$pb.TagNumber(9)
  TrackSource get source => $_getN(8);
  @$pb.TagNumber(9)
  set source(TrackSource v) {
    setField(9, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasSource() => $_has(8);
  @$pb.TagNumber(9)
  void clearSource() => clearField(9);

  @$pb.TagNumber(10)
  $core.List<VideoLayer> get layers => $_getList(9);

  @$pb.TagNumber(11)
  $core.String get mimeType => $_getSZ(10);
  @$pb.TagNumber(11)
  set mimeType($core.String v) {
    $_setString(10, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasMimeType() => $_has(10);
  @$pb.TagNumber(11)
  void clearMimeType() => clearField(11);

  @$pb.TagNumber(12)
  $core.String get mid => $_getSZ(11);
  @$pb.TagNumber(12)
  set mid($core.String v) {
    $_setString(11, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasMid() => $_has(11);
  @$pb.TagNumber(12)
  void clearMid() => clearField(12);
}

class VideoLayer extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'VideoLayer',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..e<VideoQuality>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'quality',
        $pb.PbFieldType.OE,
        defaultOrMaker: VideoQuality.LOW,
        valueOf: VideoQuality.valueOf,
        enumValues: VideoQuality.values)
    ..a<$core.int>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'width',
        $pb.PbFieldType.OU3)
    ..a<$core.int>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'height',
        $pb.PbFieldType.OU3)
    ..a<$core.int>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'bitrate',
        $pb.PbFieldType.OU3)
    ..a<$core.int>(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'ssrc',
        $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  VideoLayer._() : super();
  factory VideoLayer({
    VideoQuality? quality,
    $core.int? width,
    $core.int? height,
    $core.int? bitrate,
    $core.int? ssrc,
  }) {
    final _result = create();
    if (quality != null) {
      _result.quality = quality;
    }
    if (width != null) {
      _result.width = width;
    }
    if (height != null) {
      _result.height = height;
    }
    if (bitrate != null) {
      _result.bitrate = bitrate;
    }
    if (ssrc != null) {
      _result.ssrc = ssrc;
    }
    return _result;
  }
  factory VideoLayer.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory VideoLayer.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  VideoLayer clone() => VideoLayer()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  VideoLayer copyWith(void Function(VideoLayer) updates) =>
      super.copyWith((message) => updates(message as VideoLayer))
          as VideoLayer; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static VideoLayer create() => VideoLayer._();
  VideoLayer createEmptyInstance() => create();
  static $pb.PbList<VideoLayer> createRepeated() => $pb.PbList<VideoLayer>();
  @$core.pragma('dart2js:noInline')
  static VideoLayer getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VideoLayer>(create);
  static VideoLayer? _defaultInstance;

  @$pb.TagNumber(1)
  VideoQuality get quality => $_getN(0);
  @$pb.TagNumber(1)
  set quality(VideoQuality v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasQuality() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuality() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get width => $_getIZ(1);
  @$pb.TagNumber(2)
  set width($core.int v) {
    $_setUnsignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasWidth() => $_has(1);
  @$pb.TagNumber(2)
  void clearWidth() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get height => $_getIZ(2);
  @$pb.TagNumber(3)
  set height($core.int v) {
    $_setUnsignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasHeight() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeight() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get bitrate => $_getIZ(3);
  @$pb.TagNumber(4)
  set bitrate($core.int v) {
    $_setUnsignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasBitrate() => $_has(3);
  @$pb.TagNumber(4)
  void clearBitrate() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get ssrc => $_getIZ(4);
  @$pb.TagNumber(5)
  set ssrc($core.int v) {
    $_setUnsignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasSsrc() => $_has(4);
  @$pb.TagNumber(5)
  void clearSsrc() => clearField(5);
}

enum DataPacket_Value { user, speaker, notSet }

class DataPacket extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, DataPacket_Value> _DataPacket_ValueByTag = {
    2: DataPacket_Value.user,
    3: DataPacket_Value.speaker,
    0: DataPacket_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'DataPacket',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..oo(0, [2, 3])
    ..e<DataPacket_Kind>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'kind',
        $pb.PbFieldType.OE,
        defaultOrMaker: DataPacket_Kind.RELIABLE,
        valueOf: DataPacket_Kind.valueOf,
        enumValues: DataPacket_Kind.values)
    ..aOM<UserPacket>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'user',
        subBuilder: UserPacket.create)
    ..aOM<ActiveSpeakerUpdate>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'speaker',
        subBuilder: ActiveSpeakerUpdate.create)
    ..hasRequiredFields = false;

  DataPacket._() : super();
  factory DataPacket({
    DataPacket_Kind? kind,
    UserPacket? user,
    ActiveSpeakerUpdate? speaker,
  }) {
    final _result = create();
    if (kind != null) {
      _result.kind = kind;
    }
    if (user != null) {
      _result.user = user;
    }
    if (speaker != null) {
      _result.speaker = speaker;
    }
    return _result;
  }
  factory DataPacket.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DataPacket.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DataPacket clone() => DataPacket()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DataPacket copyWith(void Function(DataPacket) updates) =>
      super.copyWith((message) => updates(message as DataPacket))
          as DataPacket; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DataPacket create() => DataPacket._();
  DataPacket createEmptyInstance() => create();
  static $pb.PbList<DataPacket> createRepeated() => $pb.PbList<DataPacket>();
  @$core.pragma('dart2js:noInline')
  static DataPacket getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DataPacket>(create);
  static DataPacket? _defaultInstance;

  DataPacket_Value whichValue() => _DataPacket_ValueByTag[$_whichOneof(0)]!;
  void clearValue() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  DataPacket_Kind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(DataPacket_Kind v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => clearField(1);

  @$pb.TagNumber(2)
  UserPacket get user => $_getN(1);
  @$pb.TagNumber(2)
  set user(UserPacket v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasUser() => $_has(1);
  @$pb.TagNumber(2)
  void clearUser() => clearField(2);
  @$pb.TagNumber(2)
  UserPacket ensureUser() => $_ensure(1);

  @$pb.TagNumber(3)
  ActiveSpeakerUpdate get speaker => $_getN(2);
  @$pb.TagNumber(3)
  set speaker(ActiveSpeakerUpdate v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasSpeaker() => $_has(2);
  @$pb.TagNumber(3)
  void clearSpeaker() => clearField(3);
  @$pb.TagNumber(3)
  ActiveSpeakerUpdate ensureSpeaker() => $_ensure(2);
}

class ActiveSpeakerUpdate extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ActiveSpeakerUpdate',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..pc<SpeakerInfo>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'speakers',
        $pb.PbFieldType.PM,
        subBuilder: SpeakerInfo.create)
    ..hasRequiredFields = false;

  ActiveSpeakerUpdate._() : super();
  factory ActiveSpeakerUpdate({
    $core.Iterable<SpeakerInfo>? speakers,
  }) {
    final _result = create();
    if (speakers != null) {
      _result.speakers.addAll(speakers);
    }
    return _result;
  }
  factory ActiveSpeakerUpdate.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ActiveSpeakerUpdate.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ActiveSpeakerUpdate clone() => ActiveSpeakerUpdate()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ActiveSpeakerUpdate copyWith(void Function(ActiveSpeakerUpdate) updates) =>
      super.copyWith((message) => updates(message as ActiveSpeakerUpdate))
          as ActiveSpeakerUpdate; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ActiveSpeakerUpdate create() => ActiveSpeakerUpdate._();
  ActiveSpeakerUpdate createEmptyInstance() => create();
  static $pb.PbList<ActiveSpeakerUpdate> createRepeated() =>
      $pb.PbList<ActiveSpeakerUpdate>();
  @$core.pragma('dart2js:noInline')
  static ActiveSpeakerUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ActiveSpeakerUpdate>(create);
  static ActiveSpeakerUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SpeakerInfo> get speakers => $_getList(0);
}

class SpeakerInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SpeakerInfo',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'sid')
    ..a<$core.double>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'level',
        $pb.PbFieldType.OF)
    ..aOB(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'active')
    ..hasRequiredFields = false;

  SpeakerInfo._() : super();
  factory SpeakerInfo({
    $core.String? sid,
    $core.double? level,
    $core.bool? active,
  }) {
    final _result = create();
    if (sid != null) {
      _result.sid = sid;
    }
    if (level != null) {
      _result.level = level;
    }
    if (active != null) {
      _result.active = active;
    }
    return _result;
  }
  factory SpeakerInfo.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SpeakerInfo.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SpeakerInfo clone() => SpeakerInfo()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SpeakerInfo copyWith(void Function(SpeakerInfo) updates) =>
      super.copyWith((message) => updates(message as SpeakerInfo))
          as SpeakerInfo; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SpeakerInfo create() => SpeakerInfo._();
  SpeakerInfo createEmptyInstance() => create();
  static $pb.PbList<SpeakerInfo> createRepeated() => $pb.PbList<SpeakerInfo>();
  @$core.pragma('dart2js:noInline')
  static SpeakerInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SpeakerInfo>(create);
  static SpeakerInfo? _defaultInstance;

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
  $core.double get level => $_getN(1);
  @$pb.TagNumber(2)
  set level($core.double v) {
    $_setFloat(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasLevel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLevel() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get active => $_getBF(2);
  @$pb.TagNumber(3)
  set active($core.bool v) {
    $_setBool(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasActive() => $_has(2);
  @$pb.TagNumber(3)
  void clearActive() => clearField(3);
}

class UserPacket extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'UserPacket',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'participantSid')
    ..a<$core.List<$core.int>>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'payload',
        $pb.PbFieldType.OY)
    ..pPS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'destinationSids')
    ..hasRequiredFields = false;

  UserPacket._() : super();
  factory UserPacket({
    $core.String? participantSid,
    $core.List<$core.int>? payload,
    $core.Iterable<$core.String>? destinationSids,
  }) {
    final _result = create();
    if (participantSid != null) {
      _result.participantSid = participantSid;
    }
    if (payload != null) {
      _result.payload = payload;
    }
    if (destinationSids != null) {
      _result.destinationSids.addAll(destinationSids);
    }
    return _result;
  }
  factory UserPacket.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory UserPacket.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  UserPacket clone() => UserPacket()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  UserPacket copyWith(void Function(UserPacket) updates) =>
      super.copyWith((message) => updates(message as UserPacket))
          as UserPacket; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UserPacket create() => UserPacket._();
  UserPacket createEmptyInstance() => create();
  static $pb.PbList<UserPacket> createRepeated() => $pb.PbList<UserPacket>();
  @$core.pragma('dart2js:noInline')
  static UserPacket getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UserPacket>(create);
  static UserPacket? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get participantSid => $_getSZ(0);
  @$pb.TagNumber(1)
  set participantSid($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasParticipantSid() => $_has(0);
  @$pb.TagNumber(1)
  void clearParticipantSid() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get payload => $_getN(1);
  @$pb.TagNumber(2)
  set payload($core.List<$core.int> v) {
    $_setBytes(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPayload() => $_has(1);
  @$pb.TagNumber(2)
  void clearPayload() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.String> get destinationSids => $_getList(2);
}

class ParticipantTracks extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ParticipantTracks',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'participantSid')
    ..pPS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'trackSids')
    ..hasRequiredFields = false;

  ParticipantTracks._() : super();
  factory ParticipantTracks({
    $core.String? participantSid,
    $core.Iterable<$core.String>? trackSids,
  }) {
    final _result = create();
    if (participantSid != null) {
      _result.participantSid = participantSid;
    }
    if (trackSids != null) {
      _result.trackSids.addAll(trackSids);
    }
    return _result;
  }
  factory ParticipantTracks.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ParticipantTracks.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ParticipantTracks clone() => ParticipantTracks()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ParticipantTracks copyWith(void Function(ParticipantTracks) updates) =>
      super.copyWith((message) => updates(message as ParticipantTracks))
          as ParticipantTracks; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ParticipantTracks create() => ParticipantTracks._();
  ParticipantTracks createEmptyInstance() => create();
  static $pb.PbList<ParticipantTracks> createRepeated() =>
      $pb.PbList<ParticipantTracks>();
  @$core.pragma('dart2js:noInline')
  static ParticipantTracks getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ParticipantTracks>(create);
  static ParticipantTracks? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get participantSid => $_getSZ(0);
  @$pb.TagNumber(1)
  set participantSid($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasParticipantSid() => $_has(0);
  @$pb.TagNumber(1)
  void clearParticipantSid() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.String> get trackSids => $_getList(1);
}

class ClientInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ClientInfo',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..e<ClientInfo_SDK>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'sdk',
        $pb.PbFieldType.OE,
        defaultOrMaker: ClientInfo_SDK.UNKNOWN,
        valueOf: ClientInfo_SDK.valueOf,
        enumValues: ClientInfo_SDK.values)
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'version')
    ..a<$core.int>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'protocol',
        $pb.PbFieldType.O3)
    ..aOS(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'os')
    ..aOS(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'osVersion')
    ..aOS(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'deviceModel')
    ..aOS(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'browser')
    ..aOS(
        8,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'browserVersion')
    ..aOS(
        9,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'address')
    ..hasRequiredFields = false;

  ClientInfo._() : super();
  factory ClientInfo({
    ClientInfo_SDK? sdk,
    $core.String? version,
    $core.int? protocol,
    $core.String? os,
    $core.String? osVersion,
    $core.String? deviceModel,
    $core.String? browser,
    $core.String? browserVersion,
    $core.String? address,
  }) {
    final _result = create();
    if (sdk != null) {
      _result.sdk = sdk;
    }
    if (version != null) {
      _result.version = version;
    }
    if (protocol != null) {
      _result.protocol = protocol;
    }
    if (os != null) {
      _result.os = os;
    }
    if (osVersion != null) {
      _result.osVersion = osVersion;
    }
    if (deviceModel != null) {
      _result.deviceModel = deviceModel;
    }
    if (browser != null) {
      _result.browser = browser;
    }
    if (browserVersion != null) {
      _result.browserVersion = browserVersion;
    }
    if (address != null) {
      _result.address = address;
    }
    return _result;
  }
  factory ClientInfo.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ClientInfo.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ClientInfo clone() => ClientInfo()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ClientInfo copyWith(void Function(ClientInfo) updates) =>
      super.copyWith((message) => updates(message as ClientInfo))
          as ClientInfo; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ClientInfo create() => ClientInfo._();
  ClientInfo createEmptyInstance() => create();
  static $pb.PbList<ClientInfo> createRepeated() => $pb.PbList<ClientInfo>();
  @$core.pragma('dart2js:noInline')
  static ClientInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClientInfo>(create);
  static ClientInfo? _defaultInstance;

  @$pb.TagNumber(1)
  ClientInfo_SDK get sdk => $_getN(0);
  @$pb.TagNumber(1)
  set sdk(ClientInfo_SDK v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasSdk() => $_has(0);
  @$pb.TagNumber(1)
  void clearSdk() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get protocol => $_getIZ(2);
  @$pb.TagNumber(3)
  set protocol($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasProtocol() => $_has(2);
  @$pb.TagNumber(3)
  void clearProtocol() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get os => $_getSZ(3);
  @$pb.TagNumber(4)
  set os($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasOs() => $_has(3);
  @$pb.TagNumber(4)
  void clearOs() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get osVersion => $_getSZ(4);
  @$pb.TagNumber(5)
  set osVersion($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasOsVersion() => $_has(4);
  @$pb.TagNumber(5)
  void clearOsVersion() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get deviceModel => $_getSZ(5);
  @$pb.TagNumber(6)
  set deviceModel($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasDeviceModel() => $_has(5);
  @$pb.TagNumber(6)
  void clearDeviceModel() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get browser => $_getSZ(6);
  @$pb.TagNumber(7)
  set browser($core.String v) {
    $_setString(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasBrowser() => $_has(6);
  @$pb.TagNumber(7)
  void clearBrowser() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get browserVersion => $_getSZ(7);
  @$pb.TagNumber(8)
  set browserVersion($core.String v) {
    $_setString(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasBrowserVersion() => $_has(7);
  @$pb.TagNumber(8)
  void clearBrowserVersion() => clearField(8);

  @$pb.TagNumber(9)
  $core.String get address => $_getSZ(8);
  @$pb.TagNumber(9)
  set address($core.String v) {
    $_setString(8, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasAddress() => $_has(8);
  @$pb.TagNumber(9)
  void clearAddress() => clearField(9);
}

class ClientConfiguration extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ClientConfiguration',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOM<VideoConfiguration>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'video',
        subBuilder: VideoConfiguration.create)
    ..aOM<VideoConfiguration>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'screen',
        subBuilder: VideoConfiguration.create)
    ..e<ClientConfigSetting>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'resumeConnection',
        $pb.PbFieldType.OE,
        defaultOrMaker: ClientConfigSetting.UNSET,
        valueOf: ClientConfigSetting.valueOf,
        enumValues: ClientConfigSetting.values)
    ..hasRequiredFields = false;

  ClientConfiguration._() : super();
  factory ClientConfiguration({
    VideoConfiguration? video,
    VideoConfiguration? screen,
    ClientConfigSetting? resumeConnection,
  }) {
    final _result = create();
    if (video != null) {
      _result.video = video;
    }
    if (screen != null) {
      _result.screen = screen;
    }
    if (resumeConnection != null) {
      _result.resumeConnection = resumeConnection;
    }
    return _result;
  }
  factory ClientConfiguration.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ClientConfiguration.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ClientConfiguration clone() => ClientConfiguration()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ClientConfiguration copyWith(void Function(ClientConfiguration) updates) =>
      super.copyWith((message) => updates(message as ClientConfiguration))
          as ClientConfiguration; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ClientConfiguration create() => ClientConfiguration._();
  ClientConfiguration createEmptyInstance() => create();
  static $pb.PbList<ClientConfiguration> createRepeated() =>
      $pb.PbList<ClientConfiguration>();
  @$core.pragma('dart2js:noInline')
  static ClientConfiguration getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClientConfiguration>(create);
  static ClientConfiguration? _defaultInstance;

  @$pb.TagNumber(1)
  VideoConfiguration get video => $_getN(0);
  @$pb.TagNumber(1)
  set video(VideoConfiguration v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasVideo() => $_has(0);
  @$pb.TagNumber(1)
  void clearVideo() => clearField(1);
  @$pb.TagNumber(1)
  VideoConfiguration ensureVideo() => $_ensure(0);

  @$pb.TagNumber(2)
  VideoConfiguration get screen => $_getN(1);
  @$pb.TagNumber(2)
  set screen(VideoConfiguration v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasScreen() => $_has(1);
  @$pb.TagNumber(2)
  void clearScreen() => clearField(2);
  @$pb.TagNumber(2)
  VideoConfiguration ensureScreen() => $_ensure(1);

  @$pb.TagNumber(3)
  ClientConfigSetting get resumeConnection => $_getN(2);
  @$pb.TagNumber(3)
  set resumeConnection(ClientConfigSetting v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasResumeConnection() => $_has(2);
  @$pb.TagNumber(3)
  void clearResumeConnection() => clearField(3);
}

class VideoConfiguration extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'VideoConfiguration',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..e<ClientConfigSetting>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'hardwareEncoder',
        $pb.PbFieldType.OE,
        defaultOrMaker: ClientConfigSetting.UNSET,
        valueOf: ClientConfigSetting.valueOf,
        enumValues: ClientConfigSetting.values)
    ..hasRequiredFields = false;

  VideoConfiguration._() : super();
  factory VideoConfiguration({
    ClientConfigSetting? hardwareEncoder,
  }) {
    final _result = create();
    if (hardwareEncoder != null) {
      _result.hardwareEncoder = hardwareEncoder;
    }
    return _result;
  }
  factory VideoConfiguration.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory VideoConfiguration.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  VideoConfiguration clone() => VideoConfiguration()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  VideoConfiguration copyWith(void Function(VideoConfiguration) updates) =>
      super.copyWith((message) => updates(message as VideoConfiguration))
          as VideoConfiguration; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static VideoConfiguration create() => VideoConfiguration._();
  VideoConfiguration createEmptyInstance() => create();
  static $pb.PbList<VideoConfiguration> createRepeated() =>
      $pb.PbList<VideoConfiguration>();
  @$core.pragma('dart2js:noInline')
  static VideoConfiguration getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VideoConfiguration>(create);
  static VideoConfiguration? _defaultInstance;

  @$pb.TagNumber(1)
  ClientConfigSetting get hardwareEncoder => $_getN(0);
  @$pb.TagNumber(1)
  set hardwareEncoder(ClientConfigSetting v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasHardwareEncoder() => $_has(0);
  @$pb.TagNumber(1)
  void clearHardwareEncoder() => clearField(1);
}

class RTPStats extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'RTPStats',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOM<$0.Timestamp>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'startTime',
        subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'endTime',
        subBuilder: $0.Timestamp.create)
    ..a<$core.double>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'duration',
        $pb.PbFieldType.OD)
    ..a<$core.int>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'packets',
        $pb.PbFieldType.OU3)
    ..a<$core.double>(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'packetRate',
        $pb.PbFieldType.OD)
    ..a<$fixnum.Int64>(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'bytes',
        $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.double>(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'bitrate',
        $pb.PbFieldType.OD)
    ..a<$core.int>(
        8,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'packetsLost',
        $pb.PbFieldType.OU3)
    ..a<$core.double>(
        9,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'packetLossRate',
        $pb.PbFieldType.OD)
    ..a<$core.double>(
        10,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'packetLossPercentage',
        $pb.PbFieldType.OF)
    ..a<$core.int>(
        11,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'packetsDuplicate',
        $pb.PbFieldType.OU3)
    ..a<$core.double>(
        12,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'packetDuplicateRate',
        $pb.PbFieldType.OD)
    ..a<$fixnum.Int64>(
        13,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'bytesDuplicate',
        $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.double>(
        14,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'bitrateDuplicate',
        $pb.PbFieldType.OD)
    ..a<$core.int>(
        15,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'packetsPadding',
        $pb.PbFieldType.OU3)
    ..a<$core.double>(
        16,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'packetPaddingRate',
        $pb.PbFieldType.OD)
    ..a<$fixnum.Int64>(
        17,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'bytesPadding',
        $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.double>(
        18,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'bitratePadding',
        $pb.PbFieldType.OD)
    ..a<$core.int>(
        19,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'packetsOutOfOrder',
        $pb.PbFieldType.OU3)
    ..a<$core.int>(
        20,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'frames',
        $pb.PbFieldType.OU3)
    ..a<$core.double>(
        21,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'frameRate',
        $pb.PbFieldType.OD)
    ..a<$core.double>(
        22,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'jitterCurrent',
        $pb.PbFieldType.OD)
    ..a<$core.double>(
        23,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'jitterMax',
        $pb.PbFieldType.OD)
    ..m<$core.int, $core.int>(
        24,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'gapHistogram',
        entryClassName: 'RTPStats.GapHistogramEntry',
        keyFieldType: $pb.PbFieldType.O3,
        valueFieldType: $pb.PbFieldType.OU3,
        packageName: const $pb.PackageName('livekit'))
    ..a<$core.int>(
        25,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'nacks',
        $pb.PbFieldType.OU3)
    ..a<$core.int>(
        26,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'nackMisses',
        $pb.PbFieldType.OU3)
    ..a<$core.int>(
        27,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'plis',
        $pb.PbFieldType.OU3)
    ..aOM<$0.Timestamp>(
        28,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'lastPli',
        subBuilder: $0.Timestamp.create)
    ..a<$core.int>(
        29,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'firs',
        $pb.PbFieldType.OU3)
    ..aOM<$0.Timestamp>(
        30,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'lastFir',
        subBuilder: $0.Timestamp.create)
    ..a<$core.int>(
        31,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'rttCurrent',
        $pb.PbFieldType.OU3)
    ..a<$core.int>(
        32,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'rttMax',
        $pb.PbFieldType.OU3)
    ..a<$core.int>(
        33,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'keyFrames',
        $pb.PbFieldType.OU3)
    ..aOM<$0.Timestamp>(
        34,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'lastKeyFrame',
        subBuilder: $0.Timestamp.create)
    ..a<$core.int>(
        35,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'layerLockPlis',
        $pb.PbFieldType.OU3)
    ..aOM<$0.Timestamp>(
        36,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'lastLayerLockPli',
        subBuilder: $0.Timestamp.create)
    ..hasRequiredFields = false;

  RTPStats._() : super();
  factory RTPStats({
    $0.Timestamp? startTime,
    $0.Timestamp? endTime,
    $core.double? duration,
    $core.int? packets,
    $core.double? packetRate,
    $fixnum.Int64? bytes,
    $core.double? bitrate,
    $core.int? packetsLost,
    $core.double? packetLossRate,
    $core.double? packetLossPercentage,
    $core.int? packetsDuplicate,
    $core.double? packetDuplicateRate,
    $fixnum.Int64? bytesDuplicate,
    $core.double? bitrateDuplicate,
    $core.int? packetsPadding,
    $core.double? packetPaddingRate,
    $fixnum.Int64? bytesPadding,
    $core.double? bitratePadding,
    $core.int? packetsOutOfOrder,
    $core.int? frames,
    $core.double? frameRate,
    $core.double? jitterCurrent,
    $core.double? jitterMax,
    $core.Map<$core.int, $core.int>? gapHistogram,
    $core.int? nacks,
    $core.int? nackMisses,
    $core.int? plis,
    $0.Timestamp? lastPli,
    $core.int? firs,
    $0.Timestamp? lastFir,
    $core.int? rttCurrent,
    $core.int? rttMax,
    $core.int? keyFrames,
    $0.Timestamp? lastKeyFrame,
    $core.int? layerLockPlis,
    $0.Timestamp? lastLayerLockPli,
  }) {
    final _result = create();
    if (startTime != null) {
      _result.startTime = startTime;
    }
    if (endTime != null) {
      _result.endTime = endTime;
    }
    if (duration != null) {
      _result.duration = duration;
    }
    if (packets != null) {
      _result.packets = packets;
    }
    if (packetRate != null) {
      _result.packetRate = packetRate;
    }
    if (bytes != null) {
      _result.bytes = bytes;
    }
    if (bitrate != null) {
      _result.bitrate = bitrate;
    }
    if (packetsLost != null) {
      _result.packetsLost = packetsLost;
    }
    if (packetLossRate != null) {
      _result.packetLossRate = packetLossRate;
    }
    if (packetLossPercentage != null) {
      _result.packetLossPercentage = packetLossPercentage;
    }
    if (packetsDuplicate != null) {
      _result.packetsDuplicate = packetsDuplicate;
    }
    if (packetDuplicateRate != null) {
      _result.packetDuplicateRate = packetDuplicateRate;
    }
    if (bytesDuplicate != null) {
      _result.bytesDuplicate = bytesDuplicate;
    }
    if (bitrateDuplicate != null) {
      _result.bitrateDuplicate = bitrateDuplicate;
    }
    if (packetsPadding != null) {
      _result.packetsPadding = packetsPadding;
    }
    if (packetPaddingRate != null) {
      _result.packetPaddingRate = packetPaddingRate;
    }
    if (bytesPadding != null) {
      _result.bytesPadding = bytesPadding;
    }
    if (bitratePadding != null) {
      _result.bitratePadding = bitratePadding;
    }
    if (packetsOutOfOrder != null) {
      _result.packetsOutOfOrder = packetsOutOfOrder;
    }
    if (frames != null) {
      _result.frames = frames;
    }
    if (frameRate != null) {
      _result.frameRate = frameRate;
    }
    if (jitterCurrent != null) {
      _result.jitterCurrent = jitterCurrent;
    }
    if (jitterMax != null) {
      _result.jitterMax = jitterMax;
    }
    if (gapHistogram != null) {
      _result.gapHistogram.addAll(gapHistogram);
    }
    if (nacks != null) {
      _result.nacks = nacks;
    }
    if (nackMisses != null) {
      _result.nackMisses = nackMisses;
    }
    if (plis != null) {
      _result.plis = plis;
    }
    if (lastPli != null) {
      _result.lastPli = lastPli;
    }
    if (firs != null) {
      _result.firs = firs;
    }
    if (lastFir != null) {
      _result.lastFir = lastFir;
    }
    if (rttCurrent != null) {
      _result.rttCurrent = rttCurrent;
    }
    if (rttMax != null) {
      _result.rttMax = rttMax;
    }
    if (keyFrames != null) {
      _result.keyFrames = keyFrames;
    }
    if (lastKeyFrame != null) {
      _result.lastKeyFrame = lastKeyFrame;
    }
    if (layerLockPlis != null) {
      _result.layerLockPlis = layerLockPlis;
    }
    if (lastLayerLockPli != null) {
      _result.lastLayerLockPli = lastLayerLockPli;
    }
    return _result;
  }
  factory RTPStats.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RTPStats.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RTPStats clone() => RTPStats()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RTPStats copyWith(void Function(RTPStats) updates) =>
      super.copyWith((message) => updates(message as RTPStats))
          as RTPStats; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RTPStats create() => RTPStats._();
  RTPStats createEmptyInstance() => create();
  static $pb.PbList<RTPStats> createRepeated() => $pb.PbList<RTPStats>();
  @$core.pragma('dart2js:noInline')
  static RTPStats getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RTPStats>(create);
  static RTPStats? _defaultInstance;

  @$pb.TagNumber(1)
  $0.Timestamp get startTime => $_getN(0);
  @$pb.TagNumber(1)
  set startTime($0.Timestamp v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasStartTime() => $_has(0);
  @$pb.TagNumber(1)
  void clearStartTime() => clearField(1);
  @$pb.TagNumber(1)
  $0.Timestamp ensureStartTime() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.Timestamp get endTime => $_getN(1);
  @$pb.TagNumber(2)
  set endTime($0.Timestamp v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasEndTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearEndTime() => clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureEndTime() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.double get duration => $_getN(2);
  @$pb.TagNumber(3)
  set duration($core.double v) {
    $_setDouble(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasDuration() => $_has(2);
  @$pb.TagNumber(3)
  void clearDuration() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get packets => $_getIZ(3);
  @$pb.TagNumber(4)
  set packets($core.int v) {
    $_setUnsignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasPackets() => $_has(3);
  @$pb.TagNumber(4)
  void clearPackets() => clearField(4);

  @$pb.TagNumber(5)
  $core.double get packetRate => $_getN(4);
  @$pb.TagNumber(5)
  set packetRate($core.double v) {
    $_setDouble(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasPacketRate() => $_has(4);
  @$pb.TagNumber(5)
  void clearPacketRate() => clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get bytes => $_getI64(5);
  @$pb.TagNumber(6)
  set bytes($fixnum.Int64 v) {
    $_setInt64(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasBytes() => $_has(5);
  @$pb.TagNumber(6)
  void clearBytes() => clearField(6);

  @$pb.TagNumber(7)
  $core.double get bitrate => $_getN(6);
  @$pb.TagNumber(7)
  set bitrate($core.double v) {
    $_setDouble(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasBitrate() => $_has(6);
  @$pb.TagNumber(7)
  void clearBitrate() => clearField(7);

  @$pb.TagNumber(8)
  $core.int get packetsLost => $_getIZ(7);
  @$pb.TagNumber(8)
  set packetsLost($core.int v) {
    $_setUnsignedInt32(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasPacketsLost() => $_has(7);
  @$pb.TagNumber(8)
  void clearPacketsLost() => clearField(8);

  @$pb.TagNumber(9)
  $core.double get packetLossRate => $_getN(8);
  @$pb.TagNumber(9)
  set packetLossRate($core.double v) {
    $_setDouble(8, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasPacketLossRate() => $_has(8);
  @$pb.TagNumber(9)
  void clearPacketLossRate() => clearField(9);

  @$pb.TagNumber(10)
  $core.double get packetLossPercentage => $_getN(9);
  @$pb.TagNumber(10)
  set packetLossPercentage($core.double v) {
    $_setFloat(9, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasPacketLossPercentage() => $_has(9);
  @$pb.TagNumber(10)
  void clearPacketLossPercentage() => clearField(10);

  @$pb.TagNumber(11)
  $core.int get packetsDuplicate => $_getIZ(10);
  @$pb.TagNumber(11)
  set packetsDuplicate($core.int v) {
    $_setUnsignedInt32(10, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasPacketsDuplicate() => $_has(10);
  @$pb.TagNumber(11)
  void clearPacketsDuplicate() => clearField(11);

  @$pb.TagNumber(12)
  $core.double get packetDuplicateRate => $_getN(11);
  @$pb.TagNumber(12)
  set packetDuplicateRate($core.double v) {
    $_setDouble(11, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasPacketDuplicateRate() => $_has(11);
  @$pb.TagNumber(12)
  void clearPacketDuplicateRate() => clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get bytesDuplicate => $_getI64(12);
  @$pb.TagNumber(13)
  set bytesDuplicate($fixnum.Int64 v) {
    $_setInt64(12, v);
  }

  @$pb.TagNumber(13)
  $core.bool hasBytesDuplicate() => $_has(12);
  @$pb.TagNumber(13)
  void clearBytesDuplicate() => clearField(13);

  @$pb.TagNumber(14)
  $core.double get bitrateDuplicate => $_getN(13);
  @$pb.TagNumber(14)
  set bitrateDuplicate($core.double v) {
    $_setDouble(13, v);
  }

  @$pb.TagNumber(14)
  $core.bool hasBitrateDuplicate() => $_has(13);
  @$pb.TagNumber(14)
  void clearBitrateDuplicate() => clearField(14);

  @$pb.TagNumber(15)
  $core.int get packetsPadding => $_getIZ(14);
  @$pb.TagNumber(15)
  set packetsPadding($core.int v) {
    $_setUnsignedInt32(14, v);
  }

  @$pb.TagNumber(15)
  $core.bool hasPacketsPadding() => $_has(14);
  @$pb.TagNumber(15)
  void clearPacketsPadding() => clearField(15);

  @$pb.TagNumber(16)
  $core.double get packetPaddingRate => $_getN(15);
  @$pb.TagNumber(16)
  set packetPaddingRate($core.double v) {
    $_setDouble(15, v);
  }

  @$pb.TagNumber(16)
  $core.bool hasPacketPaddingRate() => $_has(15);
  @$pb.TagNumber(16)
  void clearPacketPaddingRate() => clearField(16);

  @$pb.TagNumber(17)
  $fixnum.Int64 get bytesPadding => $_getI64(16);
  @$pb.TagNumber(17)
  set bytesPadding($fixnum.Int64 v) {
    $_setInt64(16, v);
  }

  @$pb.TagNumber(17)
  $core.bool hasBytesPadding() => $_has(16);
  @$pb.TagNumber(17)
  void clearBytesPadding() => clearField(17);

  @$pb.TagNumber(18)
  $core.double get bitratePadding => $_getN(17);
  @$pb.TagNumber(18)
  set bitratePadding($core.double v) {
    $_setDouble(17, v);
  }

  @$pb.TagNumber(18)
  $core.bool hasBitratePadding() => $_has(17);
  @$pb.TagNumber(18)
  void clearBitratePadding() => clearField(18);

  @$pb.TagNumber(19)
  $core.int get packetsOutOfOrder => $_getIZ(18);
  @$pb.TagNumber(19)
  set packetsOutOfOrder($core.int v) {
    $_setUnsignedInt32(18, v);
  }

  @$pb.TagNumber(19)
  $core.bool hasPacketsOutOfOrder() => $_has(18);
  @$pb.TagNumber(19)
  void clearPacketsOutOfOrder() => clearField(19);

  @$pb.TagNumber(20)
  $core.int get frames => $_getIZ(19);
  @$pb.TagNumber(20)
  set frames($core.int v) {
    $_setUnsignedInt32(19, v);
  }

  @$pb.TagNumber(20)
  $core.bool hasFrames() => $_has(19);
  @$pb.TagNumber(20)
  void clearFrames() => clearField(20);

  @$pb.TagNumber(21)
  $core.double get frameRate => $_getN(20);
  @$pb.TagNumber(21)
  set frameRate($core.double v) {
    $_setDouble(20, v);
  }

  @$pb.TagNumber(21)
  $core.bool hasFrameRate() => $_has(20);
  @$pb.TagNumber(21)
  void clearFrameRate() => clearField(21);

  @$pb.TagNumber(22)
  $core.double get jitterCurrent => $_getN(21);
  @$pb.TagNumber(22)
  set jitterCurrent($core.double v) {
    $_setDouble(21, v);
  }

  @$pb.TagNumber(22)
  $core.bool hasJitterCurrent() => $_has(21);
  @$pb.TagNumber(22)
  void clearJitterCurrent() => clearField(22);

  @$pb.TagNumber(23)
  $core.double get jitterMax => $_getN(22);
  @$pb.TagNumber(23)
  set jitterMax($core.double v) {
    $_setDouble(22, v);
  }

  @$pb.TagNumber(23)
  $core.bool hasJitterMax() => $_has(22);
  @$pb.TagNumber(23)
  void clearJitterMax() => clearField(23);

  @$pb.TagNumber(24)
  $core.Map<$core.int, $core.int> get gapHistogram => $_getMap(23);

  @$pb.TagNumber(25)
  $core.int get nacks => $_getIZ(24);
  @$pb.TagNumber(25)
  set nacks($core.int v) {
    $_setUnsignedInt32(24, v);
  }

  @$pb.TagNumber(25)
  $core.bool hasNacks() => $_has(24);
  @$pb.TagNumber(25)
  void clearNacks() => clearField(25);

  @$pb.TagNumber(26)
  $core.int get nackMisses => $_getIZ(25);
  @$pb.TagNumber(26)
  set nackMisses($core.int v) {
    $_setUnsignedInt32(25, v);
  }

  @$pb.TagNumber(26)
  $core.bool hasNackMisses() => $_has(25);
  @$pb.TagNumber(26)
  void clearNackMisses() => clearField(26);

  @$pb.TagNumber(27)
  $core.int get plis => $_getIZ(26);
  @$pb.TagNumber(27)
  set plis($core.int v) {
    $_setUnsignedInt32(26, v);
  }

  @$pb.TagNumber(27)
  $core.bool hasPlis() => $_has(26);
  @$pb.TagNumber(27)
  void clearPlis() => clearField(27);

  @$pb.TagNumber(28)
  $0.Timestamp get lastPli => $_getN(27);
  @$pb.TagNumber(28)
  set lastPli($0.Timestamp v) {
    setField(28, v);
  }

  @$pb.TagNumber(28)
  $core.bool hasLastPli() => $_has(27);
  @$pb.TagNumber(28)
  void clearLastPli() => clearField(28);
  @$pb.TagNumber(28)
  $0.Timestamp ensureLastPli() => $_ensure(27);

  @$pb.TagNumber(29)
  $core.int get firs => $_getIZ(28);
  @$pb.TagNumber(29)
  set firs($core.int v) {
    $_setUnsignedInt32(28, v);
  }

  @$pb.TagNumber(29)
  $core.bool hasFirs() => $_has(28);
  @$pb.TagNumber(29)
  void clearFirs() => clearField(29);

  @$pb.TagNumber(30)
  $0.Timestamp get lastFir => $_getN(29);
  @$pb.TagNumber(30)
  set lastFir($0.Timestamp v) {
    setField(30, v);
  }

  @$pb.TagNumber(30)
  $core.bool hasLastFir() => $_has(29);
  @$pb.TagNumber(30)
  void clearLastFir() => clearField(30);
  @$pb.TagNumber(30)
  $0.Timestamp ensureLastFir() => $_ensure(29);

  @$pb.TagNumber(31)
  $core.int get rttCurrent => $_getIZ(30);
  @$pb.TagNumber(31)
  set rttCurrent($core.int v) {
    $_setUnsignedInt32(30, v);
  }

  @$pb.TagNumber(31)
  $core.bool hasRttCurrent() => $_has(30);
  @$pb.TagNumber(31)
  void clearRttCurrent() => clearField(31);

  @$pb.TagNumber(32)
  $core.int get rttMax => $_getIZ(31);
  @$pb.TagNumber(32)
  set rttMax($core.int v) {
    $_setUnsignedInt32(31, v);
  }

  @$pb.TagNumber(32)
  $core.bool hasRttMax() => $_has(31);
  @$pb.TagNumber(32)
  void clearRttMax() => clearField(32);

  @$pb.TagNumber(33)
  $core.int get keyFrames => $_getIZ(32);
  @$pb.TagNumber(33)
  set keyFrames($core.int v) {
    $_setUnsignedInt32(32, v);
  }

  @$pb.TagNumber(33)
  $core.bool hasKeyFrames() => $_has(32);
  @$pb.TagNumber(33)
  void clearKeyFrames() => clearField(33);

  @$pb.TagNumber(34)
  $0.Timestamp get lastKeyFrame => $_getN(33);
  @$pb.TagNumber(34)
  set lastKeyFrame($0.Timestamp v) {
    setField(34, v);
  }

  @$pb.TagNumber(34)
  $core.bool hasLastKeyFrame() => $_has(33);
  @$pb.TagNumber(34)
  void clearLastKeyFrame() => clearField(34);
  @$pb.TagNumber(34)
  $0.Timestamp ensureLastKeyFrame() => $_ensure(33);

  @$pb.TagNumber(35)
  $core.int get layerLockPlis => $_getIZ(34);
  @$pb.TagNumber(35)
  set layerLockPlis($core.int v) {
    $_setUnsignedInt32(34, v);
  }

  @$pb.TagNumber(35)
  $core.bool hasLayerLockPlis() => $_has(34);
  @$pb.TagNumber(35)
  void clearLayerLockPlis() => clearField(35);

  @$pb.TagNumber(36)
  $0.Timestamp get lastLayerLockPli => $_getN(35);
  @$pb.TagNumber(36)
  set lastLayerLockPli($0.Timestamp v) {
    setField(36, v);
  }

  @$pb.TagNumber(36)
  $core.bool hasLastLayerLockPli() => $_has(35);
  @$pb.TagNumber(36)
  void clearLastLayerLockPli() => clearField(36);
  @$pb.TagNumber(36)
  $0.Timestamp ensureLastLayerLockPli() => $_ensure(35);
}
