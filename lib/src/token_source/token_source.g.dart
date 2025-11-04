// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_source.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenRequestOptions _$TokenRequestOptionsFromJson(Map<String, dynamic> json) => TokenRequestOptions(
      roomName: json['roomName'] as String?,
      participantName: json['participantName'] as String?,
      participantIdentity: json['participantIdentity'] as String?,
      participantMetadata: json['participantMetadata'] as String?,
      participantAttributes: (json['participantAttributes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      agentName: json['agentName'] as String?,
      agentMetadata: json['agentMetadata'] as String?,
    );

Map<String, dynamic> _$TokenRequestOptionsToJson(TokenRequestOptions instance) => <String, dynamic>{
      'roomName': instance.roomName,
      'participantName': instance.participantName,
      'participantIdentity': instance.participantIdentity,
      'participantMetadata': instance.participantMetadata,
      'participantAttributes': instance.participantAttributes,
      'agentName': instance.agentName,
      'agentMetadata': instance.agentMetadata,
    };

TokenSourceRequest _$TokenSourceRequestFromJson(Map<String, dynamic> json) => TokenSourceRequest(
      roomName: json['room_name'] as String?,
      participantName: json['participant_name'] as String?,
      participantIdentity: json['participant_identity'] as String?,
      participantMetadata: json['participant_metadata'] as String?,
      participantAttributes: (json['participant_attributes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      roomConfiguration:
          json['room_config'] == null ? null : RoomConfiguration.fromJson(json['room_config'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TokenSourceRequestToJson(TokenSourceRequest instance) => <String, dynamic>{
      'room_name': instance.roomName,
      'participant_name': instance.participantName,
      'participant_identity': instance.participantIdentity,
      'participant_metadata': instance.participantMetadata,
      'participant_attributes': instance.participantAttributes,
      'room_config': instance.roomConfiguration,
    };

TokenSourceResponse _$TokenSourceResponseFromJson(Map<String, dynamic> json) => TokenSourceResponse(
      serverUrl: json['server_url'] as String,
      participantToken: json['participant_token'] as String,
      participantName: json['participant_name'] as String?,
      roomName: json['room_name'] as String?,
    );

Map<String, dynamic> _$TokenSourceResponseToJson(TokenSourceResponse instance) => <String, dynamic>{
      'server_url': instance.serverUrl,
      'participant_token': instance.participantToken,
      'participant_name': instance.participantName,
      'room_name': instance.roomName,
    };
