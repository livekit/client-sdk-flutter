//
//  Generated code. Do not modify.
//  source: livekit_rtc.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use signalTargetDescriptor instead')
const SignalTarget$json = {
  '1': 'SignalTarget',
  '2': [
    {'1': 'PUBLISHER', '2': 0},
    {'1': 'SUBSCRIBER', '2': 1},
  ],
};

/// Descriptor for `SignalTarget`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List signalTargetDescriptor = $convert.base64Decode(
    'CgxTaWduYWxUYXJnZXQSDQoJUFVCTElTSEVSEAASDgoKU1VCU0NSSUJFUhAB');

@$core.Deprecated('Use streamStateDescriptor instead')
const StreamState$json = {
  '1': 'StreamState',
  '2': [
    {'1': 'ACTIVE', '2': 0},
    {'1': 'PAUSED', '2': 1},
  ],
};

/// Descriptor for `StreamState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List streamStateDescriptor = $convert
    .base64Decode('CgtTdHJlYW1TdGF0ZRIKCgZBQ1RJVkUQABIKCgZQQVVTRUQQAQ==');

@$core.Deprecated('Use candidateProtocolDescriptor instead')
const CandidateProtocol$json = {
  '1': 'CandidateProtocol',
  '2': [
    {'1': 'UDP', '2': 0},
    {'1': 'TCP', '2': 1},
    {'1': 'TLS', '2': 2},
  ],
};

/// Descriptor for `CandidateProtocol`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List candidateProtocolDescriptor = $convert.base64Decode(
    'ChFDYW5kaWRhdGVQcm90b2NvbBIHCgNVRFAQABIHCgNUQ1AQARIHCgNUTFMQAg==');

@$core.Deprecated('Use signalRequestDescriptor instead')
const SignalRequest$json = {
  '1': 'SignalRequest',
  '2': [
    {
      '1': 'offer',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.livekit.SessionDescription',
      '9': 0,
      '10': 'offer'
    },
    {
      '1': 'answer',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.livekit.SessionDescription',
      '9': 0,
      '10': 'answer'
    },
    {
      '1': 'trickle',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.livekit.TrickleRequest',
      '9': 0,
      '10': 'trickle'
    },
    {
      '1': 'add_track',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.livekit.AddTrackRequest',
      '9': 0,
      '10': 'addTrack'
    },
    {
      '1': 'mute',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.livekit.MuteTrackRequest',
      '9': 0,
      '10': 'mute'
    },
    {
      '1': 'subscription',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.livekit.UpdateSubscription',
      '9': 0,
      '10': 'subscription'
    },
    {
      '1': 'track_setting',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.livekit.UpdateTrackSettings',
      '9': 0,
      '10': 'trackSetting'
    },
    {
      '1': 'leave',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.livekit.LeaveRequest',
      '9': 0,
      '10': 'leave'
    },
    {
      '1': 'update_layers',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.livekit.UpdateVideoLayers',
      '9': 0,
      '10': 'updateLayers'
    },
    {
      '1': 'subscription_permission',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.livekit.SubscriptionPermission',
      '9': 0,
      '10': 'subscriptionPermission'
    },
    {
      '1': 'sync_state',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.livekit.SyncState',
      '9': 0,
      '10': 'syncState'
    },
    {
      '1': 'simulate',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.livekit.SimulateScenario',
      '9': 0,
      '10': 'simulate'
    },
    {'1': 'ping', '3': 14, '4': 1, '5': 3, '9': 0, '10': 'ping'},
    {
      '1': 'update_metadata',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.livekit.UpdateParticipantMetadata',
      '9': 0,
      '10': 'updateMetadata'
    },
    {
      '1': 'ping_req',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.livekit.Ping',
      '9': 0,
      '10': 'pingReq'
    },
  ],
  '8': [
    {'1': 'message'},
  ],
};

/// Descriptor for `SignalRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signalRequestDescriptor = $convert.base64Decode(
    'Cg1TaWduYWxSZXF1ZXN0EjMKBW9mZmVyGAEgASgLMhsubGl2ZWtpdC5TZXNzaW9uRGVzY3JpcH'
    'Rpb25IAFIFb2ZmZXISNQoGYW5zd2VyGAIgASgLMhsubGl2ZWtpdC5TZXNzaW9uRGVzY3JpcHRp'
    'b25IAFIGYW5zd2VyEjMKB3RyaWNrbGUYAyABKAsyFy5saXZla2l0LlRyaWNrbGVSZXF1ZXN0SA'
    'BSB3RyaWNrbGUSNwoJYWRkX3RyYWNrGAQgASgLMhgubGl2ZWtpdC5BZGRUcmFja1JlcXVlc3RI'
    'AFIIYWRkVHJhY2sSLwoEbXV0ZRgFIAEoCzIZLmxpdmVraXQuTXV0ZVRyYWNrUmVxdWVzdEgAUg'
    'RtdXRlEkEKDHN1YnNjcmlwdGlvbhgGIAEoCzIbLmxpdmVraXQuVXBkYXRlU3Vic2NyaXB0aW9u'
    'SABSDHN1YnNjcmlwdGlvbhJDCg10cmFja19zZXR0aW5nGAcgASgLMhwubGl2ZWtpdC5VcGRhdG'
    'VUcmFja1NldHRpbmdzSABSDHRyYWNrU2V0dGluZxItCgVsZWF2ZRgIIAEoCzIVLmxpdmVraXQu'
    'TGVhdmVSZXF1ZXN0SABSBWxlYXZlEkEKDXVwZGF0ZV9sYXllcnMYCiABKAsyGi5saXZla2l0Ll'
    'VwZGF0ZVZpZGVvTGF5ZXJzSABSDHVwZGF0ZUxheWVycxJaChdzdWJzY3JpcHRpb25fcGVybWlz'
    'c2lvbhgLIAEoCzIfLmxpdmVraXQuU3Vic2NyaXB0aW9uUGVybWlzc2lvbkgAUhZzdWJzY3JpcH'
    'Rpb25QZXJtaXNzaW9uEjMKCnN5bmNfc3RhdGUYDCABKAsyEi5saXZla2l0LlN5bmNTdGF0ZUgA'
    'UglzeW5jU3RhdGUSNwoIc2ltdWxhdGUYDSABKAsyGS5saXZla2l0LlNpbXVsYXRlU2NlbmFyaW'
    '9IAFIIc2ltdWxhdGUSFAoEcGluZxgOIAEoA0gAUgRwaW5nEk0KD3VwZGF0ZV9tZXRhZGF0YRgP'
    'IAEoCzIiLmxpdmVraXQuVXBkYXRlUGFydGljaXBhbnRNZXRhZGF0YUgAUg51cGRhdGVNZXRhZG'
    'F0YRIqCghwaW5nX3JlcRgQIAEoCzINLmxpdmVraXQuUGluZ0gAUgdwaW5nUmVxQgkKB21lc3Nh'
    'Z2U=');

@$core.Deprecated('Use signalResponseDescriptor instead')
const SignalResponse$json = {
  '1': 'SignalResponse',
  '2': [
    {
      '1': 'join',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.livekit.JoinResponse',
      '9': 0,
      '10': 'join'
    },
    {
      '1': 'answer',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.livekit.SessionDescription',
      '9': 0,
      '10': 'answer'
    },
    {
      '1': 'offer',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.livekit.SessionDescription',
      '9': 0,
      '10': 'offer'
    },
    {
      '1': 'trickle',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.livekit.TrickleRequest',
      '9': 0,
      '10': 'trickle'
    },
    {
      '1': 'update',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.livekit.ParticipantUpdate',
      '9': 0,
      '10': 'update'
    },
    {
      '1': 'track_published',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.livekit.TrackPublishedResponse',
      '9': 0,
      '10': 'trackPublished'
    },
    {
      '1': 'leave',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.livekit.LeaveRequest',
      '9': 0,
      '10': 'leave'
    },
    {
      '1': 'mute',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.livekit.MuteTrackRequest',
      '9': 0,
      '10': 'mute'
    },
    {
      '1': 'speakers_changed',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.livekit.SpeakersChanged',
      '9': 0,
      '10': 'speakersChanged'
    },
    {
      '1': 'room_update',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.livekit.RoomUpdate',
      '9': 0,
      '10': 'roomUpdate'
    },
    {
      '1': 'connection_quality',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.livekit.ConnectionQualityUpdate',
      '9': 0,
      '10': 'connectionQuality'
    },
    {
      '1': 'stream_state_update',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.livekit.StreamStateUpdate',
      '9': 0,
      '10': 'streamStateUpdate'
    },
    {
      '1': 'subscribed_quality_update',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.livekit.SubscribedQualityUpdate',
      '9': 0,
      '10': 'subscribedQualityUpdate'
    },
    {
      '1': 'subscription_permission_update',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.livekit.SubscriptionPermissionUpdate',
      '9': 0,
      '10': 'subscriptionPermissionUpdate'
    },
    {
      '1': 'refresh_token',
      '3': 16,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'refreshToken'
    },
    {
      '1': 'track_unpublished',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.livekit.TrackUnpublishedResponse',
      '9': 0,
      '10': 'trackUnpublished'
    },
    {'1': 'pong', '3': 18, '4': 1, '5': 3, '9': 0, '10': 'pong'},
    {
      '1': 'reconnect',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.livekit.ReconnectResponse',
      '9': 0,
      '10': 'reconnect'
    },
    {
      '1': 'pong_resp',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.livekit.Pong',
      '9': 0,
      '10': 'pongResp'
    },
    {
      '1': 'subscription_response',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.livekit.SubscriptionResponse',
      '9': 0,
      '10': 'subscriptionResponse'
    },
  ],
  '8': [
    {'1': 'message'},
  ],
};

/// Descriptor for `SignalResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signalResponseDescriptor = $convert.base64Decode(
    'Cg5TaWduYWxSZXNwb25zZRIrCgRqb2luGAEgASgLMhUubGl2ZWtpdC5Kb2luUmVzcG9uc2VIAF'
    'IEam9pbhI1CgZhbnN3ZXIYAiABKAsyGy5saXZla2l0LlNlc3Npb25EZXNjcmlwdGlvbkgAUgZh'
    'bnN3ZXISMwoFb2ZmZXIYAyABKAsyGy5saXZla2l0LlNlc3Npb25EZXNjcmlwdGlvbkgAUgVvZm'
    'ZlchIzCgd0cmlja2xlGAQgASgLMhcubGl2ZWtpdC5Ucmlja2xlUmVxdWVzdEgAUgd0cmlja2xl'
    'EjQKBnVwZGF0ZRgFIAEoCzIaLmxpdmVraXQuUGFydGljaXBhbnRVcGRhdGVIAFIGdXBkYXRlEk'
    'oKD3RyYWNrX3B1Ymxpc2hlZBgGIAEoCzIfLmxpdmVraXQuVHJhY2tQdWJsaXNoZWRSZXNwb25z'
    'ZUgAUg50cmFja1B1Ymxpc2hlZBItCgVsZWF2ZRgIIAEoCzIVLmxpdmVraXQuTGVhdmVSZXF1ZX'
    'N0SABSBWxlYXZlEi8KBG11dGUYCSABKAsyGS5saXZla2l0Lk11dGVUcmFja1JlcXVlc3RIAFIE'
    'bXV0ZRJFChBzcGVha2Vyc19jaGFuZ2VkGAogASgLMhgubGl2ZWtpdC5TcGVha2Vyc0NoYW5nZW'
    'RIAFIPc3BlYWtlcnNDaGFuZ2VkEjYKC3Jvb21fdXBkYXRlGAsgASgLMhMubGl2ZWtpdC5Sb29t'
    'VXBkYXRlSABSCnJvb21VcGRhdGUSUQoSY29ubmVjdGlvbl9xdWFsaXR5GAwgASgLMiAubGl2ZW'
    'tpdC5Db25uZWN0aW9uUXVhbGl0eVVwZGF0ZUgAUhFjb25uZWN0aW9uUXVhbGl0eRJMChNzdHJl'
    'YW1fc3RhdGVfdXBkYXRlGA0gASgLMhoubGl2ZWtpdC5TdHJlYW1TdGF0ZVVwZGF0ZUgAUhFzdH'
    'JlYW1TdGF0ZVVwZGF0ZRJeChlzdWJzY3JpYmVkX3F1YWxpdHlfdXBkYXRlGA4gASgLMiAubGl2'
    'ZWtpdC5TdWJzY3JpYmVkUXVhbGl0eVVwZGF0ZUgAUhdzdWJzY3JpYmVkUXVhbGl0eVVwZGF0ZR'
    'JtCh5zdWJzY3JpcHRpb25fcGVybWlzc2lvbl91cGRhdGUYDyABKAsyJS5saXZla2l0LlN1YnNj'
    'cmlwdGlvblBlcm1pc3Npb25VcGRhdGVIAFIcc3Vic2NyaXB0aW9uUGVybWlzc2lvblVwZGF0ZR'
    'IlCg1yZWZyZXNoX3Rva2VuGBAgASgJSABSDHJlZnJlc2hUb2tlbhJQChF0cmFja191bnB1Ymxp'
    'c2hlZBgRIAEoCzIhLmxpdmVraXQuVHJhY2tVbnB1Ymxpc2hlZFJlc3BvbnNlSABSEHRyYWNrVW'
    '5wdWJsaXNoZWQSFAoEcG9uZxgSIAEoA0gAUgRwb25nEjoKCXJlY29ubmVjdBgTIAEoCzIaLmxp'
    'dmVraXQuUmVjb25uZWN0UmVzcG9uc2VIAFIJcmVjb25uZWN0EiwKCXBvbmdfcmVzcBgUIAEoCz'
    'INLmxpdmVraXQuUG9uZ0gAUghwb25nUmVzcBJUChVzdWJzY3JpcHRpb25fcmVzcG9uc2UYFSAB'
    'KAsyHS5saXZla2l0LlN1YnNjcmlwdGlvblJlc3BvbnNlSABSFHN1YnNjcmlwdGlvblJlc3Bvbn'
    'NlQgkKB21lc3NhZ2U=');

@$core.Deprecated('Use simulcastCodecDescriptor instead')
const SimulcastCodec$json = {
  '1': 'SimulcastCodec',
  '2': [
    {'1': 'codec', '3': 1, '4': 1, '5': 9, '10': 'codec'},
    {'1': 'cid', '3': 2, '4': 1, '5': 9, '10': 'cid'},
  ],
};

/// Descriptor for `SimulcastCodec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List simulcastCodecDescriptor = $convert.base64Decode(
    'Cg5TaW11bGNhc3RDb2RlYxIUCgVjb2RlYxgBIAEoCVIFY29kZWMSEAoDY2lkGAIgASgJUgNjaW'
    'Q=');

@$core.Deprecated('Use addTrackRequestDescriptor instead')
const AddTrackRequest$json = {
  '1': 'AddTrackRequest',
  '2': [
    {'1': 'cid', '3': 1, '4': 1, '5': 9, '10': 'cid'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'type',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.livekit.TrackType',
      '10': 'type'
    },
    {'1': 'width', '3': 4, '4': 1, '5': 13, '10': 'width'},
    {'1': 'height', '3': 5, '4': 1, '5': 13, '10': 'height'},
    {'1': 'muted', '3': 6, '4': 1, '5': 8, '10': 'muted'},
    {'1': 'disable_dtx', '3': 7, '4': 1, '5': 8, '10': 'disableDtx'},
    {
      '1': 'source',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.livekit.TrackSource',
      '10': 'source'
    },
    {
      '1': 'layers',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.livekit.VideoLayer',
      '10': 'layers'
    },
    {
      '1': 'simulcast_codecs',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.livekit.SimulcastCodec',
      '10': 'simulcastCodecs'
    },
    {'1': 'sid', '3': 11, '4': 1, '5': 9, '10': 'sid'},
    {'1': 'stereo', '3': 12, '4': 1, '5': 8, '10': 'stereo'},
    {'1': 'disable_red', '3': 13, '4': 1, '5': 8, '10': 'disableRed'},
    {
      '1': 'encryption',
      '3': 14,
      '4': 1,
      '5': 14,
      '6': '.livekit.Encryption.Type',
      '10': 'encryption'
    },
    {'1': 'stream', '3': 15, '4': 1, '5': 9, '10': 'stream'},
  ],
};

/// Descriptor for `AddTrackRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addTrackRequestDescriptor = $convert.base64Decode(
    'Cg9BZGRUcmFja1JlcXVlc3QSEAoDY2lkGAEgASgJUgNjaWQSEgoEbmFtZRgCIAEoCVIEbmFtZR'
    'ImCgR0eXBlGAMgASgOMhIubGl2ZWtpdC5UcmFja1R5cGVSBHR5cGUSFAoFd2lkdGgYBCABKA1S'
    'BXdpZHRoEhYKBmhlaWdodBgFIAEoDVIGaGVpZ2h0EhQKBW11dGVkGAYgASgIUgVtdXRlZBIfCg'
    'tkaXNhYmxlX2R0eBgHIAEoCFIKZGlzYWJsZUR0eBIsCgZzb3VyY2UYCCABKA4yFC5saXZla2l0'
    'LlRyYWNrU291cmNlUgZzb3VyY2USKwoGbGF5ZXJzGAkgAygLMhMubGl2ZWtpdC5WaWRlb0xheW'
    'VyUgZsYXllcnMSQgoQc2ltdWxjYXN0X2NvZGVjcxgKIAMoCzIXLmxpdmVraXQuU2ltdWxjYXN0'
    'Q29kZWNSD3NpbXVsY2FzdENvZGVjcxIQCgNzaWQYCyABKAlSA3NpZBIWCgZzdGVyZW8YDCABKA'
    'hSBnN0ZXJlbxIfCgtkaXNhYmxlX3JlZBgNIAEoCFIKZGlzYWJsZVJlZBI4CgplbmNyeXB0aW9u'
    'GA4gASgOMhgubGl2ZWtpdC5FbmNyeXB0aW9uLlR5cGVSCmVuY3J5cHRpb24SFgoGc3RyZWFtGA'
    '8gASgJUgZzdHJlYW0=');

@$core.Deprecated('Use trickleRequestDescriptor instead')
const TrickleRequest$json = {
  '1': 'TrickleRequest',
  '2': [
    {'1': 'candidateInit', '3': 1, '4': 1, '5': 9, '10': 'candidateInit'},
    {
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
    'Cg5Ucmlja2xlUmVxdWVzdBIkCg1jYW5kaWRhdGVJbml0GAEgASgJUg1jYW5kaWRhdGVJbml0Ei'
    '0KBnRhcmdldBgCIAEoDjIVLmxpdmVraXQuU2lnbmFsVGFyZ2V0UgZ0YXJnZXQ=');

@$core.Deprecated('Use muteTrackRequestDescriptor instead')
const MuteTrackRequest$json = {
  '1': 'MuteTrackRequest',
  '2': [
    {'1': 'sid', '3': 1, '4': 1, '5': 9, '10': 'sid'},
    {'1': 'muted', '3': 2, '4': 1, '5': 8, '10': 'muted'},
  ],
};

/// Descriptor for `MuteTrackRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List muteTrackRequestDescriptor = $convert.base64Decode(
    'ChBNdXRlVHJhY2tSZXF1ZXN0EhAKA3NpZBgBIAEoCVIDc2lkEhQKBW11dGVkGAIgASgIUgVtdX'
    'RlZA==');

@$core.Deprecated('Use joinResponseDescriptor instead')
const JoinResponse$json = {
  '1': 'JoinResponse',
  '2': [
    {'1': 'room', '3': 1, '4': 1, '5': 11, '6': '.livekit.Room', '10': 'room'},
    {
      '1': 'participant',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.livekit.ParticipantInfo',
      '10': 'participant'
    },
    {
      '1': 'other_participants',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.livekit.ParticipantInfo',
      '10': 'otherParticipants'
    },
    {'1': 'server_version', '3': 4, '4': 1, '5': 9, '10': 'serverVersion'},
    {
      '1': 'ice_servers',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.livekit.ICEServer',
      '10': 'iceServers'
    },
    {
      '1': 'subscriber_primary',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'subscriberPrimary'
    },
    {'1': 'alternative_url', '3': 7, '4': 1, '5': 9, '10': 'alternativeUrl'},
    {
      '1': 'client_configuration',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.livekit.ClientConfiguration',
      '10': 'clientConfiguration'
    },
    {'1': 'server_region', '3': 9, '4': 1, '5': 9, '10': 'serverRegion'},
    {'1': 'ping_timeout', '3': 10, '4': 1, '5': 5, '10': 'pingTimeout'},
    {'1': 'ping_interval', '3': 11, '4': 1, '5': 5, '10': 'pingInterval'},
    {
      '1': 'server_info',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.livekit.ServerInfo',
      '10': 'serverInfo'
    },
    {'1': 'sif_trailer', '3': 13, '4': 1, '5': 12, '10': 'sifTrailer'},
  ],
};

/// Descriptor for `JoinResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List joinResponseDescriptor = $convert.base64Decode(
    'CgxKb2luUmVzcG9uc2USIQoEcm9vbRgBIAEoCzINLmxpdmVraXQuUm9vbVIEcm9vbRI6CgtwYX'
    'J0aWNpcGFudBgCIAEoCzIYLmxpdmVraXQuUGFydGljaXBhbnRJbmZvUgtwYXJ0aWNpcGFudBJH'
    'ChJvdGhlcl9wYXJ0aWNpcGFudHMYAyADKAsyGC5saXZla2l0LlBhcnRpY2lwYW50SW5mb1IRb3'
    'RoZXJQYXJ0aWNpcGFudHMSJQoOc2VydmVyX3ZlcnNpb24YBCABKAlSDXNlcnZlclZlcnNpb24S'
    'MwoLaWNlX3NlcnZlcnMYBSADKAsyEi5saXZla2l0LklDRVNlcnZlclIKaWNlU2VydmVycxItCh'
    'JzdWJzY3JpYmVyX3ByaW1hcnkYBiABKAhSEXN1YnNjcmliZXJQcmltYXJ5EicKD2FsdGVybmF0'
    'aXZlX3VybBgHIAEoCVIOYWx0ZXJuYXRpdmVVcmwSTwoUY2xpZW50X2NvbmZpZ3VyYXRpb24YCC'
    'ABKAsyHC5saXZla2l0LkNsaWVudENvbmZpZ3VyYXRpb25SE2NsaWVudENvbmZpZ3VyYXRpb24S'
    'IwoNc2VydmVyX3JlZ2lvbhgJIAEoCVIMc2VydmVyUmVnaW9uEiEKDHBpbmdfdGltZW91dBgKIA'
    'EoBVILcGluZ1RpbWVvdXQSIwoNcGluZ19pbnRlcnZhbBgLIAEoBVIMcGluZ0ludGVydmFsEjQK'
    'C3NlcnZlcl9pbmZvGAwgASgLMhMubGl2ZWtpdC5TZXJ2ZXJJbmZvUgpzZXJ2ZXJJbmZvEh8KC3'
    'NpZl90cmFpbGVyGA0gASgMUgpzaWZUcmFpbGVy');

@$core.Deprecated('Use reconnectResponseDescriptor instead')
const ReconnectResponse$json = {
  '1': 'ReconnectResponse',
  '2': [
    {
      '1': 'ice_servers',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.livekit.ICEServer',
      '10': 'iceServers'
    },
    {
      '1': 'client_configuration',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.livekit.ClientConfiguration',
      '10': 'clientConfiguration'
    },
  ],
};

/// Descriptor for `ReconnectResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reconnectResponseDescriptor = $convert.base64Decode(
    'ChFSZWNvbm5lY3RSZXNwb25zZRIzCgtpY2Vfc2VydmVycxgBIAMoCzISLmxpdmVraXQuSUNFU2'
    'VydmVyUgppY2VTZXJ2ZXJzEk8KFGNsaWVudF9jb25maWd1cmF0aW9uGAIgASgLMhwubGl2ZWtp'
    'dC5DbGllbnRDb25maWd1cmF0aW9uUhNjbGllbnRDb25maWd1cmF0aW9u');

@$core.Deprecated('Use trackPublishedResponseDescriptor instead')
const TrackPublishedResponse$json = {
  '1': 'TrackPublishedResponse',
  '2': [
    {'1': 'cid', '3': 1, '4': 1, '5': 9, '10': 'cid'},
    {
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
        'ChZUcmFja1B1Ymxpc2hlZFJlc3BvbnNlEhAKA2NpZBgBIAEoCVIDY2lkEigKBXRyYWNrGAIgAS'
        'gLMhIubGl2ZWtpdC5UcmFja0luZm9SBXRyYWNr');

@$core.Deprecated('Use trackUnpublishedResponseDescriptor instead')
const TrackUnpublishedResponse$json = {
  '1': 'TrackUnpublishedResponse',
  '2': [
    {'1': 'track_sid', '3': 1, '4': 1, '5': 9, '10': 'trackSid'},
  ],
};

/// Descriptor for `TrackUnpublishedResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackUnpublishedResponseDescriptor =
    $convert.base64Decode(
        'ChhUcmFja1VucHVibGlzaGVkUmVzcG9uc2USGwoJdHJhY2tfc2lkGAEgASgJUgh0cmFja1NpZA'
        '==');

@$core.Deprecated('Use sessionDescriptionDescriptor instead')
const SessionDescription$json = {
  '1': 'SessionDescription',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    {'1': 'sdp', '3': 2, '4': 1, '5': 9, '10': 'sdp'},
  ],
};

/// Descriptor for `SessionDescription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionDescriptionDescriptor = $convert.base64Decode(
    'ChJTZXNzaW9uRGVzY3JpcHRpb24SEgoEdHlwZRgBIAEoCVIEdHlwZRIQCgNzZHAYAiABKAlSA3'
    'NkcA==');

@$core.Deprecated('Use participantUpdateDescriptor instead')
const ParticipantUpdate$json = {
  '1': 'ParticipantUpdate',
  '2': [
    {
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
    'ChFQYXJ0aWNpcGFudFVwZGF0ZRI8CgxwYXJ0aWNpcGFudHMYASADKAsyGC5saXZla2l0LlBhcn'
    'RpY2lwYW50SW5mb1IMcGFydGljaXBhbnRz');

@$core.Deprecated('Use updateSubscriptionDescriptor instead')
const UpdateSubscription$json = {
  '1': 'UpdateSubscription',
  '2': [
    {'1': 'track_sids', '3': 1, '4': 3, '5': 9, '10': 'trackSids'},
    {'1': 'subscribe', '3': 2, '4': 1, '5': 8, '10': 'subscribe'},
    {
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
    'ChJVcGRhdGVTdWJzY3JpcHRpb24SHQoKdHJhY2tfc2lkcxgBIAMoCVIJdHJhY2tTaWRzEhwKCX'
    'N1YnNjcmliZRgCIAEoCFIJc3Vic2NyaWJlEkkKEnBhcnRpY2lwYW50X3RyYWNrcxgDIAMoCzIa'
    'LmxpdmVraXQuUGFydGljaXBhbnRUcmFja3NSEXBhcnRpY2lwYW50VHJhY2tz');

@$core.Deprecated('Use updateTrackSettingsDescriptor instead')
const UpdateTrackSettings$json = {
  '1': 'UpdateTrackSettings',
  '2': [
    {'1': 'track_sids', '3': 1, '4': 3, '5': 9, '10': 'trackSids'},
    {'1': 'disabled', '3': 3, '4': 1, '5': 8, '10': 'disabled'},
    {
      '1': 'quality',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.livekit.VideoQuality',
      '10': 'quality'
    },
    {'1': 'width', '3': 5, '4': 1, '5': 13, '10': 'width'},
    {'1': 'height', '3': 6, '4': 1, '5': 13, '10': 'height'},
    {'1': 'fps', '3': 7, '4': 1, '5': 13, '10': 'fps'},
    {'1': 'priority', '3': 8, '4': 1, '5': 13, '10': 'priority'},
  ],
};

/// Descriptor for `UpdateTrackSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateTrackSettingsDescriptor = $convert.base64Decode(
    'ChNVcGRhdGVUcmFja1NldHRpbmdzEh0KCnRyYWNrX3NpZHMYASADKAlSCXRyYWNrU2lkcxIaCg'
    'hkaXNhYmxlZBgDIAEoCFIIZGlzYWJsZWQSLwoHcXVhbGl0eRgEIAEoDjIVLmxpdmVraXQuVmlk'
    'ZW9RdWFsaXR5UgdxdWFsaXR5EhQKBXdpZHRoGAUgASgNUgV3aWR0aBIWCgZoZWlnaHQYBiABKA'
    '1SBmhlaWdodBIQCgNmcHMYByABKA1SA2ZwcxIaCghwcmlvcml0eRgIIAEoDVIIcHJpb3JpdHk=');

@$core.Deprecated('Use leaveRequestDescriptor instead')
const LeaveRequest$json = {
  '1': 'LeaveRequest',
  '2': [
    {'1': 'can_reconnect', '3': 1, '4': 1, '5': 8, '10': 'canReconnect'},
    {
      '1': 'reason',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.livekit.DisconnectReason',
      '10': 'reason'
    },
  ],
};

/// Descriptor for `LeaveRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List leaveRequestDescriptor = $convert.base64Decode(
    'CgxMZWF2ZVJlcXVlc3QSIwoNY2FuX3JlY29ubmVjdBgBIAEoCFIMY2FuUmVjb25uZWN0EjEKBn'
    'JlYXNvbhgCIAEoDjIZLmxpdmVraXQuRGlzY29ubmVjdFJlYXNvblIGcmVhc29u');

@$core.Deprecated('Use updateVideoLayersDescriptor instead')
const UpdateVideoLayers$json = {
  '1': 'UpdateVideoLayers',
  '2': [
    {'1': 'track_sid', '3': 1, '4': 1, '5': 9, '10': 'trackSid'},
    {
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
    'ChFVcGRhdGVWaWRlb0xheWVycxIbCgl0cmFja19zaWQYASABKAlSCHRyYWNrU2lkEisKBmxheW'
    'VycxgCIAMoCzITLmxpdmVraXQuVmlkZW9MYXllclIGbGF5ZXJz');

@$core.Deprecated('Use updateParticipantMetadataDescriptor instead')
const UpdateParticipantMetadata$json = {
  '1': 'UpdateParticipantMetadata',
  '2': [
    {'1': 'metadata', '3': 1, '4': 1, '5': 9, '10': 'metadata'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `UpdateParticipantMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateParticipantMetadataDescriptor =
    $convert.base64Decode(
        'ChlVcGRhdGVQYXJ0aWNpcGFudE1ldGFkYXRhEhoKCG1ldGFkYXRhGAEgASgJUghtZXRhZGF0YR'
        'ISCgRuYW1lGAIgASgJUgRuYW1l');

@$core.Deprecated('Use iCEServerDescriptor instead')
const ICEServer$json = {
  '1': 'ICEServer',
  '2': [
    {'1': 'urls', '3': 1, '4': 3, '5': 9, '10': 'urls'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {'1': 'credential', '3': 3, '4': 1, '5': 9, '10': 'credential'},
  ],
};

/// Descriptor for `ICEServer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List iCEServerDescriptor = $convert.base64Decode(
    'CglJQ0VTZXJ2ZXISEgoEdXJscxgBIAMoCVIEdXJscxIaCgh1c2VybmFtZRgCIAEoCVIIdXNlcm'
    '5hbWUSHgoKY3JlZGVudGlhbBgDIAEoCVIKY3JlZGVudGlhbA==');

@$core.Deprecated('Use speakersChangedDescriptor instead')
const SpeakersChanged$json = {
  '1': 'SpeakersChanged',
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

/// Descriptor for `SpeakersChanged`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List speakersChangedDescriptor = $convert.base64Decode(
    'Cg9TcGVha2Vyc0NoYW5nZWQSMAoIc3BlYWtlcnMYASADKAsyFC5saXZla2l0LlNwZWFrZXJJbm'
    'ZvUghzcGVha2Vycw==');

@$core.Deprecated('Use roomUpdateDescriptor instead')
const RoomUpdate$json = {
  '1': 'RoomUpdate',
  '2': [
    {'1': 'room', '3': 1, '4': 1, '5': 11, '6': '.livekit.Room', '10': 'room'},
  ],
};

/// Descriptor for `RoomUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roomUpdateDescriptor = $convert.base64Decode(
    'CgpSb29tVXBkYXRlEiEKBHJvb20YASABKAsyDS5saXZla2l0LlJvb21SBHJvb20=');

@$core.Deprecated('Use connectionQualityInfoDescriptor instead')
const ConnectionQualityInfo$json = {
  '1': 'ConnectionQualityInfo',
  '2': [
    {'1': 'participant_sid', '3': 1, '4': 1, '5': 9, '10': 'participantSid'},
    {
      '1': 'quality',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.livekit.ConnectionQuality',
      '10': 'quality'
    },
    {'1': 'score', '3': 3, '4': 1, '5': 2, '10': 'score'},
  ],
};

/// Descriptor for `ConnectionQualityInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectionQualityInfoDescriptor = $convert.base64Decode(
    'ChVDb25uZWN0aW9uUXVhbGl0eUluZm8SJwoPcGFydGljaXBhbnRfc2lkGAEgASgJUg5wYXJ0aW'
    'NpcGFudFNpZBI0CgdxdWFsaXR5GAIgASgOMhoubGl2ZWtpdC5Db25uZWN0aW9uUXVhbGl0eVIH'
    'cXVhbGl0eRIUCgVzY29yZRgDIAEoAlIFc2NvcmU=');

@$core.Deprecated('Use connectionQualityUpdateDescriptor instead')
const ConnectionQualityUpdate$json = {
  '1': 'ConnectionQualityUpdate',
  '2': [
    {
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
        'ChdDb25uZWN0aW9uUXVhbGl0eVVwZGF0ZRI4Cgd1cGRhdGVzGAEgAygLMh4ubGl2ZWtpdC5Db2'
        '5uZWN0aW9uUXVhbGl0eUluZm9SB3VwZGF0ZXM=');

@$core.Deprecated('Use streamStateInfoDescriptor instead')
const StreamStateInfo$json = {
  '1': 'StreamStateInfo',
  '2': [
    {'1': 'participant_sid', '3': 1, '4': 1, '5': 9, '10': 'participantSid'},
    {'1': 'track_sid', '3': 2, '4': 1, '5': 9, '10': 'trackSid'},
    {
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
    'Cg9TdHJlYW1TdGF0ZUluZm8SJwoPcGFydGljaXBhbnRfc2lkGAEgASgJUg5wYXJ0aWNpcGFudF'
    'NpZBIbCgl0cmFja19zaWQYAiABKAlSCHRyYWNrU2lkEioKBXN0YXRlGAMgASgOMhQubGl2ZWtp'
    'dC5TdHJlYW1TdGF0ZVIFc3RhdGU=');

@$core.Deprecated('Use streamStateUpdateDescriptor instead')
const StreamStateUpdate$json = {
  '1': 'StreamStateUpdate',
  '2': [
    {
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
    'ChFTdHJlYW1TdGF0ZVVwZGF0ZRI9Cg1zdHJlYW1fc3RhdGVzGAEgAygLMhgubGl2ZWtpdC5TdH'
    'JlYW1TdGF0ZUluZm9SDHN0cmVhbVN0YXRlcw==');

@$core.Deprecated('Use subscribedQualityDescriptor instead')
const SubscribedQuality$json = {
  '1': 'SubscribedQuality',
  '2': [
    {
      '1': 'quality',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.livekit.VideoQuality',
      '10': 'quality'
    },
    {'1': 'enabled', '3': 2, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `SubscribedQuality`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribedQualityDescriptor = $convert.base64Decode(
    'ChFTdWJzY3JpYmVkUXVhbGl0eRIvCgdxdWFsaXR5GAEgASgOMhUubGl2ZWtpdC5WaWRlb1F1YW'
    'xpdHlSB3F1YWxpdHkSGAoHZW5hYmxlZBgCIAEoCFIHZW5hYmxlZA==');

@$core.Deprecated('Use subscribedCodecDescriptor instead')
const SubscribedCodec$json = {
  '1': 'SubscribedCodec',
  '2': [
    {'1': 'codec', '3': 1, '4': 1, '5': 9, '10': 'codec'},
    {
      '1': 'qualities',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.livekit.SubscribedQuality',
      '10': 'qualities'
    },
  ],
};

/// Descriptor for `SubscribedCodec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribedCodecDescriptor = $convert.base64Decode(
    'Cg9TdWJzY3JpYmVkQ29kZWMSFAoFY29kZWMYASABKAlSBWNvZGVjEjgKCXF1YWxpdGllcxgCIA'
    'MoCzIaLmxpdmVraXQuU3Vic2NyaWJlZFF1YWxpdHlSCXF1YWxpdGllcw==');

@$core.Deprecated('Use subscribedQualityUpdateDescriptor instead')
const SubscribedQualityUpdate$json = {
  '1': 'SubscribedQualityUpdate',
  '2': [
    {'1': 'track_sid', '3': 1, '4': 1, '5': 9, '10': 'trackSid'},
    {
      '1': 'subscribed_qualities',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.livekit.SubscribedQuality',
      '10': 'subscribedQualities'
    },
    {
      '1': 'subscribed_codecs',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.livekit.SubscribedCodec',
      '10': 'subscribedCodecs'
    },
  ],
};

/// Descriptor for `SubscribedQualityUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribedQualityUpdateDescriptor = $convert.base64Decode(
    'ChdTdWJzY3JpYmVkUXVhbGl0eVVwZGF0ZRIbCgl0cmFja19zaWQYASABKAlSCHRyYWNrU2lkEk'
    '0KFHN1YnNjcmliZWRfcXVhbGl0aWVzGAIgAygLMhoubGl2ZWtpdC5TdWJzY3JpYmVkUXVhbGl0'
    'eVITc3Vic2NyaWJlZFF1YWxpdGllcxJFChFzdWJzY3JpYmVkX2NvZGVjcxgDIAMoCzIYLmxpdm'
    'VraXQuU3Vic2NyaWJlZENvZGVjUhBzdWJzY3JpYmVkQ29kZWNz');

@$core.Deprecated('Use trackPermissionDescriptor instead')
const TrackPermission$json = {
  '1': 'TrackPermission',
  '2': [
    {'1': 'participant_sid', '3': 1, '4': 1, '5': 9, '10': 'participantSid'},
    {'1': 'all_tracks', '3': 2, '4': 1, '5': 8, '10': 'allTracks'},
    {'1': 'track_sids', '3': 3, '4': 3, '5': 9, '10': 'trackSids'},
    {
      '1': 'participant_identity',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'participantIdentity'
    },
  ],
};

/// Descriptor for `TrackPermission`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackPermissionDescriptor = $convert.base64Decode(
    'Cg9UcmFja1Blcm1pc3Npb24SJwoPcGFydGljaXBhbnRfc2lkGAEgASgJUg5wYXJ0aWNpcGFudF'
    'NpZBIdCgphbGxfdHJhY2tzGAIgASgIUglhbGxUcmFja3MSHQoKdHJhY2tfc2lkcxgDIAMoCVIJ'
    'dHJhY2tTaWRzEjEKFHBhcnRpY2lwYW50X2lkZW50aXR5GAQgASgJUhNwYXJ0aWNpcGFudElkZW'
    '50aXR5');

@$core.Deprecated('Use subscriptionPermissionDescriptor instead')
const SubscriptionPermission$json = {
  '1': 'SubscriptionPermission',
  '2': [
    {'1': 'all_participants', '3': 1, '4': 1, '5': 8, '10': 'allParticipants'},
    {
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
final $typed_data.Uint8List subscriptionPermissionDescriptor = $convert.base64Decode(
    'ChZTdWJzY3JpcHRpb25QZXJtaXNzaW9uEikKEGFsbF9wYXJ0aWNpcGFudHMYASABKAhSD2FsbF'
    'BhcnRpY2lwYW50cxJFChF0cmFja19wZXJtaXNzaW9ucxgCIAMoCzIYLmxpdmVraXQuVHJhY2tQ'
    'ZXJtaXNzaW9uUhB0cmFja1Blcm1pc3Npb25z');

@$core.Deprecated('Use subscriptionPermissionUpdateDescriptor instead')
const SubscriptionPermissionUpdate$json = {
  '1': 'SubscriptionPermissionUpdate',
  '2': [
    {'1': 'participant_sid', '3': 1, '4': 1, '5': 9, '10': 'participantSid'},
    {'1': 'track_sid', '3': 2, '4': 1, '5': 9, '10': 'trackSid'},
    {'1': 'allowed', '3': 3, '4': 1, '5': 8, '10': 'allowed'},
  ],
};

/// Descriptor for `SubscriptionPermissionUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscriptionPermissionUpdateDescriptor =
    $convert.base64Decode(
        'ChxTdWJzY3JpcHRpb25QZXJtaXNzaW9uVXBkYXRlEicKD3BhcnRpY2lwYW50X3NpZBgBIAEoCV'
        'IOcGFydGljaXBhbnRTaWQSGwoJdHJhY2tfc2lkGAIgASgJUgh0cmFja1NpZBIYCgdhbGxvd2Vk'
        'GAMgASgIUgdhbGxvd2Vk');

@$core.Deprecated('Use syncStateDescriptor instead')
const SyncState$json = {
  '1': 'SyncState',
  '2': [
    {
      '1': 'answer',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.livekit.SessionDescription',
      '10': 'answer'
    },
    {
      '1': 'subscription',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.livekit.UpdateSubscription',
      '10': 'subscription'
    },
    {
      '1': 'publish_tracks',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.livekit.TrackPublishedResponse',
      '10': 'publishTracks'
    },
    {
      '1': 'data_channels',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.livekit.DataChannelInfo',
      '10': 'dataChannels'
    },
    {
      '1': 'offer',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.livekit.SessionDescription',
      '10': 'offer'
    },
  ],
};

/// Descriptor for `SyncState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncStateDescriptor = $convert.base64Decode(
    'CglTeW5jU3RhdGUSMwoGYW5zd2VyGAEgASgLMhsubGl2ZWtpdC5TZXNzaW9uRGVzY3JpcHRpb2'
    '5SBmFuc3dlchI/CgxzdWJzY3JpcHRpb24YAiABKAsyGy5saXZla2l0LlVwZGF0ZVN1YnNjcmlw'
    'dGlvblIMc3Vic2NyaXB0aW9uEkYKDnB1Ymxpc2hfdHJhY2tzGAMgAygLMh8ubGl2ZWtpdC5Ucm'
    'Fja1B1Ymxpc2hlZFJlc3BvbnNlUg1wdWJsaXNoVHJhY2tzEj0KDWRhdGFfY2hhbm5lbHMYBCAD'
    'KAsyGC5saXZla2l0LkRhdGFDaGFubmVsSW5mb1IMZGF0YUNoYW5uZWxzEjEKBW9mZmVyGAUgAS'
    'gLMhsubGl2ZWtpdC5TZXNzaW9uRGVzY3JpcHRpb25SBW9mZmVy');

@$core.Deprecated('Use dataChannelInfoDescriptor instead')
const DataChannelInfo$json = {
  '1': 'DataChannelInfo',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'id', '3': 2, '4': 1, '5': 13, '10': 'id'},
    {
      '1': 'target',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.livekit.SignalTarget',
      '10': 'target'
    },
  ],
};

/// Descriptor for `DataChannelInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dataChannelInfoDescriptor = $convert.base64Decode(
    'Cg9EYXRhQ2hhbm5lbEluZm8SFAoFbGFiZWwYASABKAlSBWxhYmVsEg4KAmlkGAIgASgNUgJpZB'
    'ItCgZ0YXJnZXQYAyABKA4yFS5saXZla2l0LlNpZ25hbFRhcmdldFIGdGFyZ2V0');

@$core.Deprecated('Use simulateScenarioDescriptor instead')
const SimulateScenario$json = {
  '1': 'SimulateScenario',
  '2': [
    {
      '1': 'speaker_update',
      '3': 1,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'speakerUpdate'
    },
    {'1': 'node_failure', '3': 2, '4': 1, '5': 8, '9': 0, '10': 'nodeFailure'},
    {'1': 'migration', '3': 3, '4': 1, '5': 8, '9': 0, '10': 'migration'},
    {'1': 'server_leave', '3': 4, '4': 1, '5': 8, '9': 0, '10': 'serverLeave'},
    {
      '1': 'switch_candidate_protocol',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.livekit.CandidateProtocol',
      '9': 0,
      '10': 'switchCandidateProtocol'
    },
    {
      '1': 'subscriber_bandwidth',
      '3': 6,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'subscriberBandwidth'
    },
  ],
  '8': [
    {'1': 'scenario'},
  ],
};

/// Descriptor for `SimulateScenario`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List simulateScenarioDescriptor = $convert.base64Decode(
    'ChBTaW11bGF0ZVNjZW5hcmlvEicKDnNwZWFrZXJfdXBkYXRlGAEgASgFSABSDXNwZWFrZXJVcG'
    'RhdGUSIwoMbm9kZV9mYWlsdXJlGAIgASgISABSC25vZGVGYWlsdXJlEh4KCW1pZ3JhdGlvbhgD'
    'IAEoCEgAUgltaWdyYXRpb24SIwoMc2VydmVyX2xlYXZlGAQgASgISABSC3NlcnZlckxlYXZlEl'
    'gKGXN3aXRjaF9jYW5kaWRhdGVfcHJvdG9jb2wYBSABKA4yGi5saXZla2l0LkNhbmRpZGF0ZVBy'
    'b3RvY29sSABSF3N3aXRjaENhbmRpZGF0ZVByb3RvY29sEjMKFHN1YnNjcmliZXJfYmFuZHdpZH'
    'RoGAYgASgDSABSE3N1YnNjcmliZXJCYW5kd2lkdGhCCgoIc2NlbmFyaW8=');

@$core.Deprecated('Use pingDescriptor instead')
const Ping$json = {
  '1': 'Ping',
  '2': [
    {'1': 'timestamp', '3': 1, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'rtt', '3': 2, '4': 1, '5': 3, '10': 'rtt'},
  ],
};

/// Descriptor for `Ping`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pingDescriptor = $convert.base64Decode(
    'CgRQaW5nEhwKCXRpbWVzdGFtcBgBIAEoA1IJdGltZXN0YW1wEhAKA3J0dBgCIAEoA1IDcnR0');

@$core.Deprecated('Use pongDescriptor instead')
const Pong$json = {
  '1': 'Pong',
  '2': [
    {
      '1': 'last_ping_timestamp',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'lastPingTimestamp'
    },
    {'1': 'timestamp', '3': 2, '4': 1, '5': 3, '10': 'timestamp'},
  ],
};

/// Descriptor for `Pong`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pongDescriptor = $convert.base64Decode(
    'CgRQb25nEi4KE2xhc3RfcGluZ190aW1lc3RhbXAYASABKANSEWxhc3RQaW5nVGltZXN0YW1wEh'
    'wKCXRpbWVzdGFtcBgCIAEoA1IJdGltZXN0YW1w');

@$core.Deprecated('Use regionSettingsDescriptor instead')
const RegionSettings$json = {
  '1': 'RegionSettings',
  '2': [
    {
      '1': 'regions',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.livekit.RegionInfo',
      '10': 'regions'
    },
  ],
};

/// Descriptor for `RegionSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List regionSettingsDescriptor = $convert.base64Decode(
    'Cg5SZWdpb25TZXR0aW5ncxItCgdyZWdpb25zGAEgAygLMhMubGl2ZWtpdC5SZWdpb25JbmZvUg'
    'dyZWdpb25z');

@$core.Deprecated('Use regionInfoDescriptor instead')
const RegionInfo$json = {
  '1': 'RegionInfo',
  '2': [
    {'1': 'region', '3': 1, '4': 1, '5': 9, '10': 'region'},
    {'1': 'url', '3': 2, '4': 1, '5': 9, '10': 'url'},
    {'1': 'distance', '3': 3, '4': 1, '5': 3, '10': 'distance'},
  ],
};

/// Descriptor for `RegionInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List regionInfoDescriptor = $convert.base64Decode(
    'CgpSZWdpb25JbmZvEhYKBnJlZ2lvbhgBIAEoCVIGcmVnaW9uEhAKA3VybBgCIAEoCVIDdXJsEh'
    'oKCGRpc3RhbmNlGAMgASgDUghkaXN0YW5jZQ==');

@$core.Deprecated('Use subscriptionResponseDescriptor instead')
const SubscriptionResponse$json = {
  '1': 'SubscriptionResponse',
  '2': [
    {'1': 'track_sid', '3': 1, '4': 1, '5': 9, '10': 'trackSid'},
    {
      '1': 'err',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.livekit.SubscriptionError',
      '10': 'err'
    },
  ],
};

/// Descriptor for `SubscriptionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscriptionResponseDescriptor = $convert.base64Decode(
    'ChRTdWJzY3JpcHRpb25SZXNwb25zZRIbCgl0cmFja19zaWQYASABKAlSCHRyYWNrU2lkEiwKA2'
    'VychgCIAEoDjIaLmxpdmVraXQuU3Vic2NyaXB0aW9uRXJyb3JSA2Vycg==');
