import 'dart:convert';

import '../agent/constants.dart';

AgentAttributes agentAttributesFromJson(String str) =>
    AgentAttributes.fromJson(json.decode(str) as Map<String, dynamic>);

String agentAttributesToJson(AgentAttributes data) => json.encode(data.toJson());

TranscriptionAttributes transcriptionAttributesFromJson(String str) =>
    TranscriptionAttributes.fromJson(json.decode(str) as Map<String, dynamic>);

String transcriptionAttributesToJson(TranscriptionAttributes data) => json.encode(data.toJson());

class AgentAttributes {
  const AgentAttributes({
    this.lkAgentInputs,
    this.lkAgentOutputs,
    this.lkAgentState,
    this.lkPublishOnBehalf,
  });

  final List<AgentInput>? lkAgentInputs;
  final List<AgentOutput>? lkAgentOutputs;
  final AgentState? lkAgentState;
  final String? lkPublishOnBehalf;

  factory AgentAttributes.fromJson(Map<String, dynamic> json) => AgentAttributes(
        lkAgentInputs: _decodeAgentInputList(json[_AgentKeys.inputs]),
        lkAgentOutputs: _decodeAgentOutputList(json[_AgentKeys.outputs]),
        lkAgentState: _decodeAgentState(json[lkAgentStateAttributeKey]),
        lkPublishOnBehalf: json[lkPublishOnBehalfAttributeKey] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (lkAgentInputs != null && lkAgentInputs!.isNotEmpty)
          _AgentKeys.inputs: lkAgentInputs!.map(_agentInputToJson).toList(),
        if (lkAgentOutputs != null && lkAgentOutputs!.isNotEmpty)
          _AgentKeys.outputs: lkAgentOutputs!.map(_agentOutputToJson).toList(),
        if (lkAgentState != null) lkAgentStateAttributeKey: _agentStateToJson(lkAgentState!),
        if (lkPublishOnBehalf != null) lkPublishOnBehalfAttributeKey: lkPublishOnBehalf,
      };
}

enum AgentInput { AUDIO, TEXT, VIDEO }

enum AgentOutput { AUDIO, TRANSCRIPTION }

enum AgentState { IDLE, INITIALIZING, LISTENING, SPEAKING, THINKING }

List<AgentInput>? _decodeAgentInputList(Object? raw) {
  final values = raw as List<dynamic>?;
  if (values == null) {
    return null;
  }
  return values
      .map((value) => _agentInputFromJson(value as String?))
      .where((value) => value != null)
      .cast<AgentInput>()
      .toList();
}

List<AgentOutput>? _decodeAgentOutputList(Object? raw) {
  final values = raw as List<dynamic>?;
  if (values == null) {
    return null;
  }
  return values
      .map((value) => _agentOutputFromJson(value as String?))
      .where((value) => value != null)
      .cast<AgentOutput>()
      .toList();
}

AgentState? _decodeAgentState(Object? raw) {
  if (raw is! String) {
    return null;
  }
  return _agentStateFromJson(raw);
}

AgentInput? _agentInputFromJson(String? value) {
  return switch (value) {
    'audio' => AgentInput.AUDIO,
    'text' => AgentInput.TEXT,
    'video' => AgentInput.VIDEO,
    _ => null,
  };
}

String _agentInputToJson(AgentInput input) => switch (input) {
      AgentInput.AUDIO => 'audio',
      AgentInput.TEXT => 'text',
      AgentInput.VIDEO => 'video',
    };

AgentOutput? _agentOutputFromJson(String? value) {
  return switch (value) {
    'audio' => AgentOutput.AUDIO,
    'transcription' => AgentOutput.TRANSCRIPTION,
    _ => null,
  };
}

String _agentOutputToJson(AgentOutput output) => switch (output) {
      AgentOutput.AUDIO => 'audio',
      AgentOutput.TRANSCRIPTION => 'transcription',
    };

AgentState? _agentStateFromJson(String value) {
  return switch (value) {
    'idle' => AgentState.IDLE,
    'initializing' => AgentState.INITIALIZING,
    'listening' => AgentState.LISTENING,
    'speaking' => AgentState.SPEAKING,
    'thinking' => AgentState.THINKING,
    _ => null,
  };
}

String _agentStateToJson(AgentState state) => switch (state) {
      AgentState.IDLE => 'idle',
      AgentState.INITIALIZING => 'initializing',
      AgentState.LISTENING => 'listening',
      AgentState.SPEAKING => 'speaking',
      AgentState.THINKING => 'thinking',
    };

class _AgentKeys {
  static const inputs = 'lk.agent.inputs';
  static const outputs = 'lk.agent.outputs';
}

class TranscriptionAttributes {
  const TranscriptionAttributes({
    this.lkSegmentId,
    this.lkTranscribedTrackId,
    this.lkTranscriptionFinal,
  });

  final String? lkSegmentId;
  final String? lkTranscribedTrackId;
  final bool? lkTranscriptionFinal;

  factory TranscriptionAttributes.fromJson(Map<String, dynamic> json) => TranscriptionAttributes(
        lkSegmentId: json['lk.segment_id'] as String?,
        lkTranscribedTrackId: json['lk.transcribed_track_id'] as String?,
        lkTranscriptionFinal: _parseBool(json['lk.transcription_final']),
      );

  Map<String, dynamic> toJson() => {
        if (lkSegmentId != null) 'lk.segment_id': lkSegmentId,
        if (lkTranscribedTrackId != null) 'lk.transcribed_track_id': lkTranscribedTrackId,
        if (lkTranscriptionFinal != null) 'lk.transcription_final': lkTranscriptionFinal,
      };
}

bool? _parseBool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }
  return null;
}
