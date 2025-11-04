import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../agent/constants.dart';

part 'agent_attributes.g.dart';

AgentAttributes agentAttributesFromJson(String source) =>
    AgentAttributes.fromJson(jsonDecode(source) as Map<String, dynamic>);

String agentAttributesToJson(AgentAttributes value) => jsonEncode(value.toJson());

TranscriptionAttributes transcriptionAttributesFromJson(String source) =>
    TranscriptionAttributes.fromJson(jsonDecode(source) as Map<String, dynamic>);

String transcriptionAttributesToJson(TranscriptionAttributes value) => jsonEncode(value.toJson());

@JsonSerializable()
class AgentAttributes {
  const AgentAttributes({
    this.lkAgentInputs,
    this.lkAgentOutputs,
    this.lkAgentState,
    this.lkPublishOnBehalf,
  });

  @JsonKey(name: lkAgentInputsAttributeKey)
  final List<AgentInput>? lkAgentInputs;

  @JsonKey(name: lkAgentOutputsAttributeKey)
  final List<AgentOutput>? lkAgentOutputs;

  @JsonKey(name: lkAgentStateAttributeKey)
  final AgentState? lkAgentState;

  @JsonKey(name: lkPublishOnBehalfAttributeKey)
  final String? lkPublishOnBehalf;

  factory AgentAttributes.fromJson(Map<String, dynamic> json) => _$AgentAttributesFromJson(json);

  Map<String, dynamic> toJson() => _$AgentAttributesToJson(this);
}

@JsonEnum(alwaysCreate: true)
enum AgentInput {
  @JsonValue('audio')
  AUDIO,
  @JsonValue('text')
  TEXT,
  @JsonValue('video')
  VIDEO,
}

@JsonEnum(alwaysCreate: true)
enum AgentOutput {
  @JsonValue('audio')
  AUDIO,
  @JsonValue('transcription')
  TRANSCRIPTION,
}

@JsonEnum(alwaysCreate: true)
enum AgentState {
  @JsonValue('idle')
  IDLE,
  @JsonValue('initializing')
  INITIALIZING,
  @JsonValue('listening')
  LISTENING,
  @JsonValue('speaking')
  SPEAKING,
  @JsonValue('thinking')
  THINKING,
}

@JsonSerializable()
class TranscriptionAttributes {
  const TranscriptionAttributes({
    this.lkSegmentId,
    this.lkTranscribedTrackId,
    this.lkTranscriptionFinal,
  });

  @JsonKey(name: 'lk.segment_id')
  final String? lkSegmentId;

  @JsonKey(name: 'lk.transcribed_track_id')
  final String? lkTranscribedTrackId;

  @JsonKey(name: 'lk.transcription_final', fromJson: _boolFromJson, toJson: _boolToJson)
  final bool? lkTranscriptionFinal;

  factory TranscriptionAttributes.fromJson(Map<String, dynamic> json) =>
      _$TranscriptionAttributesFromJson(json);

  Map<String, dynamic> toJson() => _$TranscriptionAttributesToJson(this);
}

bool? _boolFromJson(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1') {
      return true;
    }
    if (lower == 'false' || lower == '0') {
      return false;
    }
  }
  return null;
}

Object? _boolToJson(bool? value) => value;
