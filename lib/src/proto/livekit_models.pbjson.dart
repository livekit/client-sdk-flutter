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
  ],
};

/// Descriptor for `TrackSource`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List trackSourceDescriptor = $convert.base64Decode(
    'CgtUcmFja1NvdXJjZRILCgdVTktOT1dOEAASCgoGQ0FNRVJBEAESDgoKTUlDUk9QSE9ORRACEhAKDFNDUkVFTl9TSEFSRRAD');
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
  ],
};

/// Descriptor for `Room`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roomDescriptor = $convert.base64Decode(
    'CgRSb29tEhAKA3NpZBgBIAEoCVIDc2lkEhIKBG5hbWUYAiABKAlSBG5hbWUSIwoNZW1wdHlfdGltZW91dBgDIAEoDVIMZW1wdHlUaW1lb3V0EikKEG1heF9wYXJ0aWNpcGFudHMYBCABKA1SD21heFBhcnRpY2lwYW50cxIjCg1jcmVhdGlvbl90aW1lGAUgASgDUgxjcmVhdGlvblRpbWUSIwoNdHVybl9wYXNzd29yZBgGIAEoCVIMdHVyblBhc3N3b3JkEjUKDmVuYWJsZWRfY29kZWNzGAcgAygLMg4ubGl2ZWtpdC5Db2RlY1INZW5hYmxlZENvZGVjcxIaCghtZXRhZGF0YRgIIAEoCVIIbWV0YWRhdGESKQoQbnVtX3BhcnRpY2lwYW50cxgJIAEoDVIPbnVtUGFydGljaXBhbnRz');
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
    const {'1': 'hidden', '3': 7, '4': 1, '5': 8, '10': 'hidden'},
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
    'Cg9QYXJ0aWNpcGFudEluZm8SEAoDc2lkGAEgASgJUgNzaWQSGgoIaWRlbnRpdHkYAiABKAlSCGlkZW50aXR5EjQKBXN0YXRlGAMgASgOMh4ubGl2ZWtpdC5QYXJ0aWNpcGFudEluZm8uU3RhdGVSBXN0YXRlEioKBnRyYWNrcxgEIAMoCzISLmxpdmVraXQuVHJhY2tJbmZvUgZ0cmFja3MSGgoIbWV0YWRhdGEYBSABKAlSCG1ldGFkYXRhEhsKCWpvaW5lZF9hdBgGIAEoA1IIam9pbmVkQXQSFgoGaGlkZGVuGAcgASgIUgZoaWRkZW4iPgoFU3RhdGUSCwoHSk9JTklORxAAEgoKBkpPSU5FRBABEgoKBkFDVElWRRACEhAKDERJU0NPTk5FQ1RFRBAD');
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
  ],
};

/// Descriptor for `TrackInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackInfoDescriptor = $convert.base64Decode(
    'CglUcmFja0luZm8SEAoDc2lkGAEgASgJUgNzaWQSJgoEdHlwZRgCIAEoDjISLmxpdmVraXQuVHJhY2tUeXBlUgR0eXBlEhIKBG5hbWUYAyABKAlSBG5hbWUSFAoFbXV0ZWQYBCABKAhSBW11dGVkEhQKBXdpZHRoGAUgASgNUgV3aWR0aBIWCgZoZWlnaHQYBiABKA1SBmhlaWdodBIcCglzaW11bGNhc3QYByABKAhSCXNpbXVsY2FzdBIfCgtkaXNhYmxlX2R0eBgIIAEoCFIKZGlzYWJsZUR0eBIsCgZzb3VyY2UYCSABKA4yFC5saXZla2l0LlRyYWNrU291cmNlUgZzb3VyY2U=');
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
