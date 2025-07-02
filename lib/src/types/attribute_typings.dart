// To parse this JSON data, do
//
//     final agentAttributes = agentAttributesFromJson(jsonString);
//     final transcriptionAttributes = transcriptionAttributesFromJson(jsonString);

import 'dart:convert';

AgentAttributes agentAttributesFromJson(String str) =>
    AgentAttributes.fromJson(json.decode(str));

String agentAttributesToJson(AgentAttributes data) =>
    json.encode(data.toJson());

TranscriptionAttributes transcriptionAttributesFromJson(String str) =>
    TranscriptionAttributes.fromJson(json.decode(str));

String transcriptionAttributesToJson(TranscriptionAttributes data) =>
    json.encode(data.toJson());

class AgentAttributes {
  List<AgentInput>? lkAgentInputs;
  List<AgentOutput>? lkAgentOutputs;
  AgentState? lkAgentState;
  String? lkPublishOnBehalf;

  AgentAttributes({
    this.lkAgentInputs,
    this.lkAgentOutputs,
    this.lkAgentState,
    this.lkPublishOnBehalf,
  });

  factory AgentAttributes.fromJson(Map<String, dynamic> json) =>
      AgentAttributes(
        lkAgentInputs: json['lk.agent.inputs'] == null
            ? []
            : List<AgentInput>.from(
                json['lk.agent.inputs']!.map((x) => agentInputValues.map[x]!)),
        lkAgentOutputs: json['lk.agent.outputs'] == null
            ? []
            : List<AgentOutput>.from(json['lk.agent.outputs']!
                .map((x) => agentOutputValues.map[x]!)),
        lkAgentState: agentStateValues.map[json['lk.agent.state']]!,
        lkPublishOnBehalf: json['lk.publish_on_behalf'],
      );

  Map<String, dynamic> toJson() => {
        'lk.agent.inputs': lkAgentInputs == null
            ? []
            : List<dynamic>.from(
                lkAgentInputs!.map((x) => agentInputValues.reverse[x])),
        'lk.agent.outputs': lkAgentOutputs == null
            ? []
            : List<dynamic>.from(
                lkAgentOutputs!.map((x) => agentOutputValues.reverse[x])),
        'lk.agent.state': agentStateValues.reverse[lkAgentState],
        'lk.publish_on_behalf': lkPublishOnBehalf,
      };
}

enum AgentInput { AUDIO, TEXT, VIDEO }

final agentInputValues = EnumValues({
  'audio': AgentInput.AUDIO,
  'text': AgentInput.TEXT,
  'video': AgentInput.VIDEO
});

enum AgentOutput { AUDIO, TRANSCRIPTION }

final agentOutputValues = EnumValues(
    {'audio': AgentOutput.AUDIO, 'transcription': AgentOutput.TRANSCRIPTION});

enum AgentState { IDLE, INITIALIZING, LISTENING, SPEAKING, THINKING }

final agentStateValues = EnumValues({
  'idle': AgentState.IDLE,
  'initializing': AgentState.INITIALIZING,
  'listening': AgentState.LISTENING,
  'speaking': AgentState.SPEAKING,
  'thinking': AgentState.THINKING
});

///Schema for transcription-related attributes
class TranscriptionAttributes {
  ///The segment id of the transcription
  String? lkSegmentId;

  ///The associated track id of the transcription
  String? lkTranscribedTrackId;

  ///Whether the transcription is final
  bool? lkTranscriptionFinal;

  TranscriptionAttributes({
    this.lkSegmentId,
    this.lkTranscribedTrackId,
    this.lkTranscriptionFinal,
  });

  factory TranscriptionAttributes.fromJson(Map<String, dynamic> json) =>
      TranscriptionAttributes(
        lkSegmentId: json['lk.segment_id'],
        lkTranscribedTrackId: json['lk.transcribed_track_id'],
        lkTranscriptionFinal: json['lk.transcription_final'],
      );

  Map<String, dynamic> toJson() => {
        'lk.segment_id': lkSegmentId,
        'lk.transcribed_track_id': lkTranscribedTrackId,
        'lk.transcription_final': lkTranscriptionFinal,
      };
}

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
