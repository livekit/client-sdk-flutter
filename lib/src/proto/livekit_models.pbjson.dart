///
//  Generated code. Do not modify.
//  source: livekit_models.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

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
final $typed_data.Uint8List trackTypeDescriptor =
    $convert.base64Decode('CglUcmFja1R5cGUSCQoFQVVESU8QABIJCgVWSURFTxABEggKBERBVEEQAg==');
@$core.Deprecated('Use roomDescriptor instead')
const Room$json = const {
  '1': 'Room',
  '2': const [
    const {'1': 'sid', '3': 1, '4': 1, '5': 9, '10': 'sid'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'empty_timeout', '3': 3, '4': 1, '5': 13, '10': 'emptyTimeout'},
    const {'1': 'max_participants', '3': 4, '4': 1, '5': 13, '10': 'maxParticipants'},
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
  ],
};

/// Descriptor for `Room`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roomDescriptor = $convert.base64Decode(
    'CgRSb29tEhAKA3NpZBgBIAEoCVIDc2lkEhIKBG5hbWUYAiABKAlSBG5hbWUSIwoNZW1wdHlfdGltZW91dBgDIAEoDVIMZW1wdHlUaW1lb3V0EikKEG1heF9wYXJ0aWNpcGFudHMYBCABKA1SD21heFBhcnRpY2lwYW50cxIjCg1jcmVhdGlvbl90aW1lGAUgASgDUgxjcmVhdGlvblRpbWUSIwoNdHVybl9wYXNzd29yZBgGIAEoCVIMdHVyblBhc3N3b3JkEjUKDmVuYWJsZWRfY29kZWNzGAcgAygLMg4ubGl2ZWtpdC5Db2RlY1INZW5hYmxlZENvZGVjcw==');
@$core.Deprecated('Use codecDescriptor instead')
const Codec$json = const {
  '1': 'Codec',
  '2': const [
    const {'1': 'mime', '3': 1, '4': 1, '5': 9, '10': 'mime'},
    const {'1': 'fmtp_line', '3': 2, '4': 1, '5': 9, '10': 'fmtpLine'},
  ],
};

/// Descriptor for `Codec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List codecDescriptor = $convert
    .base64Decode('CgVDb2RlYxISCgRtaW1lGAEgASgJUgRtaW1lEhsKCWZtdHBfbGluZRgCIAEoCVIIZm10cExpbmU=');
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
    const {'1': 'tracks', '3': 4, '4': 3, '5': 11, '6': '.livekit.TrackInfo', '10': 'tracks'},
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
    const {'1': 'type', '3': 2, '4': 1, '5': 14, '6': '.livekit.TrackType', '10': 'type'},
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'muted', '3': 4, '4': 1, '5': 8, '10': 'muted'},
    const {'1': 'width', '3': 5, '4': 1, '5': 13, '10': 'width'},
    const {'1': 'height', '3': 6, '4': 1, '5': 13, '10': 'height'},
    const {'1': 'simulcast', '3': 7, '4': 1, '5': 8, '10': 'simulcast'},
  ],
};

/// Descriptor for `TrackInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackInfoDescriptor = $convert.base64Decode(
    'CglUcmFja0luZm8SEAoDc2lkGAEgASgJUgNzaWQSJgoEdHlwZRgCIAEoDjISLmxpdmVraXQuVHJhY2tUeXBlUgR0eXBlEhIKBG5hbWUYAyABKAlSBG5hbWUSFAoFbXV0ZWQYBCABKAhSBW11dGVkEhQKBXdpZHRoGAUgASgNUgV3aWR0aBIWCgZoZWlnaHQYBiABKA1SBmhlaWdodBIcCglzaW11bGNhc3QYByABKAhSCXNpbXVsY2FzdA==');
@$core.Deprecated('Use dataMessageDescriptor instead')
const DataMessage$json = const {
  '1': 'DataMessage',
  '2': const [
    const {'1': 'text', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'text'},
    const {'1': 'binary', '3': 2, '4': 1, '5': 12, '9': 0, '10': 'binary'},
  ],
  '8': const [
    const {'1': 'value'},
  ],
};

/// Descriptor for `DataMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dataMessageDescriptor = $convert.base64Decode(
    'CgtEYXRhTWVzc2FnZRIUCgR0ZXh0GAEgASgJSABSBHRleHQSGAoGYmluYXJ5GAIgASgMSABSBmJpbmFyeUIHCgV2YWx1ZQ==');
@$core.Deprecated('Use recordingInputDescriptor instead')
const RecordingInput$json = const {
  '1': 'RecordingInput',
  '2': const [
    const {'1': 'url', '3': 1, '4': 1, '5': 9, '10': 'url'},
    const {
      '1': 'template',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.livekit.RecordingTemplate',
      '10': 'template'
    },
    const {'1': 'width', '3': 3, '4': 1, '5': 5, '10': 'width'},
    const {'1': 'height', '3': 4, '4': 1, '5': 5, '10': 'height'},
    const {'1': 'depth', '3': 5, '4': 1, '5': 5, '10': 'depth'},
    const {'1': 'framerate', '3': 6, '4': 1, '5': 5, '10': 'framerate'},
  ],
};

/// Descriptor for `RecordingInput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recordingInputDescriptor = $convert.base64Decode(
    'Cg5SZWNvcmRpbmdJbnB1dBIQCgN1cmwYASABKAlSA3VybBI2Cgh0ZW1wbGF0ZRgCIAEoCzIaLmxpdmVraXQuUmVjb3JkaW5nVGVtcGxhdGVSCHRlbXBsYXRlEhQKBXdpZHRoGAMgASgFUgV3aWR0aBIWCgZoZWlnaHQYBCABKAVSBmhlaWdodBIUCgVkZXB0aBgFIAEoBVIFZGVwdGgSHAoJZnJhbWVyYXRlGAYgASgFUglmcmFtZXJhdGU=');
@$core.Deprecated('Use recordingTemplateDescriptor instead')
const RecordingTemplate$json = const {
  '1': 'RecordingTemplate',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'ws_url', '3': 2, '4': 1, '5': 9, '10': 'wsUrl'},
    const {'1': 'token', '3': 3, '4': 1, '5': 9, '10': 'token'},
    const {'1': 'room_name', '3': 4, '4': 1, '5': 9, '10': 'roomName'},
  ],
};

/// Descriptor for `RecordingTemplate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recordingTemplateDescriptor = $convert.base64Decode(
    'ChFSZWNvcmRpbmdUZW1wbGF0ZRISCgR0eXBlGAEgASgJUgR0eXBlEhUKBndzX3VybBgCIAEoCVIFd3NVcmwSFAoFdG9rZW4YAyABKAlSBXRva2VuEhsKCXJvb21fbmFtZRgEIAEoCVIIcm9vbU5hbWU=');
@$core.Deprecated('Use recordingOutputDescriptor instead')
const RecordingOutput$json = const {
  '1': 'RecordingOutput',
  '2': const [
    const {'1': 'file', '3': 1, '4': 1, '5': 9, '10': 'file'},
    const {'1': 'rtmp', '3': 2, '4': 1, '5': 9, '10': 'rtmp'},
    const {'1': 's3', '3': 3, '4': 1, '5': 11, '6': '.livekit.RecordingS3Output', '10': 's3'},
    const {'1': 'width', '3': 4, '4': 1, '5': 5, '10': 'width'},
    const {'1': 'height', '3': 5, '4': 1, '5': 5, '10': 'height'},
    const {'1': 'audio_bitrate', '3': 6, '4': 1, '5': 9, '10': 'audioBitrate'},
    const {'1': 'audio_frequency', '3': 7, '4': 1, '5': 9, '10': 'audioFrequency'},
    const {'1': 'video_bitrate', '3': 8, '4': 1, '5': 9, '10': 'videoBitrate'},
    const {'1': 'video_buffer', '3': 9, '4': 1, '5': 9, '10': 'videoBuffer'},
  ],
};

/// Descriptor for `RecordingOutput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recordingOutputDescriptor = $convert.base64Decode(
    'Cg9SZWNvcmRpbmdPdXRwdXQSEgoEZmlsZRgBIAEoCVIEZmlsZRISCgRydG1wGAIgASgJUgRydG1wEioKAnMzGAMgASgLMhoubGl2ZWtpdC5SZWNvcmRpbmdTM091dHB1dFICczMSFAoFd2lkdGgYBCABKAVSBXdpZHRoEhYKBmhlaWdodBgFIAEoBVIGaGVpZ2h0EiMKDWF1ZGlvX2JpdHJhdGUYBiABKAlSDGF1ZGlvQml0cmF0ZRInCg9hdWRpb19mcmVxdWVuY3kYByABKAlSDmF1ZGlvRnJlcXVlbmN5EiMKDXZpZGVvX2JpdHJhdGUYCCABKAlSDHZpZGVvQml0cmF0ZRIhCgx2aWRlb19idWZmZXIYCSABKAlSC3ZpZGVvQnVmZmVy');
@$core.Deprecated('Use recordingS3OutputDescriptor instead')
const RecordingS3Output$json = const {
  '1': 'RecordingS3Output',
  '2': const [
    const {'1': 'bucket', '3': 1, '4': 1, '5': 9, '10': 'bucket'},
    const {'1': 'key', '3': 2, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'access_key', '3': 3, '4': 1, '5': 9, '10': 'accessKey'},
    const {'1': 'secret', '3': 4, '4': 1, '5': 9, '10': 'secret'},
  ],
};

/// Descriptor for `RecordingS3Output`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recordingS3OutputDescriptor = $convert.base64Decode(
    'ChFSZWNvcmRpbmdTM091dHB1dBIWCgZidWNrZXQYASABKAlSBmJ1Y2tldBIQCgNrZXkYAiABKAlSA2tleRIdCgphY2Nlc3Nfa2V5GAMgASgJUglhY2Nlc3NLZXkSFgoGc2VjcmV0GAQgASgJUgZzZWNyZXQ=');
