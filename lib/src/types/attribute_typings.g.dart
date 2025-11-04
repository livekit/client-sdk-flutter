// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attribute_typings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentAttributes _$AgentAttributesFromJson(Map<String, dynamic> json) => AgentAttributes(
      lkAgentInputs:
          (json['lk.agent.inputs'] as List<dynamic>?)?.map((e) => $enumDecode(_$AgentInputEnumMap, e)).toList(),
      lkAgentOutputs:
          (json['lk.agent.outputs'] as List<dynamic>?)?.map((e) => $enumDecode(_$AgentOutputEnumMap, e)).toList(),
      lkAgentState: $enumDecodeNullable(_$AgentStateEnumMap, json['lk.agent.state']),
      lkPublishOnBehalf: json['lk.publish_on_behalf'] as String?,
    );

Map<String, dynamic> _$AgentAttributesToJson(AgentAttributes instance) => <String, dynamic>{
      'lk.agent.inputs': instance.lkAgentInputs?.map((e) => _$AgentInputEnumMap[e]!).toList(),
      'lk.agent.outputs': instance.lkAgentOutputs?.map((e) => _$AgentOutputEnumMap[e]!).toList(),
      'lk.agent.state': _$AgentStateEnumMap[instance.lkAgentState],
      'lk.publish_on_behalf': instance.lkPublishOnBehalf,
    };

const _$AgentInputEnumMap = {
  AgentInput.AUDIO: 'audio',
  AgentInput.TEXT: 'text',
  AgentInput.VIDEO: 'video',
};

const _$AgentOutputEnumMap = {
  AgentOutput.AUDIO: 'audio',
  AgentOutput.TRANSCRIPTION: 'transcription',
};

const _$AgentStateEnumMap = {
  AgentState.IDLE: 'idle',
  AgentState.INITIALIZING: 'initializing',
  AgentState.LISTENING: 'listening',
  AgentState.SPEAKING: 'speaking',
  AgentState.THINKING: 'thinking',
};

TranscriptionAttributes _$TranscriptionAttributesFromJson(Map<String, dynamic> json) => TranscriptionAttributes(
      lkSegmentId: json['lk.segment_id'] as String?,
      lkTranscribedTrackId: json['lk.transcribed_track_id'] as String?,
      lkTranscriptionFinal: json['lk.transcription_final'] as bool?,
    );

Map<String, dynamic> _$TranscriptionAttributesToJson(TranscriptionAttributes instance) => <String, dynamic>{
      'lk.segment_id': instance.lkSegmentId,
      'lk.transcribed_track_id': instance.lkTranscribedTrackId,
      'lk.transcription_final': instance.lkTranscriptionFinal,
    };
