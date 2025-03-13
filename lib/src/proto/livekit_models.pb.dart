//
//  Generated code. Do not modify.
//  source: livekit_models.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'google/protobuf/timestamp.pb.dart' as $0;
import 'livekit_metrics.pb.dart' as $1;
import 'livekit_models.pbenum.dart';

export 'livekit_models.pbenum.dart';

class Room extends $pb.GeneratedMessage {
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
    $core.int? numPublishers,
    TimedVersion? version,
    $core.int? departureTimeout,
  }) {
    final $result = create();
    if (sid != null) {
      $result.sid = sid;
    }
    if (name != null) {
      $result.name = name;
    }
    if (emptyTimeout != null) {
      $result.emptyTimeout = emptyTimeout;
    }
    if (maxParticipants != null) {
      $result.maxParticipants = maxParticipants;
    }
    if (creationTime != null) {
      $result.creationTime = creationTime;
    }
    if (turnPassword != null) {
      $result.turnPassword = turnPassword;
    }
    if (enabledCodecs != null) {
      $result.enabledCodecs.addAll(enabledCodecs);
    }
    if (metadata != null) {
      $result.metadata = metadata;
    }
    if (numParticipants != null) {
      $result.numParticipants = numParticipants;
    }
    if (activeRecording != null) {
      $result.activeRecording = activeRecording;
    }
    if (numPublishers != null) {
      $result.numPublishers = numPublishers;
    }
    if (version != null) {
      $result.version = version;
    }
    if (departureTimeout != null) {
      $result.departureTimeout = departureTimeout;
    }
    return $result;
  }
  Room._() : super();
  factory Room.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Room.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Room',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sid')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..a<$core.int>(
        3, _omitFieldNames ? '' : 'emptyTimeout', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        4, _omitFieldNames ? '' : 'maxParticipants', $pb.PbFieldType.OU3)
    ..aInt64(5, _omitFieldNames ? '' : 'creationTime')
    ..aOS(6, _omitFieldNames ? '' : 'turnPassword')
    ..pc<Codec>(7, _omitFieldNames ? '' : 'enabledCodecs', $pb.PbFieldType.PM,
        subBuilder: Codec.create)
    ..aOS(8, _omitFieldNames ? '' : 'metadata')
    ..a<$core.int>(
        9, _omitFieldNames ? '' : 'numParticipants', $pb.PbFieldType.OU3)
    ..aOB(10, _omitFieldNames ? '' : 'activeRecording')
    ..a<$core.int>(
        11, _omitFieldNames ? '' : 'numPublishers', $pb.PbFieldType.OU3)
    ..aOM<TimedVersion>(13, _omitFieldNames ? '' : 'version',
        subBuilder: TimedVersion.create)
    ..a<$core.int>(
        14, _omitFieldNames ? '' : 'departureTimeout', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Room clone() => Room()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Room copyWith(void Function(Room) updates) =>
      super.copyWith((message) => updates(message as Room)) as Room;

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

  @$pb.TagNumber(11)
  $core.int get numPublishers => $_getIZ(10);
  @$pb.TagNumber(11)
  set numPublishers($core.int v) {
    $_setUnsignedInt32(10, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasNumPublishers() => $_has(10);
  @$pb.TagNumber(11)
  void clearNumPublishers() => clearField(11);

  @$pb.TagNumber(13)
  TimedVersion get version => $_getN(11);
  @$pb.TagNumber(13)
  set version(TimedVersion v) {
    setField(13, v);
  }

  @$pb.TagNumber(13)
  $core.bool hasVersion() => $_has(11);
  @$pb.TagNumber(13)
  void clearVersion() => clearField(13);
  @$pb.TagNumber(13)
  TimedVersion ensureVersion() => $_ensure(11);

  @$pb.TagNumber(14)
  $core.int get departureTimeout => $_getIZ(12);
  @$pb.TagNumber(14)
  set departureTimeout($core.int v) {
    $_setUnsignedInt32(12, v);
  }

  @$pb.TagNumber(14)
  $core.bool hasDepartureTimeout() => $_has(12);
  @$pb.TagNumber(14)
  void clearDepartureTimeout() => clearField(14);
}

class Codec extends $pb.GeneratedMessage {
  factory Codec({
    $core.String? mime,
    $core.String? fmtpLine,
  }) {
    final $result = create();
    if (mime != null) {
      $result.mime = mime;
    }
    if (fmtpLine != null) {
      $result.fmtpLine = fmtpLine;
    }
    return $result;
  }
  Codec._() : super();
  factory Codec.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Codec.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Codec',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'mime')
    ..aOS(2, _omitFieldNames ? '' : 'fmtpLine')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Codec clone() => Codec()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Codec copyWith(void Function(Codec) updates) =>
      super.copyWith((message) => updates(message as Codec)) as Codec;

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

class PlayoutDelay extends $pb.GeneratedMessage {
  factory PlayoutDelay({
    $core.bool? enabled,
    $core.int? min,
    $core.int? max,
  }) {
    final $result = create();
    if (enabled != null) {
      $result.enabled = enabled;
    }
    if (min != null) {
      $result.min = min;
    }
    if (max != null) {
      $result.max = max;
    }
    return $result;
  }
  PlayoutDelay._() : super();
  factory PlayoutDelay.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory PlayoutDelay.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlayoutDelay',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'min', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'max', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  PlayoutDelay clone() => PlayoutDelay()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  PlayoutDelay copyWith(void Function(PlayoutDelay) updates) =>
      super.copyWith((message) => updates(message as PlayoutDelay))
          as PlayoutDelay;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlayoutDelay create() => PlayoutDelay._();
  PlayoutDelay createEmptyInstance() => create();
  static $pb.PbList<PlayoutDelay> createRepeated() =>
      $pb.PbList<PlayoutDelay>();
  @$core.pragma('dart2js:noInline')
  static PlayoutDelay getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlayoutDelay>(create);
  static PlayoutDelay? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get min => $_getIZ(1);
  @$pb.TagNumber(2)
  set min($core.int v) {
    $_setUnsignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMin() => $_has(1);
  @$pb.TagNumber(2)
  void clearMin() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get max => $_getIZ(2);
  @$pb.TagNumber(3)
  set max($core.int v) {
    $_setUnsignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasMax() => $_has(2);
  @$pb.TagNumber(3)
  void clearMax() => clearField(3);
}

class ParticipantPermission extends $pb.GeneratedMessage {
  factory ParticipantPermission({
    $core.bool? canSubscribe,
    $core.bool? canPublish,
    $core.bool? canPublishData,
    $core.bool? hidden,
    @$core.Deprecated('This field is deprecated.') $core.bool? recorder,
    $core.Iterable<TrackSource>? canPublishSources,
    $core.bool? canUpdateMetadata,
    @$core.Deprecated('This field is deprecated.') $core.bool? agent,
    $core.bool? canSubscribeMetrics,
  }) {
    final $result = create();
    if (canSubscribe != null) {
      $result.canSubscribe = canSubscribe;
    }
    if (canPublish != null) {
      $result.canPublish = canPublish;
    }
    if (canPublishData != null) {
      $result.canPublishData = canPublishData;
    }
    if (hidden != null) {
      $result.hidden = hidden;
    }
    if (recorder != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.recorder = recorder;
    }
    if (canPublishSources != null) {
      $result.canPublishSources.addAll(canPublishSources);
    }
    if (canUpdateMetadata != null) {
      $result.canUpdateMetadata = canUpdateMetadata;
    }
    if (agent != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.agent = agent;
    }
    if (canSubscribeMetrics != null) {
      $result.canSubscribeMetrics = canSubscribeMetrics;
    }
    return $result;
  }
  ParticipantPermission._() : super();
  factory ParticipantPermission.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ParticipantPermission.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ParticipantPermission',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'canSubscribe')
    ..aOB(2, _omitFieldNames ? '' : 'canPublish')
    ..aOB(3, _omitFieldNames ? '' : 'canPublishData')
    ..aOB(7, _omitFieldNames ? '' : 'hidden')
    ..aOB(8, _omitFieldNames ? '' : 'recorder')
    ..pc<TrackSource>(
        9, _omitFieldNames ? '' : 'canPublishSources', $pb.PbFieldType.KE,
        valueOf: TrackSource.valueOf,
        enumValues: TrackSource.values,
        defaultEnumValue: TrackSource.UNKNOWN)
    ..aOB(10, _omitFieldNames ? '' : 'canUpdateMetadata')
    ..aOB(11, _omitFieldNames ? '' : 'agent')
    ..aOB(12, _omitFieldNames ? '' : 'canSubscribeMetrics')
    ..hasRequiredFields = false;

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
          as ParticipantPermission;

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

  /// allow participant to subscribe to other tracks in the room
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

  /// allow participant to publish new tracks to room
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

  /// allow participant to publish data
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

  /// indicates that it's hidden to others
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

  /// indicates it's a recorder instance
  /// deprecated: use ParticipantInfo.kind instead
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(8)
  $core.bool get recorder => $_getBF(4);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(8)
  set recorder($core.bool v) {
    $_setBool(4, v);
  }

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(8)
  $core.bool hasRecorder() => $_has(4);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(8)
  void clearRecorder() => clearField(8);

  /// sources that are allowed to be published
  @$pb.TagNumber(9)
  $core.List<TrackSource> get canPublishSources => $_getList(5);

  /// indicates that participant can update own metadata and attributes
  @$pb.TagNumber(10)
  $core.bool get canUpdateMetadata => $_getBF(6);
  @$pb.TagNumber(10)
  set canUpdateMetadata($core.bool v) {
    $_setBool(6, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasCanUpdateMetadata() => $_has(6);
  @$pb.TagNumber(10)
  void clearCanUpdateMetadata() => clearField(10);

  /// indicates that participant is an agent
  /// deprecated: use ParticipantInfo.kind instead
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(11)
  $core.bool get agent => $_getBF(7);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(11)
  set agent($core.bool v) {
    $_setBool(7, v);
  }

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(11)
  $core.bool hasAgent() => $_has(7);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(11)
  void clearAgent() => clearField(11);

  /// if a participant can subscribe to metrics
  @$pb.TagNumber(12)
  $core.bool get canSubscribeMetrics => $_getBF(8);
  @$pb.TagNumber(12)
  set canSubscribeMetrics($core.bool v) {
    $_setBool(8, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasCanSubscribeMetrics() => $_has(8);
  @$pb.TagNumber(12)
  void clearCanSubscribeMetrics() => clearField(12);
}

class ParticipantInfo extends $pb.GeneratedMessage {
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
    $core.bool? isPublisher,
    ParticipantInfo_Kind? kind,
    $core.Map<$core.String, $core.String>? attributes,
    DisconnectReason? disconnectReason,
  }) {
    final $result = create();
    if (sid != null) {
      $result.sid = sid;
    }
    if (identity != null) {
      $result.identity = identity;
    }
    if (state != null) {
      $result.state = state;
    }
    if (tracks != null) {
      $result.tracks.addAll(tracks);
    }
    if (metadata != null) {
      $result.metadata = metadata;
    }
    if (joinedAt != null) {
      $result.joinedAt = joinedAt;
    }
    if (name != null) {
      $result.name = name;
    }
    if (version != null) {
      $result.version = version;
    }
    if (permission != null) {
      $result.permission = permission;
    }
    if (region != null) {
      $result.region = region;
    }
    if (isPublisher != null) {
      $result.isPublisher = isPublisher;
    }
    if (kind != null) {
      $result.kind = kind;
    }
    if (attributes != null) {
      $result.attributes.addAll(attributes);
    }
    if (disconnectReason != null) {
      $result.disconnectReason = disconnectReason;
    }
    return $result;
  }
  ParticipantInfo._() : super();
  factory ParticipantInfo.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ParticipantInfo.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ParticipantInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sid')
    ..aOS(2, _omitFieldNames ? '' : 'identity')
    ..e<ParticipantInfo_State>(
        3, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker: ParticipantInfo_State.JOINING,
        valueOf: ParticipantInfo_State.valueOf,
        enumValues: ParticipantInfo_State.values)
    ..pc<TrackInfo>(4, _omitFieldNames ? '' : 'tracks', $pb.PbFieldType.PM,
        subBuilder: TrackInfo.create)
    ..aOS(5, _omitFieldNames ? '' : 'metadata')
    ..aInt64(6, _omitFieldNames ? '' : 'joinedAt')
    ..aOS(9, _omitFieldNames ? '' : 'name')
    ..a<$core.int>(10, _omitFieldNames ? '' : 'version', $pb.PbFieldType.OU3)
    ..aOM<ParticipantPermission>(11, _omitFieldNames ? '' : 'permission',
        subBuilder: ParticipantPermission.create)
    ..aOS(12, _omitFieldNames ? '' : 'region')
    ..aOB(13, _omitFieldNames ? '' : 'isPublisher')
    ..e<ParticipantInfo_Kind>(
        14, _omitFieldNames ? '' : 'kind', $pb.PbFieldType.OE,
        defaultOrMaker: ParticipantInfo_Kind.STANDARD,
        valueOf: ParticipantInfo_Kind.valueOf,
        enumValues: ParticipantInfo_Kind.values)
    ..m<$core.String, $core.String>(15, _omitFieldNames ? '' : 'attributes',
        entryClassName: 'ParticipantInfo.AttributesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('livekit'))
    ..e<DisconnectReason>(
        16, _omitFieldNames ? '' : 'disconnectReason', $pb.PbFieldType.OE,
        defaultOrMaker: DisconnectReason.UNKNOWN_REASON,
        valueOf: DisconnectReason.valueOf,
        enumValues: DisconnectReason.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ParticipantInfo clone() => ParticipantInfo()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ParticipantInfo copyWith(void Function(ParticipantInfo) updates) =>
      super.copyWith((message) => updates(message as ParticipantInfo))
          as ParticipantInfo;

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

  /// timestamp when participant joined room, in seconds
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

  /// indicates the participant has an active publisher connection
  /// and can publish to the server
  @$pb.TagNumber(13)
  $core.bool get isPublisher => $_getBF(10);
  @$pb.TagNumber(13)
  set isPublisher($core.bool v) {
    $_setBool(10, v);
  }

  @$pb.TagNumber(13)
  $core.bool hasIsPublisher() => $_has(10);
  @$pb.TagNumber(13)
  void clearIsPublisher() => clearField(13);

  @$pb.TagNumber(14)
  ParticipantInfo_Kind get kind => $_getN(11);
  @$pb.TagNumber(14)
  set kind(ParticipantInfo_Kind v) {
    setField(14, v);
  }

  @$pb.TagNumber(14)
  $core.bool hasKind() => $_has(11);
  @$pb.TagNumber(14)
  void clearKind() => clearField(14);

  @$pb.TagNumber(15)
  $core.Map<$core.String, $core.String> get attributes => $_getMap(12);

  @$pb.TagNumber(16)
  DisconnectReason get disconnectReason => $_getN(13);
  @$pb.TagNumber(16)
  set disconnectReason(DisconnectReason v) {
    setField(16, v);
  }

  @$pb.TagNumber(16)
  $core.bool hasDisconnectReason() => $_has(13);
  @$pb.TagNumber(16)
  void clearDisconnectReason() => clearField(16);
}

class Encryption extends $pb.GeneratedMessage {
  factory Encryption() => create();
  Encryption._() : super();
  factory Encryption.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Encryption.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Encryption',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Encryption clone() => Encryption()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Encryption copyWith(void Function(Encryption) updates) =>
      super.copyWith((message) => updates(message as Encryption)) as Encryption;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Encryption create() => Encryption._();
  Encryption createEmptyInstance() => create();
  static $pb.PbList<Encryption> createRepeated() => $pb.PbList<Encryption>();
  @$core.pragma('dart2js:noInline')
  static Encryption getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Encryption>(create);
  static Encryption? _defaultInstance;
}

class SimulcastCodecInfo extends $pb.GeneratedMessage {
  factory SimulcastCodecInfo({
    $core.String? mimeType,
    $core.String? mid,
    $core.String? cid,
    $core.Iterable<VideoLayer>? layers,
  }) {
    final $result = create();
    if (mimeType != null) {
      $result.mimeType = mimeType;
    }
    if (mid != null) {
      $result.mid = mid;
    }
    if (cid != null) {
      $result.cid = cid;
    }
    if (layers != null) {
      $result.layers.addAll(layers);
    }
    return $result;
  }
  SimulcastCodecInfo._() : super();
  factory SimulcastCodecInfo.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SimulcastCodecInfo.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SimulcastCodecInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'mimeType')
    ..aOS(2, _omitFieldNames ? '' : 'mid')
    ..aOS(3, _omitFieldNames ? '' : 'cid')
    ..pc<VideoLayer>(4, _omitFieldNames ? '' : 'layers', $pb.PbFieldType.PM,
        subBuilder: VideoLayer.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SimulcastCodecInfo clone() => SimulcastCodecInfo()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SimulcastCodecInfo copyWith(void Function(SimulcastCodecInfo) updates) =>
      super.copyWith((message) => updates(message as SimulcastCodecInfo))
          as SimulcastCodecInfo;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SimulcastCodecInfo create() => SimulcastCodecInfo._();
  SimulcastCodecInfo createEmptyInstance() => create();
  static $pb.PbList<SimulcastCodecInfo> createRepeated() =>
      $pb.PbList<SimulcastCodecInfo>();
  @$core.pragma('dart2js:noInline')
  static SimulcastCodecInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SimulcastCodecInfo>(create);
  static SimulcastCodecInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get mimeType => $_getSZ(0);
  @$pb.TagNumber(1)
  set mimeType($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasMimeType() => $_has(0);
  @$pb.TagNumber(1)
  void clearMimeType() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get mid => $_getSZ(1);
  @$pb.TagNumber(2)
  set mid($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMid() => $_has(1);
  @$pb.TagNumber(2)
  void clearMid() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get cid => $_getSZ(2);
  @$pb.TagNumber(3)
  set cid($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasCid() => $_has(2);
  @$pb.TagNumber(3)
  void clearCid() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<VideoLayer> get layers => $_getList(3);
}

class TrackInfo extends $pb.GeneratedMessage {
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
    $core.Iterable<SimulcastCodecInfo>? codecs,
    $core.bool? stereo,
    $core.bool? disableRed,
    Encryption_Type? encryption,
    $core.String? stream,
    TimedVersion? version,
    $core.Iterable<AudioTrackFeature>? audioFeatures,
  }) {
    final $result = create();
    if (sid != null) {
      $result.sid = sid;
    }
    if (type != null) {
      $result.type = type;
    }
    if (name != null) {
      $result.name = name;
    }
    if (muted != null) {
      $result.muted = muted;
    }
    if (width != null) {
      $result.width = width;
    }
    if (height != null) {
      $result.height = height;
    }
    if (simulcast != null) {
      $result.simulcast = simulcast;
    }
    if (disableDtx != null) {
      $result.disableDtx = disableDtx;
    }
    if (source != null) {
      $result.source = source;
    }
    if (layers != null) {
      $result.layers.addAll(layers);
    }
    if (mimeType != null) {
      $result.mimeType = mimeType;
    }
    if (mid != null) {
      $result.mid = mid;
    }
    if (codecs != null) {
      $result.codecs.addAll(codecs);
    }
    if (stereo != null) {
      $result.stereo = stereo;
    }
    if (disableRed != null) {
      $result.disableRed = disableRed;
    }
    if (encryption != null) {
      $result.encryption = encryption;
    }
    if (stream != null) {
      $result.stream = stream;
    }
    if (version != null) {
      $result.version = version;
    }
    if (audioFeatures != null) {
      $result.audioFeatures.addAll(audioFeatures);
    }
    return $result;
  }
  TrackInfo._() : super();
  factory TrackInfo.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TrackInfo.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TrackInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sid')
    ..e<TrackType>(2, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker: TrackType.AUDIO,
        valueOf: TrackType.valueOf,
        enumValues: TrackType.values)
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOB(4, _omitFieldNames ? '' : 'muted')
    ..a<$core.int>(5, _omitFieldNames ? '' : 'width', $pb.PbFieldType.OU3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'height', $pb.PbFieldType.OU3)
    ..aOB(7, _omitFieldNames ? '' : 'simulcast')
    ..aOB(8, _omitFieldNames ? '' : 'disableDtx')
    ..e<TrackSource>(9, _omitFieldNames ? '' : 'source', $pb.PbFieldType.OE,
        defaultOrMaker: TrackSource.UNKNOWN,
        valueOf: TrackSource.valueOf,
        enumValues: TrackSource.values)
    ..pc<VideoLayer>(10, _omitFieldNames ? '' : 'layers', $pb.PbFieldType.PM,
        subBuilder: VideoLayer.create)
    ..aOS(11, _omitFieldNames ? '' : 'mimeType')
    ..aOS(12, _omitFieldNames ? '' : 'mid')
    ..pc<SimulcastCodecInfo>(
        13, _omitFieldNames ? '' : 'codecs', $pb.PbFieldType.PM,
        subBuilder: SimulcastCodecInfo.create)
    ..aOB(14, _omitFieldNames ? '' : 'stereo')
    ..aOB(15, _omitFieldNames ? '' : 'disableRed')
    ..e<Encryption_Type>(
        16, _omitFieldNames ? '' : 'encryption', $pb.PbFieldType.OE,
        defaultOrMaker: Encryption_Type.NONE,
        valueOf: Encryption_Type.valueOf,
        enumValues: Encryption_Type.values)
    ..aOS(17, _omitFieldNames ? '' : 'stream')
    ..aOM<TimedVersion>(18, _omitFieldNames ? '' : 'version',
        subBuilder: TimedVersion.create)
    ..pc<AudioTrackFeature>(
        19, _omitFieldNames ? '' : 'audioFeatures', $pb.PbFieldType.KE,
        valueOf: AudioTrackFeature.valueOf,
        enumValues: AudioTrackFeature.values,
        defaultEnumValue: AudioTrackFeature.TF_STEREO)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TrackInfo clone() => TrackInfo()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TrackInfo copyWith(void Function(TrackInfo) updates) =>
      super.copyWith((message) => updates(message as TrackInfo)) as TrackInfo;

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

  /// original width of video (unset for audio)
  /// clients may receive a lower resolution version with simulcast
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

  /// original height of video (unset for audio)
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

  /// true if track is simulcasted
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

  /// true if DTX (Discontinuous Transmission) is disabled for audio
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

  /// source of media
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

  /// mime type of codec
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

  @$pb.TagNumber(13)
  $core.List<SimulcastCodecInfo> get codecs => $_getList(12);

  @$pb.TagNumber(14)
  $core.bool get stereo => $_getBF(13);
  @$pb.TagNumber(14)
  set stereo($core.bool v) {
    $_setBool(13, v);
  }

  @$pb.TagNumber(14)
  $core.bool hasStereo() => $_has(13);
  @$pb.TagNumber(14)
  void clearStereo() => clearField(14);

  /// true if RED (Redundant Encoding) is disabled for audio
  @$pb.TagNumber(15)
  $core.bool get disableRed => $_getBF(14);
  @$pb.TagNumber(15)
  set disableRed($core.bool v) {
    $_setBool(14, v);
  }

  @$pb.TagNumber(15)
  $core.bool hasDisableRed() => $_has(14);
  @$pb.TagNumber(15)
  void clearDisableRed() => clearField(15);

  @$pb.TagNumber(16)
  Encryption_Type get encryption => $_getN(15);
  @$pb.TagNumber(16)
  set encryption(Encryption_Type v) {
    setField(16, v);
  }

  @$pb.TagNumber(16)
  $core.bool hasEncryption() => $_has(15);
  @$pb.TagNumber(16)
  void clearEncryption() => clearField(16);

  @$pb.TagNumber(17)
  $core.String get stream => $_getSZ(16);
  @$pb.TagNumber(17)
  set stream($core.String v) {
    $_setString(16, v);
  }

  @$pb.TagNumber(17)
  $core.bool hasStream() => $_has(16);
  @$pb.TagNumber(17)
  void clearStream() => clearField(17);

  @$pb.TagNumber(18)
  TimedVersion get version => $_getN(17);
  @$pb.TagNumber(18)
  set version(TimedVersion v) {
    setField(18, v);
  }

  @$pb.TagNumber(18)
  $core.bool hasVersion() => $_has(17);
  @$pb.TagNumber(18)
  void clearVersion() => clearField(18);
  @$pb.TagNumber(18)
  TimedVersion ensureVersion() => $_ensure(17);

  @$pb.TagNumber(19)
  $core.List<AudioTrackFeature> get audioFeatures => $_getList(18);
}

/// provide information about available spatial layers
class VideoLayer extends $pb.GeneratedMessage {
  factory VideoLayer({
    VideoQuality? quality,
    $core.int? width,
    $core.int? height,
    $core.int? bitrate,
    $core.int? ssrc,
  }) {
    final $result = create();
    if (quality != null) {
      $result.quality = quality;
    }
    if (width != null) {
      $result.width = width;
    }
    if (height != null) {
      $result.height = height;
    }
    if (bitrate != null) {
      $result.bitrate = bitrate;
    }
    if (ssrc != null) {
      $result.ssrc = ssrc;
    }
    return $result;
  }
  VideoLayer._() : super();
  factory VideoLayer.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory VideoLayer.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VideoLayer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..e<VideoQuality>(1, _omitFieldNames ? '' : 'quality', $pb.PbFieldType.OE,
        defaultOrMaker: VideoQuality.LOW,
        valueOf: VideoQuality.valueOf,
        enumValues: VideoQuality.values)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'width', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'height', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'bitrate', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'ssrc', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  VideoLayer clone() => VideoLayer()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  VideoLayer copyWith(void Function(VideoLayer) updates) =>
      super.copyWith((message) => updates(message as VideoLayer)) as VideoLayer;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VideoLayer create() => VideoLayer._();
  VideoLayer createEmptyInstance() => create();
  static $pb.PbList<VideoLayer> createRepeated() => $pb.PbList<VideoLayer>();
  @$core.pragma('dart2js:noInline')
  static VideoLayer getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VideoLayer>(create);
  static VideoLayer? _defaultInstance;

  /// for tracks with a single layer, this should be HIGH
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

  /// target bitrate in bit per second (bps), server will measure actual
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

enum DataPacket_Value {
  user,
  speaker,
  sipDtmf,
  transcription,
  metrics,
  chatMessage,
  rpcRequest,
  rpcAck,
  rpcResponse,
  streamHeader,
  streamChunk,
  streamTrailer,
  notSet
}

/// new DataPacket API
class DataPacket extends $pb.GeneratedMessage {
  factory DataPacket({
    @$core.Deprecated('This field is deprecated.') DataPacket_Kind? kind,
    UserPacket? user,
    @$core.Deprecated('This field is deprecated.') ActiveSpeakerUpdate? speaker,
    $core.String? participantIdentity,
    $core.Iterable<$core.String>? destinationIdentities,
    SipDTMF? sipDtmf,
    Transcription? transcription,
    $1.MetricsBatch? metrics,
    ChatMessage? chatMessage,
    RpcRequest? rpcRequest,
    RpcAck? rpcAck,
    RpcResponse? rpcResponse,
    DataStream_Header? streamHeader,
    DataStream_Chunk? streamChunk,
    DataStream_Trailer? streamTrailer,
  }) {
    final $result = create();
    if (kind != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.kind = kind;
    }
    if (user != null) {
      $result.user = user;
    }
    if (speaker != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.speaker = speaker;
    }
    if (participantIdentity != null) {
      $result.participantIdentity = participantIdentity;
    }
    if (destinationIdentities != null) {
      $result.destinationIdentities.addAll(destinationIdentities);
    }
    if (sipDtmf != null) {
      $result.sipDtmf = sipDtmf;
    }
    if (transcription != null) {
      $result.transcription = transcription;
    }
    if (metrics != null) {
      $result.metrics = metrics;
    }
    if (chatMessage != null) {
      $result.chatMessage = chatMessage;
    }
    if (rpcRequest != null) {
      $result.rpcRequest = rpcRequest;
    }
    if (rpcAck != null) {
      $result.rpcAck = rpcAck;
    }
    if (rpcResponse != null) {
      $result.rpcResponse = rpcResponse;
    }
    if (streamHeader != null) {
      $result.streamHeader = streamHeader;
    }
    if (streamChunk != null) {
      $result.streamChunk = streamChunk;
    }
    if (streamTrailer != null) {
      $result.streamTrailer = streamTrailer;
    }
    return $result;
  }
  DataPacket._() : super();
  factory DataPacket.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DataPacket.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, DataPacket_Value> _DataPacket_ValueByTag = {
    2: DataPacket_Value.user,
    3: DataPacket_Value.speaker,
    6: DataPacket_Value.sipDtmf,
    7: DataPacket_Value.transcription,
    8: DataPacket_Value.metrics,
    9: DataPacket_Value.chatMessage,
    10: DataPacket_Value.rpcRequest,
    11: DataPacket_Value.rpcAck,
    12: DataPacket_Value.rpcResponse,
    13: DataPacket_Value.streamHeader,
    14: DataPacket_Value.streamChunk,
    15: DataPacket_Value.streamTrailer,
    0: DataPacket_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DataPacket',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..oo(0, [2, 3, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15])
    ..e<DataPacket_Kind>(1, _omitFieldNames ? '' : 'kind', $pb.PbFieldType.OE,
        defaultOrMaker: DataPacket_Kind.RELIABLE,
        valueOf: DataPacket_Kind.valueOf,
        enumValues: DataPacket_Kind.values)
    ..aOM<UserPacket>(2, _omitFieldNames ? '' : 'user',
        subBuilder: UserPacket.create)
    ..aOM<ActiveSpeakerUpdate>(3, _omitFieldNames ? '' : 'speaker',
        subBuilder: ActiveSpeakerUpdate.create)
    ..aOS(4, _omitFieldNames ? '' : 'participantIdentity')
    ..pPS(5, _omitFieldNames ? '' : 'destinationIdentities')
    ..aOM<SipDTMF>(6, _omitFieldNames ? '' : 'sipDtmf',
        subBuilder: SipDTMF.create)
    ..aOM<Transcription>(7, _omitFieldNames ? '' : 'transcription',
        subBuilder: Transcription.create)
    ..aOM<$1.MetricsBatch>(8, _omitFieldNames ? '' : 'metrics',
        subBuilder: $1.MetricsBatch.create)
    ..aOM<ChatMessage>(9, _omitFieldNames ? '' : 'chatMessage',
        subBuilder: ChatMessage.create)
    ..aOM<RpcRequest>(10, _omitFieldNames ? '' : 'rpcRequest',
        subBuilder: RpcRequest.create)
    ..aOM<RpcAck>(11, _omitFieldNames ? '' : 'rpcAck',
        subBuilder: RpcAck.create)
    ..aOM<RpcResponse>(12, _omitFieldNames ? '' : 'rpcResponse',
        subBuilder: RpcResponse.create)
    ..aOM<DataStream_Header>(13, _omitFieldNames ? '' : 'streamHeader',
        subBuilder: DataStream_Header.create)
    ..aOM<DataStream_Chunk>(14, _omitFieldNames ? '' : 'streamChunk',
        subBuilder: DataStream_Chunk.create)
    ..aOM<DataStream_Trailer>(15, _omitFieldNames ? '' : 'streamTrailer',
        subBuilder: DataStream_Trailer.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DataPacket clone() => DataPacket()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DataPacket copyWith(void Function(DataPacket) updates) =>
      super.copyWith((message) => updates(message as DataPacket)) as DataPacket;

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

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(1)
  DataPacket_Kind get kind => $_getN(0);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(1)
  set kind(DataPacket_Kind v) {
    setField(1, v);
  }

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$core.Deprecated('This field is deprecated.')
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

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  ActiveSpeakerUpdate get speaker => $_getN(2);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  set speaker(ActiveSpeakerUpdate v) {
    setField(3, v);
  }

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  $core.bool hasSpeaker() => $_has(2);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  void clearSpeaker() => clearField(3);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  ActiveSpeakerUpdate ensureSpeaker() => $_ensure(2);

  /// participant identity of user that sent the message
  @$pb.TagNumber(4)
  $core.String get participantIdentity => $_getSZ(3);
  @$pb.TagNumber(4)
  set participantIdentity($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasParticipantIdentity() => $_has(3);
  @$pb.TagNumber(4)
  void clearParticipantIdentity() => clearField(4);

  /// identities of participants who will receive the message (sent to all by default)
  @$pb.TagNumber(5)
  $core.List<$core.String> get destinationIdentities => $_getList(4);

  @$pb.TagNumber(6)
  SipDTMF get sipDtmf => $_getN(5);
  @$pb.TagNumber(6)
  set sipDtmf(SipDTMF v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasSipDtmf() => $_has(5);
  @$pb.TagNumber(6)
  void clearSipDtmf() => clearField(6);
  @$pb.TagNumber(6)
  SipDTMF ensureSipDtmf() => $_ensure(5);

  @$pb.TagNumber(7)
  Transcription get transcription => $_getN(6);
  @$pb.TagNumber(7)
  set transcription(Transcription v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasTranscription() => $_has(6);
  @$pb.TagNumber(7)
  void clearTranscription() => clearField(7);
  @$pb.TagNumber(7)
  Transcription ensureTranscription() => $_ensure(6);

  @$pb.TagNumber(8)
  $1.MetricsBatch get metrics => $_getN(7);
  @$pb.TagNumber(8)
  set metrics($1.MetricsBatch v) {
    setField(8, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasMetrics() => $_has(7);
  @$pb.TagNumber(8)
  void clearMetrics() => clearField(8);
  @$pb.TagNumber(8)
  $1.MetricsBatch ensureMetrics() => $_ensure(7);

  @$pb.TagNumber(9)
  ChatMessage get chatMessage => $_getN(8);
  @$pb.TagNumber(9)
  set chatMessage(ChatMessage v) {
    setField(9, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasChatMessage() => $_has(8);
  @$pb.TagNumber(9)
  void clearChatMessage() => clearField(9);
  @$pb.TagNumber(9)
  ChatMessage ensureChatMessage() => $_ensure(8);

  @$pb.TagNumber(10)
  RpcRequest get rpcRequest => $_getN(9);
  @$pb.TagNumber(10)
  set rpcRequest(RpcRequest v) {
    setField(10, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasRpcRequest() => $_has(9);
  @$pb.TagNumber(10)
  void clearRpcRequest() => clearField(10);
  @$pb.TagNumber(10)
  RpcRequest ensureRpcRequest() => $_ensure(9);

  @$pb.TagNumber(11)
  RpcAck get rpcAck => $_getN(10);
  @$pb.TagNumber(11)
  set rpcAck(RpcAck v) {
    setField(11, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasRpcAck() => $_has(10);
  @$pb.TagNumber(11)
  void clearRpcAck() => clearField(11);
  @$pb.TagNumber(11)
  RpcAck ensureRpcAck() => $_ensure(10);

  @$pb.TagNumber(12)
  RpcResponse get rpcResponse => $_getN(11);
  @$pb.TagNumber(12)
  set rpcResponse(RpcResponse v) {
    setField(12, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasRpcResponse() => $_has(11);
  @$pb.TagNumber(12)
  void clearRpcResponse() => clearField(12);
  @$pb.TagNumber(12)
  RpcResponse ensureRpcResponse() => $_ensure(11);

  @$pb.TagNumber(13)
  DataStream_Header get streamHeader => $_getN(12);
  @$pb.TagNumber(13)
  set streamHeader(DataStream_Header v) {
    setField(13, v);
  }

  @$pb.TagNumber(13)
  $core.bool hasStreamHeader() => $_has(12);
  @$pb.TagNumber(13)
  void clearStreamHeader() => clearField(13);
  @$pb.TagNumber(13)
  DataStream_Header ensureStreamHeader() => $_ensure(12);

  @$pb.TagNumber(14)
  DataStream_Chunk get streamChunk => $_getN(13);
  @$pb.TagNumber(14)
  set streamChunk(DataStream_Chunk v) {
    setField(14, v);
  }

  @$pb.TagNumber(14)
  $core.bool hasStreamChunk() => $_has(13);
  @$pb.TagNumber(14)
  void clearStreamChunk() => clearField(14);
  @$pb.TagNumber(14)
  DataStream_Chunk ensureStreamChunk() => $_ensure(13);

  @$pb.TagNumber(15)
  DataStream_Trailer get streamTrailer => $_getN(14);
  @$pb.TagNumber(15)
  set streamTrailer(DataStream_Trailer v) {
    setField(15, v);
  }

  @$pb.TagNumber(15)
  $core.bool hasStreamTrailer() => $_has(14);
  @$pb.TagNumber(15)
  void clearStreamTrailer() => clearField(15);
  @$pb.TagNumber(15)
  DataStream_Trailer ensureStreamTrailer() => $_ensure(14);
}

class ActiveSpeakerUpdate extends $pb.GeneratedMessage {
  factory ActiveSpeakerUpdate({
    $core.Iterable<SpeakerInfo>? speakers,
  }) {
    final $result = create();
    if (speakers != null) {
      $result.speakers.addAll(speakers);
    }
    return $result;
  }
  ActiveSpeakerUpdate._() : super();
  factory ActiveSpeakerUpdate.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ActiveSpeakerUpdate.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ActiveSpeakerUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..pc<SpeakerInfo>(1, _omitFieldNames ? '' : 'speakers', $pb.PbFieldType.PM,
        subBuilder: SpeakerInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ActiveSpeakerUpdate clone() => ActiveSpeakerUpdate()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ActiveSpeakerUpdate copyWith(void Function(ActiveSpeakerUpdate) updates) =>
      super.copyWith((message) => updates(message as ActiveSpeakerUpdate))
          as ActiveSpeakerUpdate;

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
  factory SpeakerInfo({
    $core.String? sid,
    $core.double? level,
    $core.bool? active,
  }) {
    final $result = create();
    if (sid != null) {
      $result.sid = sid;
    }
    if (level != null) {
      $result.level = level;
    }
    if (active != null) {
      $result.active = active;
    }
    return $result;
  }
  SpeakerInfo._() : super();
  factory SpeakerInfo.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SpeakerInfo.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SpeakerInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sid')
    ..a<$core.double>(2, _omitFieldNames ? '' : 'level', $pb.PbFieldType.OF)
    ..aOB(3, _omitFieldNames ? '' : 'active')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SpeakerInfo clone() => SpeakerInfo()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SpeakerInfo copyWith(void Function(SpeakerInfo) updates) =>
      super.copyWith((message) => updates(message as SpeakerInfo))
          as SpeakerInfo;

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

  /// audio level, 0-1.0, 1 is loudest
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

  /// true if speaker is currently active
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
  factory UserPacket({
    @$core.Deprecated('This field is deprecated.') $core.String? participantSid,
    $core.List<$core.int>? payload,
    @$core.Deprecated('This field is deprecated.')
    $core.Iterable<$core.String>? destinationSids,
    $core.String? topic,
    @$core.Deprecated('This field is deprecated.')
    $core.String? participantIdentity,
    @$core.Deprecated('This field is deprecated.')
    $core.Iterable<$core.String>? destinationIdentities,
    $core.String? id,
    $fixnum.Int64? startTime,
    $fixnum.Int64? endTime,
  }) {
    final $result = create();
    if (participantSid != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.participantSid = participantSid;
    }
    if (payload != null) {
      $result.payload = payload;
    }
    if (destinationSids != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.destinationSids.addAll(destinationSids);
    }
    if (topic != null) {
      $result.topic = topic;
    }
    if (participantIdentity != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.participantIdentity = participantIdentity;
    }
    if (destinationIdentities != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.destinationIdentities.addAll(destinationIdentities);
    }
    if (id != null) {
      $result.id = id;
    }
    if (startTime != null) {
      $result.startTime = startTime;
    }
    if (endTime != null) {
      $result.endTime = endTime;
    }
    return $result;
  }
  UserPacket._() : super();
  factory UserPacket.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory UserPacket.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserPacket',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'participantSid')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'payload', $pb.PbFieldType.OY)
    ..pPS(3, _omitFieldNames ? '' : 'destinationSids')
    ..aOS(4, _omitFieldNames ? '' : 'topic')
    ..aOS(5, _omitFieldNames ? '' : 'participantIdentity')
    ..pPS(6, _omitFieldNames ? '' : 'destinationIdentities')
    ..aOS(8, _omitFieldNames ? '' : 'id')
    ..a<$fixnum.Int64>(
        9, _omitFieldNames ? '' : 'startTime', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        10, _omitFieldNames ? '' : 'endTime', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  UserPacket clone() => UserPacket()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  UserPacket copyWith(void Function(UserPacket) updates) =>
      super.copyWith((message) => updates(message as UserPacket)) as UserPacket;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserPacket create() => UserPacket._();
  UserPacket createEmptyInstance() => create();
  static $pb.PbList<UserPacket> createRepeated() => $pb.PbList<UserPacket>();
  @$core.pragma('dart2js:noInline')
  static UserPacket getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UserPacket>(create);
  static UserPacket? _defaultInstance;

  /// participant ID of user that sent the message
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(1)
  $core.String get participantSid => $_getSZ(0);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(1)
  set participantSid($core.String v) {
    $_setString(0, v);
  }

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(1)
  $core.bool hasParticipantSid() => $_has(0);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(1)
  void clearParticipantSid() => clearField(1);

  /// user defined payload
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

  /// the ID of the participants who will receive the message (sent to all by default)
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  $core.List<$core.String> get destinationSids => $_getList(2);

  /// topic under which the message was published
  @$pb.TagNumber(4)
  $core.String get topic => $_getSZ(3);
  @$pb.TagNumber(4)
  set topic($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasTopic() => $_has(3);
  @$pb.TagNumber(4)
  void clearTopic() => clearField(4);

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(5)
  $core.String get participantIdentity => $_getSZ(4);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(5)
  set participantIdentity($core.String v) {
    $_setString(4, v);
  }

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(5)
  $core.bool hasParticipantIdentity() => $_has(4);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(5)
  void clearParticipantIdentity() => clearField(5);

  /// identities of participants who will receive the message (sent to all by default)
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(6)
  $core.List<$core.String> get destinationIdentities => $_getList(5);

  /// Unique ID to indentify the message
  @$pb.TagNumber(8)
  $core.String get id => $_getSZ(6);
  @$pb.TagNumber(8)
  set id($core.String v) {
    $_setString(6, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasId() => $_has(6);
  @$pb.TagNumber(8)
  void clearId() => clearField(8);

  /// start and end time allow relating the message to specific media time
  @$pb.TagNumber(9)
  $fixnum.Int64 get startTime => $_getI64(7);
  @$pb.TagNumber(9)
  set startTime($fixnum.Int64 v) {
    $_setInt64(7, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasStartTime() => $_has(7);
  @$pb.TagNumber(9)
  void clearStartTime() => clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get endTime => $_getI64(8);
  @$pb.TagNumber(10)
  set endTime($fixnum.Int64 v) {
    $_setInt64(8, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasEndTime() => $_has(8);
  @$pb.TagNumber(10)
  void clearEndTime() => clearField(10);
}

class SipDTMF extends $pb.GeneratedMessage {
  factory SipDTMF({
    $core.int? code,
    $core.String? digit,
  }) {
    final $result = create();
    if (code != null) {
      $result.code = code;
    }
    if (digit != null) {
      $result.digit = digit;
    }
    return $result;
  }
  SipDTMF._() : super();
  factory SipDTMF.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SipDTMF.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SipDTMF',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'code', $pb.PbFieldType.OU3)
    ..aOS(4, _omitFieldNames ? '' : 'digit')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SipDTMF clone() => SipDTMF()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SipDTMF copyWith(void Function(SipDTMF) updates) =>
      super.copyWith((message) => updates(message as SipDTMF)) as SipDTMF;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SipDTMF create() => SipDTMF._();
  SipDTMF createEmptyInstance() => create();
  static $pb.PbList<SipDTMF> createRepeated() => $pb.PbList<SipDTMF>();
  @$core.pragma('dart2js:noInline')
  static SipDTMF getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SipDTMF>(create);
  static SipDTMF? _defaultInstance;

  @$pb.TagNumber(3)
  $core.int get code => $_getIZ(0);
  @$pb.TagNumber(3)
  set code($core.int v) {
    $_setUnsignedInt32(0, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(3)
  void clearCode() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get digit => $_getSZ(1);
  @$pb.TagNumber(4)
  set digit($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasDigit() => $_has(1);
  @$pb.TagNumber(4)
  void clearDigit() => clearField(4);
}

class Transcription extends $pb.GeneratedMessage {
  factory Transcription({
    $core.String? transcribedParticipantIdentity,
    $core.String? trackId,
    $core.Iterable<TranscriptionSegment>? segments,
  }) {
    final $result = create();
    if (transcribedParticipantIdentity != null) {
      $result.transcribedParticipantIdentity = transcribedParticipantIdentity;
    }
    if (trackId != null) {
      $result.trackId = trackId;
    }
    if (segments != null) {
      $result.segments.addAll(segments);
    }
    return $result;
  }
  Transcription._() : super();
  factory Transcription.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Transcription.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Transcription',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(2, _omitFieldNames ? '' : 'transcribedParticipantIdentity')
    ..aOS(3, _omitFieldNames ? '' : 'trackId')
    ..pc<TranscriptionSegment>(
        4, _omitFieldNames ? '' : 'segments', $pb.PbFieldType.PM,
        subBuilder: TranscriptionSegment.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Transcription clone() => Transcription()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Transcription copyWith(void Function(Transcription) updates) =>
      super.copyWith((message) => updates(message as Transcription))
          as Transcription;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Transcription create() => Transcription._();
  Transcription createEmptyInstance() => create();
  static $pb.PbList<Transcription> createRepeated() =>
      $pb.PbList<Transcription>();
  @$core.pragma('dart2js:noInline')
  static Transcription getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Transcription>(create);
  static Transcription? _defaultInstance;

  /// Participant that got its speech transcribed
  @$pb.TagNumber(2)
  $core.String get transcribedParticipantIdentity => $_getSZ(0);
  @$pb.TagNumber(2)
  set transcribedParticipantIdentity($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTranscribedParticipantIdentity() => $_has(0);
  @$pb.TagNumber(2)
  void clearTranscribedParticipantIdentity() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get trackId => $_getSZ(1);
  @$pb.TagNumber(3)
  set trackId($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTrackId() => $_has(1);
  @$pb.TagNumber(3)
  void clearTrackId() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<TranscriptionSegment> get segments => $_getList(2);
}

class TranscriptionSegment extends $pb.GeneratedMessage {
  factory TranscriptionSegment({
    $core.String? id,
    $core.String? text,
    $fixnum.Int64? startTime,
    $fixnum.Int64? endTime,
    $core.bool? final_5,
    $core.String? language,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (text != null) {
      $result.text = text;
    }
    if (startTime != null) {
      $result.startTime = startTime;
    }
    if (endTime != null) {
      $result.endTime = endTime;
    }
    if (final_5 != null) {
      $result.final_5 = final_5;
    }
    if (language != null) {
      $result.language = language;
    }
    return $result;
  }
  TranscriptionSegment._() : super();
  factory TranscriptionSegment.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TranscriptionSegment.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TranscriptionSegment',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'startTime', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'endTime', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(5, _omitFieldNames ? '' : 'final')
    ..aOS(6, _omitFieldNames ? '' : 'language')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TranscriptionSegment clone() =>
      TranscriptionSegment()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TranscriptionSegment copyWith(void Function(TranscriptionSegment) updates) =>
      super.copyWith((message) => updates(message as TranscriptionSegment))
          as TranscriptionSegment;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TranscriptionSegment create() => TranscriptionSegment._();
  TranscriptionSegment createEmptyInstance() => create();
  static $pb.PbList<TranscriptionSegment> createRepeated() =>
      $pb.PbList<TranscriptionSegment>();
  @$core.pragma('dart2js:noInline')
  static TranscriptionSegment getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TranscriptionSegment>(create);
  static TranscriptionSegment? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get startTime => $_getI64(2);
  @$pb.TagNumber(3)
  set startTime($fixnum.Int64 v) {
    $_setInt64(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasStartTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearStartTime() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get endTime => $_getI64(3);
  @$pb.TagNumber(4)
  set endTime($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasEndTime() => $_has(3);
  @$pb.TagNumber(4)
  void clearEndTime() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get final_5 => $_getBF(4);
  @$pb.TagNumber(5)
  set final_5($core.bool v) {
    $_setBool(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasFinal_5() => $_has(4);
  @$pb.TagNumber(5)
  void clearFinal_5() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get language => $_getSZ(5);
  @$pb.TagNumber(6)
  set language($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasLanguage() => $_has(5);
  @$pb.TagNumber(6)
  void clearLanguage() => clearField(6);
}

class ChatMessage extends $pb.GeneratedMessage {
  factory ChatMessage({
    $core.String? id,
    $fixnum.Int64? timestamp,
    $fixnum.Int64? editTimestamp,
    $core.String? message,
    $core.bool? deleted,
    $core.bool? generated,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (timestamp != null) {
      $result.timestamp = timestamp;
    }
    if (editTimestamp != null) {
      $result.editTimestamp = editTimestamp;
    }
    if (message != null) {
      $result.message = message;
    }
    if (deleted != null) {
      $result.deleted = deleted;
    }
    if (generated != null) {
      $result.generated = generated;
    }
    return $result;
  }
  ChatMessage._() : super();
  factory ChatMessage.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ChatMessage.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChatMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'timestamp')
    ..aInt64(3, _omitFieldNames ? '' : 'editTimestamp')
    ..aOS(4, _omitFieldNames ? '' : 'message')
    ..aOB(5, _omitFieldNames ? '' : 'deleted')
    ..aOB(6, _omitFieldNames ? '' : 'generated')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ChatMessage clone() => ChatMessage()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ChatMessage copyWith(void Function(ChatMessage) updates) =>
      super.copyWith((message) => updates(message as ChatMessage))
          as ChatMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChatMessage create() => ChatMessage._();
  ChatMessage createEmptyInstance() => create();
  static $pb.PbList<ChatMessage> createRepeated() => $pb.PbList<ChatMessage>();
  @$core.pragma('dart2js:noInline')
  static ChatMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChatMessage>(create);
  static ChatMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get timestamp => $_getI64(1);
  @$pb.TagNumber(2)
  set timestamp($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimestamp() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get editTimestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set editTimestamp($fixnum.Int64 v) {
    $_setInt64(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasEditTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearEditTimestamp() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get message => $_getSZ(3);
  @$pb.TagNumber(4)
  set message($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasMessage() => $_has(3);
  @$pb.TagNumber(4)
  void clearMessage() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get deleted => $_getBF(4);
  @$pb.TagNumber(5)
  set deleted($core.bool v) {
    $_setBool(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasDeleted() => $_has(4);
  @$pb.TagNumber(5)
  void clearDeleted() => clearField(5);

  @$pb.TagNumber(6)
  $core.bool get generated => $_getBF(5);
  @$pb.TagNumber(6)
  set generated($core.bool v) {
    $_setBool(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasGenerated() => $_has(5);
  @$pb.TagNumber(6)
  void clearGenerated() => clearField(6);
}

class RpcRequest extends $pb.GeneratedMessage {
  factory RpcRequest({
    $core.String? id,
    $core.String? method,
    $core.String? payload,
    $core.int? responseTimeoutMs,
    $core.int? version,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (method != null) {
      $result.method = method;
    }
    if (payload != null) {
      $result.payload = payload;
    }
    if (responseTimeoutMs != null) {
      $result.responseTimeoutMs = responseTimeoutMs;
    }
    if (version != null) {
      $result.version = version;
    }
    return $result;
  }
  RpcRequest._() : super();
  factory RpcRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RpcRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RpcRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'method')
    ..aOS(3, _omitFieldNames ? '' : 'payload')
    ..a<$core.int>(
        4, _omitFieldNames ? '' : 'responseTimeoutMs', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'version', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RpcRequest clone() => RpcRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RpcRequest copyWith(void Function(RpcRequest) updates) =>
      super.copyWith((message) => updates(message as RpcRequest)) as RpcRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RpcRequest create() => RpcRequest._();
  RpcRequest createEmptyInstance() => create();
  static $pb.PbList<RpcRequest> createRepeated() => $pb.PbList<RpcRequest>();
  @$core.pragma('dart2js:noInline')
  static RpcRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RpcRequest>(create);
  static RpcRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get method => $_getSZ(1);
  @$pb.TagNumber(2)
  set method($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMethod() => $_has(1);
  @$pb.TagNumber(2)
  void clearMethod() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get payload => $_getSZ(2);
  @$pb.TagNumber(3)
  set payload($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasPayload() => $_has(2);
  @$pb.TagNumber(3)
  void clearPayload() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get responseTimeoutMs => $_getIZ(3);
  @$pb.TagNumber(4)
  set responseTimeoutMs($core.int v) {
    $_setUnsignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasResponseTimeoutMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearResponseTimeoutMs() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get version => $_getIZ(4);
  @$pb.TagNumber(5)
  set version($core.int v) {
    $_setUnsignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasVersion() => $_has(4);
  @$pb.TagNumber(5)
  void clearVersion() => clearField(5);
}

class RpcAck extends $pb.GeneratedMessage {
  factory RpcAck({
    $core.String? requestId,
  }) {
    final $result = create();
    if (requestId != null) {
      $result.requestId = requestId;
    }
    return $result;
  }
  RpcAck._() : super();
  factory RpcAck.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RpcAck.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RpcAck',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RpcAck clone() => RpcAck()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RpcAck copyWith(void Function(RpcAck) updates) =>
      super.copyWith((message) => updates(message as RpcAck)) as RpcAck;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RpcAck create() => RpcAck._();
  RpcAck createEmptyInstance() => create();
  static $pb.PbList<RpcAck> createRepeated() => $pb.PbList<RpcAck>();
  @$core.pragma('dart2js:noInline')
  static RpcAck getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RpcAck>(create);
  static RpcAck? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get requestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => clearField(1);
}

enum RpcResponse_Value { payload, error, notSet }

class RpcResponse extends $pb.GeneratedMessage {
  factory RpcResponse({
    $core.String? requestId,
    $core.String? payload,
    RpcError? error,
  }) {
    final $result = create();
    if (requestId != null) {
      $result.requestId = requestId;
    }
    if (payload != null) {
      $result.payload = payload;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  RpcResponse._() : super();
  factory RpcResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RpcResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, RpcResponse_Value> _RpcResponse_ValueByTag =
      {
    2: RpcResponse_Value.payload,
    3: RpcResponse_Value.error,
    0: RpcResponse_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RpcResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..oo(0, [2, 3])
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..aOS(2, _omitFieldNames ? '' : 'payload')
    ..aOM<RpcError>(3, _omitFieldNames ? '' : 'error',
        subBuilder: RpcError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RpcResponse clone() => RpcResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RpcResponse copyWith(void Function(RpcResponse) updates) =>
      super.copyWith((message) => updates(message as RpcResponse))
          as RpcResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RpcResponse create() => RpcResponse._();
  RpcResponse createEmptyInstance() => create();
  static $pb.PbList<RpcResponse> createRepeated() => $pb.PbList<RpcResponse>();
  @$core.pragma('dart2js:noInline')
  static RpcResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RpcResponse>(create);
  static RpcResponse? _defaultInstance;

  RpcResponse_Value whichValue() => _RpcResponse_ValueByTag[$_whichOneof(0)]!;
  void clearValue() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get requestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get payload => $_getSZ(1);
  @$pb.TagNumber(2)
  set payload($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPayload() => $_has(1);
  @$pb.TagNumber(2)
  void clearPayload() => clearField(2);

  @$pb.TagNumber(3)
  RpcError get error => $_getN(2);
  @$pb.TagNumber(3)
  set error(RpcError v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => clearField(3);
  @$pb.TagNumber(3)
  RpcError ensureError() => $_ensure(2);
}

class RpcError extends $pb.GeneratedMessage {
  factory RpcError({
    $core.int? code,
    $core.String? message,
    $core.String? data,
  }) {
    final $result = create();
    if (code != null) {
      $result.code = code;
    }
    if (message != null) {
      $result.message = message;
    }
    if (data != null) {
      $result.data = data;
    }
    return $result;
  }
  RpcError._() : super();
  factory RpcError.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RpcError.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RpcError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'code', $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOS(3, _omitFieldNames ? '' : 'data')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RpcError clone() => RpcError()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RpcError copyWith(void Function(RpcError) updates) =>
      super.copyWith((message) => updates(message as RpcError)) as RpcError;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RpcError create() => RpcError._();
  RpcError createEmptyInstance() => create();
  static $pb.PbList<RpcError> createRepeated() => $pb.PbList<RpcError>();
  @$core.pragma('dart2js:noInline')
  static RpcError getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RpcError>(create);
  static RpcError? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get code => $_getIZ(0);
  @$pb.TagNumber(1)
  set code($core.int v) {
    $_setUnsignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get data => $_getSZ(2);
  @$pb.TagNumber(3)
  set data($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasData() => $_has(2);
  @$pb.TagNumber(3)
  void clearData() => clearField(3);
}

class ParticipantTracks extends $pb.GeneratedMessage {
  factory ParticipantTracks({
    $core.String? participantSid,
    $core.Iterable<$core.String>? trackSids,
  }) {
    final $result = create();
    if (participantSid != null) {
      $result.participantSid = participantSid;
    }
    if (trackSids != null) {
      $result.trackSids.addAll(trackSids);
    }
    return $result;
  }
  ParticipantTracks._() : super();
  factory ParticipantTracks.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ParticipantTracks.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ParticipantTracks',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'participantSid')
    ..pPS(2, _omitFieldNames ? '' : 'trackSids')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ParticipantTracks clone() => ParticipantTracks()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ParticipantTracks copyWith(void Function(ParticipantTracks) updates) =>
      super.copyWith((message) => updates(message as ParticipantTracks))
          as ParticipantTracks;

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

  /// participant ID of participant to whom the tracks belong
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

/// details about the server
class ServerInfo extends $pb.GeneratedMessage {
  factory ServerInfo({
    ServerInfo_Edition? edition,
    $core.String? version,
    $core.int? protocol,
    $core.String? region,
    $core.String? nodeId,
    $core.String? debugInfo,
    $core.int? agentProtocol,
  }) {
    final $result = create();
    if (edition != null) {
      $result.edition = edition;
    }
    if (version != null) {
      $result.version = version;
    }
    if (protocol != null) {
      $result.protocol = protocol;
    }
    if (region != null) {
      $result.region = region;
    }
    if (nodeId != null) {
      $result.nodeId = nodeId;
    }
    if (debugInfo != null) {
      $result.debugInfo = debugInfo;
    }
    if (agentProtocol != null) {
      $result.agentProtocol = agentProtocol;
    }
    return $result;
  }
  ServerInfo._() : super();
  factory ServerInfo.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ServerInfo.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServerInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..e<ServerInfo_Edition>(
        1, _omitFieldNames ? '' : 'edition', $pb.PbFieldType.OE,
        defaultOrMaker: ServerInfo_Edition.Standard,
        valueOf: ServerInfo_Edition.valueOf,
        enumValues: ServerInfo_Edition.values)
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'protocol', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'region')
    ..aOS(5, _omitFieldNames ? '' : 'nodeId')
    ..aOS(6, _omitFieldNames ? '' : 'debugInfo')
    ..a<$core.int>(
        7, _omitFieldNames ? '' : 'agentProtocol', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ServerInfo clone() => ServerInfo()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ServerInfo copyWith(void Function(ServerInfo) updates) =>
      super.copyWith((message) => updates(message as ServerInfo)) as ServerInfo;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServerInfo create() => ServerInfo._();
  ServerInfo createEmptyInstance() => create();
  static $pb.PbList<ServerInfo> createRepeated() => $pb.PbList<ServerInfo>();
  @$core.pragma('dart2js:noInline')
  static ServerInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServerInfo>(create);
  static ServerInfo? _defaultInstance;

  @$pb.TagNumber(1)
  ServerInfo_Edition get edition => $_getN(0);
  @$pb.TagNumber(1)
  set edition(ServerInfo_Edition v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasEdition() => $_has(0);
  @$pb.TagNumber(1)
  void clearEdition() => clearField(1);

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
  $core.String get region => $_getSZ(3);
  @$pb.TagNumber(4)
  set region($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasRegion() => $_has(3);
  @$pb.TagNumber(4)
  void clearRegion() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get nodeId => $_getSZ(4);
  @$pb.TagNumber(5)
  set nodeId($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasNodeId() => $_has(4);
  @$pb.TagNumber(5)
  void clearNodeId() => clearField(5);

  /// additional debugging information. sent only if server is in development mode
  @$pb.TagNumber(6)
  $core.String get debugInfo => $_getSZ(5);
  @$pb.TagNumber(6)
  set debugInfo($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasDebugInfo() => $_has(5);
  @$pb.TagNumber(6)
  void clearDebugInfo() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get agentProtocol => $_getIZ(6);
  @$pb.TagNumber(7)
  set agentProtocol($core.int v) {
    $_setSignedInt32(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasAgentProtocol() => $_has(6);
  @$pb.TagNumber(7)
  void clearAgentProtocol() => clearField(7);
}

/// details about the client
class ClientInfo extends $pb.GeneratedMessage {
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
    $core.String? network,
    $core.String? otherSdks,
  }) {
    final $result = create();
    if (sdk != null) {
      $result.sdk = sdk;
    }
    if (version != null) {
      $result.version = version;
    }
    if (protocol != null) {
      $result.protocol = protocol;
    }
    if (os != null) {
      $result.os = os;
    }
    if (osVersion != null) {
      $result.osVersion = osVersion;
    }
    if (deviceModel != null) {
      $result.deviceModel = deviceModel;
    }
    if (browser != null) {
      $result.browser = browser;
    }
    if (browserVersion != null) {
      $result.browserVersion = browserVersion;
    }
    if (address != null) {
      $result.address = address;
    }
    if (network != null) {
      $result.network = network;
    }
    if (otherSdks != null) {
      $result.otherSdks = otherSdks;
    }
    return $result;
  }
  ClientInfo._() : super();
  factory ClientInfo.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ClientInfo.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..e<ClientInfo_SDK>(1, _omitFieldNames ? '' : 'sdk', $pb.PbFieldType.OE,
        defaultOrMaker: ClientInfo_SDK.UNKNOWN,
        valueOf: ClientInfo_SDK.valueOf,
        enumValues: ClientInfo_SDK.values)
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'protocol', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'os')
    ..aOS(5, _omitFieldNames ? '' : 'osVersion')
    ..aOS(6, _omitFieldNames ? '' : 'deviceModel')
    ..aOS(7, _omitFieldNames ? '' : 'browser')
    ..aOS(8, _omitFieldNames ? '' : 'browserVersion')
    ..aOS(9, _omitFieldNames ? '' : 'address')
    ..aOS(10, _omitFieldNames ? '' : 'network')
    ..aOS(11, _omitFieldNames ? '' : 'otherSdks')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ClientInfo clone() => ClientInfo()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ClientInfo copyWith(void Function(ClientInfo) updates) =>
      super.copyWith((message) => updates(message as ClientInfo)) as ClientInfo;

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

  /// wifi, wired, cellular, vpn, empty if not known
  @$pb.TagNumber(10)
  $core.String get network => $_getSZ(9);
  @$pb.TagNumber(10)
  set network($core.String v) {
    $_setString(9, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasNetwork() => $_has(9);
  @$pb.TagNumber(10)
  void clearNetwork() => clearField(10);

  /// comma separated list of additional LiveKit SDKs in use of this client, with versions
  /// e.g. "components-js:1.2.3,track-processors-js:1.2.3"
  @$pb.TagNumber(11)
  $core.String get otherSdks => $_getSZ(10);
  @$pb.TagNumber(11)
  set otherSdks($core.String v) {
    $_setString(10, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasOtherSdks() => $_has(10);
  @$pb.TagNumber(11)
  void clearOtherSdks() => clearField(11);
}

/// server provided client configuration
class ClientConfiguration extends $pb.GeneratedMessage {
  factory ClientConfiguration({
    VideoConfiguration? video,
    VideoConfiguration? screen,
    ClientConfigSetting? resumeConnection,
    DisabledCodecs? disabledCodecs,
    ClientConfigSetting? forceRelay,
  }) {
    final $result = create();
    if (video != null) {
      $result.video = video;
    }
    if (screen != null) {
      $result.screen = screen;
    }
    if (resumeConnection != null) {
      $result.resumeConnection = resumeConnection;
    }
    if (disabledCodecs != null) {
      $result.disabledCodecs = disabledCodecs;
    }
    if (forceRelay != null) {
      $result.forceRelay = forceRelay;
    }
    return $result;
  }
  ClientConfiguration._() : super();
  factory ClientConfiguration.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ClientConfiguration.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientConfiguration',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOM<VideoConfiguration>(1, _omitFieldNames ? '' : 'video',
        subBuilder: VideoConfiguration.create)
    ..aOM<VideoConfiguration>(2, _omitFieldNames ? '' : 'screen',
        subBuilder: VideoConfiguration.create)
    ..e<ClientConfigSetting>(
        3, _omitFieldNames ? '' : 'resumeConnection', $pb.PbFieldType.OE,
        defaultOrMaker: ClientConfigSetting.UNSET,
        valueOf: ClientConfigSetting.valueOf,
        enumValues: ClientConfigSetting.values)
    ..aOM<DisabledCodecs>(4, _omitFieldNames ? '' : 'disabledCodecs',
        subBuilder: DisabledCodecs.create)
    ..e<ClientConfigSetting>(
        5, _omitFieldNames ? '' : 'forceRelay', $pb.PbFieldType.OE,
        defaultOrMaker: ClientConfigSetting.UNSET,
        valueOf: ClientConfigSetting.valueOf,
        enumValues: ClientConfigSetting.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ClientConfiguration clone() => ClientConfiguration()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ClientConfiguration copyWith(void Function(ClientConfiguration) updates) =>
      super.copyWith((message) => updates(message as ClientConfiguration))
          as ClientConfiguration;

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

  @$pb.TagNumber(4)
  DisabledCodecs get disabledCodecs => $_getN(3);
  @$pb.TagNumber(4)
  set disabledCodecs(DisabledCodecs v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasDisabledCodecs() => $_has(3);
  @$pb.TagNumber(4)
  void clearDisabledCodecs() => clearField(4);
  @$pb.TagNumber(4)
  DisabledCodecs ensureDisabledCodecs() => $_ensure(3);

  @$pb.TagNumber(5)
  ClientConfigSetting get forceRelay => $_getN(4);
  @$pb.TagNumber(5)
  set forceRelay(ClientConfigSetting v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasForceRelay() => $_has(4);
  @$pb.TagNumber(5)
  void clearForceRelay() => clearField(5);
}

class VideoConfiguration extends $pb.GeneratedMessage {
  factory VideoConfiguration({
    ClientConfigSetting? hardwareEncoder,
  }) {
    final $result = create();
    if (hardwareEncoder != null) {
      $result.hardwareEncoder = hardwareEncoder;
    }
    return $result;
  }
  VideoConfiguration._() : super();
  factory VideoConfiguration.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory VideoConfiguration.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VideoConfiguration',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..e<ClientConfigSetting>(
        1, _omitFieldNames ? '' : 'hardwareEncoder', $pb.PbFieldType.OE,
        defaultOrMaker: ClientConfigSetting.UNSET,
        valueOf: ClientConfigSetting.valueOf,
        enumValues: ClientConfigSetting.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  VideoConfiguration clone() => VideoConfiguration()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  VideoConfiguration copyWith(void Function(VideoConfiguration) updates) =>
      super.copyWith((message) => updates(message as VideoConfiguration))
          as VideoConfiguration;

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

class DisabledCodecs extends $pb.GeneratedMessage {
  factory DisabledCodecs({
    $core.Iterable<Codec>? codecs,
    $core.Iterable<Codec>? publish,
  }) {
    final $result = create();
    if (codecs != null) {
      $result.codecs.addAll(codecs);
    }
    if (publish != null) {
      $result.publish.addAll(publish);
    }
    return $result;
  }
  DisabledCodecs._() : super();
  factory DisabledCodecs.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DisabledCodecs.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DisabledCodecs',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..pc<Codec>(1, _omitFieldNames ? '' : 'codecs', $pb.PbFieldType.PM,
        subBuilder: Codec.create)
    ..pc<Codec>(2, _omitFieldNames ? '' : 'publish', $pb.PbFieldType.PM,
        subBuilder: Codec.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DisabledCodecs clone() => DisabledCodecs()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DisabledCodecs copyWith(void Function(DisabledCodecs) updates) =>
      super.copyWith((message) => updates(message as DisabledCodecs))
          as DisabledCodecs;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DisabledCodecs create() => DisabledCodecs._();
  DisabledCodecs createEmptyInstance() => create();
  static $pb.PbList<DisabledCodecs> createRepeated() =>
      $pb.PbList<DisabledCodecs>();
  @$core.pragma('dart2js:noInline')
  static DisabledCodecs getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DisabledCodecs>(create);
  static DisabledCodecs? _defaultInstance;

  /// disabled for both publish and subscribe
  @$pb.TagNumber(1)
  $core.List<Codec> get codecs => $_getList(0);

  /// only disable for publish
  @$pb.TagNumber(2)
  $core.List<Codec> get publish => $_getList(1);
}

class RTPDrift extends $pb.GeneratedMessage {
  factory RTPDrift({
    $0.Timestamp? startTime,
    $0.Timestamp? endTime,
    $core.double? duration,
    $fixnum.Int64? startTimestamp,
    $fixnum.Int64? endTimestamp,
    $fixnum.Int64? rtpClockTicks,
    $fixnum.Int64? driftSamples,
    $core.double? driftMs,
    $core.double? clockRate,
  }) {
    final $result = create();
    if (startTime != null) {
      $result.startTime = startTime;
    }
    if (endTime != null) {
      $result.endTime = endTime;
    }
    if (duration != null) {
      $result.duration = duration;
    }
    if (startTimestamp != null) {
      $result.startTimestamp = startTimestamp;
    }
    if (endTimestamp != null) {
      $result.endTimestamp = endTimestamp;
    }
    if (rtpClockTicks != null) {
      $result.rtpClockTicks = rtpClockTicks;
    }
    if (driftSamples != null) {
      $result.driftSamples = driftSamples;
    }
    if (driftMs != null) {
      $result.driftMs = driftMs;
    }
    if (clockRate != null) {
      $result.clockRate = clockRate;
    }
    return $result;
  }
  RTPDrift._() : super();
  factory RTPDrift.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RTPDrift.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RTPDrift',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOM<$0.Timestamp>(1, _omitFieldNames ? '' : 'startTime',
        subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'endTime',
        subBuilder: $0.Timestamp.create)
    ..a<$core.double>(3, _omitFieldNames ? '' : 'duration', $pb.PbFieldType.OD)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'startTimestamp', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'endTimestamp', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        6, _omitFieldNames ? '' : 'rtpClockTicks', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aInt64(7, _omitFieldNames ? '' : 'driftSamples')
    ..a<$core.double>(8, _omitFieldNames ? '' : 'driftMs', $pb.PbFieldType.OD)
    ..a<$core.double>(9, _omitFieldNames ? '' : 'clockRate', $pb.PbFieldType.OD)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RTPDrift clone() => RTPDrift()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RTPDrift copyWith(void Function(RTPDrift) updates) =>
      super.copyWith((message) => updates(message as RTPDrift)) as RTPDrift;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RTPDrift create() => RTPDrift._();
  RTPDrift createEmptyInstance() => create();
  static $pb.PbList<RTPDrift> createRepeated() => $pb.PbList<RTPDrift>();
  @$core.pragma('dart2js:noInline')
  static RTPDrift getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RTPDrift>(create);
  static RTPDrift? _defaultInstance;

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
  $fixnum.Int64 get startTimestamp => $_getI64(3);
  @$pb.TagNumber(4)
  set startTimestamp($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasStartTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearStartTimestamp() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get endTimestamp => $_getI64(4);
  @$pb.TagNumber(5)
  set endTimestamp($fixnum.Int64 v) {
    $_setInt64(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasEndTimestamp() => $_has(4);
  @$pb.TagNumber(5)
  void clearEndTimestamp() => clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get rtpClockTicks => $_getI64(5);
  @$pb.TagNumber(6)
  set rtpClockTicks($fixnum.Int64 v) {
    $_setInt64(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasRtpClockTicks() => $_has(5);
  @$pb.TagNumber(6)
  void clearRtpClockTicks() => clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get driftSamples => $_getI64(6);
  @$pb.TagNumber(7)
  set driftSamples($fixnum.Int64 v) {
    $_setInt64(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasDriftSamples() => $_has(6);
  @$pb.TagNumber(7)
  void clearDriftSamples() => clearField(7);

  @$pb.TagNumber(8)
  $core.double get driftMs => $_getN(7);
  @$pb.TagNumber(8)
  set driftMs($core.double v) {
    $_setDouble(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasDriftMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearDriftMs() => clearField(8);

  @$pb.TagNumber(9)
  $core.double get clockRate => $_getN(8);
  @$pb.TagNumber(9)
  set clockRate($core.double v) {
    $_setDouble(8, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasClockRate() => $_has(8);
  @$pb.TagNumber(9)
  void clearClockRate() => clearField(9);
}

class RTPStats extends $pb.GeneratedMessage {
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
    $core.int? nackAcks,
    $core.int? nackRepeated,
    $fixnum.Int64? headerBytes,
    $fixnum.Int64? headerBytesDuplicate,
    $fixnum.Int64? headerBytesPadding,
    RTPDrift? packetDrift,
    RTPDrift? ntpReportDrift,
    RTPDrift? rebasedReportDrift,
    RTPDrift? receivedReportDrift,
  }) {
    final $result = create();
    if (startTime != null) {
      $result.startTime = startTime;
    }
    if (endTime != null) {
      $result.endTime = endTime;
    }
    if (duration != null) {
      $result.duration = duration;
    }
    if (packets != null) {
      $result.packets = packets;
    }
    if (packetRate != null) {
      $result.packetRate = packetRate;
    }
    if (bytes != null) {
      $result.bytes = bytes;
    }
    if (bitrate != null) {
      $result.bitrate = bitrate;
    }
    if (packetsLost != null) {
      $result.packetsLost = packetsLost;
    }
    if (packetLossRate != null) {
      $result.packetLossRate = packetLossRate;
    }
    if (packetLossPercentage != null) {
      $result.packetLossPercentage = packetLossPercentage;
    }
    if (packetsDuplicate != null) {
      $result.packetsDuplicate = packetsDuplicate;
    }
    if (packetDuplicateRate != null) {
      $result.packetDuplicateRate = packetDuplicateRate;
    }
    if (bytesDuplicate != null) {
      $result.bytesDuplicate = bytesDuplicate;
    }
    if (bitrateDuplicate != null) {
      $result.bitrateDuplicate = bitrateDuplicate;
    }
    if (packetsPadding != null) {
      $result.packetsPadding = packetsPadding;
    }
    if (packetPaddingRate != null) {
      $result.packetPaddingRate = packetPaddingRate;
    }
    if (bytesPadding != null) {
      $result.bytesPadding = bytesPadding;
    }
    if (bitratePadding != null) {
      $result.bitratePadding = bitratePadding;
    }
    if (packetsOutOfOrder != null) {
      $result.packetsOutOfOrder = packetsOutOfOrder;
    }
    if (frames != null) {
      $result.frames = frames;
    }
    if (frameRate != null) {
      $result.frameRate = frameRate;
    }
    if (jitterCurrent != null) {
      $result.jitterCurrent = jitterCurrent;
    }
    if (jitterMax != null) {
      $result.jitterMax = jitterMax;
    }
    if (gapHistogram != null) {
      $result.gapHistogram.addAll(gapHistogram);
    }
    if (nacks != null) {
      $result.nacks = nacks;
    }
    if (nackMisses != null) {
      $result.nackMisses = nackMisses;
    }
    if (plis != null) {
      $result.plis = plis;
    }
    if (lastPli != null) {
      $result.lastPli = lastPli;
    }
    if (firs != null) {
      $result.firs = firs;
    }
    if (lastFir != null) {
      $result.lastFir = lastFir;
    }
    if (rttCurrent != null) {
      $result.rttCurrent = rttCurrent;
    }
    if (rttMax != null) {
      $result.rttMax = rttMax;
    }
    if (keyFrames != null) {
      $result.keyFrames = keyFrames;
    }
    if (lastKeyFrame != null) {
      $result.lastKeyFrame = lastKeyFrame;
    }
    if (layerLockPlis != null) {
      $result.layerLockPlis = layerLockPlis;
    }
    if (lastLayerLockPli != null) {
      $result.lastLayerLockPli = lastLayerLockPli;
    }
    if (nackAcks != null) {
      $result.nackAcks = nackAcks;
    }
    if (nackRepeated != null) {
      $result.nackRepeated = nackRepeated;
    }
    if (headerBytes != null) {
      $result.headerBytes = headerBytes;
    }
    if (headerBytesDuplicate != null) {
      $result.headerBytesDuplicate = headerBytesDuplicate;
    }
    if (headerBytesPadding != null) {
      $result.headerBytesPadding = headerBytesPadding;
    }
    if (packetDrift != null) {
      $result.packetDrift = packetDrift;
    }
    if (ntpReportDrift != null) {
      $result.ntpReportDrift = ntpReportDrift;
    }
    if (rebasedReportDrift != null) {
      $result.rebasedReportDrift = rebasedReportDrift;
    }
    if (receivedReportDrift != null) {
      $result.receivedReportDrift = receivedReportDrift;
    }
    return $result;
  }
  RTPStats._() : super();
  factory RTPStats.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RTPStats.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RTPStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOM<$0.Timestamp>(1, _omitFieldNames ? '' : 'startTime',
        subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'endTime',
        subBuilder: $0.Timestamp.create)
    ..a<$core.double>(3, _omitFieldNames ? '' : 'duration', $pb.PbFieldType.OD)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'packets', $pb.PbFieldType.OU3)
    ..a<$core.double>(
        5, _omitFieldNames ? '' : 'packetRate', $pb.PbFieldType.OD)
    ..a<$fixnum.Int64>(6, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.double>(7, _omitFieldNames ? '' : 'bitrate', $pb.PbFieldType.OD)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'packetsLost', $pb.PbFieldType.OU3)
    ..a<$core.double>(
        9, _omitFieldNames ? '' : 'packetLossRate', $pb.PbFieldType.OD)
    ..a<$core.double>(
        10, _omitFieldNames ? '' : 'packetLossPercentage', $pb.PbFieldType.OF)
    ..a<$core.int>(
        11, _omitFieldNames ? '' : 'packetsDuplicate', $pb.PbFieldType.OU3)
    ..a<$core.double>(
        12, _omitFieldNames ? '' : 'packetDuplicateRate', $pb.PbFieldType.OD)
    ..a<$fixnum.Int64>(
        13, _omitFieldNames ? '' : 'bytesDuplicate', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.double>(
        14, _omitFieldNames ? '' : 'bitrateDuplicate', $pb.PbFieldType.OD)
    ..a<$core.int>(
        15, _omitFieldNames ? '' : 'packetsPadding', $pb.PbFieldType.OU3)
    ..a<$core.double>(
        16, _omitFieldNames ? '' : 'packetPaddingRate', $pb.PbFieldType.OD)
    ..a<$fixnum.Int64>(
        17, _omitFieldNames ? '' : 'bytesPadding', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.double>(
        18, _omitFieldNames ? '' : 'bitratePadding', $pb.PbFieldType.OD)
    ..a<$core.int>(
        19, _omitFieldNames ? '' : 'packetsOutOfOrder', $pb.PbFieldType.OU3)
    ..a<$core.int>(20, _omitFieldNames ? '' : 'frames', $pb.PbFieldType.OU3)
    ..a<$core.double>(
        21, _omitFieldNames ? '' : 'frameRate', $pb.PbFieldType.OD)
    ..a<$core.double>(
        22, _omitFieldNames ? '' : 'jitterCurrent', $pb.PbFieldType.OD)
    ..a<$core.double>(
        23, _omitFieldNames ? '' : 'jitterMax', $pb.PbFieldType.OD)
    ..m<$core.int, $core.int>(24, _omitFieldNames ? '' : 'gapHistogram',
        entryClassName: 'RTPStats.GapHistogramEntry',
        keyFieldType: $pb.PbFieldType.O3,
        valueFieldType: $pb.PbFieldType.OU3,
        packageName: const $pb.PackageName('livekit'))
    ..a<$core.int>(25, _omitFieldNames ? '' : 'nacks', $pb.PbFieldType.OU3)
    ..a<$core.int>(26, _omitFieldNames ? '' : 'nackMisses', $pb.PbFieldType.OU3)
    ..a<$core.int>(27, _omitFieldNames ? '' : 'plis', $pb.PbFieldType.OU3)
    ..aOM<$0.Timestamp>(28, _omitFieldNames ? '' : 'lastPli',
        subBuilder: $0.Timestamp.create)
    ..a<$core.int>(29, _omitFieldNames ? '' : 'firs', $pb.PbFieldType.OU3)
    ..aOM<$0.Timestamp>(30, _omitFieldNames ? '' : 'lastFir',
        subBuilder: $0.Timestamp.create)
    ..a<$core.int>(31, _omitFieldNames ? '' : 'rttCurrent', $pb.PbFieldType.OU3)
    ..a<$core.int>(32, _omitFieldNames ? '' : 'rttMax', $pb.PbFieldType.OU3)
    ..a<$core.int>(33, _omitFieldNames ? '' : 'keyFrames', $pb.PbFieldType.OU3)
    ..aOM<$0.Timestamp>(34, _omitFieldNames ? '' : 'lastKeyFrame',
        subBuilder: $0.Timestamp.create)
    ..a<$core.int>(
        35, _omitFieldNames ? '' : 'layerLockPlis', $pb.PbFieldType.OU3)
    ..aOM<$0.Timestamp>(36, _omitFieldNames ? '' : 'lastLayerLockPli',
        subBuilder: $0.Timestamp.create)
    ..a<$core.int>(37, _omitFieldNames ? '' : 'nackAcks', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        38, _omitFieldNames ? '' : 'nackRepeated', $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        39, _omitFieldNames ? '' : 'headerBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        40, _omitFieldNames ? '' : 'headerBytesDuplicate', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        41, _omitFieldNames ? '' : 'headerBytesPadding', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<RTPDrift>(44, _omitFieldNames ? '' : 'packetDrift',
        subBuilder: RTPDrift.create)
    ..aOM<RTPDrift>(45, _omitFieldNames ? '' : 'ntpReportDrift',
        subBuilder: RTPDrift.create)
    ..aOM<RTPDrift>(46, _omitFieldNames ? '' : 'rebasedReportDrift',
        subBuilder: RTPDrift.create)
    ..aOM<RTPDrift>(47, _omitFieldNames ? '' : 'receivedReportDrift',
        subBuilder: RTPDrift.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RTPStats clone() => RTPStats()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RTPStats copyWith(void Function(RTPStats) updates) =>
      super.copyWith((message) => updates(message as RTPStats)) as RTPStats;

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

  @$pb.TagNumber(37)
  $core.int get nackAcks => $_getIZ(36);
  @$pb.TagNumber(37)
  set nackAcks($core.int v) {
    $_setUnsignedInt32(36, v);
  }

  @$pb.TagNumber(37)
  $core.bool hasNackAcks() => $_has(36);
  @$pb.TagNumber(37)
  void clearNackAcks() => clearField(37);

  @$pb.TagNumber(38)
  $core.int get nackRepeated => $_getIZ(37);
  @$pb.TagNumber(38)
  set nackRepeated($core.int v) {
    $_setUnsignedInt32(37, v);
  }

  @$pb.TagNumber(38)
  $core.bool hasNackRepeated() => $_has(37);
  @$pb.TagNumber(38)
  void clearNackRepeated() => clearField(38);

  @$pb.TagNumber(39)
  $fixnum.Int64 get headerBytes => $_getI64(38);
  @$pb.TagNumber(39)
  set headerBytes($fixnum.Int64 v) {
    $_setInt64(38, v);
  }

  @$pb.TagNumber(39)
  $core.bool hasHeaderBytes() => $_has(38);
  @$pb.TagNumber(39)
  void clearHeaderBytes() => clearField(39);

  @$pb.TagNumber(40)
  $fixnum.Int64 get headerBytesDuplicate => $_getI64(39);
  @$pb.TagNumber(40)
  set headerBytesDuplicate($fixnum.Int64 v) {
    $_setInt64(39, v);
  }

  @$pb.TagNumber(40)
  $core.bool hasHeaderBytesDuplicate() => $_has(39);
  @$pb.TagNumber(40)
  void clearHeaderBytesDuplicate() => clearField(40);

  @$pb.TagNumber(41)
  $fixnum.Int64 get headerBytesPadding => $_getI64(40);
  @$pb.TagNumber(41)
  set headerBytesPadding($fixnum.Int64 v) {
    $_setInt64(40, v);
  }

  @$pb.TagNumber(41)
  $core.bool hasHeaderBytesPadding() => $_has(40);
  @$pb.TagNumber(41)
  void clearHeaderBytesPadding() => clearField(41);

  @$pb.TagNumber(44)
  RTPDrift get packetDrift => $_getN(41);
  @$pb.TagNumber(44)
  set packetDrift(RTPDrift v) {
    setField(44, v);
  }

  @$pb.TagNumber(44)
  $core.bool hasPacketDrift() => $_has(41);
  @$pb.TagNumber(44)
  void clearPacketDrift() => clearField(44);
  @$pb.TagNumber(44)
  RTPDrift ensurePacketDrift() => $_ensure(41);

  @$pb.TagNumber(45)
  RTPDrift get ntpReportDrift => $_getN(42);
  @$pb.TagNumber(45)
  set ntpReportDrift(RTPDrift v) {
    setField(45, v);
  }

  @$pb.TagNumber(45)
  $core.bool hasNtpReportDrift() => $_has(42);
  @$pb.TagNumber(45)
  void clearNtpReportDrift() => clearField(45);
  @$pb.TagNumber(45)
  RTPDrift ensureNtpReportDrift() => $_ensure(42);

  @$pb.TagNumber(46)
  RTPDrift get rebasedReportDrift => $_getN(43);
  @$pb.TagNumber(46)
  set rebasedReportDrift(RTPDrift v) {
    setField(46, v);
  }

  @$pb.TagNumber(46)
  $core.bool hasRebasedReportDrift() => $_has(43);
  @$pb.TagNumber(46)
  void clearRebasedReportDrift() => clearField(46);
  @$pb.TagNumber(46)
  RTPDrift ensureRebasedReportDrift() => $_ensure(43);

  @$pb.TagNumber(47)
  RTPDrift get receivedReportDrift => $_getN(44);
  @$pb.TagNumber(47)
  set receivedReportDrift(RTPDrift v) {
    setField(47, v);
  }

  @$pb.TagNumber(47)
  $core.bool hasReceivedReportDrift() => $_has(44);
  @$pb.TagNumber(47)
  void clearReceivedReportDrift() => clearField(47);
  @$pb.TagNumber(47)
  RTPDrift ensureReceivedReportDrift() => $_ensure(44);
}

class RTCPSenderReportState extends $pb.GeneratedMessage {
  factory RTCPSenderReportState({
    $core.int? rtpTimestamp,
    $fixnum.Int64? rtpTimestampExt,
    $fixnum.Int64? ntpTimestamp,
    $fixnum.Int64? at,
    $fixnum.Int64? atAdjusted,
    $core.int? packets,
    $fixnum.Int64? octets,
  }) {
    final $result = create();
    if (rtpTimestamp != null) {
      $result.rtpTimestamp = rtpTimestamp;
    }
    if (rtpTimestampExt != null) {
      $result.rtpTimestampExt = rtpTimestampExt;
    }
    if (ntpTimestamp != null) {
      $result.ntpTimestamp = ntpTimestamp;
    }
    if (at != null) {
      $result.at = at;
    }
    if (atAdjusted != null) {
      $result.atAdjusted = atAdjusted;
    }
    if (packets != null) {
      $result.packets = packets;
    }
    if (octets != null) {
      $result.octets = octets;
    }
    return $result;
  }
  RTCPSenderReportState._() : super();
  factory RTCPSenderReportState.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RTCPSenderReportState.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RTCPSenderReportState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1, _omitFieldNames ? '' : 'rtpTimestamp', $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'rtpTimestampExt', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'ntpTimestamp', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aInt64(4, _omitFieldNames ? '' : 'at')
    ..aInt64(5, _omitFieldNames ? '' : 'atAdjusted')
    ..a<$core.int>(6, _omitFieldNames ? '' : 'packets', $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(7, _omitFieldNames ? '' : 'octets', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RTCPSenderReportState clone() =>
      RTCPSenderReportState()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RTCPSenderReportState copyWith(
          void Function(RTCPSenderReportState) updates) =>
      super.copyWith((message) => updates(message as RTCPSenderReportState))
          as RTCPSenderReportState;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RTCPSenderReportState create() => RTCPSenderReportState._();
  RTCPSenderReportState createEmptyInstance() => create();
  static $pb.PbList<RTCPSenderReportState> createRepeated() =>
      $pb.PbList<RTCPSenderReportState>();
  @$core.pragma('dart2js:noInline')
  static RTCPSenderReportState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RTCPSenderReportState>(create);
  static RTCPSenderReportState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get rtpTimestamp => $_getIZ(0);
  @$pb.TagNumber(1)
  set rtpTimestamp($core.int v) {
    $_setUnsignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasRtpTimestamp() => $_has(0);
  @$pb.TagNumber(1)
  void clearRtpTimestamp() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get rtpTimestampExt => $_getI64(1);
  @$pb.TagNumber(2)
  set rtpTimestampExt($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasRtpTimestampExt() => $_has(1);
  @$pb.TagNumber(2)
  void clearRtpTimestampExt() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get ntpTimestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set ntpTimestamp($fixnum.Int64 v) {
    $_setInt64(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasNtpTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearNtpTimestamp() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get at => $_getI64(3);
  @$pb.TagNumber(4)
  set at($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearAt() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get atAdjusted => $_getI64(4);
  @$pb.TagNumber(5)
  set atAdjusted($fixnum.Int64 v) {
    $_setInt64(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasAtAdjusted() => $_has(4);
  @$pb.TagNumber(5)
  void clearAtAdjusted() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get packets => $_getIZ(5);
  @$pb.TagNumber(6)
  set packets($core.int v) {
    $_setUnsignedInt32(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasPackets() => $_has(5);
  @$pb.TagNumber(6)
  void clearPackets() => clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get octets => $_getI64(6);
  @$pb.TagNumber(7)
  set octets($fixnum.Int64 v) {
    $_setInt64(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasOctets() => $_has(6);
  @$pb.TagNumber(7)
  void clearOctets() => clearField(7);
}

enum RTPForwarderState_CodecMunger { vp8Munger, notSet }

class RTPForwarderState extends $pb.GeneratedMessage {
  factory RTPForwarderState({
    $core.bool? started,
    $core.int? referenceLayerSpatial,
    $fixnum.Int64? preStartTime,
    $fixnum.Int64? extFirstTimestamp,
    $fixnum.Int64? dummyStartTimestampOffset,
    RTPMungerState? rtpMunger,
    VP8MungerState? vp8Munger,
    $core.Iterable<RTCPSenderReportState>? senderReportState,
  }) {
    final $result = create();
    if (started != null) {
      $result.started = started;
    }
    if (referenceLayerSpatial != null) {
      $result.referenceLayerSpatial = referenceLayerSpatial;
    }
    if (preStartTime != null) {
      $result.preStartTime = preStartTime;
    }
    if (extFirstTimestamp != null) {
      $result.extFirstTimestamp = extFirstTimestamp;
    }
    if (dummyStartTimestampOffset != null) {
      $result.dummyStartTimestampOffset = dummyStartTimestampOffset;
    }
    if (rtpMunger != null) {
      $result.rtpMunger = rtpMunger;
    }
    if (vp8Munger != null) {
      $result.vp8Munger = vp8Munger;
    }
    if (senderReportState != null) {
      $result.senderReportState.addAll(senderReportState);
    }
    return $result;
  }
  RTPForwarderState._() : super();
  factory RTPForwarderState.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RTPForwarderState.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, RTPForwarderState_CodecMunger>
      _RTPForwarderState_CodecMungerByTag = {
    7: RTPForwarderState_CodecMunger.vp8Munger,
    0: RTPForwarderState_CodecMunger.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RTPForwarderState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..oo(0, [7])
    ..aOB(1, _omitFieldNames ? '' : 'started')
    ..a<$core.int>(
        2, _omitFieldNames ? '' : 'referenceLayerSpatial', $pb.PbFieldType.O3)
    ..aInt64(3, _omitFieldNames ? '' : 'preStartTime')
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'extFirstTimestamp', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'dummyStartTimestampOffset',
        $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<RTPMungerState>(6, _omitFieldNames ? '' : 'rtpMunger',
        subBuilder: RTPMungerState.create)
    ..aOM<VP8MungerState>(7, _omitFieldNames ? '' : 'vp8Munger',
        subBuilder: VP8MungerState.create)
    ..pc<RTCPSenderReportState>(
        8, _omitFieldNames ? '' : 'senderReportState', $pb.PbFieldType.PM,
        subBuilder: RTCPSenderReportState.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RTPForwarderState clone() => RTPForwarderState()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RTPForwarderState copyWith(void Function(RTPForwarderState) updates) =>
      super.copyWith((message) => updates(message as RTPForwarderState))
          as RTPForwarderState;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RTPForwarderState create() => RTPForwarderState._();
  RTPForwarderState createEmptyInstance() => create();
  static $pb.PbList<RTPForwarderState> createRepeated() =>
      $pb.PbList<RTPForwarderState>();
  @$core.pragma('dart2js:noInline')
  static RTPForwarderState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RTPForwarderState>(create);
  static RTPForwarderState? _defaultInstance;

  RTPForwarderState_CodecMunger whichCodecMunger() =>
      _RTPForwarderState_CodecMungerByTag[$_whichOneof(0)]!;
  void clearCodecMunger() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.bool get started => $_getBF(0);
  @$pb.TagNumber(1)
  set started($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasStarted() => $_has(0);
  @$pb.TagNumber(1)
  void clearStarted() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get referenceLayerSpatial => $_getIZ(1);
  @$pb.TagNumber(2)
  set referenceLayerSpatial($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasReferenceLayerSpatial() => $_has(1);
  @$pb.TagNumber(2)
  void clearReferenceLayerSpatial() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get preStartTime => $_getI64(2);
  @$pb.TagNumber(3)
  set preStartTime($fixnum.Int64 v) {
    $_setInt64(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasPreStartTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearPreStartTime() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get extFirstTimestamp => $_getI64(3);
  @$pb.TagNumber(4)
  set extFirstTimestamp($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasExtFirstTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearExtFirstTimestamp() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get dummyStartTimestampOffset => $_getI64(4);
  @$pb.TagNumber(5)
  set dummyStartTimestampOffset($fixnum.Int64 v) {
    $_setInt64(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasDummyStartTimestampOffset() => $_has(4);
  @$pb.TagNumber(5)
  void clearDummyStartTimestampOffset() => clearField(5);

  @$pb.TagNumber(6)
  RTPMungerState get rtpMunger => $_getN(5);
  @$pb.TagNumber(6)
  set rtpMunger(RTPMungerState v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasRtpMunger() => $_has(5);
  @$pb.TagNumber(6)
  void clearRtpMunger() => clearField(6);
  @$pb.TagNumber(6)
  RTPMungerState ensureRtpMunger() => $_ensure(5);

  @$pb.TagNumber(7)
  VP8MungerState get vp8Munger => $_getN(6);
  @$pb.TagNumber(7)
  set vp8Munger(VP8MungerState v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasVp8Munger() => $_has(6);
  @$pb.TagNumber(7)
  void clearVp8Munger() => clearField(7);
  @$pb.TagNumber(7)
  VP8MungerState ensureVp8Munger() => $_ensure(6);

  @$pb.TagNumber(8)
  $core.List<RTCPSenderReportState> get senderReportState => $_getList(7);
}

class RTPMungerState extends $pb.GeneratedMessage {
  factory RTPMungerState({
    $fixnum.Int64? extLastSequenceNumber,
    $fixnum.Int64? extSecondLastSequenceNumber,
    $fixnum.Int64? extLastTimestamp,
    $fixnum.Int64? extSecondLastTimestamp,
    $core.bool? lastMarker,
    $core.bool? secondLastMarker,
  }) {
    final $result = create();
    if (extLastSequenceNumber != null) {
      $result.extLastSequenceNumber = extLastSequenceNumber;
    }
    if (extSecondLastSequenceNumber != null) {
      $result.extSecondLastSequenceNumber = extSecondLastSequenceNumber;
    }
    if (extLastTimestamp != null) {
      $result.extLastTimestamp = extLastTimestamp;
    }
    if (extSecondLastTimestamp != null) {
      $result.extSecondLastTimestamp = extSecondLastTimestamp;
    }
    if (lastMarker != null) {
      $result.lastMarker = lastMarker;
    }
    if (secondLastMarker != null) {
      $result.secondLastMarker = secondLastMarker;
    }
    return $result;
  }
  RTPMungerState._() : super();
  factory RTPMungerState.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RTPMungerState.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RTPMungerState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'extLastSequenceNumber', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'extSecondLastSequenceNumber',
        $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'extLastTimestamp', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'extSecondLastTimestamp', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(5, _omitFieldNames ? '' : 'lastMarker')
    ..aOB(6, _omitFieldNames ? '' : 'secondLastMarker')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RTPMungerState clone() => RTPMungerState()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RTPMungerState copyWith(void Function(RTPMungerState) updates) =>
      super.copyWith((message) => updates(message as RTPMungerState))
          as RTPMungerState;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RTPMungerState create() => RTPMungerState._();
  RTPMungerState createEmptyInstance() => create();
  static $pb.PbList<RTPMungerState> createRepeated() =>
      $pb.PbList<RTPMungerState>();
  @$core.pragma('dart2js:noInline')
  static RTPMungerState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RTPMungerState>(create);
  static RTPMungerState? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get extLastSequenceNumber => $_getI64(0);
  @$pb.TagNumber(1)
  set extLastSequenceNumber($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasExtLastSequenceNumber() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtLastSequenceNumber() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get extSecondLastSequenceNumber => $_getI64(1);
  @$pb.TagNumber(2)
  set extSecondLastSequenceNumber($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasExtSecondLastSequenceNumber() => $_has(1);
  @$pb.TagNumber(2)
  void clearExtSecondLastSequenceNumber() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get extLastTimestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set extLastTimestamp($fixnum.Int64 v) {
    $_setInt64(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasExtLastTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearExtLastTimestamp() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get extSecondLastTimestamp => $_getI64(3);
  @$pb.TagNumber(4)
  set extSecondLastTimestamp($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasExtSecondLastTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearExtSecondLastTimestamp() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get lastMarker => $_getBF(4);
  @$pb.TagNumber(5)
  set lastMarker($core.bool v) {
    $_setBool(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasLastMarker() => $_has(4);
  @$pb.TagNumber(5)
  void clearLastMarker() => clearField(5);

  @$pb.TagNumber(6)
  $core.bool get secondLastMarker => $_getBF(5);
  @$pb.TagNumber(6)
  set secondLastMarker($core.bool v) {
    $_setBool(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasSecondLastMarker() => $_has(5);
  @$pb.TagNumber(6)
  void clearSecondLastMarker() => clearField(6);
}

class VP8MungerState extends $pb.GeneratedMessage {
  factory VP8MungerState({
    $core.int? extLastPictureId,
    $core.bool? pictureIdUsed,
    $core.int? lastTl0PicIdx,
    $core.bool? tl0PicIdxUsed,
    $core.bool? tidUsed,
    $core.int? lastKeyIdx,
    $core.bool? keyIdxUsed,
  }) {
    final $result = create();
    if (extLastPictureId != null) {
      $result.extLastPictureId = extLastPictureId;
    }
    if (pictureIdUsed != null) {
      $result.pictureIdUsed = pictureIdUsed;
    }
    if (lastTl0PicIdx != null) {
      $result.lastTl0PicIdx = lastTl0PicIdx;
    }
    if (tl0PicIdxUsed != null) {
      $result.tl0PicIdxUsed = tl0PicIdxUsed;
    }
    if (tidUsed != null) {
      $result.tidUsed = tidUsed;
    }
    if (lastKeyIdx != null) {
      $result.lastKeyIdx = lastKeyIdx;
    }
    if (keyIdxUsed != null) {
      $result.keyIdxUsed = keyIdxUsed;
    }
    return $result;
  }
  VP8MungerState._() : super();
  factory VP8MungerState.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory VP8MungerState.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VP8MungerState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1, _omitFieldNames ? '' : 'extLastPictureId', $pb.PbFieldType.O3)
    ..aOB(2, _omitFieldNames ? '' : 'pictureIdUsed')
    ..a<$core.int>(
        3, _omitFieldNames ? '' : 'lastTl0PicIdx', $pb.PbFieldType.OU3)
    ..aOB(4, _omitFieldNames ? '' : 'tl0PicIdxUsed')
    ..aOB(5, _omitFieldNames ? '' : 'tidUsed')
    ..a<$core.int>(6, _omitFieldNames ? '' : 'lastKeyIdx', $pb.PbFieldType.OU3)
    ..aOB(7, _omitFieldNames ? '' : 'keyIdxUsed')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  VP8MungerState clone() => VP8MungerState()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  VP8MungerState copyWith(void Function(VP8MungerState) updates) =>
      super.copyWith((message) => updates(message as VP8MungerState))
          as VP8MungerState;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VP8MungerState create() => VP8MungerState._();
  VP8MungerState createEmptyInstance() => create();
  static $pb.PbList<VP8MungerState> createRepeated() =>
      $pb.PbList<VP8MungerState>();
  @$core.pragma('dart2js:noInline')
  static VP8MungerState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VP8MungerState>(create);
  static VP8MungerState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get extLastPictureId => $_getIZ(0);
  @$pb.TagNumber(1)
  set extLastPictureId($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasExtLastPictureId() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtLastPictureId() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get pictureIdUsed => $_getBF(1);
  @$pb.TagNumber(2)
  set pictureIdUsed($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPictureIdUsed() => $_has(1);
  @$pb.TagNumber(2)
  void clearPictureIdUsed() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get lastTl0PicIdx => $_getIZ(2);
  @$pb.TagNumber(3)
  set lastTl0PicIdx($core.int v) {
    $_setUnsignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasLastTl0PicIdx() => $_has(2);
  @$pb.TagNumber(3)
  void clearLastTl0PicIdx() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get tl0PicIdxUsed => $_getBF(3);
  @$pb.TagNumber(4)
  set tl0PicIdxUsed($core.bool v) {
    $_setBool(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasTl0PicIdxUsed() => $_has(3);
  @$pb.TagNumber(4)
  void clearTl0PicIdxUsed() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get tidUsed => $_getBF(4);
  @$pb.TagNumber(5)
  set tidUsed($core.bool v) {
    $_setBool(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasTidUsed() => $_has(4);
  @$pb.TagNumber(5)
  void clearTidUsed() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get lastKeyIdx => $_getIZ(5);
  @$pb.TagNumber(6)
  set lastKeyIdx($core.int v) {
    $_setUnsignedInt32(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasLastKeyIdx() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastKeyIdx() => clearField(6);

  @$pb.TagNumber(7)
  $core.bool get keyIdxUsed => $_getBF(6);
  @$pb.TagNumber(7)
  set keyIdxUsed($core.bool v) {
    $_setBool(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasKeyIdxUsed() => $_has(6);
  @$pb.TagNumber(7)
  void clearKeyIdxUsed() => clearField(7);
}

class TimedVersion extends $pb.GeneratedMessage {
  factory TimedVersion({
    $fixnum.Int64? unixMicro,
    $core.int? ticks,
  }) {
    final $result = create();
    if (unixMicro != null) {
      $result.unixMicro = unixMicro;
    }
    if (ticks != null) {
      $result.ticks = ticks;
    }
    return $result;
  }
  TimedVersion._() : super();
  factory TimedVersion.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TimedVersion.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TimedVersion',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'unixMicro')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'ticks', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TimedVersion clone() => TimedVersion()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TimedVersion copyWith(void Function(TimedVersion) updates) =>
      super.copyWith((message) => updates(message as TimedVersion))
          as TimedVersion;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TimedVersion create() => TimedVersion._();
  TimedVersion createEmptyInstance() => create();
  static $pb.PbList<TimedVersion> createRepeated() =>
      $pb.PbList<TimedVersion>();
  @$core.pragma('dart2js:noInline')
  static TimedVersion getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TimedVersion>(create);
  static TimedVersion? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get unixMicro => $_getI64(0);
  @$pb.TagNumber(1)
  set unixMicro($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasUnixMicro() => $_has(0);
  @$pb.TagNumber(1)
  void clearUnixMicro() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get ticks => $_getIZ(1);
  @$pb.TagNumber(2)
  set ticks($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTicks() => $_has(1);
  @$pb.TagNumber(2)
  void clearTicks() => clearField(2);
}

/// header properties specific to text streams
class DataStream_TextHeader extends $pb.GeneratedMessage {
  factory DataStream_TextHeader({
    DataStream_OperationType? operationType,
    $core.int? version,
    $core.String? replyToStreamId,
    $core.Iterable<$core.String>? attachedStreamIds,
    $core.bool? generated,
  }) {
    final $result = create();
    if (operationType != null) {
      $result.operationType = operationType;
    }
    if (version != null) {
      $result.version = version;
    }
    if (replyToStreamId != null) {
      $result.replyToStreamId = replyToStreamId;
    }
    if (attachedStreamIds != null) {
      $result.attachedStreamIds.addAll(attachedStreamIds);
    }
    if (generated != null) {
      $result.generated = generated;
    }
    return $result;
  }
  DataStream_TextHeader._() : super();
  factory DataStream_TextHeader.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DataStream_TextHeader.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DataStream.TextHeader',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..e<DataStream_OperationType>(
        1, _omitFieldNames ? '' : 'operationType', $pb.PbFieldType.OE,
        defaultOrMaker: DataStream_OperationType.CREATE,
        valueOf: DataStream_OperationType.valueOf,
        enumValues: DataStream_OperationType.values)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'version', $pb.PbFieldType.O3)
    ..aOS(3, _omitFieldNames ? '' : 'replyToStreamId')
    ..pPS(4, _omitFieldNames ? '' : 'attachedStreamIds')
    ..aOB(5, _omitFieldNames ? '' : 'generated')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DataStream_TextHeader clone() =>
      DataStream_TextHeader()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DataStream_TextHeader copyWith(
          void Function(DataStream_TextHeader) updates) =>
      super.copyWith((message) => updates(message as DataStream_TextHeader))
          as DataStream_TextHeader;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DataStream_TextHeader create() => DataStream_TextHeader._();
  DataStream_TextHeader createEmptyInstance() => create();
  static $pb.PbList<DataStream_TextHeader> createRepeated() =>
      $pb.PbList<DataStream_TextHeader>();
  @$core.pragma('dart2js:noInline')
  static DataStream_TextHeader getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DataStream_TextHeader>(create);
  static DataStream_TextHeader? _defaultInstance;

  @$pb.TagNumber(1)
  DataStream_OperationType get operationType => $_getN(0);
  @$pb.TagNumber(1)
  set operationType(DataStream_OperationType v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasOperationType() => $_has(0);
  @$pb.TagNumber(1)
  void clearOperationType() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get version => $_getIZ(1);
  @$pb.TagNumber(2)
  set version($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get replyToStreamId => $_getSZ(2);
  @$pb.TagNumber(3)
  set replyToStreamId($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasReplyToStreamId() => $_has(2);
  @$pb.TagNumber(3)
  void clearReplyToStreamId() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.String> get attachedStreamIds => $_getList(3);

  @$pb.TagNumber(5)
  $core.bool get generated => $_getBF(4);
  @$pb.TagNumber(5)
  set generated($core.bool v) {
    $_setBool(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasGenerated() => $_has(4);
  @$pb.TagNumber(5)
  void clearGenerated() => clearField(5);
}

/// header properties specific to file or image streams
class DataStream_FileHeader extends $pb.GeneratedMessage {
  factory DataStream_FileHeader({
    $core.String? fileName,
  }) {
    final $result = create();
    if (fileName != null) {
      $result.fileName = fileName;
    }
    return $result;
  }
  DataStream_FileHeader._() : super();
  factory DataStream_FileHeader.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DataStream_FileHeader.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DataStream.FileHeader',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'fileName')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DataStream_FileHeader clone() =>
      DataStream_FileHeader()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DataStream_FileHeader copyWith(
          void Function(DataStream_FileHeader) updates) =>
      super.copyWith((message) => updates(message as DataStream_FileHeader))
          as DataStream_FileHeader;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DataStream_FileHeader create() => DataStream_FileHeader._();
  DataStream_FileHeader createEmptyInstance() => create();
  static $pb.PbList<DataStream_FileHeader> createRepeated() =>
      $pb.PbList<DataStream_FileHeader>();
  @$core.pragma('dart2js:noInline')
  static DataStream_FileHeader getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DataStream_FileHeader>(create);
  static DataStream_FileHeader? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fileName => $_getSZ(0);
  @$pb.TagNumber(1)
  set fileName($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasFileName() => $_has(0);
  @$pb.TagNumber(1)
  void clearFileName() => clearField(1);
}

enum DataStream_Header_ContentHeader { textHeader, fileHeader, notSet }

/// main DataStream.Header that contains a oneof for specific headers
class DataStream_Header extends $pb.GeneratedMessage {
  factory DataStream_Header({
    $core.String? streamId,
    $fixnum.Int64? timestamp,
    $core.String? topic,
    $core.String? mimeType,
    $fixnum.Int64? totalLength,
    Encryption_Type? encryptionType,
    $core.Map<$core.String, $core.String>? extensions,
    DataStream_TextHeader? textHeader,
    DataStream_FileHeader? fileHeader,
  }) {
    final $result = create();
    if (streamId != null) {
      $result.streamId = streamId;
    }
    if (timestamp != null) {
      $result.timestamp = timestamp;
    }
    if (topic != null) {
      $result.topic = topic;
    }
    if (mimeType != null) {
      $result.mimeType = mimeType;
    }
    if (totalLength != null) {
      $result.totalLength = totalLength;
    }
    if (encryptionType != null) {
      $result.encryptionType = encryptionType;
    }
    if (extensions != null) {
      $result.extensions.addAll(extensions);
    }
    if (textHeader != null) {
      $result.textHeader = textHeader;
    }
    if (fileHeader != null) {
      $result.fileHeader = fileHeader;
    }
    return $result;
  }
  DataStream_Header._() : super();
  factory DataStream_Header.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DataStream_Header.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, DataStream_Header_ContentHeader>
      _DataStream_Header_ContentHeaderByTag = {
    9: DataStream_Header_ContentHeader.textHeader,
    10: DataStream_Header_ContentHeader.fileHeader,
    0: DataStream_Header_ContentHeader.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DataStream.Header',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..oo(0, [9, 10])
    ..aOS(1, _omitFieldNames ? '' : 'streamId')
    ..aInt64(2, _omitFieldNames ? '' : 'timestamp')
    ..aOS(3, _omitFieldNames ? '' : 'topic')
    ..aOS(4, _omitFieldNames ? '' : 'mimeType')
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'totalLength', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..e<Encryption_Type>(
        7, _omitFieldNames ? '' : 'encryptionType', $pb.PbFieldType.OE,
        defaultOrMaker: Encryption_Type.NONE,
        valueOf: Encryption_Type.valueOf,
        enumValues: Encryption_Type.values)
    ..m<$core.String, $core.String>(8, _omitFieldNames ? '' : 'extensions',
        entryClassName: 'DataStream.Header.ExtensionsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('livekit'))
    ..aOM<DataStream_TextHeader>(9, _omitFieldNames ? '' : 'textHeader',
        subBuilder: DataStream_TextHeader.create)
    ..aOM<DataStream_FileHeader>(10, _omitFieldNames ? '' : 'fileHeader',
        subBuilder: DataStream_FileHeader.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DataStream_Header clone() => DataStream_Header()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DataStream_Header copyWith(void Function(DataStream_Header) updates) =>
      super.copyWith((message) => updates(message as DataStream_Header))
          as DataStream_Header;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DataStream_Header create() => DataStream_Header._();
  DataStream_Header createEmptyInstance() => create();
  static $pb.PbList<DataStream_Header> createRepeated() =>
      $pb.PbList<DataStream_Header>();
  @$core.pragma('dart2js:noInline')
  static DataStream_Header getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DataStream_Header>(create);
  static DataStream_Header? _defaultInstance;

  DataStream_Header_ContentHeader whichContentHeader() =>
      _DataStream_Header_ContentHeaderByTag[$_whichOneof(0)]!;
  void clearContentHeader() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get streamId => $_getSZ(0);
  @$pb.TagNumber(1)
  set streamId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasStreamId() => $_has(0);
  @$pb.TagNumber(1)
  void clearStreamId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get timestamp => $_getI64(1);
  @$pb.TagNumber(2)
  set timestamp($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimestamp() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get topic => $_getSZ(2);
  @$pb.TagNumber(3)
  set topic($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTopic() => $_has(2);
  @$pb.TagNumber(3)
  void clearTopic() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get mimeType => $_getSZ(3);
  @$pb.TagNumber(4)
  set mimeType($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasMimeType() => $_has(3);
  @$pb.TagNumber(4)
  void clearMimeType() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get totalLength => $_getI64(4);
  @$pb.TagNumber(5)
  set totalLength($fixnum.Int64 v) {
    $_setInt64(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasTotalLength() => $_has(4);
  @$pb.TagNumber(5)
  void clearTotalLength() => clearField(5);

  @$pb.TagNumber(7)
  Encryption_Type get encryptionType => $_getN(5);
  @$pb.TagNumber(7)
  set encryptionType(Encryption_Type v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasEncryptionType() => $_has(5);
  @$pb.TagNumber(7)
  void clearEncryptionType() => clearField(7);

  @$pb.TagNumber(8)
  $core.Map<$core.String, $core.String> get extensions => $_getMap(6);

  @$pb.TagNumber(9)
  DataStream_TextHeader get textHeader => $_getN(7);
  @$pb.TagNumber(9)
  set textHeader(DataStream_TextHeader v) {
    setField(9, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasTextHeader() => $_has(7);
  @$pb.TagNumber(9)
  void clearTextHeader() => clearField(9);
  @$pb.TagNumber(9)
  DataStream_TextHeader ensureTextHeader() => $_ensure(7);

  @$pb.TagNumber(10)
  DataStream_FileHeader get fileHeader => $_getN(8);
  @$pb.TagNumber(10)
  set fileHeader(DataStream_FileHeader v) {
    setField(10, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasFileHeader() => $_has(8);
  @$pb.TagNumber(10)
  void clearFileHeader() => clearField(10);
  @$pb.TagNumber(10)
  DataStream_FileHeader ensureFileHeader() => $_ensure(8);
}

class DataStream_Chunk extends $pb.GeneratedMessage {
  factory DataStream_Chunk({
    $core.String? streamId,
    $fixnum.Int64? chunkIndex,
    $core.List<$core.int>? content,
    $core.int? version,
    $core.List<$core.int>? iv,
  }) {
    final $result = create();
    if (streamId != null) {
      $result.streamId = streamId;
    }
    if (chunkIndex != null) {
      $result.chunkIndex = chunkIndex;
    }
    if (content != null) {
      $result.content = content;
    }
    if (version != null) {
      $result.version = version;
    }
    if (iv != null) {
      $result.iv = iv;
    }
    return $result;
  }
  DataStream_Chunk._() : super();
  factory DataStream_Chunk.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DataStream_Chunk.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DataStream.Chunk',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'streamId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'chunkIndex', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'content', $pb.PbFieldType.OY)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'version', $pb.PbFieldType.O3)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'iv', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DataStream_Chunk clone() => DataStream_Chunk()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DataStream_Chunk copyWith(void Function(DataStream_Chunk) updates) =>
      super.copyWith((message) => updates(message as DataStream_Chunk))
          as DataStream_Chunk;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DataStream_Chunk create() => DataStream_Chunk._();
  DataStream_Chunk createEmptyInstance() => create();
  static $pb.PbList<DataStream_Chunk> createRepeated() =>
      $pb.PbList<DataStream_Chunk>();
  @$core.pragma('dart2js:noInline')
  static DataStream_Chunk getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DataStream_Chunk>(create);
  static DataStream_Chunk? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get streamId => $_getSZ(0);
  @$pb.TagNumber(1)
  set streamId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasStreamId() => $_has(0);
  @$pb.TagNumber(1)
  void clearStreamId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get chunkIndex => $_getI64(1);
  @$pb.TagNumber(2)
  set chunkIndex($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasChunkIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearChunkIndex() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get content => $_getN(2);
  @$pb.TagNumber(3)
  set content($core.List<$core.int> v) {
    $_setBytes(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasContent() => $_has(2);
  @$pb.TagNumber(3)
  void clearContent() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get version => $_getIZ(3);
  @$pb.TagNumber(4)
  set version($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearVersion() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get iv => $_getN(4);
  @$pb.TagNumber(5)
  set iv($core.List<$core.int> v) {
    $_setBytes(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasIv() => $_has(4);
  @$pb.TagNumber(5)
  void clearIv() => clearField(5);
}

class DataStream_Trailer extends $pb.GeneratedMessage {
  factory DataStream_Trailer({
    $core.String? streamId,
    $core.String? reason,
    $core.Map<$core.String, $core.String>? extensions,
  }) {
    final $result = create();
    if (streamId != null) {
      $result.streamId = streamId;
    }
    if (reason != null) {
      $result.reason = reason;
    }
    if (extensions != null) {
      $result.extensions.addAll(extensions);
    }
    return $result;
  }
  DataStream_Trailer._() : super();
  factory DataStream_Trailer.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DataStream_Trailer.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DataStream.Trailer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'streamId')
    ..aOS(2, _omitFieldNames ? '' : 'reason')
    ..m<$core.String, $core.String>(3, _omitFieldNames ? '' : 'extensions',
        entryClassName: 'DataStream.Trailer.ExtensionsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('livekit'))
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DataStream_Trailer clone() => DataStream_Trailer()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DataStream_Trailer copyWith(void Function(DataStream_Trailer) updates) =>
      super.copyWith((message) => updates(message as DataStream_Trailer))
          as DataStream_Trailer;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DataStream_Trailer create() => DataStream_Trailer._();
  DataStream_Trailer createEmptyInstance() => create();
  static $pb.PbList<DataStream_Trailer> createRepeated() =>
      $pb.PbList<DataStream_Trailer>();
  @$core.pragma('dart2js:noInline')
  static DataStream_Trailer getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DataStream_Trailer>(create);
  static DataStream_Trailer? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get streamId => $_getSZ(0);
  @$pb.TagNumber(1)
  set streamId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasStreamId() => $_has(0);
  @$pb.TagNumber(1)
  void clearStreamId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get reason => $_getSZ(1);
  @$pb.TagNumber(2)
  set reason($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasReason() => $_has(1);
  @$pb.TagNumber(2)
  void clearReason() => clearField(2);

  @$pb.TagNumber(3)
  $core.Map<$core.String, $core.String> get extensions => $_getMap(2);
}

class DataStream extends $pb.GeneratedMessage {
  factory DataStream() => create();
  DataStream._() : super();
  factory DataStream.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DataStream.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DataStream',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DataStream clone() => DataStream()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DataStream copyWith(void Function(DataStream) updates) =>
      super.copyWith((message) => updates(message as DataStream)) as DataStream;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DataStream create() => DataStream._();
  DataStream createEmptyInstance() => create();
  static $pb.PbList<DataStream> createRepeated() => $pb.PbList<DataStream>();
  @$core.pragma('dart2js:noInline')
  static DataStream getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DataStream>(create);
  static DataStream? _defaultInstance;
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
