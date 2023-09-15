//
//  Generated code. Do not modify.
//  source: livekit_models.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use audioCodecDescriptor instead')
const AudioCodec$json = {
  '1': 'AudioCodec',
  '2': [
    {'1': 'DEFAULT_AC', '2': 0},
    {'1': 'OPUS', '2': 1},
    {'1': 'AAC', '2': 2},
  ],
};

/// Descriptor for `AudioCodec`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List audioCodecDescriptor = $convert.base64Decode(
    'CgpBdWRpb0NvZGVjEg4KCkRFRkFVTFRfQUMQABIICgRPUFVTEAESBwoDQUFDEAI=');

@$core.Deprecated('Use videoCodecDescriptor instead')
const VideoCodec$json = {
  '1': 'VideoCodec',
  '2': [
    {'1': 'DEFAULT_VC', '2': 0},
    {'1': 'H264_BASELINE', '2': 1},
    {'1': 'H264_MAIN', '2': 2},
    {'1': 'H264_HIGH', '2': 3},
    {'1': 'VP8', '2': 4},
  ],
};

/// Descriptor for `VideoCodec`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List videoCodecDescriptor = $convert.base64Decode(
    'CgpWaWRlb0NvZGVjEg4KCkRFRkFVTFRfVkMQABIRCg1IMjY0X0JBU0VMSU5FEAESDQoJSDI2NF'
    '9NQUlOEAISDQoJSDI2NF9ISUdIEAMSBwoDVlA4EAQ=');

@$core.Deprecated('Use trackTypeDescriptor instead')
const TrackType$json = {
  '1': 'TrackType',
  '2': [
    {'1': 'AUDIO', '2': 0},
    {'1': 'VIDEO', '2': 1},
    {'1': 'DATA', '2': 2},
  ],
};

/// Descriptor for `TrackType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List trackTypeDescriptor = $convert.base64Decode(
    'CglUcmFja1R5cGUSCQoFQVVESU8QABIJCgVWSURFTxABEggKBERBVEEQAg==');

@$core.Deprecated('Use trackSourceDescriptor instead')
const TrackSource$json = {
  '1': 'TrackSource',
  '2': [
    {'1': 'UNKNOWN', '2': 0},
    {'1': 'CAMERA', '2': 1},
    {'1': 'MICROPHONE', '2': 2},
    {'1': 'SCREEN_SHARE', '2': 3},
    {'1': 'SCREEN_SHARE_AUDIO', '2': 4},
  ],
};

/// Descriptor for `TrackSource`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List trackSourceDescriptor = $convert.base64Decode(
    'CgtUcmFja1NvdXJjZRILCgdVTktOT1dOEAASCgoGQ0FNRVJBEAESDgoKTUlDUk9QSE9ORRACEh'
    'AKDFNDUkVFTl9TSEFSRRADEhYKElNDUkVFTl9TSEFSRV9BVURJTxAE');

@$core.Deprecated('Use videoQualityDescriptor instead')
const VideoQuality$json = {
  '1': 'VideoQuality',
  '2': [
    {'1': 'LOW', '2': 0},
    {'1': 'MEDIUM', '2': 1},
    {'1': 'HIGH', '2': 2},
    {'1': 'OFF', '2': 3},
  ],
};

/// Descriptor for `VideoQuality`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List videoQualityDescriptor = $convert.base64Decode(
    'CgxWaWRlb1F1YWxpdHkSBwoDTE9XEAASCgoGTUVESVVNEAESCAoESElHSBACEgcKA09GRhAD');

@$core.Deprecated('Use connectionQualityDescriptor instead')
const ConnectionQuality$json = {
  '1': 'ConnectionQuality',
  '2': [
    {'1': 'POOR', '2': 0},
    {'1': 'GOOD', '2': 1},
    {'1': 'EXCELLENT', '2': 2},
  ],
};

/// Descriptor for `ConnectionQuality`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List connectionQualityDescriptor = $convert.base64Decode(
    'ChFDb25uZWN0aW9uUXVhbGl0eRIICgRQT09SEAASCAoER09PRBABEg0KCUVYQ0VMTEVOVBAC');

@$core.Deprecated('Use clientConfigSettingDescriptor instead')
const ClientConfigSetting$json = {
  '1': 'ClientConfigSetting',
  '2': [
    {'1': 'UNSET', '2': 0},
    {'1': 'DISABLED', '2': 1},
    {'1': 'ENABLED', '2': 2},
  ],
};

/// Descriptor for `ClientConfigSetting`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List clientConfigSettingDescriptor = $convert.base64Decode(
    'ChNDbGllbnRDb25maWdTZXR0aW5nEgkKBVVOU0VUEAASDAoIRElTQUJMRUQQARILCgdFTkFCTE'
    'VEEAI=');

@$core.Deprecated('Use disconnectReasonDescriptor instead')
const DisconnectReason$json = {
  '1': 'DisconnectReason',
  '2': [
    {'1': 'UNKNOWN_REASON', '2': 0},
    {'1': 'CLIENT_INITIATED', '2': 1},
    {'1': 'DUPLICATE_IDENTITY', '2': 2},
    {'1': 'SERVER_SHUTDOWN', '2': 3},
    {'1': 'PARTICIPANT_REMOVED', '2': 4},
    {'1': 'ROOM_DELETED', '2': 5},
    {'1': 'STATE_MISMATCH', '2': 6},
    {'1': 'JOIN_FAILURE', '2': 7},
  ],
};

/// Descriptor for `DisconnectReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List disconnectReasonDescriptor = $convert.base64Decode(
    'ChBEaXNjb25uZWN0UmVhc29uEhIKDlVOS05PV05fUkVBU09OEAASFAoQQ0xJRU5UX0lOSVRJQV'
    'RFRBABEhYKEkRVUExJQ0FURV9JREVOVElUWRACEhMKD1NFUlZFUl9TSFVURE9XThADEhcKE1BB'
    'UlRJQ0lQQU5UX1JFTU9WRUQQBBIQCgxST09NX0RFTEVURUQQBRISCg5TVEFURV9NSVNNQVRDSB'
    'AGEhAKDEpPSU5fRkFJTFVSRRAH');

@$core.Deprecated('Use reconnectReasonDescriptor instead')
const ReconnectReason$json = {
  '1': 'ReconnectReason',
  '2': [
    {'1': 'RR_UNKNOWN', '2': 0},
    {'1': 'RR_SIGNAL_DISCONNECTED', '2': 1},
    {'1': 'RR_PUBLISHER_FAILED', '2': 2},
    {'1': 'RR_SUBSCRIBER_FAILED', '2': 3},
    {'1': 'RR_SWITCH_CANDIDATE', '2': 4},
  ],
};

/// Descriptor for `ReconnectReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List reconnectReasonDescriptor = $convert.base64Decode(
    'Cg9SZWNvbm5lY3RSZWFzb24SDgoKUlJfVU5LTk9XThAAEhoKFlJSX1NJR05BTF9ESVNDT05ORU'
    'NURUQQARIXChNSUl9QVUJMSVNIRVJfRkFJTEVEEAISGAoUUlJfU1VCU0NSSUJFUl9GQUlMRUQQ'
    'AxIXChNSUl9TV0lUQ0hfQ0FORElEQVRFEAQ=');

@$core.Deprecated('Use subscriptionErrorDescriptor instead')
const SubscriptionError$json = {
  '1': 'SubscriptionError',
  '2': [
    {'1': 'SE_UNKNOWN', '2': 0},
    {'1': 'SE_CODEC_UNSUPPORTED', '2': 1},
    {'1': 'SE_TRACK_NOTFOUND', '2': 2},
  ],
};

/// Descriptor for `SubscriptionError`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List subscriptionErrorDescriptor = $convert.base64Decode(
    'ChFTdWJzY3JpcHRpb25FcnJvchIOCgpTRV9VTktOT1dOEAASGAoUU0VfQ09ERUNfVU5TVVBQT1'
    'JURUQQARIVChFTRV9UUkFDS19OT1RGT1VORBAC');

@$core.Deprecated('Use roomDescriptor instead')
const Room$json = {
  '1': 'Room',
  '2': [
    {'1': 'sid', '3': 1, '4': 1, '5': 9, '10': 'sid'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'empty_timeout', '3': 3, '4': 1, '5': 13, '10': 'emptyTimeout'},
    {'1': 'max_participants', '3': 4, '4': 1, '5': 13, '10': 'maxParticipants'},
    {'1': 'creation_time', '3': 5, '4': 1, '5': 3, '10': 'creationTime'},
    {'1': 'turn_password', '3': 6, '4': 1, '5': 9, '10': 'turnPassword'},
    {
      '1': 'enabled_codecs',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.livekit.Codec',
      '10': 'enabledCodecs'
    },
    {'1': 'metadata', '3': 8, '4': 1, '5': 9, '10': 'metadata'},
    {'1': 'num_participants', '3': 9, '4': 1, '5': 13, '10': 'numParticipants'},
    {'1': 'num_publishers', '3': 11, '4': 1, '5': 13, '10': 'numPublishers'},
    {'1': 'active_recording', '3': 10, '4': 1, '5': 8, '10': 'activeRecording'},
    {
      '1': 'playout_delay',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.livekit.PlayoutDelay',
      '10': 'playoutDelay'
    },
  ],
};

/// Descriptor for `Room`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roomDescriptor = $convert.base64Decode(
    'CgRSb29tEhAKA3NpZBgBIAEoCVIDc2lkEhIKBG5hbWUYAiABKAlSBG5hbWUSIwoNZW1wdHlfdG'
    'ltZW91dBgDIAEoDVIMZW1wdHlUaW1lb3V0EikKEG1heF9wYXJ0aWNpcGFudHMYBCABKA1SD21h'
    'eFBhcnRpY2lwYW50cxIjCg1jcmVhdGlvbl90aW1lGAUgASgDUgxjcmVhdGlvblRpbWUSIwoNdH'
    'Vybl9wYXNzd29yZBgGIAEoCVIMdHVyblBhc3N3b3JkEjUKDmVuYWJsZWRfY29kZWNzGAcgAygL'
    'Mg4ubGl2ZWtpdC5Db2RlY1INZW5hYmxlZENvZGVjcxIaCghtZXRhZGF0YRgIIAEoCVIIbWV0YW'
    'RhdGESKQoQbnVtX3BhcnRpY2lwYW50cxgJIAEoDVIPbnVtUGFydGljaXBhbnRzEiUKDm51bV9w'
    'dWJsaXNoZXJzGAsgASgNUg1udW1QdWJsaXNoZXJzEikKEGFjdGl2ZV9yZWNvcmRpbmcYCiABKA'
    'hSD2FjdGl2ZVJlY29yZGluZxI6Cg1wbGF5b3V0X2RlbGF5GAwgASgLMhUubGl2ZWtpdC5QbGF5'
    'b3V0RGVsYXlSDHBsYXlvdXREZWxheQ==');

@$core.Deprecated('Use codecDescriptor instead')
const Codec$json = {
  '1': 'Codec',
  '2': [
    {'1': 'mime', '3': 1, '4': 1, '5': 9, '10': 'mime'},
    {'1': 'fmtp_line', '3': 2, '4': 1, '5': 9, '10': 'fmtpLine'},
  ],
};

/// Descriptor for `Codec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List codecDescriptor = $convert.base64Decode(
    'CgVDb2RlYxISCgRtaW1lGAEgASgJUgRtaW1lEhsKCWZtdHBfbGluZRgCIAEoCVIIZm10cExpbm'
    'U=');

@$core.Deprecated('Use playoutDelayDescriptor instead')
const PlayoutDelay$json = {
  '1': 'PlayoutDelay',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'min', '3': 2, '4': 1, '5': 13, '10': 'min'},
  ],
};

/// Descriptor for `PlayoutDelay`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playoutDelayDescriptor = $convert.base64Decode(
    'CgxQbGF5b3V0RGVsYXkSGAoHZW5hYmxlZBgBIAEoCFIHZW5hYmxlZBIQCgNtaW4YAiABKA1SA2'
    '1pbg==');

@$core.Deprecated('Use participantPermissionDescriptor instead')
const ParticipantPermission$json = {
  '1': 'ParticipantPermission',
  '2': [
    {'1': 'can_subscribe', '3': 1, '4': 1, '5': 8, '10': 'canSubscribe'},
    {'1': 'can_publish', '3': 2, '4': 1, '5': 8, '10': 'canPublish'},
    {'1': 'can_publish_data', '3': 3, '4': 1, '5': 8, '10': 'canPublishData'},
    {
      '1': 'can_publish_sources',
      '3': 9,
      '4': 3,
      '5': 14,
      '6': '.livekit.TrackSource',
      '10': 'canPublishSources'
    },
    {'1': 'hidden', '3': 7, '4': 1, '5': 8, '10': 'hidden'},
    {'1': 'recorder', '3': 8, '4': 1, '5': 8, '10': 'recorder'},
    {
      '1': 'can_update_metadata',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'canUpdateMetadata'
    },
  ],
};

/// Descriptor for `ParticipantPermission`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List participantPermissionDescriptor = $convert.base64Decode(
    'ChVQYXJ0aWNpcGFudFBlcm1pc3Npb24SIwoNY2FuX3N1YnNjcmliZRgBIAEoCFIMY2FuU3Vic2'
    'NyaWJlEh8KC2Nhbl9wdWJsaXNoGAIgASgIUgpjYW5QdWJsaXNoEigKEGNhbl9wdWJsaXNoX2Rh'
    'dGEYAyABKAhSDmNhblB1Ymxpc2hEYXRhEkQKE2Nhbl9wdWJsaXNoX3NvdXJjZXMYCSADKA4yFC'
    '5saXZla2l0LlRyYWNrU291cmNlUhFjYW5QdWJsaXNoU291cmNlcxIWCgZoaWRkZW4YByABKAhS'
    'BmhpZGRlbhIaCghyZWNvcmRlchgIIAEoCFIIcmVjb3JkZXISLgoTY2FuX3VwZGF0ZV9tZXRhZG'
    'F0YRgKIAEoCFIRY2FuVXBkYXRlTWV0YWRhdGE=');

@$core.Deprecated('Use participantInfoDescriptor instead')
const ParticipantInfo$json = {
  '1': 'ParticipantInfo',
  '2': [
    {'1': 'sid', '3': 1, '4': 1, '5': 9, '10': 'sid'},
    {'1': 'identity', '3': 2, '4': 1, '5': 9, '10': 'identity'},
    {
      '1': 'state',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.livekit.ParticipantInfo.State',
      '10': 'state'
    },
    {
      '1': 'tracks',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.livekit.TrackInfo',
      '10': 'tracks'
    },
    {'1': 'metadata', '3': 5, '4': 1, '5': 9, '10': 'metadata'},
    {'1': 'joined_at', '3': 6, '4': 1, '5': 3, '10': 'joinedAt'},
    {'1': 'name', '3': 9, '4': 1, '5': 9, '10': 'name'},
    {'1': 'version', '3': 10, '4': 1, '5': 13, '10': 'version'},
    {
      '1': 'permission',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.livekit.ParticipantPermission',
      '10': 'permission'
    },
    {'1': 'region', '3': 12, '4': 1, '5': 9, '10': 'region'},
    {'1': 'is_publisher', '3': 13, '4': 1, '5': 8, '10': 'isPublisher'},
  ],
  '4': [ParticipantInfo_State$json],
};

@$core.Deprecated('Use participantInfoDescriptor instead')
const ParticipantInfo_State$json = {
  '1': 'State',
  '2': [
    {'1': 'JOINING', '2': 0},
    {'1': 'JOINED', '2': 1},
    {'1': 'ACTIVE', '2': 2},
    {'1': 'DISCONNECTED', '2': 3},
  ],
};

/// Descriptor for `ParticipantInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List participantInfoDescriptor = $convert.base64Decode(
    'Cg9QYXJ0aWNpcGFudEluZm8SEAoDc2lkGAEgASgJUgNzaWQSGgoIaWRlbnRpdHkYAiABKAlSCG'
    'lkZW50aXR5EjQKBXN0YXRlGAMgASgOMh4ubGl2ZWtpdC5QYXJ0aWNpcGFudEluZm8uU3RhdGVS'
    'BXN0YXRlEioKBnRyYWNrcxgEIAMoCzISLmxpdmVraXQuVHJhY2tJbmZvUgZ0cmFja3MSGgoIbW'
    'V0YWRhdGEYBSABKAlSCG1ldGFkYXRhEhsKCWpvaW5lZF9hdBgGIAEoA1IIam9pbmVkQXQSEgoE'
    'bmFtZRgJIAEoCVIEbmFtZRIYCgd2ZXJzaW9uGAogASgNUgd2ZXJzaW9uEj4KCnBlcm1pc3Npb2'
    '4YCyABKAsyHi5saXZla2l0LlBhcnRpY2lwYW50UGVybWlzc2lvblIKcGVybWlzc2lvbhIWCgZy'
    'ZWdpb24YDCABKAlSBnJlZ2lvbhIhCgxpc19wdWJsaXNoZXIYDSABKAhSC2lzUHVibGlzaGVyIj'
    '4KBVN0YXRlEgsKB0pPSU5JTkcQABIKCgZKT0lORUQQARIKCgZBQ1RJVkUQAhIQCgxESVNDT05O'
    'RUNURUQQAw==');

@$core.Deprecated('Use encryptionDescriptor instead')
const Encryption$json = {
  '1': 'Encryption',
  '4': [Encryption_Type$json],
};

@$core.Deprecated('Use encryptionDescriptor instead')
const Encryption_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'NONE', '2': 0},
    {'1': 'GCM', '2': 1},
    {'1': 'CUSTOM', '2': 2},
  ],
};

/// Descriptor for `Encryption`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List encryptionDescriptor = $convert.base64Decode(
    'CgpFbmNyeXB0aW9uIiUKBFR5cGUSCAoETk9ORRAAEgcKA0dDTRABEgoKBkNVU1RPTRAC');

@$core.Deprecated('Use simulcastCodecInfoDescriptor instead')
const SimulcastCodecInfo$json = {
  '1': 'SimulcastCodecInfo',
  '2': [
    {'1': 'mime_type', '3': 1, '4': 1, '5': 9, '10': 'mimeType'},
    {'1': 'mid', '3': 2, '4': 1, '5': 9, '10': 'mid'},
    {'1': 'cid', '3': 3, '4': 1, '5': 9, '10': 'cid'},
    {
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
    'ChJTaW11bGNhc3RDb2RlY0luZm8SGwoJbWltZV90eXBlGAEgASgJUghtaW1lVHlwZRIQCgNtaW'
    'QYAiABKAlSA21pZBIQCgNjaWQYAyABKAlSA2NpZBIrCgZsYXllcnMYBCADKAsyEy5saXZla2l0'
    'LlZpZGVvTGF5ZXJSBmxheWVycw==');

@$core.Deprecated('Use trackInfoDescriptor instead')
const TrackInfo$json = {
  '1': 'TrackInfo',
  '2': [
    {'1': 'sid', '3': 1, '4': 1, '5': 9, '10': 'sid'},
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.livekit.TrackType',
      '10': 'type'
    },
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'muted', '3': 4, '4': 1, '5': 8, '10': 'muted'},
    {'1': 'width', '3': 5, '4': 1, '5': 13, '10': 'width'},
    {'1': 'height', '3': 6, '4': 1, '5': 13, '10': 'height'},
    {'1': 'simulcast', '3': 7, '4': 1, '5': 8, '10': 'simulcast'},
    {'1': 'disable_dtx', '3': 8, '4': 1, '5': 8, '10': 'disableDtx'},
    {
      '1': 'source',
      '3': 9,
      '4': 1,
      '5': 14,
      '6': '.livekit.TrackSource',
      '10': 'source'
    },
    {
      '1': 'layers',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.livekit.VideoLayer',
      '10': 'layers'
    },
    {'1': 'mime_type', '3': 11, '4': 1, '5': 9, '10': 'mimeType'},
    {'1': 'mid', '3': 12, '4': 1, '5': 9, '10': 'mid'},
    {
      '1': 'codecs',
      '3': 13,
      '4': 3,
      '5': 11,
      '6': '.livekit.SimulcastCodecInfo',
      '10': 'codecs'
    },
    {'1': 'stereo', '3': 14, '4': 1, '5': 8, '10': 'stereo'},
    {'1': 'disable_red', '3': 15, '4': 1, '5': 8, '10': 'disableRed'},
    {
      '1': 'encryption',
      '3': 16,
      '4': 1,
      '5': 14,
      '6': '.livekit.Encryption.Type',
      '10': 'encryption'
    },
    {'1': 'stream', '3': 17, '4': 1, '5': 9, '10': 'stream'},
  ],
};

/// Descriptor for `TrackInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackInfoDescriptor = $convert.base64Decode(
    'CglUcmFja0luZm8SEAoDc2lkGAEgASgJUgNzaWQSJgoEdHlwZRgCIAEoDjISLmxpdmVraXQuVH'
    'JhY2tUeXBlUgR0eXBlEhIKBG5hbWUYAyABKAlSBG5hbWUSFAoFbXV0ZWQYBCABKAhSBW11dGVk'
    'EhQKBXdpZHRoGAUgASgNUgV3aWR0aBIWCgZoZWlnaHQYBiABKA1SBmhlaWdodBIcCglzaW11bG'
    'Nhc3QYByABKAhSCXNpbXVsY2FzdBIfCgtkaXNhYmxlX2R0eBgIIAEoCFIKZGlzYWJsZUR0eBIs'
    'CgZzb3VyY2UYCSABKA4yFC5saXZla2l0LlRyYWNrU291cmNlUgZzb3VyY2USKwoGbGF5ZXJzGA'
    'ogAygLMhMubGl2ZWtpdC5WaWRlb0xheWVyUgZsYXllcnMSGwoJbWltZV90eXBlGAsgASgJUght'
    'aW1lVHlwZRIQCgNtaWQYDCABKAlSA21pZBIzCgZjb2RlY3MYDSADKAsyGy5saXZla2l0LlNpbX'
    'VsY2FzdENvZGVjSW5mb1IGY29kZWNzEhYKBnN0ZXJlbxgOIAEoCFIGc3RlcmVvEh8KC2Rpc2Fi'
    'bGVfcmVkGA8gASgIUgpkaXNhYmxlUmVkEjgKCmVuY3J5cHRpb24YECABKA4yGC5saXZla2l0Lk'
    'VuY3J5cHRpb24uVHlwZVIKZW5jcnlwdGlvbhIWCgZzdHJlYW0YESABKAlSBnN0cmVhbQ==');

@$core.Deprecated('Use videoLayerDescriptor instead')
const VideoLayer$json = {
  '1': 'VideoLayer',
  '2': [
    {
      '1': 'quality',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.livekit.VideoQuality',
      '10': 'quality'
    },
    {'1': 'width', '3': 2, '4': 1, '5': 13, '10': 'width'},
    {'1': 'height', '3': 3, '4': 1, '5': 13, '10': 'height'},
    {'1': 'bitrate', '3': 4, '4': 1, '5': 13, '10': 'bitrate'},
    {'1': 'ssrc', '3': 5, '4': 1, '5': 13, '10': 'ssrc'},
  ],
};

/// Descriptor for `VideoLayer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List videoLayerDescriptor = $convert.base64Decode(
    'CgpWaWRlb0xheWVyEi8KB3F1YWxpdHkYASABKA4yFS5saXZla2l0LlZpZGVvUXVhbGl0eVIHcX'
    'VhbGl0eRIUCgV3aWR0aBgCIAEoDVIFd2lkdGgSFgoGaGVpZ2h0GAMgASgNUgZoZWlnaHQSGAoH'
    'Yml0cmF0ZRgEIAEoDVIHYml0cmF0ZRISCgRzc3JjGAUgASgNUgRzc3Jj');

@$core.Deprecated('Use dataPacketDescriptor instead')
const DataPacket$json = {
  '1': 'DataPacket',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.livekit.DataPacket.Kind',
      '10': 'kind'
    },
    {
      '1': 'user',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.livekit.UserPacket',
      '9': 0,
      '10': 'user'
    },
    {
      '1': 'speaker',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.livekit.ActiveSpeakerUpdate',
      '9': 0,
      '10': 'speaker'
    },
  ],
  '4': [DataPacket_Kind$json],
  '8': [
    {'1': 'value'},
  ],
};

@$core.Deprecated('Use dataPacketDescriptor instead')
const DataPacket_Kind$json = {
  '1': 'Kind',
  '2': [
    {'1': 'RELIABLE', '2': 0},
    {'1': 'LOSSY', '2': 1},
  ],
};

/// Descriptor for `DataPacket`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dataPacketDescriptor = $convert.base64Decode(
    'CgpEYXRhUGFja2V0EiwKBGtpbmQYASABKA4yGC5saXZla2l0LkRhdGFQYWNrZXQuS2luZFIEa2'
    'luZBIpCgR1c2VyGAIgASgLMhMubGl2ZWtpdC5Vc2VyUGFja2V0SABSBHVzZXISOAoHc3BlYWtl'
    'chgDIAEoCzIcLmxpdmVraXQuQWN0aXZlU3BlYWtlclVwZGF0ZUgAUgdzcGVha2VyIh8KBEtpbm'
    'QSDAoIUkVMSUFCTEUQABIJCgVMT1NTWRABQgcKBXZhbHVl');

@$core.Deprecated('Use activeSpeakerUpdateDescriptor instead')
const ActiveSpeakerUpdate$json = {
  '1': 'ActiveSpeakerUpdate',
  '2': [
    {
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
    'ChNBY3RpdmVTcGVha2VyVXBkYXRlEjAKCHNwZWFrZXJzGAEgAygLMhQubGl2ZWtpdC5TcGVha2'
    'VySW5mb1IIc3BlYWtlcnM=');

@$core.Deprecated('Use speakerInfoDescriptor instead')
const SpeakerInfo$json = {
  '1': 'SpeakerInfo',
  '2': [
    {'1': 'sid', '3': 1, '4': 1, '5': 9, '10': 'sid'},
    {'1': 'level', '3': 2, '4': 1, '5': 2, '10': 'level'},
    {'1': 'active', '3': 3, '4': 1, '5': 8, '10': 'active'},
  ],
};

/// Descriptor for `SpeakerInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List speakerInfoDescriptor = $convert.base64Decode(
    'CgtTcGVha2VySW5mbxIQCgNzaWQYASABKAlSA3NpZBIUCgVsZXZlbBgCIAEoAlIFbGV2ZWwSFg'
    'oGYWN0aXZlGAMgASgIUgZhY3RpdmU=');

@$core.Deprecated('Use userPacketDescriptor instead')
const UserPacket$json = {
  '1': 'UserPacket',
  '2': [
    {'1': 'participant_sid', '3': 1, '4': 1, '5': 9, '10': 'participantSid'},
    {
      '1': 'participant_identity',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'participantIdentity'
    },
    {'1': 'payload', '3': 2, '4': 1, '5': 12, '10': 'payload'},
    {'1': 'destination_sids', '3': 3, '4': 3, '5': 9, '10': 'destinationSids'},
    {
      '1': 'destination_identities',
      '3': 6,
      '4': 3,
      '5': 9,
      '10': 'destinationIdentities'
    },
    {'1': 'topic', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'topic', '17': true},
  ],
  '8': [
    {'1': '_topic'},
  ],
};

/// Descriptor for `UserPacket`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userPacketDescriptor = $convert.base64Decode(
    'CgpVc2VyUGFja2V0EicKD3BhcnRpY2lwYW50X3NpZBgBIAEoCVIOcGFydGljaXBhbnRTaWQSMQ'
    'oUcGFydGljaXBhbnRfaWRlbnRpdHkYBSABKAlSE3BhcnRpY2lwYW50SWRlbnRpdHkSGAoHcGF5'
    'bG9hZBgCIAEoDFIHcGF5bG9hZBIpChBkZXN0aW5hdGlvbl9zaWRzGAMgAygJUg9kZXN0aW5hdG'
    'lvblNpZHMSNQoWZGVzdGluYXRpb25faWRlbnRpdGllcxgGIAMoCVIVZGVzdGluYXRpb25JZGVu'
    'dGl0aWVzEhkKBXRvcGljGAQgASgJSABSBXRvcGljiAEBQggKBl90b3BpYw==');

@$core.Deprecated('Use participantTracksDescriptor instead')
const ParticipantTracks$json = {
  '1': 'ParticipantTracks',
  '2': [
    {'1': 'participant_sid', '3': 1, '4': 1, '5': 9, '10': 'participantSid'},
    {'1': 'track_sids', '3': 2, '4': 3, '5': 9, '10': 'trackSids'},
  ],
};

/// Descriptor for `ParticipantTracks`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List participantTracksDescriptor = $convert.base64Decode(
    'ChFQYXJ0aWNpcGFudFRyYWNrcxInCg9wYXJ0aWNpcGFudF9zaWQYASABKAlSDnBhcnRpY2lwYW'
    '50U2lkEh0KCnRyYWNrX3NpZHMYAiADKAlSCXRyYWNrU2lkcw==');

@$core.Deprecated('Use serverInfoDescriptor instead')
const ServerInfo$json = {
  '1': 'ServerInfo',
  '2': [
    {
      '1': 'edition',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.livekit.ServerInfo.Edition',
      '10': 'edition'
    },
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
    {'1': 'protocol', '3': 3, '4': 1, '5': 5, '10': 'protocol'},
    {'1': 'region', '3': 4, '4': 1, '5': 9, '10': 'region'},
    {'1': 'node_id', '3': 5, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'debug_info', '3': 6, '4': 1, '5': 9, '10': 'debugInfo'},
  ],
  '4': [ServerInfo_Edition$json],
};

@$core.Deprecated('Use serverInfoDescriptor instead')
const ServerInfo_Edition$json = {
  '1': 'Edition',
  '2': [
    {'1': 'Standard', '2': 0},
    {'1': 'Cloud', '2': 1},
  ],
};

/// Descriptor for `ServerInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverInfoDescriptor = $convert.base64Decode(
    'CgpTZXJ2ZXJJbmZvEjUKB2VkaXRpb24YASABKA4yGy5saXZla2l0LlNlcnZlckluZm8uRWRpdG'
    'lvblIHZWRpdGlvbhIYCgd2ZXJzaW9uGAIgASgJUgd2ZXJzaW9uEhoKCHByb3RvY29sGAMgASgF'
    'Ughwcm90b2NvbBIWCgZyZWdpb24YBCABKAlSBnJlZ2lvbhIXCgdub2RlX2lkGAUgASgJUgZub2'
    'RlSWQSHQoKZGVidWdfaW5mbxgGIAEoCVIJZGVidWdJbmZvIiIKB0VkaXRpb24SDAoIU3RhbmRh'
    'cmQQABIJCgVDbG91ZBAB');

@$core.Deprecated('Use clientInfoDescriptor instead')
const ClientInfo$json = {
  '1': 'ClientInfo',
  '2': [
    {
      '1': 'sdk',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.livekit.ClientInfo.SDK',
      '10': 'sdk'
    },
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
    {'1': 'protocol', '3': 3, '4': 1, '5': 5, '10': 'protocol'},
    {'1': 'os', '3': 4, '4': 1, '5': 9, '10': 'os'},
    {'1': 'os_version', '3': 5, '4': 1, '5': 9, '10': 'osVersion'},
    {'1': 'device_model', '3': 6, '4': 1, '5': 9, '10': 'deviceModel'},
    {'1': 'browser', '3': 7, '4': 1, '5': 9, '10': 'browser'},
    {'1': 'browser_version', '3': 8, '4': 1, '5': 9, '10': 'browserVersion'},
    {'1': 'address', '3': 9, '4': 1, '5': 9, '10': 'address'},
    {'1': 'network', '3': 10, '4': 1, '5': 9, '10': 'network'},
  ],
  '4': [ClientInfo_SDK$json],
};

@$core.Deprecated('Use clientInfoDescriptor instead')
const ClientInfo_SDK$json = {
  '1': 'SDK',
  '2': [
    {'1': 'UNKNOWN', '2': 0},
    {'1': 'JS', '2': 1},
    {'1': 'SWIFT', '2': 2},
    {'1': 'ANDROID', '2': 3},
    {'1': 'FLUTTER', '2': 4},
    {'1': 'GO', '2': 5},
    {'1': 'UNITY', '2': 6},
    {'1': 'REACT_NATIVE', '2': 7},
    {'1': 'RUST', '2': 8},
    {'1': 'PYTHON', '2': 9},
    {'1': 'CPP', '2': 10},
  ],
};

/// Descriptor for `ClientInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientInfoDescriptor = $convert.base64Decode(
    'CgpDbGllbnRJbmZvEikKA3NkaxgBIAEoDjIXLmxpdmVraXQuQ2xpZW50SW5mby5TREtSA3Nkax'
    'IYCgd2ZXJzaW9uGAIgASgJUgd2ZXJzaW9uEhoKCHByb3RvY29sGAMgASgFUghwcm90b2NvbBIO'
    'CgJvcxgEIAEoCVICb3MSHQoKb3NfdmVyc2lvbhgFIAEoCVIJb3NWZXJzaW9uEiEKDGRldmljZV'
    '9tb2RlbBgGIAEoCVILZGV2aWNlTW9kZWwSGAoHYnJvd3NlchgHIAEoCVIHYnJvd3NlchInCg9i'
    'cm93c2VyX3ZlcnNpb24YCCABKAlSDmJyb3dzZXJWZXJzaW9uEhgKB2FkZHJlc3MYCSABKAlSB2'
    'FkZHJlc3MSGAoHbmV0d29yaxgKIAEoCVIHbmV0d29yayKDAQoDU0RLEgsKB1VOS05PV04QABIG'
    'CgJKUxABEgkKBVNXSUZUEAISCwoHQU5EUk9JRBADEgsKB0ZMVVRURVIQBBIGCgJHTxAFEgkKBV'
    'VOSVRZEAYSEAoMUkVBQ1RfTkFUSVZFEAcSCAoEUlVTVBAIEgoKBlBZVEhPThAJEgcKA0NQUBAK');

@$core.Deprecated('Use clientConfigurationDescriptor instead')
const ClientConfiguration$json = {
  '1': 'ClientConfiguration',
  '2': [
    {
      '1': 'video',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.livekit.VideoConfiguration',
      '10': 'video'
    },
    {
      '1': 'screen',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.livekit.VideoConfiguration',
      '10': 'screen'
    },
    {
      '1': 'resume_connection',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.livekit.ClientConfigSetting',
      '10': 'resumeConnection'
    },
    {
      '1': 'disabled_codecs',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.livekit.DisabledCodecs',
      '10': 'disabledCodecs'
    },
    {
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
    'ChNDbGllbnRDb25maWd1cmF0aW9uEjEKBXZpZGVvGAEgASgLMhsubGl2ZWtpdC5WaWRlb0Nvbm'
    'ZpZ3VyYXRpb25SBXZpZGVvEjMKBnNjcmVlbhgCIAEoCzIbLmxpdmVraXQuVmlkZW9Db25maWd1'
    'cmF0aW9uUgZzY3JlZW4SSQoRcmVzdW1lX2Nvbm5lY3Rpb24YAyABKA4yHC5saXZla2l0LkNsaW'
    'VudENvbmZpZ1NldHRpbmdSEHJlc3VtZUNvbm5lY3Rpb24SQAoPZGlzYWJsZWRfY29kZWNzGAQg'
    'ASgLMhcubGl2ZWtpdC5EaXNhYmxlZENvZGVjc1IOZGlzYWJsZWRDb2RlY3MSPQoLZm9yY2Vfcm'
    'VsYXkYBSABKA4yHC5saXZla2l0LkNsaWVudENvbmZpZ1NldHRpbmdSCmZvcmNlUmVsYXk=');

@$core.Deprecated('Use videoConfigurationDescriptor instead')
const VideoConfiguration$json = {
  '1': 'VideoConfiguration',
  '2': [
    {
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
    'ChJWaWRlb0NvbmZpZ3VyYXRpb24SRwoQaGFyZHdhcmVfZW5jb2RlchgBIAEoDjIcLmxpdmVraX'
    'QuQ2xpZW50Q29uZmlnU2V0dGluZ1IPaGFyZHdhcmVFbmNvZGVy');

@$core.Deprecated('Use disabledCodecsDescriptor instead')
const DisabledCodecs$json = {
  '1': 'DisabledCodecs',
  '2': [
    {
      '1': 'codecs',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.livekit.Codec',
      '10': 'codecs'
    },
    {
      '1': 'publish',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.livekit.Codec',
      '10': 'publish'
    },
  ],
};

/// Descriptor for `DisabledCodecs`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List disabledCodecsDescriptor = $convert.base64Decode(
    'Cg5EaXNhYmxlZENvZGVjcxImCgZjb2RlY3MYASADKAsyDi5saXZla2l0LkNvZGVjUgZjb2RlY3'
    'MSKAoHcHVibGlzaBgCIAMoCzIOLmxpdmVraXQuQ29kZWNSB3B1Ymxpc2g=');

@$core.Deprecated('Use rTPDriftDescriptor instead')
const RTPDrift$json = {
  '1': 'RTPDrift',
  '2': [
    {
      '1': 'start_time',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'startTime'
    },
    {
      '1': 'end_time',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'endTime'
    },
    {'1': 'duration', '3': 3, '4': 1, '5': 1, '10': 'duration'},
    {'1': 'start_timestamp', '3': 4, '4': 1, '5': 4, '10': 'startTimestamp'},
    {'1': 'end_timestamp', '3': 5, '4': 1, '5': 4, '10': 'endTimestamp'},
    {'1': 'rtp_clock_ticks', '3': 6, '4': 1, '5': 4, '10': 'rtpClockTicks'},
    {'1': 'drift_samples', '3': 7, '4': 1, '5': 3, '10': 'driftSamples'},
    {'1': 'drift_ms', '3': 8, '4': 1, '5': 1, '10': 'driftMs'},
    {'1': 'clock_rate', '3': 9, '4': 1, '5': 1, '10': 'clockRate'},
  ],
};

/// Descriptor for `RTPDrift`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rTPDriftDescriptor = $convert.base64Decode(
    'CghSVFBEcmlmdBI5CgpzdGFydF90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdG'
    'FtcFIJc3RhcnRUaW1lEjUKCGVuZF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz'
    'dGFtcFIHZW5kVGltZRIaCghkdXJhdGlvbhgDIAEoAVIIZHVyYXRpb24SJwoPc3RhcnRfdGltZX'
    'N0YW1wGAQgASgEUg5zdGFydFRpbWVzdGFtcBIjCg1lbmRfdGltZXN0YW1wGAUgASgEUgxlbmRU'
    'aW1lc3RhbXASJgoPcnRwX2Nsb2NrX3RpY2tzGAYgASgEUg1ydHBDbG9ja1RpY2tzEiMKDWRyaW'
    'Z0X3NhbXBsZXMYByABKANSDGRyaWZ0U2FtcGxlcxIZCghkcmlmdF9tcxgIIAEoAVIHZHJpZnRN'
    'cxIdCgpjbG9ja19yYXRlGAkgASgBUgljbG9ja1JhdGU=');

@$core.Deprecated('Use rTPStatsDescriptor instead')
const RTPStats$json = {
  '1': 'RTPStats',
  '2': [
    {
      '1': 'start_time',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'startTime'
    },
    {
      '1': 'end_time',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'endTime'
    },
    {'1': 'duration', '3': 3, '4': 1, '5': 1, '10': 'duration'},
    {'1': 'packets', '3': 4, '4': 1, '5': 13, '10': 'packets'},
    {'1': 'packet_rate', '3': 5, '4': 1, '5': 1, '10': 'packetRate'},
    {'1': 'bytes', '3': 6, '4': 1, '5': 4, '10': 'bytes'},
    {'1': 'header_bytes', '3': 39, '4': 1, '5': 4, '10': 'headerBytes'},
    {'1': 'bitrate', '3': 7, '4': 1, '5': 1, '10': 'bitrate'},
    {'1': 'packets_lost', '3': 8, '4': 1, '5': 13, '10': 'packetsLost'},
    {'1': 'packet_loss_rate', '3': 9, '4': 1, '5': 1, '10': 'packetLossRate'},
    {
      '1': 'packet_loss_percentage',
      '3': 10,
      '4': 1,
      '5': 2,
      '10': 'packetLossPercentage'
    },
    {
      '1': 'packets_duplicate',
      '3': 11,
      '4': 1,
      '5': 13,
      '10': 'packetsDuplicate'
    },
    {
      '1': 'packet_duplicate_rate',
      '3': 12,
      '4': 1,
      '5': 1,
      '10': 'packetDuplicateRate'
    },
    {'1': 'bytes_duplicate', '3': 13, '4': 1, '5': 4, '10': 'bytesDuplicate'},
    {
      '1': 'header_bytes_duplicate',
      '3': 40,
      '4': 1,
      '5': 4,
      '10': 'headerBytesDuplicate'
    },
    {
      '1': 'bitrate_duplicate',
      '3': 14,
      '4': 1,
      '5': 1,
      '10': 'bitrateDuplicate'
    },
    {'1': 'packets_padding', '3': 15, '4': 1, '5': 13, '10': 'packetsPadding'},
    {
      '1': 'packet_padding_rate',
      '3': 16,
      '4': 1,
      '5': 1,
      '10': 'packetPaddingRate'
    },
    {'1': 'bytes_padding', '3': 17, '4': 1, '5': 4, '10': 'bytesPadding'},
    {
      '1': 'header_bytes_padding',
      '3': 41,
      '4': 1,
      '5': 4,
      '10': 'headerBytesPadding'
    },
    {'1': 'bitrate_padding', '3': 18, '4': 1, '5': 1, '10': 'bitratePadding'},
    {
      '1': 'packets_out_of_order',
      '3': 19,
      '4': 1,
      '5': 13,
      '10': 'packetsOutOfOrder'
    },
    {'1': 'frames', '3': 20, '4': 1, '5': 13, '10': 'frames'},
    {'1': 'frame_rate', '3': 21, '4': 1, '5': 1, '10': 'frameRate'},
    {'1': 'jitter_current', '3': 22, '4': 1, '5': 1, '10': 'jitterCurrent'},
    {'1': 'jitter_max', '3': 23, '4': 1, '5': 1, '10': 'jitterMax'},
    {
      '1': 'gap_histogram',
      '3': 24,
      '4': 3,
      '5': 11,
      '6': '.livekit.RTPStats.GapHistogramEntry',
      '10': 'gapHistogram'
    },
    {'1': 'nacks', '3': 25, '4': 1, '5': 13, '10': 'nacks'},
    {'1': 'nack_acks', '3': 37, '4': 1, '5': 13, '10': 'nackAcks'},
    {'1': 'nack_misses', '3': 26, '4': 1, '5': 13, '10': 'nackMisses'},
    {'1': 'nack_repeated', '3': 38, '4': 1, '5': 13, '10': 'nackRepeated'},
    {'1': 'plis', '3': 27, '4': 1, '5': 13, '10': 'plis'},
    {
      '1': 'last_pli',
      '3': 28,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastPli'
    },
    {'1': 'firs', '3': 29, '4': 1, '5': 13, '10': 'firs'},
    {
      '1': 'last_fir',
      '3': 30,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastFir'
    },
    {'1': 'rtt_current', '3': 31, '4': 1, '5': 13, '10': 'rttCurrent'},
    {'1': 'rtt_max', '3': 32, '4': 1, '5': 13, '10': 'rttMax'},
    {'1': 'key_frames', '3': 33, '4': 1, '5': 13, '10': 'keyFrames'},
    {
      '1': 'last_key_frame',
      '3': 34,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastKeyFrame'
    },
    {'1': 'layer_lock_plis', '3': 35, '4': 1, '5': 13, '10': 'layerLockPlis'},
    {
      '1': 'last_layer_lock_pli',
      '3': 36,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastLayerLockPli'
    },
    {
      '1': 'packet_drift',
      '3': 44,
      '4': 1,
      '5': 11,
      '6': '.livekit.RTPDrift',
      '10': 'packetDrift'
    },
    {
      '1': 'report_drift',
      '3': 45,
      '4': 1,
      '5': 11,
      '6': '.livekit.RTPDrift',
      '10': 'reportDrift'
    },
  ],
  '3': [RTPStats_GapHistogramEntry$json],
};

@$core.Deprecated('Use rTPStatsDescriptor instead')
const RTPStats_GapHistogramEntry$json = {
  '1': 'GapHistogramEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 5, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 13, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `RTPStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rTPStatsDescriptor = $convert.base64Decode(
    'CghSVFBTdGF0cxI5CgpzdGFydF90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdG'
    'FtcFIJc3RhcnRUaW1lEjUKCGVuZF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz'
    'dGFtcFIHZW5kVGltZRIaCghkdXJhdGlvbhgDIAEoAVIIZHVyYXRpb24SGAoHcGFja2V0cxgEIA'
    'EoDVIHcGFja2V0cxIfCgtwYWNrZXRfcmF0ZRgFIAEoAVIKcGFja2V0UmF0ZRIUCgVieXRlcxgG'
    'IAEoBFIFYnl0ZXMSIQoMaGVhZGVyX2J5dGVzGCcgASgEUgtoZWFkZXJCeXRlcxIYCgdiaXRyYX'
    'RlGAcgASgBUgdiaXRyYXRlEiEKDHBhY2tldHNfbG9zdBgIIAEoDVILcGFja2V0c0xvc3QSKAoQ'
    'cGFja2V0X2xvc3NfcmF0ZRgJIAEoAVIOcGFja2V0TG9zc1JhdGUSNAoWcGFja2V0X2xvc3NfcG'
    'VyY2VudGFnZRgKIAEoAlIUcGFja2V0TG9zc1BlcmNlbnRhZ2USKwoRcGFja2V0c19kdXBsaWNh'
    'dGUYCyABKA1SEHBhY2tldHNEdXBsaWNhdGUSMgoVcGFja2V0X2R1cGxpY2F0ZV9yYXRlGAwgAS'
    'gBUhNwYWNrZXREdXBsaWNhdGVSYXRlEicKD2J5dGVzX2R1cGxpY2F0ZRgNIAEoBFIOYnl0ZXNE'
    'dXBsaWNhdGUSNAoWaGVhZGVyX2J5dGVzX2R1cGxpY2F0ZRgoIAEoBFIUaGVhZGVyQnl0ZXNEdX'
    'BsaWNhdGUSKwoRYml0cmF0ZV9kdXBsaWNhdGUYDiABKAFSEGJpdHJhdGVEdXBsaWNhdGUSJwoP'
    'cGFja2V0c19wYWRkaW5nGA8gASgNUg5wYWNrZXRzUGFkZGluZxIuChNwYWNrZXRfcGFkZGluZ1'
    '9yYXRlGBAgASgBUhFwYWNrZXRQYWRkaW5nUmF0ZRIjCg1ieXRlc19wYWRkaW5nGBEgASgEUgxi'
    'eXRlc1BhZGRpbmcSMAoUaGVhZGVyX2J5dGVzX3BhZGRpbmcYKSABKARSEmhlYWRlckJ5dGVzUG'
    'FkZGluZxInCg9iaXRyYXRlX3BhZGRpbmcYEiABKAFSDmJpdHJhdGVQYWRkaW5nEi8KFHBhY2tl'
    'dHNfb3V0X29mX29yZGVyGBMgASgNUhFwYWNrZXRzT3V0T2ZPcmRlchIWCgZmcmFtZXMYFCABKA'
    '1SBmZyYW1lcxIdCgpmcmFtZV9yYXRlGBUgASgBUglmcmFtZVJhdGUSJQoOaml0dGVyX2N1cnJl'
    'bnQYFiABKAFSDWppdHRlckN1cnJlbnQSHQoKaml0dGVyX21heBgXIAEoAVIJaml0dGVyTWF4Ek'
    'gKDWdhcF9oaXN0b2dyYW0YGCADKAsyIy5saXZla2l0LlJUUFN0YXRzLkdhcEhpc3RvZ3JhbUVu'
    'dHJ5UgxnYXBIaXN0b2dyYW0SFAoFbmFja3MYGSABKA1SBW5hY2tzEhsKCW5hY2tfYWNrcxglIA'
    'EoDVIIbmFja0Fja3MSHwoLbmFja19taXNzZXMYGiABKA1SCm5hY2tNaXNzZXMSIwoNbmFja19y'
    'ZXBlYXRlZBgmIAEoDVIMbmFja1JlcGVhdGVkEhIKBHBsaXMYGyABKA1SBHBsaXMSNQoIbGFzdF'
    '9wbGkYHCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgdsYXN0UGxpEhIKBGZpcnMY'
    'HSABKA1SBGZpcnMSNQoIbGFzdF9maXIYHiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW'
    '1wUgdsYXN0RmlyEh8KC3J0dF9jdXJyZW50GB8gASgNUgpydHRDdXJyZW50EhcKB3J0dF9tYXgY'
    'ICABKA1SBnJ0dE1heBIdCgprZXlfZnJhbWVzGCEgASgNUglrZXlGcmFtZXMSQAoObGFzdF9rZX'
    'lfZnJhbWUYIiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgxsYXN0S2V5RnJhbWUS'
    'JgoPbGF5ZXJfbG9ja19wbGlzGCMgASgNUg1sYXllckxvY2tQbGlzEkkKE2xhc3RfbGF5ZXJfbG'
    '9ja19wbGkYJCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUhBsYXN0TGF5ZXJMb2Nr'
    'UGxpEjQKDHBhY2tldF9kcmlmdBgsIAEoCzIRLmxpdmVraXQuUlRQRHJpZnRSC3BhY2tldERyaW'
    'Z0EjQKDHJlcG9ydF9kcmlmdBgtIAEoCzIRLmxpdmVraXQuUlRQRHJpZnRSC3JlcG9ydERyaWZ0'
    'Gj8KEUdhcEhpc3RvZ3JhbUVudHJ5EhAKA2tleRgBIAEoBVIDa2V5EhQKBXZhbHVlGAIgASgNUg'
    'V2YWx1ZToCOAE=');

@$core.Deprecated('Use timedVersionDescriptor instead')
const TimedVersion$json = {
  '1': 'TimedVersion',
  '2': [
    {'1': 'unix_micro', '3': 1, '4': 1, '5': 3, '10': 'unixMicro'},
    {'1': 'ticks', '3': 2, '4': 1, '5': 5, '10': 'ticks'},
  ],
};

/// Descriptor for `TimedVersion`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List timedVersionDescriptor = $convert.base64Decode(
    'CgxUaW1lZFZlcnNpb24SHQoKdW5peF9taWNybxgBIAEoA1IJdW5peE1pY3JvEhQKBXRpY2tzGA'
    'IgASgFUgV0aWNrcw==');
