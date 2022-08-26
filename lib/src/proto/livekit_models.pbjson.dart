///
//  Generated code. Do not modify.
//  source: livekit_models.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use trackTypeDescriptor instead')
const TrackType$json = const {
  '1': 'TrackType',
  '2': const [
    const {'1': 'AUDIO', '2': 0},
    const {'1': 'VIDEO', '2': 1},
    const {'1': 'DATA', '2': 2},
  ],
};

/// Descriptor for `TrackType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List trackTypeDescriptor = $convert.base64Decode(
    'CglUcmFja1R5cGUSCQoFQVVESU8QABIJCgVWSURFTxABEggKBERBVEEQAg==');
@$core.Deprecated('Use trackSourceDescriptor instead')
const TrackSource$json = const {
  '1': 'TrackSource',
  '2': const [
    const {'1': 'UNKNOWN', '2': 0},
    const {'1': 'CAMERA', '2': 1},
    const {'1': 'MICROPHONE', '2': 2},
    const {'1': 'SCREEN_SHARE', '2': 3},
    const {'1': 'SCREEN_SHARE_AUDIO', '2': 4},
  ],
};

/// Descriptor for `TrackSource`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List trackSourceDescriptor = $convert.base64Decode(
    'CgtUcmFja1NvdXJjZRILCgdVTktOT1dOEAASCgoGQ0FNRVJBEAESDgoKTUlDUk9QSE9ORRACEhAKDFNDUkVFTl9TSEFSRRADEhYKElNDUkVFTl9TSEFSRV9BVURJTxAE');
@$core.Deprecated('Use videoQualityDescriptor instead')
const VideoQuality$json = const {
  '1': 'VideoQuality',
  '2': const [
    const {'1': 'LOW', '2': 0},
    const {'1': 'MEDIUM', '2': 1},
    const {'1': 'HIGH', '2': 2},
    const {'1': 'OFF', '2': 3},
  ],
};

/// Descriptor for `VideoQuality`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List videoQualityDescriptor = $convert.base64Decode(
    'CgxWaWRlb1F1YWxpdHkSBwoDTE9XEAASCgoGTUVESVVNEAESCAoESElHSBACEgcKA09GRhAD');
@$core.Deprecated('Use connectionQualityDescriptor instead')
const ConnectionQuality$json = const {
  '1': 'ConnectionQuality',
  '2': const [
    const {'1': 'POOR', '2': 0},
    const {'1': 'GOOD', '2': 1},
    const {'1': 'EXCELLENT', '2': 2},
  ],
};

/// Descriptor for `ConnectionQuality`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List connectionQualityDescriptor = $convert.base64Decode(
    'ChFDb25uZWN0aW9uUXVhbGl0eRIICgRQT09SEAASCAoER09PRBABEg0KCUVYQ0VMTEVOVBAC');
@$core.Deprecated('Use clientConfigSettingDescriptor instead')
const ClientConfigSetting$json = const {
  '1': 'ClientConfigSetting',
  '2': const [
    const {'1': 'UNSET', '2': 0},
    const {'1': 'DISABLED', '2': 1},
    const {'1': 'ENABLED', '2': 2},
  ],
};

/// Descriptor for `ClientConfigSetting`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List clientConfigSettingDescriptor = $convert.base64Decode(
    'ChNDbGllbnRDb25maWdTZXR0aW5nEgkKBVVOU0VUEAASDAoIRElTQUJMRUQQARILCgdFTkFCTEVEEAI=');
@$core.Deprecated('Use disconnectReasonDescriptor instead')
const DisconnectReason$json = const {
  '1': 'DisconnectReason',
  '2': const [
    const {'1': 'UNKNOWN_REASON', '2': 0},
    const {'1': 'CLIENT_INITIATED', '2': 1},
    const {'1': 'DUPLICATE_IDENTITY', '2': 2},
    const {'1': 'SERVER_SHUTDOWN', '2': 3},
    const {'1': 'PARTICIPANT_REMOVED', '2': 4},
    const {'1': 'ROOM_DELETED', '2': 5},
    const {'1': 'STATE_MISMATCH', '2': 6},
    const {'1': 'JOIN_FAILURE', '2': 7},
  ],
};

/// Descriptor for `DisconnectReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List disconnectReasonDescriptor = $convert.base64Decode(
    'ChBEaXNjb25uZWN0UmVhc29uEhIKDlVOS05PV05fUkVBU09OEAASFAoQQ0xJRU5UX0lOSVRJQVRFRBABEhYKEkRVUExJQ0FURV9JREVOVElUWRACEhMKD1NFUlZFUl9TSFVURE9XThADEhcKE1BBUlRJQ0lQQU5UX1JFTU9WRUQQBBIQCgxST09NX0RFTEVURUQQBRISCg5TVEFURV9NSVNNQVRDSBAGEhAKDEpPSU5fRkFJTFVSRRAH');
@$core.Deprecated('Use roomDescriptor instead')
const Room$json = const {
  '1': 'Room',
  '2': const [
    const {'1': 'sid', '3': 1, '4': 1, '5': 9, '10': 'sid'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'empty_timeout', '3': 3, '4': 1, '5': 13, '10': 'emptyTimeout'},
    const {
      '1': 'max_participants',
      '3': 4,
      '4': 1,
      '5': 13,
      '10': 'maxParticipants'
    },
    const {'1': 'creation_time', '3': 5, '4': 1, '5': 3, '10': 'creationTime'},
    const {'1': 'turn_password', '3': 6, '4': 1, '5': 9, '10': 'turnPassword'},
    const {
      '1': 'enabled_codecs',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.livekit.Codec',
      '10': 'enabledCodecs'
    },
    const {'1': 'metadata', '3': 8, '4': 1, '5': 9, '10': 'metadata'},
    const {
      '1': 'num_participants',
      '3': 9,
      '4': 1,
      '5': 13,
      '10': 'numParticipants'
    },
    const {
      '1': 'active_recording',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'activeRecording'
    },
  ],
};

/// Descriptor for `Room`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roomDescriptor = $convert.base64Decode(
    'CgRSb29tEhAKA3NpZBgBIAEoCVIDc2lkEhIKBG5hbWUYAiABKAlSBG5hbWUSIwoNZW1wdHlfdGltZW91dBgDIAEoDVIMZW1wdHlUaW1lb3V0EikKEG1heF9wYXJ0aWNpcGFudHMYBCABKA1SD21heFBhcnRpY2lwYW50cxIjCg1jcmVhdGlvbl90aW1lGAUgASgDUgxjcmVhdGlvblRpbWUSIwoNdHVybl9wYXNzd29yZBgGIAEoCVIMdHVyblBhc3N3b3JkEjUKDmVuYWJsZWRfY29kZWNzGAcgAygLMg4ubGl2ZWtpdC5Db2RlY1INZW5hYmxlZENvZGVjcxIaCghtZXRhZGF0YRgIIAEoCVIIbWV0YWRhdGESKQoQbnVtX3BhcnRpY2lwYW50cxgJIAEoDVIPbnVtUGFydGljaXBhbnRzEikKEGFjdGl2ZV9yZWNvcmRpbmcYCiABKAhSD2FjdGl2ZVJlY29yZGluZw==');
@$core.Deprecated('Use codecDescriptor instead')
const Codec$json = const {
  '1': 'Codec',
  '2': const [
    const {'1': 'mime', '3': 1, '4': 1, '5': 9, '10': 'mime'},
    const {'1': 'fmtp_line', '3': 2, '4': 1, '5': 9, '10': 'fmtpLine'},
  ],
};

/// Descriptor for `Codec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List codecDescriptor = $convert.base64Decode(
    'CgVDb2RlYxISCgRtaW1lGAEgASgJUgRtaW1lEhsKCWZtdHBfbGluZRgCIAEoCVIIZm10cExpbmU=');
@$core.Deprecated('Use participantPermissionDescriptor instead')
const ParticipantPermission$json = const {
  '1': 'ParticipantPermission',
  '2': const [
    const {'1': 'can_subscribe', '3': 1, '4': 1, '5': 8, '10': 'canSubscribe'},
    const {'1': 'can_publish', '3': 2, '4': 1, '5': 8, '10': 'canPublish'},
    const {
      '1': 'can_publish_data',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'canPublishData'
    },
    const {'1': 'hidden', '3': 7, '4': 1, '5': 8, '10': 'hidden'},
    const {'1': 'recorder', '3': 8, '4': 1, '5': 8, '10': 'recorder'},
  ],
};

/// Descriptor for `ParticipantPermission`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List participantPermissionDescriptor = $convert.base64Decode(
    'ChVQYXJ0aWNpcGFudFBlcm1pc3Npb24SIwoNY2FuX3N1YnNjcmliZRgBIAEoCFIMY2FuU3Vic2NyaWJlEh8KC2Nhbl9wdWJsaXNoGAIgASgIUgpjYW5QdWJsaXNoEigKEGNhbl9wdWJsaXNoX2RhdGEYAyABKAhSDmNhblB1Ymxpc2hEYXRhEhYKBmhpZGRlbhgHIAEoCFIGaGlkZGVuEhoKCHJlY29yZGVyGAggASgIUghyZWNvcmRlcg==');
@$core.Deprecated('Use participantInfoDescriptor instead')
const ParticipantInfo$json = const {
  '1': 'ParticipantInfo',
  '2': const [
    const {'1': 'sid', '3': 1, '4': 1, '5': 9, '10': 'sid'},
    const {'1': 'identity', '3': 2, '4': 1, '5': 9, '10': 'identity'},
    const {
      '1': 'state',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.livekit.ParticipantInfo.State',
      '10': 'state'
    },
    const {
      '1': 'tracks',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.livekit.TrackInfo',
      '10': 'tracks'
    },
    const {'1': 'metadata', '3': 5, '4': 1, '5': 9, '10': 'metadata'},
    const {'1': 'joined_at', '3': 6, '4': 1, '5': 3, '10': 'joinedAt'},
    const {'1': 'name', '3': 9, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'version', '3': 10, '4': 1, '5': 13, '10': 'version'},
    const {
      '1': 'permission',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.livekit.ParticipantPermission',
      '10': 'permission'
    },
    const {'1': 'region', '3': 12, '4': 1, '5': 9, '10': 'region'},
    const {'1': 'is_publisher', '3': 13, '4': 1, '5': 8, '10': 'isPublisher'},
  ],
  '4': const [ParticipantInfo_State$json],
};

@$core.Deprecated('Use participantInfoDescriptor instead')
const ParticipantInfo_State$json = const {
  '1': 'State',
  '2': const [
    const {'1': 'JOINING', '2': 0},
    const {'1': 'JOINED', '2': 1},
    const {'1': 'ACTIVE', '2': 2},
    const {'1': 'DISCONNECTED', '2': 3},
  ],
};

/// Descriptor for `ParticipantInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List participantInfoDescriptor = $convert.base64Decode(
    'Cg9QYXJ0aWNpcGFudEluZm8SEAoDc2lkGAEgASgJUgNzaWQSGgoIaWRlbnRpdHkYAiABKAlSCGlkZW50aXR5EjQKBXN0YXRlGAMgASgOMh4ubGl2ZWtpdC5QYXJ0aWNpcGFudEluZm8uU3RhdGVSBXN0YXRlEioKBnRyYWNrcxgEIAMoCzISLmxpdmVraXQuVHJhY2tJbmZvUgZ0cmFja3MSGgoIbWV0YWRhdGEYBSABKAlSCG1ldGFkYXRhEhsKCWpvaW5lZF9hdBgGIAEoA1IIam9pbmVkQXQSEgoEbmFtZRgJIAEoCVIEbmFtZRIYCgd2ZXJzaW9uGAogASgNUgd2ZXJzaW9uEj4KCnBlcm1pc3Npb24YCyABKAsyHi5saXZla2l0LlBhcnRpY2lwYW50UGVybWlzc2lvblIKcGVybWlzc2lvbhIWCgZyZWdpb24YDCABKAlSBnJlZ2lvbhIhCgxpc19wdWJsaXNoZXIYDSABKAhSC2lzUHVibGlzaGVyIj4KBVN0YXRlEgsKB0pPSU5JTkcQABIKCgZKT0lORUQQARIKCgZBQ1RJVkUQAhIQCgxESVNDT05ORUNURUQQAw==');
@$core.Deprecated('Use simulcastCodecInfoDescriptor instead')
const SimulcastCodecInfo$json = const {
  '1': 'SimulcastCodecInfo',
  '2': const [
    const {'1': 'mime_type', '3': 1, '4': 1, '5': 9, '10': 'mimeType'},
    const {'1': 'mid', '3': 2, '4': 1, '5': 9, '10': 'mid'},
    const {'1': 'cid', '3': 3, '4': 1, '5': 9, '10': 'cid'},
    const {
      '1': 'layers',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.livekit.VideoLayer',
      '10': 'layers'
    },
  ],
};

/// Descriptor for `SimulcastCodecInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List simulcastCodecInfoDescriptor = $convert.base64Decode(
    'ChJTaW11bGNhc3RDb2RlY0luZm8SGwoJbWltZV90eXBlGAEgASgJUghtaW1lVHlwZRIQCgNtaWQYAiABKAlSA21pZBIQCgNjaWQYAyABKAlSA2NpZBIrCgZsYXllcnMYBCADKAsyEy5saXZla2l0LlZpZGVvTGF5ZXJSBmxheWVycw==');
@$core.Deprecated('Use trackInfoDescriptor instead')
const TrackInfo$json = const {
  '1': 'TrackInfo',
  '2': const [
    const {'1': 'sid', '3': 1, '4': 1, '5': 9, '10': 'sid'},
    const {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.livekit.TrackType',
      '10': 'type'
    },
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'muted', '3': 4, '4': 1, '5': 8, '10': 'muted'},
    const {'1': 'width', '3': 5, '4': 1, '5': 13, '10': 'width'},
    const {'1': 'height', '3': 6, '4': 1, '5': 13, '10': 'height'},
    const {'1': 'simulcast', '3': 7, '4': 1, '5': 8, '10': 'simulcast'},
    const {'1': 'disable_dtx', '3': 8, '4': 1, '5': 8, '10': 'disableDtx'},
    const {
      '1': 'source',
      '3': 9,
      '4': 1,
      '5': 14,
      '6': '.livekit.TrackSource',
      '10': 'source'
    },
    const {
      '1': 'layers',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.livekit.VideoLayer',
      '10': 'layers'
    },
    const {'1': 'mime_type', '3': 11, '4': 1, '5': 9, '10': 'mimeType'},
    const {'1': 'mid', '3': 12, '4': 1, '5': 9, '10': 'mid'},
    const {
      '1': 'codecs',
      '3': 13,
      '4': 3,
      '5': 11,
      '6': '.livekit.SimulcastCodecInfo',
      '10': 'codecs'
    },
  ],
};

/// Descriptor for `TrackInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackInfoDescriptor = $convert.base64Decode(
    'CglUcmFja0luZm8SEAoDc2lkGAEgASgJUgNzaWQSJgoEdHlwZRgCIAEoDjISLmxpdmVraXQuVHJhY2tUeXBlUgR0eXBlEhIKBG5hbWUYAyABKAlSBG5hbWUSFAoFbXV0ZWQYBCABKAhSBW11dGVkEhQKBXdpZHRoGAUgASgNUgV3aWR0aBIWCgZoZWlnaHQYBiABKA1SBmhlaWdodBIcCglzaW11bGNhc3QYByABKAhSCXNpbXVsY2FzdBIfCgtkaXNhYmxlX2R0eBgIIAEoCFIKZGlzYWJsZUR0eBIsCgZzb3VyY2UYCSABKA4yFC5saXZla2l0LlRyYWNrU291cmNlUgZzb3VyY2USKwoGbGF5ZXJzGAogAygLMhMubGl2ZWtpdC5WaWRlb0xheWVyUgZsYXllcnMSGwoJbWltZV90eXBlGAsgASgJUghtaW1lVHlwZRIQCgNtaWQYDCABKAlSA21pZBIzCgZjb2RlY3MYDSADKAsyGy5saXZla2l0LlNpbXVsY2FzdENvZGVjSW5mb1IGY29kZWNz');
@$core.Deprecated('Use videoLayerDescriptor instead')
const VideoLayer$json = const {
  '1': 'VideoLayer',
  '2': const [
    const {
      '1': 'quality',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.livekit.VideoQuality',
      '10': 'quality'
    },
    const {'1': 'width', '3': 2, '4': 1, '5': 13, '10': 'width'},
    const {'1': 'height', '3': 3, '4': 1, '5': 13, '10': 'height'},
    const {'1': 'bitrate', '3': 4, '4': 1, '5': 13, '10': 'bitrate'},
    const {'1': 'ssrc', '3': 5, '4': 1, '5': 13, '10': 'ssrc'},
  ],
};

/// Descriptor for `VideoLayer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List videoLayerDescriptor = $convert.base64Decode(
    'CgpWaWRlb0xheWVyEi8KB3F1YWxpdHkYASABKA4yFS5saXZla2l0LlZpZGVvUXVhbGl0eVIHcXVhbGl0eRIUCgV3aWR0aBgCIAEoDVIFd2lkdGgSFgoGaGVpZ2h0GAMgASgNUgZoZWlnaHQSGAoHYml0cmF0ZRgEIAEoDVIHYml0cmF0ZRISCgRzc3JjGAUgASgNUgRzc3Jj');
@$core.Deprecated('Use dataPacketDescriptor instead')
const DataPacket$json = const {
  '1': 'DataPacket',
  '2': const [
    const {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.livekit.DataPacket.Kind',
      '10': 'kind'
    },
    const {
      '1': 'user',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.livekit.UserPacket',
      '9': 0,
      '10': 'user'
    },
    const {
      '1': 'speaker',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.livekit.ActiveSpeakerUpdate',
      '9': 0,
      '10': 'speaker'
    },
  ],
  '4': const [DataPacket_Kind$json],
  '8': const [
    const {'1': 'value'},
  ],
};

@$core.Deprecated('Use dataPacketDescriptor instead')
const DataPacket_Kind$json = const {
  '1': 'Kind',
  '2': const [
    const {'1': 'RELIABLE', '2': 0},
    const {'1': 'LOSSY', '2': 1},
  ],
};

/// Descriptor for `DataPacket`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dataPacketDescriptor = $convert.base64Decode(
    'CgpEYXRhUGFja2V0EiwKBGtpbmQYASABKA4yGC5saXZla2l0LkRhdGFQYWNrZXQuS2luZFIEa2luZBIpCgR1c2VyGAIgASgLMhMubGl2ZWtpdC5Vc2VyUGFja2V0SABSBHVzZXISOAoHc3BlYWtlchgDIAEoCzIcLmxpdmVraXQuQWN0aXZlU3BlYWtlclVwZGF0ZUgAUgdzcGVha2VyIh8KBEtpbmQSDAoIUkVMSUFCTEUQABIJCgVMT1NTWRABQgcKBXZhbHVl');
@$core.Deprecated('Use activeSpeakerUpdateDescriptor instead')
const ActiveSpeakerUpdate$json = const {
  '1': 'ActiveSpeakerUpdate',
  '2': const [
    const {
      '1': 'speakers',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.livekit.SpeakerInfo',
      '10': 'speakers'
    },
  ],
};

/// Descriptor for `ActiveSpeakerUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activeSpeakerUpdateDescriptor = $convert.base64Decode(
    'ChNBY3RpdmVTcGVha2VyVXBkYXRlEjAKCHNwZWFrZXJzGAEgAygLMhQubGl2ZWtpdC5TcGVha2VySW5mb1IIc3BlYWtlcnM=');
@$core.Deprecated('Use speakerInfoDescriptor instead')
const SpeakerInfo$json = const {
  '1': 'SpeakerInfo',
  '2': const [
    const {'1': 'sid', '3': 1, '4': 1, '5': 9, '10': 'sid'},
    const {'1': 'level', '3': 2, '4': 1, '5': 2, '10': 'level'},
    const {'1': 'active', '3': 3, '4': 1, '5': 8, '10': 'active'},
  ],
};

/// Descriptor for `SpeakerInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List speakerInfoDescriptor = $convert.base64Decode(
    'CgtTcGVha2VySW5mbxIQCgNzaWQYASABKAlSA3NpZBIUCgVsZXZlbBgCIAEoAlIFbGV2ZWwSFgoGYWN0aXZlGAMgASgIUgZhY3RpdmU=');
@$core.Deprecated('Use userPacketDescriptor instead')
const UserPacket$json = const {
  '1': 'UserPacket',
  '2': const [
    const {
      '1': 'participant_sid',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'participantSid'
    },
    const {'1': 'payload', '3': 2, '4': 1, '5': 12, '10': 'payload'},
    const {
      '1': 'destination_sids',
      '3': 3,
      '4': 3,
      '5': 9,
      '10': 'destinationSids'
    },
  ],
};

/// Descriptor for `UserPacket`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userPacketDescriptor = $convert.base64Decode(
    'CgpVc2VyUGFja2V0EicKD3BhcnRpY2lwYW50X3NpZBgBIAEoCVIOcGFydGljaXBhbnRTaWQSGAoHcGF5bG9hZBgCIAEoDFIHcGF5bG9hZBIpChBkZXN0aW5hdGlvbl9zaWRzGAMgAygJUg9kZXN0aW5hdGlvblNpZHM=');
@$core.Deprecated('Use participantTracksDescriptor instead')
const ParticipantTracks$json = const {
  '1': 'ParticipantTracks',
  '2': const [
    const {
      '1': 'participant_sid',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'participantSid'
    },
    const {'1': 'track_sids', '3': 2, '4': 3, '5': 9, '10': 'trackSids'},
  ],
};

/// Descriptor for `ParticipantTracks`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List participantTracksDescriptor = $convert.base64Decode(
    'ChFQYXJ0aWNpcGFudFRyYWNrcxInCg9wYXJ0aWNpcGFudF9zaWQYASABKAlSDnBhcnRpY2lwYW50U2lkEh0KCnRyYWNrX3NpZHMYAiADKAlSCXRyYWNrU2lkcw==');
@$core.Deprecated('Use serverInfoDescriptor instead')
const ServerInfo$json = const {
  '1': 'ServerInfo',
  '2': const [
    const {
      '1': 'edition',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.livekit.ServerInfo.Edition',
      '10': 'edition'
    },
    const {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
    const {'1': 'protocol', '3': 3, '4': 1, '5': 5, '10': 'protocol'},
    const {'1': 'region', '3': 4, '4': 1, '5': 9, '10': 'region'},
    const {'1': 'node_id', '3': 5, '4': 1, '5': 9, '10': 'nodeId'},
    const {'1': 'debug_info', '3': 6, '4': 1, '5': 9, '10': 'debugInfo'},
  ],
  '4': const [ServerInfo_Edition$json],
};

@$core.Deprecated('Use serverInfoDescriptor instead')
const ServerInfo_Edition$json = const {
  '1': 'Edition',
  '2': const [
    const {'1': 'Standard', '2': 0},
    const {'1': 'Cloud', '2': 1},
  ],
};

/// Descriptor for `ServerInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverInfoDescriptor = $convert.base64Decode(
    'CgpTZXJ2ZXJJbmZvEjUKB2VkaXRpb24YASABKA4yGy5saXZla2l0LlNlcnZlckluZm8uRWRpdGlvblIHZWRpdGlvbhIYCgd2ZXJzaW9uGAIgASgJUgd2ZXJzaW9uEhoKCHByb3RvY29sGAMgASgFUghwcm90b2NvbBIWCgZyZWdpb24YBCABKAlSBnJlZ2lvbhIXCgdub2RlX2lkGAUgASgJUgZub2RlSWQSHQoKZGVidWdfaW5mbxgGIAEoCVIJZGVidWdJbmZvIiIKB0VkaXRpb24SDAoIU3RhbmRhcmQQABIJCgVDbG91ZBAB');
@$core.Deprecated('Use clientInfoDescriptor instead')
const ClientInfo$json = const {
  '1': 'ClientInfo',
  '2': const [
    const {
      '1': 'sdk',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.livekit.ClientInfo.SDK',
      '10': 'sdk'
    },
    const {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
    const {'1': 'protocol', '3': 3, '4': 1, '5': 5, '10': 'protocol'},
    const {'1': 'os', '3': 4, '4': 1, '5': 9, '10': 'os'},
    const {'1': 'os_version', '3': 5, '4': 1, '5': 9, '10': 'osVersion'},
    const {'1': 'device_model', '3': 6, '4': 1, '5': 9, '10': 'deviceModel'},
    const {'1': 'browser', '3': 7, '4': 1, '5': 9, '10': 'browser'},
    const {
      '1': 'browser_version',
      '3': 8,
      '4': 1,
      '5': 9,
      '10': 'browserVersion'
    },
    const {'1': 'address', '3': 9, '4': 1, '5': 9, '10': 'address'},
    const {'1': 'network', '3': 10, '4': 1, '5': 9, '10': 'network'},
  ],
  '4': const [ClientInfo_SDK$json],
};

@$core.Deprecated('Use clientInfoDescriptor instead')
const ClientInfo_SDK$json = const {
  '1': 'SDK',
  '2': const [
    const {'1': 'UNKNOWN', '2': 0},
    const {'1': 'JS', '2': 1},
    const {'1': 'SWIFT', '2': 2},
    const {'1': 'ANDROID', '2': 3},
    const {'1': 'FLUTTER', '2': 4},
    const {'1': 'GO', '2': 5},
    const {'1': 'UNITY', '2': 6},
  ],
};

/// Descriptor for `ClientInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientInfoDescriptor = $convert.base64Decode(
    'CgpDbGllbnRJbmZvEikKA3NkaxgBIAEoDjIXLmxpdmVraXQuQ2xpZW50SW5mby5TREtSA3NkaxIYCgd2ZXJzaW9uGAIgASgJUgd2ZXJzaW9uEhoKCHByb3RvY29sGAMgASgFUghwcm90b2NvbBIOCgJvcxgEIAEoCVICb3MSHQoKb3NfdmVyc2lvbhgFIAEoCVIJb3NWZXJzaW9uEiEKDGRldmljZV9tb2RlbBgGIAEoCVILZGV2aWNlTW9kZWwSGAoHYnJvd3NlchgHIAEoCVIHYnJvd3NlchInCg9icm93c2VyX3ZlcnNpb24YCCABKAlSDmJyb3dzZXJWZXJzaW9uEhgKB2FkZHJlc3MYCSABKAlSB2FkZHJlc3MSGAoHbmV0d29yaxgKIAEoCVIHbmV0d29yayJSCgNTREsSCwoHVU5LTk9XThAAEgYKAkpTEAESCQoFU1dJRlQQAhILCgdBTkRST0lEEAMSCwoHRkxVVFRFUhAEEgYKAkdPEAUSCQoFVU5JVFkQBg==');
@$core.Deprecated('Use clientConfigurationDescriptor instead')
const ClientConfiguration$json = const {
  '1': 'ClientConfiguration',
  '2': const [
    const {
      '1': 'video',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.livekit.VideoConfiguration',
      '10': 'video'
    },
    const {
      '1': 'screen',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.livekit.VideoConfiguration',
      '10': 'screen'
    },
    const {
      '1': 'resume_connection',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.livekit.ClientConfigSetting',
      '10': 'resumeConnection'
    },
    const {
      '1': 'disabled_codecs',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.livekit.DisabledCodecs',
      '10': 'disabledCodecs'
    },
    const {
      '1': 'force_relay',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.livekit.ClientConfigSetting',
      '10': 'forceRelay'
    },
  ],
};

/// Descriptor for `ClientConfiguration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientConfigurationDescriptor = $convert.base64Decode(
    'ChNDbGllbnRDb25maWd1cmF0aW9uEjEKBXZpZGVvGAEgASgLMhsubGl2ZWtpdC5WaWRlb0NvbmZpZ3VyYXRpb25SBXZpZGVvEjMKBnNjcmVlbhgCIAEoCzIbLmxpdmVraXQuVmlkZW9Db25maWd1cmF0aW9uUgZzY3JlZW4SSQoRcmVzdW1lX2Nvbm5lY3Rpb24YAyABKA4yHC5saXZla2l0LkNsaWVudENvbmZpZ1NldHRpbmdSEHJlc3VtZUNvbm5lY3Rpb24SQAoPZGlzYWJsZWRfY29kZWNzGAQgASgLMhcubGl2ZWtpdC5EaXNhYmxlZENvZGVjc1IOZGlzYWJsZWRDb2RlY3MSPQoLZm9yY2VfcmVsYXkYBSABKA4yHC5saXZla2l0LkNsaWVudENvbmZpZ1NldHRpbmdSCmZvcmNlUmVsYXk=');
@$core.Deprecated('Use videoConfigurationDescriptor instead')
const VideoConfiguration$json = const {
  '1': 'VideoConfiguration',
  '2': const [
    const {
      '1': 'hardware_encoder',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.livekit.ClientConfigSetting',
      '10': 'hardwareEncoder'
    },
  ],
};

/// Descriptor for `VideoConfiguration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List videoConfigurationDescriptor = $convert.base64Decode(
    'ChJWaWRlb0NvbmZpZ3VyYXRpb24SRwoQaGFyZHdhcmVfZW5jb2RlchgBIAEoDjIcLmxpdmVraXQuQ2xpZW50Q29uZmlnU2V0dGluZ1IPaGFyZHdhcmVFbmNvZGVy');
@$core.Deprecated('Use disabledCodecsDescriptor instead')
const DisabledCodecs$json = const {
  '1': 'DisabledCodecs',
  '2': const [
    const {
      '1': 'codecs',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.livekit.Codec',
      '10': 'codecs'
    },
  ],
};

/// Descriptor for `DisabledCodecs`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List disabledCodecsDescriptor = $convert.base64Decode(
    'Cg5EaXNhYmxlZENvZGVjcxImCgZjb2RlY3MYASADKAsyDi5saXZla2l0LkNvZGVjUgZjb2RlY3M=');
@$core.Deprecated('Use rTPStatsDescriptor instead')
const RTPStats$json = const {
  '1': 'RTPStats',
  '2': const [
    const {
      '1': 'start_time',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'startTime'
    },
    const {
      '1': 'end_time',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'endTime'
    },
    const {'1': 'duration', '3': 3, '4': 1, '5': 1, '10': 'duration'},
    const {'1': 'packets', '3': 4, '4': 1, '5': 13, '10': 'packets'},
    const {'1': 'packet_rate', '3': 5, '4': 1, '5': 1, '10': 'packetRate'},
    const {'1': 'bytes', '3': 6, '4': 1, '5': 4, '10': 'bytes'},
    const {'1': 'header_bytes', '3': 39, '4': 1, '5': 4, '10': 'headerBytes'},
    const {'1': 'bitrate', '3': 7, '4': 1, '5': 1, '10': 'bitrate'},
    const {'1': 'packets_lost', '3': 8, '4': 1, '5': 13, '10': 'packetsLost'},
    const {
      '1': 'packet_loss_rate',
      '3': 9,
      '4': 1,
      '5': 1,
      '10': 'packetLossRate'
    },
    const {
      '1': 'packet_loss_percentage',
      '3': 10,
      '4': 1,
      '5': 2,
      '10': 'packetLossPercentage'
    },
    const {
      '1': 'packets_duplicate',
      '3': 11,
      '4': 1,
      '5': 13,
      '10': 'packetsDuplicate'
    },
    const {
      '1': 'packet_duplicate_rate',
      '3': 12,
      '4': 1,
      '5': 1,
      '10': 'packetDuplicateRate'
    },
    const {
      '1': 'bytes_duplicate',
      '3': 13,
      '4': 1,
      '5': 4,
      '10': 'bytesDuplicate'
    },
    const {
      '1': 'header_bytes_duplicate',
      '3': 40,
      '4': 1,
      '5': 4,
      '10': 'headerBytesDuplicate'
    },
    const {
      '1': 'bitrate_duplicate',
      '3': 14,
      '4': 1,
      '5': 1,
      '10': 'bitrateDuplicate'
    },
    const {
      '1': 'packets_padding',
      '3': 15,
      '4': 1,
      '5': 13,
      '10': 'packetsPadding'
    },
    const {
      '1': 'packet_padding_rate',
      '3': 16,
      '4': 1,
      '5': 1,
      '10': 'packetPaddingRate'
    },
    const {'1': 'bytes_padding', '3': 17, '4': 1, '5': 4, '10': 'bytesPadding'},
    const {
      '1': 'header_bytes_padding',
      '3': 41,
      '4': 1,
      '5': 4,
      '10': 'headerBytesPadding'
    },
    const {
      '1': 'bitrate_padding',
      '3': 18,
      '4': 1,
      '5': 1,
      '10': 'bitratePadding'
    },
    const {
      '1': 'packets_out_of_order',
      '3': 19,
      '4': 1,
      '5': 13,
      '10': 'packetsOutOfOrder'
    },
    const {'1': 'frames', '3': 20, '4': 1, '5': 13, '10': 'frames'},
    const {'1': 'frame_rate', '3': 21, '4': 1, '5': 1, '10': 'frameRate'},
    const {
      '1': 'jitter_current',
      '3': 22,
      '4': 1,
      '5': 1,
      '10': 'jitterCurrent'
    },
    const {'1': 'jitter_max', '3': 23, '4': 1, '5': 1, '10': 'jitterMax'},
    const {
      '1': 'gap_histogram',
      '3': 24,
      '4': 3,
      '5': 11,
      '6': '.livekit.RTPStats.GapHistogramEntry',
      '10': 'gapHistogram'
    },
    const {'1': 'nacks', '3': 25, '4': 1, '5': 13, '10': 'nacks'},
    const {'1': 'nack_acks', '3': 37, '4': 1, '5': 13, '10': 'nackAcks'},
    const {'1': 'nack_misses', '3': 26, '4': 1, '5': 13, '10': 'nackMisses'},
    const {
      '1': 'nack_repeated',
      '3': 38,
      '4': 1,
      '5': 13,
      '10': 'nackRepeated'
    },
    const {'1': 'plis', '3': 27, '4': 1, '5': 13, '10': 'plis'},
    const {
      '1': 'last_pli',
      '3': 28,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastPli'
    },
    const {'1': 'firs', '3': 29, '4': 1, '5': 13, '10': 'firs'},
    const {
      '1': 'last_fir',
      '3': 30,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastFir'
    },
    const {'1': 'rtt_current', '3': 31, '4': 1, '5': 13, '10': 'rttCurrent'},
    const {'1': 'rtt_max', '3': 32, '4': 1, '5': 13, '10': 'rttMax'},
    const {'1': 'key_frames', '3': 33, '4': 1, '5': 13, '10': 'keyFrames'},
    const {
      '1': 'last_key_frame',
      '3': 34,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastKeyFrame'
    },
    const {
      '1': 'layer_lock_plis',
      '3': 35,
      '4': 1,
      '5': 13,
      '10': 'layerLockPlis'
    },
    const {
      '1': 'last_layer_lock_pli',
      '3': 36,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastLayerLockPli'
    },
  ],
  '3': const [RTPStats_GapHistogramEntry$json],
};

@$core.Deprecated('Use rTPStatsDescriptor instead')
const RTPStats_GapHistogramEntry$json = const {
  '1': 'GapHistogramEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 5, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 13, '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `RTPStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rTPStatsDescriptor = $convert.base64Decode(
    'CghSVFBTdGF0cxI5CgpzdGFydF90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJc3RhcnRUaW1lEjUKCGVuZF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIHZW5kVGltZRIaCghkdXJhdGlvbhgDIAEoAVIIZHVyYXRpb24SGAoHcGFja2V0cxgEIAEoDVIHcGFja2V0cxIfCgtwYWNrZXRfcmF0ZRgFIAEoAVIKcGFja2V0UmF0ZRIUCgVieXRlcxgGIAEoBFIFYnl0ZXMSIQoMaGVhZGVyX2J5dGVzGCcgASgEUgtoZWFkZXJCeXRlcxIYCgdiaXRyYXRlGAcgASgBUgdiaXRyYXRlEiEKDHBhY2tldHNfbG9zdBgIIAEoDVILcGFja2V0c0xvc3QSKAoQcGFja2V0X2xvc3NfcmF0ZRgJIAEoAVIOcGFja2V0TG9zc1JhdGUSNAoWcGFja2V0X2xvc3NfcGVyY2VudGFnZRgKIAEoAlIUcGFja2V0TG9zc1BlcmNlbnRhZ2USKwoRcGFja2V0c19kdXBsaWNhdGUYCyABKA1SEHBhY2tldHNEdXBsaWNhdGUSMgoVcGFja2V0X2R1cGxpY2F0ZV9yYXRlGAwgASgBUhNwYWNrZXREdXBsaWNhdGVSYXRlEicKD2J5dGVzX2R1cGxpY2F0ZRgNIAEoBFIOYnl0ZXNEdXBsaWNhdGUSNAoWaGVhZGVyX2J5dGVzX2R1cGxpY2F0ZRgoIAEoBFIUaGVhZGVyQnl0ZXNEdXBsaWNhdGUSKwoRYml0cmF0ZV9kdXBsaWNhdGUYDiABKAFSEGJpdHJhdGVEdXBsaWNhdGUSJwoPcGFja2V0c19wYWRkaW5nGA8gASgNUg5wYWNrZXRzUGFkZGluZxIuChNwYWNrZXRfcGFkZGluZ19yYXRlGBAgASgBUhFwYWNrZXRQYWRkaW5nUmF0ZRIjCg1ieXRlc19wYWRkaW5nGBEgASgEUgxieXRlc1BhZGRpbmcSMAoUaGVhZGVyX2J5dGVzX3BhZGRpbmcYKSABKARSEmhlYWRlckJ5dGVzUGFkZGluZxInCg9iaXRyYXRlX3BhZGRpbmcYEiABKAFSDmJpdHJhdGVQYWRkaW5nEi8KFHBhY2tldHNfb3V0X29mX29yZGVyGBMgASgNUhFwYWNrZXRzT3V0T2ZPcmRlchIWCgZmcmFtZXMYFCABKA1SBmZyYW1lcxIdCgpmcmFtZV9yYXRlGBUgASgBUglmcmFtZVJhdGUSJQoOaml0dGVyX2N1cnJlbnQYFiABKAFSDWppdHRlckN1cnJlbnQSHQoKaml0dGVyX21heBgXIAEoAVIJaml0dGVyTWF4EkgKDWdhcF9oaXN0b2dyYW0YGCADKAsyIy5saXZla2l0LlJUUFN0YXRzLkdhcEhpc3RvZ3JhbUVudHJ5UgxnYXBIaXN0b2dyYW0SFAoFbmFja3MYGSABKA1SBW5hY2tzEhsKCW5hY2tfYWNrcxglIAEoDVIIbmFja0Fja3MSHwoLbmFja19taXNzZXMYGiABKA1SCm5hY2tNaXNzZXMSIwoNbmFja19yZXBlYXRlZBgmIAEoDVIMbmFja1JlcGVhdGVkEhIKBHBsaXMYGyABKA1SBHBsaXMSNQoIbGFzdF9wbGkYHCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgdsYXN0UGxpEhIKBGZpcnMYHSABKA1SBGZpcnMSNQoIbGFzdF9maXIYHiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgdsYXN0RmlyEh8KC3J0dF9jdXJyZW50GB8gASgNUgpydHRDdXJyZW50EhcKB3J0dF9tYXgYICABKA1SBnJ0dE1heBIdCgprZXlfZnJhbWVzGCEgASgNUglrZXlGcmFtZXMSQAoObGFzdF9rZXlfZnJhbWUYIiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgxsYXN0S2V5RnJhbWUSJgoPbGF5ZXJfbG9ja19wbGlzGCMgASgNUg1sYXllckxvY2tQbGlzEkkKE2xhc3RfbGF5ZXJfbG9ja19wbGkYJCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUhBsYXN0TGF5ZXJMb2NrUGxpGj8KEUdhcEhpc3RvZ3JhbUVudHJ5EhAKA2tleRgBIAEoBVIDa2V5EhQKBXZhbHVlGAIgASgNUgV2YWx1ZToCOAE=');
@$core.Deprecated('Use timedVersionDescriptor instead')
const TimedVersion$json = const {
  '1': 'TimedVersion',
  '2': const [
    const {'1': 'unix_micro', '3': 1, '4': 1, '5': 3, '10': 'unixMicro'},
    const {'1': 'ticks', '3': 2, '4': 1, '5': 5, '10': 'ticks'},
  ],
};

/// Descriptor for `TimedVersion`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List timedVersionDescriptor = $convert.base64Decode(
    'CgxUaW1lZFZlcnNpb24SHQoKdW5peF9taWNybxgBIAEoA1IJdW5peE1pY3JvEhQKBXRpY2tzGAIgASgFUgV0aWNrcw==');
