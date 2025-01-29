//
//  Generated code. Do not modify.
//  source: livekit_metrics.proto
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

export 'livekit_metrics.pbenum.dart';

class MetricsBatch extends $pb.GeneratedMessage {
  factory MetricsBatch({
    $fixnum.Int64? timestampMs,
    $0.Timestamp? normalizedTimestamp,
    $core.Iterable<$core.String>? strData,
    $core.Iterable<TimeSeriesMetric>? timeSeries,
    $core.Iterable<EventMetric>? events,
  }) {
    final $result = create();
    if (timestampMs != null) {
      $result.timestampMs = timestampMs;
    }
    if (normalizedTimestamp != null) {
      $result.normalizedTimestamp = normalizedTimestamp;
    }
    if (strData != null) {
      $result.strData.addAll(strData);
    }
    if (timeSeries != null) {
      $result.timeSeries.addAll(timeSeries);
    }
    if (events != null) {
      $result.events.addAll(events);
    }
    return $result;
  }
  MetricsBatch._() : super();
  factory MetricsBatch.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory MetricsBatch.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MetricsBatch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'timestampMs')
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'normalizedTimestamp',
        subBuilder: $0.Timestamp.create)
    ..pPS(3, _omitFieldNames ? '' : 'strData')
    ..pc<TimeSeriesMetric>(
        4, _omitFieldNames ? '' : 'timeSeries', $pb.PbFieldType.PM,
        subBuilder: TimeSeriesMetric.create)
    ..pc<EventMetric>(5, _omitFieldNames ? '' : 'events', $pb.PbFieldType.PM,
        subBuilder: EventMetric.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  MetricsBatch clone() => MetricsBatch()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  MetricsBatch copyWith(void Function(MetricsBatch) updates) =>
      super.copyWith((message) => updates(message as MetricsBatch))
          as MetricsBatch;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MetricsBatch create() => MetricsBatch._();
  MetricsBatch createEmptyInstance() => create();
  static $pb.PbList<MetricsBatch> createRepeated() =>
      $pb.PbList<MetricsBatch>();
  @$core.pragma('dart2js:noInline')
  static MetricsBatch getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MetricsBatch>(create);
  static MetricsBatch? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestampMs => $_getI64(0);
  @$pb.TagNumber(1)
  set timestampMs($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTimestampMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestampMs() => clearField(1);

  @$pb.TagNumber(2)
  $0.Timestamp get normalizedTimestamp => $_getN(1);
  @$pb.TagNumber(2)
  set normalizedTimestamp($0.Timestamp v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasNormalizedTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearNormalizedTimestamp() => clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureNormalizedTimestamp() => $_ensure(1);

  /// To avoid repeating string values, we store them in a separate list and reference them by index
  /// This is useful for storing participant identities, track names, etc.
  /// There is also a predefined list of labels that can be used to reference common metrics.
  /// They have reserved indices from 0 to (METRIC_LABEL_PREDEFINED_MAX_VALUE - 1).
  /// Indexes pointing at str_data should start from METRIC_LABEL_PREDEFINED_MAX_VALUE,
  /// such that str_data[0] == index of METRIC_LABEL_PREDEFINED_MAX_VALUE.
  @$pb.TagNumber(3)
  $core.List<$core.String> get strData => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<TimeSeriesMetric> get timeSeries => $_getList(3);

  @$pb.TagNumber(5)
  $core.List<EventMetric> get events => $_getList(4);
}

class TimeSeriesMetric extends $pb.GeneratedMessage {
  factory TimeSeriesMetric({
    $core.int? label,
    $core.int? participantIdentity,
    $core.int? trackSid,
    $core.Iterable<MetricSample>? samples,
    $core.int? rid,
  }) {
    final $result = create();
    if (label != null) {
      $result.label = label;
    }
    if (participantIdentity != null) {
      $result.participantIdentity = participantIdentity;
    }
    if (trackSid != null) {
      $result.trackSid = trackSid;
    }
    if (samples != null) {
      $result.samples.addAll(samples);
    }
    if (rid != null) {
      $result.rid = rid;
    }
    return $result;
  }
  TimeSeriesMetric._() : super();
  factory TimeSeriesMetric.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TimeSeriesMetric.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TimeSeriesMetric',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'label', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        2, _omitFieldNames ? '' : 'participantIdentity', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'trackSid', $pb.PbFieldType.OU3)
    ..pc<MetricSample>(4, _omitFieldNames ? '' : 'samples', $pb.PbFieldType.PM,
        subBuilder: MetricSample.create)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'rid', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TimeSeriesMetric clone() => TimeSeriesMetric()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TimeSeriesMetric copyWith(void Function(TimeSeriesMetric) updates) =>
      super.copyWith((message) => updates(message as TimeSeriesMetric))
          as TimeSeriesMetric;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TimeSeriesMetric create() => TimeSeriesMetric._();
  TimeSeriesMetric createEmptyInstance() => create();
  static $pb.PbList<TimeSeriesMetric> createRepeated() =>
      $pb.PbList<TimeSeriesMetric>();
  @$core.pragma('dart2js:noInline')
  static TimeSeriesMetric getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TimeSeriesMetric>(create);
  static TimeSeriesMetric? _defaultInstance;

  /// Metric name e.g "speech_probablity". The string value is not directly stored in the message, but referenced by index
  /// in the `str_data` field of `MetricsBatch`
  @$pb.TagNumber(1)
  $core.int get label => $_getIZ(0);
  @$pb.TagNumber(1)
  set label($core.int v) {
    $_setUnsignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get participantIdentity => $_getIZ(1);
  @$pb.TagNumber(2)
  set participantIdentity($core.int v) {
    $_setUnsignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasParticipantIdentity() => $_has(1);
  @$pb.TagNumber(2)
  void clearParticipantIdentity() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get trackSid => $_getIZ(2);
  @$pb.TagNumber(3)
  set trackSid($core.int v) {
    $_setUnsignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTrackSid() => $_has(2);
  @$pb.TagNumber(3)
  void clearTrackSid() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<MetricSample> get samples => $_getList(3);

  @$pb.TagNumber(5)
  $core.int get rid => $_getIZ(4);
  @$pb.TagNumber(5)
  set rid($core.int v) {
    $_setUnsignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasRid() => $_has(4);
  @$pb.TagNumber(5)
  void clearRid() => clearField(5);
}

class MetricSample extends $pb.GeneratedMessage {
  factory MetricSample({
    $fixnum.Int64? timestampMs,
    $0.Timestamp? normalizedTimestamp,
    $core.double? value,
  }) {
    final $result = create();
    if (timestampMs != null) {
      $result.timestampMs = timestampMs;
    }
    if (normalizedTimestamp != null) {
      $result.normalizedTimestamp = normalizedTimestamp;
    }
    if (value != null) {
      $result.value = value;
    }
    return $result;
  }
  MetricSample._() : super();
  factory MetricSample.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory MetricSample.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MetricSample',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'timestampMs')
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'normalizedTimestamp',
        subBuilder: $0.Timestamp.create)
    ..a<$core.double>(3, _omitFieldNames ? '' : 'value', $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  MetricSample clone() => MetricSample()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  MetricSample copyWith(void Function(MetricSample) updates) =>
      super.copyWith((message) => updates(message as MetricSample))
          as MetricSample;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MetricSample create() => MetricSample._();
  MetricSample createEmptyInstance() => create();
  static $pb.PbList<MetricSample> createRepeated() =>
      $pb.PbList<MetricSample>();
  @$core.pragma('dart2js:noInline')
  static MetricSample getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MetricSample>(create);
  static MetricSample? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestampMs => $_getI64(0);
  @$pb.TagNumber(1)
  set timestampMs($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTimestampMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestampMs() => clearField(1);

  @$pb.TagNumber(2)
  $0.Timestamp get normalizedTimestamp => $_getN(1);
  @$pb.TagNumber(2)
  set normalizedTimestamp($0.Timestamp v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasNormalizedTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearNormalizedTimestamp() => clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureNormalizedTimestamp() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.double get value => $_getN(2);
  @$pb.TagNumber(3)
  set value($core.double v) {
    $_setFloat(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearValue() => clearField(3);
}

class EventMetric extends $pb.GeneratedMessage {
  factory EventMetric({
    $core.int? label,
    $core.int? participantIdentity,
    $core.int? trackSid,
    $fixnum.Int64? startTimestampMs,
    $fixnum.Int64? endTimestampMs,
    $0.Timestamp? normalizedStartTimestamp,
    $0.Timestamp? normalizedEndTimestamp,
    $core.String? metadata,
    $core.int? rid,
  }) {
    final $result = create();
    if (label != null) {
      $result.label = label;
    }
    if (participantIdentity != null) {
      $result.participantIdentity = participantIdentity;
    }
    if (trackSid != null) {
      $result.trackSid = trackSid;
    }
    if (startTimestampMs != null) {
      $result.startTimestampMs = startTimestampMs;
    }
    if (endTimestampMs != null) {
      $result.endTimestampMs = endTimestampMs;
    }
    if (normalizedStartTimestamp != null) {
      $result.normalizedStartTimestamp = normalizedStartTimestamp;
    }
    if (normalizedEndTimestamp != null) {
      $result.normalizedEndTimestamp = normalizedEndTimestamp;
    }
    if (metadata != null) {
      $result.metadata = metadata;
    }
    if (rid != null) {
      $result.rid = rid;
    }
    return $result;
  }
  EventMetric._() : super();
  factory EventMetric.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory EventMetric.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EventMetric',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'label', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        2, _omitFieldNames ? '' : 'participantIdentity', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'trackSid', $pb.PbFieldType.OU3)
    ..aInt64(4, _omitFieldNames ? '' : 'startTimestampMs')
    ..aInt64(5, _omitFieldNames ? '' : 'endTimestampMs')
    ..aOM<$0.Timestamp>(6, _omitFieldNames ? '' : 'normalizedStartTimestamp',
        subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(7, _omitFieldNames ? '' : 'normalizedEndTimestamp',
        subBuilder: $0.Timestamp.create)
    ..aOS(8, _omitFieldNames ? '' : 'metadata')
    ..a<$core.int>(9, _omitFieldNames ? '' : 'rid', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  EventMetric clone() => EventMetric()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  EventMetric copyWith(void Function(EventMetric) updates) =>
      super.copyWith((message) => updates(message as EventMetric))
          as EventMetric;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EventMetric create() => EventMetric._();
  EventMetric createEmptyInstance() => create();
  static $pb.PbList<EventMetric> createRepeated() => $pb.PbList<EventMetric>();
  @$core.pragma('dart2js:noInline')
  static EventMetric getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EventMetric>(create);
  static EventMetric? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get label => $_getIZ(0);
  @$pb.TagNumber(1)
  set label($core.int v) {
    $_setUnsignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get participantIdentity => $_getIZ(1);
  @$pb.TagNumber(2)
  set participantIdentity($core.int v) {
    $_setUnsignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasParticipantIdentity() => $_has(1);
  @$pb.TagNumber(2)
  void clearParticipantIdentity() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get trackSid => $_getIZ(2);
  @$pb.TagNumber(3)
  set trackSid($core.int v) {
    $_setUnsignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTrackSid() => $_has(2);
  @$pb.TagNumber(3)
  void clearTrackSid() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get startTimestampMs => $_getI64(3);
  @$pb.TagNumber(4)
  set startTimestampMs($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasStartTimestampMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearStartTimestampMs() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get endTimestampMs => $_getI64(4);
  @$pb.TagNumber(5)
  set endTimestampMs($fixnum.Int64 v) {
    $_setInt64(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasEndTimestampMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearEndTimestampMs() => clearField(5);

  @$pb.TagNumber(6)
  $0.Timestamp get normalizedStartTimestamp => $_getN(5);
  @$pb.TagNumber(6)
  set normalizedStartTimestamp($0.Timestamp v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasNormalizedStartTimestamp() => $_has(5);
  @$pb.TagNumber(6)
  void clearNormalizedStartTimestamp() => clearField(6);
  @$pb.TagNumber(6)
  $0.Timestamp ensureNormalizedStartTimestamp() => $_ensure(5);

  @$pb.TagNumber(7)
  $0.Timestamp get normalizedEndTimestamp => $_getN(6);
  @$pb.TagNumber(7)
  set normalizedEndTimestamp($0.Timestamp v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasNormalizedEndTimestamp() => $_has(6);
  @$pb.TagNumber(7)
  void clearNormalizedEndTimestamp() => clearField(7);
  @$pb.TagNumber(7)
  $0.Timestamp ensureNormalizedEndTimestamp() => $_ensure(6);

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
  $core.int get rid => $_getIZ(8);
  @$pb.TagNumber(9)
  set rid($core.int v) {
    $_setUnsignedInt32(8, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasRid() => $_has(8);
  @$pb.TagNumber(9)
  void clearRid() => clearField(9);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
