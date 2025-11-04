// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoomAgentDispatch _$RoomAgentDispatchFromJson(Map<String, dynamic> json) => RoomAgentDispatch(
      agentName: json['agent_name'] as String?,
      metadata: json['metadata'] as String?,
    );

Map<String, dynamic> _$RoomAgentDispatchToJson(RoomAgentDispatch instance) => <String, dynamic>{
      'agent_name': instance.agentName,
      'metadata': instance.metadata,
    };

RoomConfiguration _$RoomConfigurationFromJson(Map<String, dynamic> json) => RoomConfiguration(
      name: json['name'] as String?,
      emptyTimeout: (json['empty_timeout'] as num?)?.toInt(),
      departureTimeout: (json['departure_timeout'] as num?)?.toInt(),
      maxParticipants: (json['max_participants'] as num?)?.toInt(),
      metadata: json['metadata'] as String?,
      minPlayoutDelay: (json['min_playout_delay'] as num?)?.toInt(),
      maxPlayoutDelay: (json['max_playout_delay'] as num?)?.toInt(),
      syncStreams: json['sync_streams'] as bool?,
      agents: (json['agents'] as List<dynamic>?)
          ?.map((e) => RoomAgentDispatch.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RoomConfigurationToJson(RoomConfiguration instance) => <String, dynamic>{
      'name': instance.name,
      'empty_timeout': instance.emptyTimeout,
      'departure_timeout': instance.departureTimeout,
      'max_participants': instance.maxParticipants,
      'metadata': instance.metadata,
      'min_playout_delay': instance.minPlayoutDelay,
      'max_playout_delay': instance.maxPlayoutDelay,
      'sync_streams': instance.syncStreams,
      'agents': instance.agents,
    };
