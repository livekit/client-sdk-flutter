///
//  Generated code. Do not modify.
//  source: livekit_rtc.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

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
final $typed_data.Uint8List signalTargetDescriptor = $convert.base64Decode(
    'CgxTaWduYWxUYXJnZXQSDQoJUFVCTElTSEVSEAASDgoKU1VCU0NSSUJFUhAB');
@$core.Deprecated('Use streamStateDescriptor instead')
const StreamState$json = const {
  '1': 'StreamState',
  '2': const [
    const {'1': 'ACTIVE', '2': 0},
    const {'1': 'PAUSED', '2': 1},
  ],
};

/// Descriptor for `StreamState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List streamStateDescriptor = $convert
    .base64Decode('CgtTdHJlYW1TdGF0ZRIKCgZBQ1RJVkUQABIKCgZQQVVTRUQQAQ==');
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
      '1': 'update_layers',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.livekit.UpdateVideoLayers',
      '9': 0,
      '10': 'updateLayers'
    },
    const {
      '1': 'subscription_permission',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.livekit.SubscriptionPermission',
      '9': 0,
      '10': 'subscriptionPermission'
    },
    const {
      '1': 'sync_state',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.livekit.SyncState',
      '9': 0,
      '10': 'syncState'
    },
    const {
      '1': 'simulate',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.livekit.SimulateScenario',
      '9': 0,
      '10': 'simulate'
    },
  ],
  '8': const [
    const {'1': 'message'},
  ],
};

/// Descriptor for `SignalRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signalRequestDescriptor = $convert.base64Decode(
    'Cg1TaWduYWxSZXF1ZXN0EjMKBW9mZmVyGAEgASgLMhsubGl2ZWtpdC5TZXNzaW9uRGVzY3JpcHRpb25IAFIFb2ZmZXISNQoGYW5zd2VyGAIgASgLMhsubGl2ZWtpdC5TZXNzaW9uRGVzY3JpcHRpb25IAFIGYW5zd2VyEjMKB3RyaWNrbGUYAyABKAsyFy5saXZla2l0LlRyaWNrbGVSZXF1ZXN0SABSB3RyaWNrbGUSNwoJYWRkX3RyYWNrGAQgASgLMhgubGl2ZWtpdC5BZGRUcmFja1JlcXVlc3RIAFIIYWRkVHJhY2sSLwoEbXV0ZRgFIAEoCzIZLmxpdmVraXQuTXV0ZVRyYWNrUmVxdWVzdEgAUgRtdXRlEkEKDHN1YnNjcmlwdGlvbhgGIAEoCzIbLmxpdmVraXQuVXBkYXRlU3Vic2NyaXB0aW9uSABSDHN1YnNjcmlwdGlvbhJDCg10cmFja19zZXR0aW5nGAcgASgLMhwubGl2ZWtpdC5VcGRhdGVUcmFja1NldHRpbmdzSABSDHRyYWNrU2V0dGluZxItCgVsZWF2ZRgIIAEoCzIVLmxpdmVraXQuTGVhdmVSZXF1ZXN0SABSBWxlYXZlEkEKDXVwZGF0ZV9sYXllcnMYCiABKAsyGi5saXZla2l0LlVwZGF0ZVZpZGVvTGF5ZXJzSABSDHVwZGF0ZUxheWVycxJaChdzdWJzY3JpcHRpb25fcGVybWlzc2lvbhgLIAEoCzIfLmxpdmVraXQuU3Vic2NyaXB0aW9uUGVybWlzc2lvbkgAUhZzdWJzY3JpcHRpb25QZXJtaXNzaW9uEjMKCnN5bmNfc3RhdGUYDCABKAsyEi5saXZla2l0LlN5bmNTdGF0ZUgAUglzeW5jU3RhdGUSNwoIc2ltdWxhdGUYDSABKAsyGS5saXZla2l0LlNpbXVsYXRlU2NlbmFyaW9IAFIIc2ltdWxhdGVCCQoHbWVzc2FnZQ==');
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
    const {
      '1': 'speakers_changed',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.livekit.SpeakersChanged',
      '9': 0,
      '10': 'speakersChanged'
    },
    const {
      '1': 'room_update',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.livekit.RoomUpdate',
      '9': 0,
      '10': 'roomUpdate'
    },
    const {
      '1': 'connection_quality',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.livekit.ConnectionQualityUpdate',
      '9': 0,
      '10': 'connectionQuality'
    },
    const {
      '1': 'stream_state_update',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.livekit.StreamStateUpdate',
      '9': 0,
      '10': 'streamStateUpdate'
    },
    const {
      '1': 'subscribed_quality_update',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.livekit.SubscribedQualityUpdate',
      '9': 0,
      '10': 'subscribedQualityUpdate'
    },
    const {
      '1': 'subscription_permission_update',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.livekit.SubscriptionPermissionUpdate',
      '9': 0,
      '10': 'subscriptionPermissionUpdate'
    },
    const {
      '1': 'refresh_token',
      '3': 16,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'refreshToken'
    },
    const {
      '1': 'track_unpublished',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.livekit.TrackUnpublishedResponse',
      '9': 0,
      '10': 'trackUnpublished'
    },
  ],
  '8': const [
    const {'1': 'message'},
  ],
};

/// Descriptor for `SignalResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signalResponseDescriptor = $convert.base64Decode(
    'Cg5TaWduYWxSZXNwb25zZRIrCgRqb2luGAEgASgLMhUubGl2ZWtpdC5Kb2luUmVzcG9uc2VIAFIEam9pbhI1CgZhbnN3ZXIYAiABKAsyGy5saXZla2l0LlNlc3Npb25EZXNjcmlwdGlvbkgAUgZhbnN3ZXISMwoFb2ZmZXIYAyABKAsyGy5saXZla2l0LlNlc3Npb25EZXNjcmlwdGlvbkgAUgVvZmZlchIzCgd0cmlja2xlGAQgASgLMhcubGl2ZWtpdC5Ucmlja2xlUmVxdWVzdEgAUgd0cmlja2xlEjQKBnVwZGF0ZRgFIAEoCzIaLmxpdmVraXQuUGFydGljaXBhbnRVcGRhdGVIAFIGdXBkYXRlEkoKD3RyYWNrX3B1Ymxpc2hlZBgGIAEoCzIfLmxpdmVraXQuVHJhY2tQdWJsaXNoZWRSZXNwb25zZUgAUg50cmFja1B1Ymxpc2hlZBItCgVsZWF2ZRgIIAEoCzIVLmxpdmVraXQuTGVhdmVSZXF1ZXN0SABSBWxlYXZlEi8KBG11dGUYCSABKAsyGS5saXZla2l0Lk11dGVUcmFja1JlcXVlc3RIAFIEbXV0ZRJFChBzcGVha2Vyc19jaGFuZ2VkGAogASgLMhgubGl2ZWtpdC5TcGVha2Vyc0NoYW5nZWRIAFIPc3BlYWtlcnNDaGFuZ2VkEjYKC3Jvb21fdXBkYXRlGAsgASgLMhMubGl2ZWtpdC5Sb29tVXBkYXRlSABSCnJvb21VcGRhdGUSUQoSY29ubmVjdGlvbl9xdWFsaXR5GAwgASgLMiAubGl2ZWtpdC5Db25uZWN0aW9uUXVhbGl0eVVwZGF0ZUgAUhFjb25uZWN0aW9uUXVhbGl0eRJMChNzdHJlYW1fc3RhdGVfdXBkYXRlGA0gASgLMhoubGl2ZWtpdC5TdHJlYW1TdGF0ZVVwZGF0ZUgAUhFzdHJlYW1TdGF0ZVVwZGF0ZRJeChlzdWJzY3JpYmVkX3F1YWxpdHlfdXBkYXRlGA4gASgLMiAubGl2ZWtpdC5TdWJzY3JpYmVkUXVhbGl0eVVwZGF0ZUgAUhdzdWJzY3JpYmVkUXVhbGl0eVVwZGF0ZRJtCh5zdWJzY3JpcHRpb25fcGVybWlzc2lvbl91cGRhdGUYDyABKAsyJS5saXZla2l0LlN1YnNjcmlwdGlvblBlcm1pc3Npb25VcGRhdGVIAFIcc3Vic2NyaXB0aW9uUGVybWlzc2lvblVwZGF0ZRIlCg1yZWZyZXNoX3Rva2VuGBAgASgJSABSDHJlZnJlc2hUb2tlbhJQChF0cmFja191bnB1Ymxpc2hlZBgRIAEoCzIhLmxpdmVraXQuVHJhY2tVbnB1Ymxpc2hlZFJlc3BvbnNlSABSEHRyYWNrVW5wdWJsaXNoZWRCCQoHbWVzc2FnZQ==');
@$core.Deprecated('Use addTrackRequestDescriptor instead')
const AddTrackRequest$json = const {
  '1': 'AddTrackRequest',
  '2': const [
    const {'1': 'cid', '3': 1, '4': 1, '5': 9, '10': 'cid'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {
      '1': 'type',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.livekit.TrackType',
      '10': 'type'
    },
    const {'1': 'width', '3': 4, '4': 1, '5': 13, '10': 'width'},
    const {'1': 'height', '3': 5, '4': 1, '5': 13, '10': 'height'},
    const {'1': 'muted', '3': 6, '4': 1, '5': 8, '10': 'muted'},
    const {'1': 'disable_dtx', '3': 7, '4': 1, '5': 8, '10': 'disableDtx'},
    const {
      '1': 'source',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.livekit.TrackSource',
      '10': 'source'
    },
    const {
      '1': 'layers',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.livekit.VideoLayer',
      '10': 'layers'
    },
  ],
};

/// Descriptor for `AddTrackRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addTrackRequestDescriptor = $convert.base64Decode(
    'Cg9BZGRUcmFja1JlcXVlc3QSEAoDY2lkGAEgASgJUgNjaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRImCgR0eXBlGAMgASgOMhIubGl2ZWtpdC5UcmFja1R5cGVSBHR5cGUSFAoFd2lkdGgYBCABKA1SBXdpZHRoEhYKBmhlaWdodBgFIAEoDVIGaGVpZ2h0EhQKBW11dGVkGAYgASgIUgVtdXRlZBIfCgtkaXNhYmxlX2R0eBgHIAEoCFIKZGlzYWJsZUR0eBIsCgZzb3VyY2UYCCABKA4yFC5saXZla2l0LlRyYWNrU291cmNlUgZzb3VyY2USKwoGbGF5ZXJzGAkgAygLMhMubGl2ZWtpdC5WaWRlb0xheWVyUgZsYXllcnM=');
@$core.Deprecated('Use trickleRequestDescriptor instead')
const TrickleRequest$json = const {
  '1': 'TrickleRequest',
  '2': const [
    const {'1': 'candidateInit', '3': 1, '4': 1, '5': 9, '10': 'candidateInit'},
    const {
      '1': 'target',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.livekit.SignalTarget',
      '10': 'target'
    },
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
@$core.Deprecated('Use joinResponseDescriptor instead')
const JoinResponse$json = const {
  '1': 'JoinResponse',
  '2': const [
    const {
      '1': 'room',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.livekit.Room',
      '10': 'room'
    },
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
    const {
      '1': 'server_version',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'serverVersion'
    },
    const {
      '1': 'ice_servers',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.livekit.ICEServer',
      '10': 'iceServers'
    },
    const {
      '1': 'subscriber_primary',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'subscriberPrimary'
    },
    const {
      '1': 'alternative_url',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'alternativeUrl'
    },
    const {
      '1': 'client_configuration',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.livekit.ClientConfiguration',
      '10': 'clientConfiguration'
    },
    const {'1': 'server_region', '3': 9, '4': 1, '5': 9, '10': 'serverRegion'},
  ],
};

/// Descriptor for `JoinResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List joinResponseDescriptor = $convert.base64Decode(
    'CgxKb2luUmVzcG9uc2USIQoEcm9vbRgBIAEoCzINLmxpdmVraXQuUm9vbVIEcm9vbRI6CgtwYXJ0aWNpcGFudBgCIAEoCzIYLmxpdmVraXQuUGFydGljaXBhbnRJbmZvUgtwYXJ0aWNpcGFudBJHChJvdGhlcl9wYXJ0aWNpcGFudHMYAyADKAsyGC5saXZla2l0LlBhcnRpY2lwYW50SW5mb1IRb3RoZXJQYXJ0aWNpcGFudHMSJQoOc2VydmVyX3ZlcnNpb24YBCABKAlSDXNlcnZlclZlcnNpb24SMwoLaWNlX3NlcnZlcnMYBSADKAsyEi5saXZla2l0LklDRVNlcnZlclIKaWNlU2VydmVycxItChJzdWJzY3JpYmVyX3ByaW1hcnkYBiABKAhSEXN1YnNjcmliZXJQcmltYXJ5EicKD2FsdGVybmF0aXZlX3VybBgHIAEoCVIOYWx0ZXJuYXRpdmVVcmwSTwoUY2xpZW50X2NvbmZpZ3VyYXRpb24YCCABKAsyHC5saXZla2l0LkNsaWVudENvbmZpZ3VyYXRpb25SE2NsaWVudENvbmZpZ3VyYXRpb24SIwoNc2VydmVyX3JlZ2lvbhgJIAEoCVIMc2VydmVyUmVnaW9u');
@$core.Deprecated('Use trackPublishedResponseDescriptor instead')
const TrackPublishedResponse$json = const {
  '1': 'TrackPublishedResponse',
  '2': const [
    const {'1': 'cid', '3': 1, '4': 1, '5': 9, '10': 'cid'},
    const {
      '1': 'track',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.livekit.TrackInfo',
      '10': 'track'
    },
  ],
};

/// Descriptor for `TrackPublishedResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackPublishedResponseDescriptor =
    $convert.base64Decode(
        'ChZUcmFja1B1Ymxpc2hlZFJlc3BvbnNlEhAKA2NpZBgBIAEoCVIDY2lkEigKBXRyYWNrGAIgASgLMhIubGl2ZWtpdC5UcmFja0luZm9SBXRyYWNr');
@$core.Deprecated('Use trackUnpublishedResponseDescriptor instead')
const TrackUnpublishedResponse$json = const {
  '1': 'TrackUnpublishedResponse',
  '2': const [
    const {'1': 'track_sid', '3': 1, '4': 1, '5': 9, '10': 'trackSid'},
  ],
};

/// Descriptor for `TrackUnpublishedResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackUnpublishedResponseDescriptor =
    $convert.base64Decode(
        'ChhUcmFja1VucHVibGlzaGVkUmVzcG9uc2USGwoJdHJhY2tfc2lkGAEgASgJUgh0cmFja1NpZA==');
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
    const {
      '1': 'participant_tracks',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.livekit.ParticipantTracks',
      '10': 'participantTracks'
    },
  ],
};

/// Descriptor for `UpdateSubscription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateSubscriptionDescriptor = $convert.base64Decode(
    'ChJVcGRhdGVTdWJzY3JpcHRpb24SHQoKdHJhY2tfc2lkcxgBIAMoCVIJdHJhY2tTaWRzEhwKCXN1YnNjcmliZRgCIAEoCFIJc3Vic2NyaWJlEkkKEnBhcnRpY2lwYW50X3RyYWNrcxgDIAMoCzIaLmxpdmVraXQuUGFydGljaXBhbnRUcmFja3NSEXBhcnRpY2lwYW50VHJhY2tz');
@$core.Deprecated('Use updateTrackSettingsDescriptor instead')
const UpdateTrackSettings$json = const {
  '1': 'UpdateTrackSettings',
  '2': const [
    const {'1': 'track_sids', '3': 1, '4': 3, '5': 9, '10': 'trackSids'},
    const {'1': 'disabled', '3': 3, '4': 1, '5': 8, '10': 'disabled'},
    const {
      '1': 'quality',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.livekit.VideoQuality',
      '10': 'quality'
    },
    const {'1': 'width', '3': 5, '4': 1, '5': 13, '10': 'width'},
    const {'1': 'height', '3': 6, '4': 1, '5': 13, '10': 'height'},
  ],
};

/// Descriptor for `UpdateTrackSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateTrackSettingsDescriptor = $convert.base64Decode(
    'ChNVcGRhdGVUcmFja1NldHRpbmdzEh0KCnRyYWNrX3NpZHMYASADKAlSCXRyYWNrU2lkcxIaCghkaXNhYmxlZBgDIAEoCFIIZGlzYWJsZWQSLwoHcXVhbGl0eRgEIAEoDjIVLmxpdmVraXQuVmlkZW9RdWFsaXR5UgdxdWFsaXR5EhQKBXdpZHRoGAUgASgNUgV3aWR0aBIWCgZoZWlnaHQYBiABKA1SBmhlaWdodA==');
@$core.Deprecated('Use leaveRequestDescriptor instead')
const LeaveRequest$json = const {
  '1': 'LeaveRequest',
  '2': const [
    const {'1': 'can_reconnect', '3': 1, '4': 1, '5': 8, '10': 'canReconnect'},
  ],
};

/// Descriptor for `LeaveRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List leaveRequestDescriptor = $convert.base64Decode(
    'CgxMZWF2ZVJlcXVlc3QSIwoNY2FuX3JlY29ubmVjdBgBIAEoCFIMY2FuUmVjb25uZWN0');
@$core.Deprecated('Use updateVideoLayersDescriptor instead')
const UpdateVideoLayers$json = const {
  '1': 'UpdateVideoLayers',
  '2': const [
    const {'1': 'track_sid', '3': 1, '4': 1, '5': 9, '10': 'trackSid'},
    const {
      '1': 'layers',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.livekit.VideoLayer',
      '10': 'layers'
    },
  ],
};

/// Descriptor for `UpdateVideoLayers`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateVideoLayersDescriptor = $convert.base64Decode(
    'ChFVcGRhdGVWaWRlb0xheWVycxIbCgl0cmFja19zaWQYASABKAlSCHRyYWNrU2lkEisKBmxheWVycxgCIAMoCzITLmxpdmVraXQuVmlkZW9MYXllclIGbGF5ZXJz');
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
@$core.Deprecated('Use speakersChangedDescriptor instead')
const SpeakersChanged$json = const {
  '1': 'SpeakersChanged',
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

/// Descriptor for `SpeakersChanged`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List speakersChangedDescriptor = $convert.base64Decode(
    'Cg9TcGVha2Vyc0NoYW5nZWQSMAoIc3BlYWtlcnMYASADKAsyFC5saXZla2l0LlNwZWFrZXJJbmZvUghzcGVha2Vycw==');
@$core.Deprecated('Use roomUpdateDescriptor instead')
const RoomUpdate$json = const {
  '1': 'RoomUpdate',
  '2': const [
    const {
      '1': 'room',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.livekit.Room',
      '10': 'room'
    },
  ],
};

/// Descriptor for `RoomUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roomUpdateDescriptor = $convert.base64Decode(
    'CgpSb29tVXBkYXRlEiEKBHJvb20YASABKAsyDS5saXZla2l0LlJvb21SBHJvb20=');
@$core.Deprecated('Use connectionQualityInfoDescriptor instead')
const ConnectionQualityInfo$json = const {
  '1': 'ConnectionQualityInfo',
  '2': const [
    const {
      '1': 'participant_sid',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'participantSid'
    },
    const {
      '1': 'quality',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.livekit.ConnectionQuality',
      '10': 'quality'
    },
    const {'1': 'score', '3': 3, '4': 1, '5': 2, '10': 'score'},
  ],
};

/// Descriptor for `ConnectionQualityInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectionQualityInfoDescriptor = $convert.base64Decode(
    'ChVDb25uZWN0aW9uUXVhbGl0eUluZm8SJwoPcGFydGljaXBhbnRfc2lkGAEgASgJUg5wYXJ0aWNpcGFudFNpZBI0CgdxdWFsaXR5GAIgASgOMhoubGl2ZWtpdC5Db25uZWN0aW9uUXVhbGl0eVIHcXVhbGl0eRIUCgVzY29yZRgDIAEoAlIFc2NvcmU=');
@$core.Deprecated('Use connectionQualityUpdateDescriptor instead')
const ConnectionQualityUpdate$json = const {
  '1': 'ConnectionQualityUpdate',
  '2': const [
    const {
      '1': 'updates',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.livekit.ConnectionQualityInfo',
      '10': 'updates'
    },
  ],
};

/// Descriptor for `ConnectionQualityUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectionQualityUpdateDescriptor =
    $convert.base64Decode(
        'ChdDb25uZWN0aW9uUXVhbGl0eVVwZGF0ZRI4Cgd1cGRhdGVzGAEgAygLMh4ubGl2ZWtpdC5Db25uZWN0aW9uUXVhbGl0eUluZm9SB3VwZGF0ZXM=');
@$core.Deprecated('Use streamStateInfoDescriptor instead')
const StreamStateInfo$json = const {
  '1': 'StreamStateInfo',
  '2': const [
    const {
      '1': 'participant_sid',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'participantSid'
    },
    const {'1': 'track_sid', '3': 2, '4': 1, '5': 9, '10': 'trackSid'},
    const {
      '1': 'state',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.livekit.StreamState',
      '10': 'state'
    },
  ],
};

/// Descriptor for `StreamStateInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamStateInfoDescriptor = $convert.base64Decode(
    'Cg9TdHJlYW1TdGF0ZUluZm8SJwoPcGFydGljaXBhbnRfc2lkGAEgASgJUg5wYXJ0aWNpcGFudFNpZBIbCgl0cmFja19zaWQYAiABKAlSCHRyYWNrU2lkEioKBXN0YXRlGAMgASgOMhQubGl2ZWtpdC5TdHJlYW1TdGF0ZVIFc3RhdGU=');
@$core.Deprecated('Use streamStateUpdateDescriptor instead')
const StreamStateUpdate$json = const {
  '1': 'StreamStateUpdate',
  '2': const [
    const {
      '1': 'stream_states',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.livekit.StreamStateInfo',
      '10': 'streamStates'
    },
  ],
};

/// Descriptor for `StreamStateUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamStateUpdateDescriptor = $convert.base64Decode(
    'ChFTdHJlYW1TdGF0ZVVwZGF0ZRI9Cg1zdHJlYW1fc3RhdGVzGAEgAygLMhgubGl2ZWtpdC5TdHJlYW1TdGF0ZUluZm9SDHN0cmVhbVN0YXRlcw==');
@$core.Deprecated('Use subscribedQualityDescriptor instead')
const SubscribedQuality$json = const {
  '1': 'SubscribedQuality',
  '2': const [
    const {
      '1': 'quality',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.livekit.VideoQuality',
      '10': 'quality'
    },
    const {'1': 'enabled', '3': 2, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `SubscribedQuality`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribedQualityDescriptor = $convert.base64Decode(
    'ChFTdWJzY3JpYmVkUXVhbGl0eRIvCgdxdWFsaXR5GAEgASgOMhUubGl2ZWtpdC5WaWRlb1F1YWxpdHlSB3F1YWxpdHkSGAoHZW5hYmxlZBgCIAEoCFIHZW5hYmxlZA==');
@$core.Deprecated('Use subscribedQualityUpdateDescriptor instead')
const SubscribedQualityUpdate$json = const {
  '1': 'SubscribedQualityUpdate',
  '2': const [
    const {'1': 'track_sid', '3': 1, '4': 1, '5': 9, '10': 'trackSid'},
    const {
      '1': 'subscribed_qualities',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.livekit.SubscribedQuality',
      '10': 'subscribedQualities'
    },
  ],
};

/// Descriptor for `SubscribedQualityUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribedQualityUpdateDescriptor =
    $convert.base64Decode(
        'ChdTdWJzY3JpYmVkUXVhbGl0eVVwZGF0ZRIbCgl0cmFja19zaWQYASABKAlSCHRyYWNrU2lkEk0KFHN1YnNjcmliZWRfcXVhbGl0aWVzGAIgAygLMhoubGl2ZWtpdC5TdWJzY3JpYmVkUXVhbGl0eVITc3Vic2NyaWJlZFF1YWxpdGllcw==');
@$core.Deprecated('Use trackPermissionDescriptor instead')
const TrackPermission$json = const {
  '1': 'TrackPermission',
  '2': const [
    const {
      '1': 'participant_sid',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'participantSid'
    },
    const {'1': 'all_tracks', '3': 2, '4': 1, '5': 8, '10': 'allTracks'},
    const {'1': 'track_sids', '3': 3, '4': 3, '5': 9, '10': 'trackSids'},
  ],
};

/// Descriptor for `TrackPermission`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackPermissionDescriptor = $convert.base64Decode(
    'Cg9UcmFja1Blcm1pc3Npb24SJwoPcGFydGljaXBhbnRfc2lkGAEgASgJUg5wYXJ0aWNpcGFudFNpZBIdCgphbGxfdHJhY2tzGAIgASgIUglhbGxUcmFja3MSHQoKdHJhY2tfc2lkcxgDIAMoCVIJdHJhY2tTaWRz');
@$core.Deprecated('Use subscriptionPermissionDescriptor instead')
const SubscriptionPermission$json = const {
  '1': 'SubscriptionPermission',
  '2': const [
    const {
      '1': 'all_participants',
      '3': 1,
      '4': 1,
      '5': 8,
      '10': 'allParticipants'
    },
    const {
      '1': 'track_permissions',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.livekit.TrackPermission',
      '10': 'trackPermissions'
    },
  ],
};

/// Descriptor for `SubscriptionPermission`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscriptionPermissionDescriptor =
    $convert.base64Decode(
        'ChZTdWJzY3JpcHRpb25QZXJtaXNzaW9uEikKEGFsbF9wYXJ0aWNpcGFudHMYASABKAhSD2FsbFBhcnRpY2lwYW50cxJFChF0cmFja19wZXJtaXNzaW9ucxgCIAMoCzIYLmxpdmVraXQuVHJhY2tQZXJtaXNzaW9uUhB0cmFja1Blcm1pc3Npb25z');
@$core.Deprecated('Use subscriptionPermissionUpdateDescriptor instead')
const SubscriptionPermissionUpdate$json = const {
  '1': 'SubscriptionPermissionUpdate',
  '2': const [
    const {
      '1': 'participant_sid',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'participantSid'
    },
    const {'1': 'track_sid', '3': 2, '4': 1, '5': 9, '10': 'trackSid'},
    const {'1': 'allowed', '3': 3, '4': 1, '5': 8, '10': 'allowed'},
  ],
};

/// Descriptor for `SubscriptionPermissionUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscriptionPermissionUpdateDescriptor =
    $convert.base64Decode(
        'ChxTdWJzY3JpcHRpb25QZXJtaXNzaW9uVXBkYXRlEicKD3BhcnRpY2lwYW50X3NpZBgBIAEoCVIOcGFydGljaXBhbnRTaWQSGwoJdHJhY2tfc2lkGAIgASgJUgh0cmFja1NpZBIYCgdhbGxvd2VkGAMgASgIUgdhbGxvd2Vk');
@$core.Deprecated('Use syncStateDescriptor instead')
const SyncState$json = const {
  '1': 'SyncState',
  '2': const [
    const {
      '1': 'answer',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.livekit.SessionDescription',
      '10': 'answer'
    },
    const {
      '1': 'subscription',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.livekit.UpdateSubscription',
      '10': 'subscription'
    },
    const {
      '1': 'publish_tracks',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.livekit.TrackPublishedResponse',
      '10': 'publishTracks'
    },
    const {
      '1': 'data_channels',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.livekit.DataChannelInfo',
      '10': 'dataChannels'
    },
  ],
};

/// Descriptor for `SyncState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncStateDescriptor = $convert.base64Decode(
    'CglTeW5jU3RhdGUSMwoGYW5zd2VyGAEgASgLMhsubGl2ZWtpdC5TZXNzaW9uRGVzY3JpcHRpb25SBmFuc3dlchI/CgxzdWJzY3JpcHRpb24YAiABKAsyGy5saXZla2l0LlVwZGF0ZVN1YnNjcmlwdGlvblIMc3Vic2NyaXB0aW9uEkYKDnB1Ymxpc2hfdHJhY2tzGAMgAygLMh8ubGl2ZWtpdC5UcmFja1B1Ymxpc2hlZFJlc3BvbnNlUg1wdWJsaXNoVHJhY2tzEj0KDWRhdGFfY2hhbm5lbHMYBCADKAsyGC5saXZla2l0LkRhdGFDaGFubmVsSW5mb1IMZGF0YUNoYW5uZWxz');
@$core.Deprecated('Use dataChannelInfoDescriptor instead')
const DataChannelInfo$json = const {
  '1': 'DataChannelInfo',
  '2': const [
    const {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    const {'1': 'id', '3': 2, '4': 1, '5': 13, '10': 'id'},
  ],
};

/// Descriptor for `DataChannelInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dataChannelInfoDescriptor = $convert.base64Decode(
    'Cg9EYXRhQ2hhbm5lbEluZm8SFAoFbGFiZWwYASABKAlSBWxhYmVsEg4KAmlkGAIgASgNUgJpZA==');
@$core.Deprecated('Use simulateScenarioDescriptor instead')
const SimulateScenario$json = const {
  '1': 'SimulateScenario',
  '2': const [
    const {
      '1': 'speaker_update',
      '3': 1,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'speakerUpdate'
    },
    const {
      '1': 'node_failure',
      '3': 2,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'nodeFailure'
    },
    const {'1': 'migration', '3': 3, '4': 1, '5': 8, '9': 0, '10': 'migration'},
    const {
      '1': 'server_leave',
      '3': 4,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'serverLeave'
    },
  ],
  '8': const [
    const {'1': 'scenario'},
  ],
};

/// Descriptor for `SimulateScenario`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List simulateScenarioDescriptor = $convert.base64Decode(
    'ChBTaW11bGF0ZVNjZW5hcmlvEicKDnNwZWFrZXJfdXBkYXRlGAEgASgFSABSDXNwZWFrZXJVcGRhdGUSIwoMbm9kZV9mYWlsdXJlGAIgASgISABSC25vZGVGYWlsdXJlEh4KCW1pZ3JhdGlvbhgDIAEoCEgAUgltaWdyYXRpb24SIwoMc2VydmVyX2xlYXZlGAQgASgISABSC3NlcnZlckxlYXZlQgoKCHNjZW5hcmlv');
