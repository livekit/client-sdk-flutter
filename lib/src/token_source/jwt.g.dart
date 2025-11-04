// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveKitVideoGrant _$LiveKitVideoGrantFromJson(Map<String, dynamic> json) => LiveKitVideoGrant(
      room: json['room'] as String?,
      roomCreate: json['room_create'] as bool?,
      roomJoin: json['room_join'] as bool?,
      roomList: json['room_list'] as bool?,
      roomRecord: json['room_record'] as bool?,
      roomAdmin: json['room_admin'] as bool?,
      canPublish: json['can_publish'] as bool?,
      canSubscribe: json['can_subscribe'] as bool?,
      canPublishData: json['can_publish_data'] as bool?,
      canPublishSources: (json['can_publish_sources'] as List<dynamic>?)?.map((e) => e as String).toList(),
      hidden: json['hidden'] as bool?,
      recorder: json['recorder'] as bool?,
    );

Map<String, dynamic> _$LiveKitVideoGrantToJson(LiveKitVideoGrant instance) => <String, dynamic>{
      'room': instance.room,
      'room_create': instance.roomCreate,
      'room_join': instance.roomJoin,
      'room_list': instance.roomList,
      'room_record': instance.roomRecord,
      'room_admin': instance.roomAdmin,
      'can_publish': instance.canPublish,
      'can_subscribe': instance.canSubscribe,
      'can_publish_data': instance.canPublishData,
      'can_publish_sources': instance.canPublishSources,
      'hidden': instance.hidden,
      'recorder': instance.recorder,
    };
