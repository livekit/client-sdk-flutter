///
//  Generated code. Do not modify.
//  source: livekit_rtc.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use signalTargetDescriptor instead')
const SignalTarget$json = const {
  '1': 'SignalTarget',
  '2': const [
    const {'1': 'PUBLISHER', '2': 0},
    const {'1': 'SUBSCRIBER', '2': 1},
  ],
};

/// Descriptor for `SignalTarget`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List signalTargetDescriptor =
    $convert.base64Decode('CgxTaWduYWxUYXJnZXQSDQoJUFVCTElTSEVSEAASDgoKU1VCU0NSSUJFUhAB');
@$core.Deprecated('Use videoQualityDescriptor instead')
const VideoQuality$json = const {
  '1': 'VideoQuality',
  '2': const [
    const {'1': 'LOW', '2': 0},
    const {'1': 'MEDIUM', '2': 1},
    const {'1': 'HIGH', '2': 2},
  ],
};

/// Descriptor for `VideoQuality`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List videoQualityDescriptor =
    $convert.base64Decode('CgxWaWRlb1F1YWxpdHkSBwoDTE9XEAASCgoGTUVESVVNEAESCAoESElHSBAC');
@$core.Deprecated('Use signalRequestDescriptor instead')
const SignalRequest$json = const {
  '1': 'SignalRequest',
  '2': const [
    const {
      '1': 'offer',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.livekit.SessionDescription',
      '9': 0,
      '10': 'offer'
    },
    const {
      '1': 'answer',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.livekit.SessionDescription',
      '9': 0,
      '10': 'answer'
    },
    const {
      '1': 'trickle',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.livekit.TrickleRequest',
      '9': 0,
      '10': 'trickle'
    },
    const {
      '1': 'add_track',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.livekit.AddTrackRequest',
      '9': 0,
      '10': 'addTrack'
    },
    const {
      '1': 'mute',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.livekit.MuteTrackRequest',
      '9': 0,
      '10': 'mute'
    },
    const {
      '1': 'subscription',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.livekit.UpdateSubscription',
      '9': 0,
      '10': 'subscription'
    },
    const {
      '1': 'track_setting',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.livekit.UpdateTrackSettings',
      '9': 0,
      '10': 'trackSetting'
    },
    const {
      '1': 'leave',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.livekit.LeaveRequest',
      '9': 0,
      '10': 'leave'
    },
    const {
      '1': 'simulcast',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.livekit.SetSimulcastLayers',
      '9': 0,
      '10': 'simulcast'
    },
  ],
  '8': const [
    const {'1': 'message'},
  ],
};

/// Descriptor for `SignalRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signalRequestDescriptor = $convert.base64Decode(
    'Cg1TaWduYWxSZXF1ZXN0EjMKBW9mZmVyGAEgASgLMhsubGl2ZWtpdC5TZXNzaW9uRGVzY3JpcHRpb25IAFIFb2ZmZXISNQoGYW5zd2VyGAIgASgLMhsubGl2ZWtpdC5TZXNzaW9uRGVzY3JpcHRpb25IAFIGYW5zd2VyEjMKB3RyaWNrbGUYAyABKAsyFy5saXZla2l0LlRyaWNrbGVSZXF1ZXN0SABSB3RyaWNrbGUSNwoJYWRkX3RyYWNrGAQgASgLMhgubGl2ZWtpdC5BZGRUcmFja1JlcXVlc3RIAFIIYWRkVHJhY2sSLwoEbXV0ZRgFIAEoCzIZLmxpdmVraXQuTXV0ZVRyYWNrUmVxdWVzdEgAUgRtdXRlEkEKDHN1YnNjcmlwdGlvbhgGIAEoCzIbLmxpdmVraXQuVXBkYXRlU3Vic2NyaXB0aW9uSABSDHN1YnNjcmlwdGlvbhJDCg10cmFja19zZXR0aW5nGAcgASgLMhwubGl2ZWtpdC5VcGRhdGVUcmFja1NldHRpbmdzSABSDHRyYWNrU2V0dGluZxItCgVsZWF2ZRgIIAEoCzIVLmxpdmVraXQuTGVhdmVSZXF1ZXN0SABSBWxlYXZlEjsKCXNpbXVsY2FzdBgJIAEoCzIbLmxpdmVraXQuU2V0U2ltdWxjYXN0TGF5ZXJzSABSCXNpbXVsY2FzdEIJCgdtZXNzYWdl');
@$core.Deprecated('Use signalResponseDescriptor instead')
const SignalResponse$json = const {
  '1': 'SignalResponse',
  '2': const [
    const {
      '1': 'join',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.livekit.JoinResponse',
      '9': 0,
      '10': 'join'
    },
    const {
      '1': 'answer',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.livekit.SessionDescription',
      '9': 0,
      '10': 'answer'
    },
    const {
      '1': 'offer',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.livekit.SessionDescription',
      '9': 0,
      '10': 'offer'
    },
    const {
      '1': 'trickle',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.livekit.TrickleRequest',
      '9': 0,
      '10': 'trickle'
    },
    const {
      '1': 'update',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.livekit.ParticipantUpdate',
      '9': 0,
      '10': 'update'
    },
    const {
      '1': 'track_published',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.livekit.TrackPublishedResponse',
      '9': 0,
      '10': 'trackPublished'
    },
    const {
      '1': 'speaker',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.livekit.ActiveSpeakerUpdate',
      '9': 0,
      '10': 'speaker'
    },
    const {
      '1': 'leave',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.livekit.LeaveRequest',
      '9': 0,
      '10': 'leave'
    },
    const {
      '1': 'mute',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.livekit.MuteTrackRequest',
      '9': 0,
      '10': 'mute'
    },
  ],
  '8': const [
    const {'1': 'message'},
  ],
};

/// Descriptor for `SignalResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signalResponseDescriptor = $convert.base64Decode(
    'Cg5TaWduYWxSZXNwb25zZRIrCgRqb2luGAEgASgLMhUubGl2ZWtpdC5Kb2luUmVzcG9uc2VIAFIEam9pbhI1CgZhbnN3ZXIYAiABKAsyGy5saXZla2l0LlNlc3Npb25EZXNjcmlwdGlvbkgAUgZhbnN3ZXISMwoFb2ZmZXIYAyABKAsyGy5saXZla2l0LlNlc3Npb25EZXNjcmlwdGlvbkgAUgVvZmZlchIzCgd0cmlja2xlGAQgASgLMhcubGl2ZWtpdC5Ucmlja2xlUmVxdWVzdEgAUgd0cmlja2xlEjQKBnVwZGF0ZRgFIAEoCzIaLmxpdmVraXQuUGFydGljaXBhbnRVcGRhdGVIAFIGdXBkYXRlEkoKD3RyYWNrX3B1Ymxpc2hlZBgGIAEoCzIfLmxpdmVraXQuVHJhY2tQdWJsaXNoZWRSZXNwb25zZUgAUg50cmFja1B1Ymxpc2hlZBI4CgdzcGVha2VyGAcgASgLMhwubGl2ZWtpdC5BY3RpdmVTcGVha2VyVXBkYXRlSABSB3NwZWFrZXISLQoFbGVhdmUYCCABKAsyFS5saXZla2l0LkxlYXZlUmVxdWVzdEgAUgVsZWF2ZRIvCgRtdXRlGAkgASgLMhkubGl2ZWtpdC5NdXRlVHJhY2tSZXF1ZXN0SABSBG11dGVCCQoHbWVzc2FnZQ==');
@$core.Deprecated('Use addTrackRequestDescriptor instead')
const AddTrackRequest$json = const {
  '1': 'AddTrackRequest',
  '2': const [
    const {'1': 'cid', '3': 1, '4': 1, '5': 9, '10': 'cid'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'type', '3': 3, '4': 1, '5': 14, '6': '.livekit.TrackType', '10': 'type'},
    const {'1': 'width', '3': 4, '4': 1, '5': 13, '10': 'width'},
    const {'1': 'height', '3': 5, '4': 1, '5': 13, '10': 'height'},
    const {'1': 'muted', '3': 6, '4': 1, '5': 8, '10': 'muted'},
  ],
};

/// Descriptor for `AddTrackRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addTrackRequestDescriptor = $convert.base64Decode(
    'Cg9BZGRUcmFja1JlcXVlc3QSEAoDY2lkGAEgASgJUgNjaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRImCgR0eXBlGAMgASgOMhIubGl2ZWtpdC5UcmFja1R5cGVSBHR5cGUSFAoFd2lkdGgYBCABKA1SBXdpZHRoEhYKBmhlaWdodBgFIAEoDVIGaGVpZ2h0EhQKBW11dGVkGAYgASgIUgVtdXRlZA==');
@$core.Deprecated('Use trickleRequestDescriptor instead')
const TrickleRequest$json = const {
  '1': 'TrickleRequest',
  '2': const [
    const {'1': 'candidateInit', '3': 1, '4': 1, '5': 9, '10': 'candidateInit'},
    const {'1': 'target', '3': 2, '4': 1, '5': 14, '6': '.livekit.SignalTarget', '10': 'target'},
  ],
};

/// Descriptor for `TrickleRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trickleRequestDescriptor = $convert.base64Decode(
    'Cg5Ucmlja2xlUmVxdWVzdBIkCg1jYW5kaWRhdGVJbml0GAEgASgJUg1jYW5kaWRhdGVJbml0Ei0KBnRhcmdldBgCIAEoDjIVLmxpdmVraXQuU2lnbmFsVGFyZ2V0UgZ0YXJnZXQ=');
@$core.Deprecated('Use muteTrackRequestDescriptor instead')
const MuteTrackRequest$json = const {
  '1': 'MuteTrackRequest',
  '2': const [
    const {'1': 'sid', '3': 1, '4': 1, '5': 9, '10': 'sid'},
    const {'1': 'muted', '3': 2, '4': 1, '5': 8, '10': 'muted'},
  ],
};

/// Descriptor for `MuteTrackRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List muteTrackRequestDescriptor = $convert.base64Decode(
    'ChBNdXRlVHJhY2tSZXF1ZXN0EhAKA3NpZBgBIAEoCVIDc2lkEhQKBW11dGVkGAIgASgIUgVtdXRlZA==');
@$core.Deprecated('Use setSimulcastLayersDescriptor instead')
const SetSimulcastLayers$json = const {
  '1': 'SetSimulcastLayers',
  '2': const [
    const {'1': 'track_sid', '3': 1, '4': 1, '5': 9, '10': 'trackSid'},
    const {'1': 'layers', '3': 2, '4': 3, '5': 14, '6': '.livekit.VideoQuality', '10': 'layers'},
  ],
};

/// Descriptor for `SetSimulcastLayers`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setSimulcastLayersDescriptor = $convert.base64Decode(
    'ChJTZXRTaW11bGNhc3RMYXllcnMSGwoJdHJhY2tfc2lkGAEgASgJUgh0cmFja1NpZBItCgZsYXllcnMYAiADKA4yFS5saXZla2l0LlZpZGVvUXVhbGl0eVIGbGF5ZXJz');
@$core.Deprecated('Use joinResponseDescriptor instead')
const JoinResponse$json = const {
  '1': 'JoinResponse',
  '2': const [
    const {'1': 'room', '3': 1, '4': 1, '5': 11, '6': '.livekit.Room', '10': 'room'},
    const {
      '1': 'participant',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.livekit.ParticipantInfo',
      '10': 'participant'
    },
    const {
      '1': 'other_participants',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.livekit.ParticipantInfo',
      '10': 'otherParticipants'
    },
    const {'1': 'server_version', '3': 4, '4': 1, '5': 9, '10': 'serverVersion'},
    const {
      '1': 'ice_servers',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.livekit.ICEServer',
      '10': 'iceServers'
    },
  ],
};

/// Descriptor for `JoinResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List joinResponseDescriptor = $convert.base64Decode(
    'CgxKb2luUmVzcG9uc2USIQoEcm9vbRgBIAEoCzINLmxpdmVraXQuUm9vbVIEcm9vbRI6CgtwYXJ0aWNpcGFudBgCIAEoCzIYLmxpdmVraXQuUGFydGljaXBhbnRJbmZvUgtwYXJ0aWNpcGFudBJHChJvdGhlcl9wYXJ0aWNpcGFudHMYAyADKAsyGC5saXZla2l0LlBhcnRpY2lwYW50SW5mb1IRb3RoZXJQYXJ0aWNpcGFudHMSJQoOc2VydmVyX3ZlcnNpb24YBCABKAlSDXNlcnZlclZlcnNpb24SMwoLaWNlX3NlcnZlcnMYBSADKAsyEi5saXZla2l0LklDRVNlcnZlclIKaWNlU2VydmVycw==');
@$core.Deprecated('Use trackPublishedResponseDescriptor instead')
const TrackPublishedResponse$json = const {
  '1': 'TrackPublishedResponse',
  '2': const [
    const {'1': 'cid', '3': 1, '4': 1, '5': 9, '10': 'cid'},
    const {'1': 'track', '3': 2, '4': 1, '5': 11, '6': '.livekit.TrackInfo', '10': 'track'},
  ],
};

/// Descriptor for `TrackPublishedResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackPublishedResponseDescriptor = $convert.base64Decode(
    'ChZUcmFja1B1Ymxpc2hlZFJlc3BvbnNlEhAKA2NpZBgBIAEoCVIDY2lkEigKBXRyYWNrGAIgASgLMhIubGl2ZWtpdC5UcmFja0luZm9SBXRyYWNr');
@$core.Deprecated('Use sessionDescriptionDescriptor instead')
const SessionDescription$json = const {
  '1': 'SessionDescription',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'sdp', '3': 2, '4': 1, '5': 9, '10': 'sdp'},
  ],
};

/// Descriptor for `SessionDescription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionDescriptionDescriptor = $convert.base64Decode(
    'ChJTZXNzaW9uRGVzY3JpcHRpb24SEgoEdHlwZRgBIAEoCVIEdHlwZRIQCgNzZHAYAiABKAlSA3NkcA==');
@$core.Deprecated('Use participantUpdateDescriptor instead')
const ParticipantUpdate$json = const {
  '1': 'ParticipantUpdate',
  '2': const [
    const {
      '1': 'participants',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.livekit.ParticipantInfo',
      '10': 'participants'
    },
  ],
};

/// Descriptor for `ParticipantUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List participantUpdateDescriptor = $convert.base64Decode(
    'ChFQYXJ0aWNpcGFudFVwZGF0ZRI8CgxwYXJ0aWNpcGFudHMYASADKAsyGC5saXZla2l0LlBhcnRpY2lwYW50SW5mb1IMcGFydGljaXBhbnRz');
@$core.Deprecated('Use updateSubscriptionDescriptor instead')
const UpdateSubscription$json = const {
  '1': 'UpdateSubscription',
  '2': const [
    const {'1': 'track_sids', '3': 1, '4': 3, '5': 9, '10': 'trackSids'},
    const {'1': 'subscribe', '3': 2, '4': 1, '5': 8, '10': 'subscribe'},
  ],
};

/// Descriptor for `UpdateSubscription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateSubscriptionDescriptor = $convert.base64Decode(
    'ChJVcGRhdGVTdWJzY3JpcHRpb24SHQoKdHJhY2tfc2lkcxgBIAMoCVIJdHJhY2tTaWRzEhwKCXN1YnNjcmliZRgCIAEoCFIJc3Vic2NyaWJl');
@$core.Deprecated('Use updateTrackSettingsDescriptor instead')
const UpdateTrackSettings$json = const {
  '1': 'UpdateTrackSettings',
  '2': const [
    const {'1': 'track_sids', '3': 1, '4': 3, '5': 9, '10': 'trackSids'},
    const {'1': 'disabled', '3': 3, '4': 1, '5': 8, '10': 'disabled'},
    const {'1': 'quality', '3': 4, '4': 1, '5': 14, '6': '.livekit.VideoQuality', '10': 'quality'},
  ],
};

/// Descriptor for `UpdateTrackSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateTrackSettingsDescriptor = $convert.base64Decode(
    'ChNVcGRhdGVUcmFja1NldHRpbmdzEh0KCnRyYWNrX3NpZHMYASADKAlSCXRyYWNrU2lkcxIaCghkaXNhYmxlZBgDIAEoCFIIZGlzYWJsZWQSLwoHcXVhbGl0eRgEIAEoDjIVLmxpdmVraXQuVmlkZW9RdWFsaXR5UgdxdWFsaXR5');
@$core.Deprecated('Use leaveRequestDescriptor instead')
const LeaveRequest$json = const {
  '1': 'LeaveRequest',
  '2': const [
    const {'1': 'can_reconnect', '3': 1, '4': 1, '5': 8, '10': 'canReconnect'},
  ],
};

/// Descriptor for `LeaveRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List leaveRequestDescriptor =
    $convert.base64Decode('CgxMZWF2ZVJlcXVlc3QSIwoNY2FuX3JlY29ubmVjdBgBIAEoCFIMY2FuUmVjb25uZWN0');
@$core.Deprecated('Use iCEServerDescriptor instead')
const ICEServer$json = const {
  '1': 'ICEServer',
  '2': const [
    const {'1': 'urls', '3': 1, '4': 3, '5': 9, '10': 'urls'},
    const {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    const {'1': 'credential', '3': 3, '4': 1, '5': 9, '10': 'credential'},
  ],
};

/// Descriptor for `ICEServer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List iCEServerDescriptor = $convert.base64Decode(
    'CglJQ0VTZXJ2ZXISEgoEdXJscxgBIAMoCVIEdXJscxIaCgh1c2VybmFtZRgCIAEoCVIIdXNlcm5hbWUSHgoKY3JlZGVudGlhbBgDIAEoCVIKY3JlZGVudGlhbA==');
