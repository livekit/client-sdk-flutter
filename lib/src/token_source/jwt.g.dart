// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveKitVideoGrant _$LiveKitVideoGrantFromJson(Map<String, dynamic> json) => LiveKitVideoGrant(
  room: json['room'] as String?,
  roomCreate: json['roomCreate'] as bool?,
  roomJoin: json['roomJoin'] as bool?,
  roomList: json['roomList'] as bool?,
  roomRecord: json['roomRecord'] as bool?,
  roomAdmin: json['roomAdmin'] as bool?,
  canPublish: json['canPublish'] as bool?,
  canSubscribe: json['canSubscribe'] as bool?,
  canPublishData: json['canPublishData'] as bool?,
  canPublishSources: (json['canPublishSources'] as List<dynamic>?)?.map((e) => e as String).toList(),
  canUpdateOwnMetadata: json['canUpdateOwnMetadata'] as bool?,
  ingressAdmin: json['ingressAdmin'] as bool?,
  hidden: json['hidden'] as bool?,
  recorder: json['recorder'] as bool?,
  agent: json['agent'] as bool?,
  canSubscribeMetrics: json['canSubscribeMetrics'] as bool?,
  canManageAgentSession: json['canManageAgentSession'] as bool?,
  destinationRoom: json['destinationRoom'] as String?,
);

Map<String, dynamic> _$LiveKitVideoGrantToJson(LiveKitVideoGrant instance) => <String, dynamic>{
  'room': ?instance.room,
  'roomCreate': ?instance.roomCreate,
  'roomJoin': ?instance.roomJoin,
  'roomList': ?instance.roomList,
  'roomRecord': ?instance.roomRecord,
  'roomAdmin': ?instance.roomAdmin,
  'canPublish': ?instance.canPublish,
  'canSubscribe': ?instance.canSubscribe,
  'canPublishData': ?instance.canPublishData,
  'canPublishSources': ?instance.canPublishSources,
  'canUpdateOwnMetadata': ?instance.canUpdateOwnMetadata,
  'ingressAdmin': ?instance.ingressAdmin,
  'hidden': ?instance.hidden,
  'recorder': ?instance.recorder,
  'agent': ?instance.agent,
  'canSubscribeMetrics': ?instance.canSubscribeMetrics,
  'canManageAgentSession': ?instance.canManageAgentSession,
  'destinationRoom': ?instance.destinationRoom,
};
