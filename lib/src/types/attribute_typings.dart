// To parse this JSON data, do
//
//     final agentAttributes = agentAttributesFromJson(jsonString);
//     final transcriptionAttributes = transcriptionAttributesFromJson(jsonString);

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'attribute_typings.g.dart';

AgentAttributes agentAttributesFromJson(String str) => AgentAttributes.fromJson(json.decode(str));

String agentAttributesToJson(AgentAttributes data) => json.encode(data.toJson());

TranscriptionAttributes transcriptionAttributesFromJson(String str) =>
    TranscriptionAttributes.fromJson(json.decode(str));

String transcriptionAttributesToJson(TranscriptionAttributes data) => json.encode(data.toJson());

@JsonSerializable()
class AgentAttributes {
  @JsonKey(name: 'lk.agent.inputs')
  List<AgentInput>? lkAgentInputs;

  @JsonKey(name: 'lk.agent.outputs')
  List<AgentOutput>? lkAgentOutputs;

  @JsonKey(name: 'lk.agent.state')
  AgentState? lkAgentState;

  @JsonKey(name: 'lk.publish_on_behalf')
  String? lkPublishOnBehalf;

  AgentAttributes({
    this.lkAgentInputs,
    this.lkAgentOutputs,
    this.lkAgentState,
    this.lkPublishOnBehalf,
  });

  factory AgentAttributes.fromJson(Map<String, dynamic> json) => _$AgentAttributesFromJson(json);
  Map<String, dynamic> toJson() => _$AgentAttributesToJson(this);
}

@JsonEnum()
enum AgentInput {
  @JsonValue('audio')
  AUDIO,
  @JsonValue('text')
  TEXT,
  @JsonValue('video')
  VIDEO,
}

@JsonEnum()
enum AgentOutput {
  @JsonValue('audio')
  AUDIO,
  @JsonValue('transcription')
  TRANSCRIPTION,
}

@JsonEnum()
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

///Schema for transcription-related attributes
@JsonSerializable()
class TranscriptionAttributes {
  ///The segment id of the transcription
  @JsonKey(name: 'lk.segment_id')
  String? lkSegmentId;

  ///The associated track id of the transcription
  @JsonKey(name: 'lk.transcribed_track_id')
  String? lkTranscribedTrackId;

  ///Whether the transcription is final
  @JsonKey(name: 'lk.transcription_final')
  bool? lkTranscriptionFinal;

  TranscriptionAttributes({
    this.lkSegmentId,
    this.lkTranscribedTrackId,
    this.lkTranscriptionFinal,
  });

  factory TranscriptionAttributes.fromJson(Map<String, dynamic> json) => _$TranscriptionAttributesFromJson(json);
  Map<String, dynamic> toJson() => _$TranscriptionAttributesToJson(this);
}
