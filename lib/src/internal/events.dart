// Copyright 2024 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../events.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../track/local/local.dart';
import '../track/options.dart';
import '../track/track.dart';
import '../types/other.dart';

mixin InternalEvent implements LiveKitEvent {}

@internal
abstract class EnginePeerStateUpdatedEvent with EngineEvent, InternalEvent {
  final rtc.RTCPeerConnectionState state;
  final bool isPrimary;
  const EnginePeerStateUpdatedEvent({
    required this.state,
    required this.isPrimary,
  });
}

@internal
class EngineSubscriberPeerStateUpdatedEvent
    extends EnginePeerStateUpdatedEvent {
  const EngineSubscriberPeerStateUpdatedEvent({
    required rtc.RTCPeerConnectionState state,
    required bool isPrimary,
  }) : super(
          state: state,
          isPrimary: isPrimary,
        );

  @override
  String toString() =>
      '${runtimeType}(state: ${state}, isPrimary: ${isPrimary})';
}

@internal
class EnginePublisherPeerStateUpdatedEvent extends EnginePeerStateUpdatedEvent {
  const EnginePublisherPeerStateUpdatedEvent({
    required rtc.RTCPeerConnectionState state,
    required bool isPrimary,
  }) : super(
          state: state,
          isPrimary: isPrimary,
        );
  @override
  String toString() =>
      '${runtimeType}(state: ${state}, isPrimary: ${isPrimary})';
}

@internal
class TrackStreamUpdatedEvent with TrackEvent, InternalEvent {
  final Track track;
  final rtc.MediaStream stream;
  const TrackStreamUpdatedEvent({
    required this.track,
    required this.stream,
  });
}

@internal
class AudioPlaybackStarted with TrackEvent, EngineEvent, InternalEvent {
  final Track track;
  const AudioPlaybackStarted({
    required this.track,
  });
}

@internal
class AudioPlaybackFailed with TrackEvent, EngineEvent, InternalEvent {
  final Track track;
  const AudioPlaybackFailed({
    required this.track,
  });
}

@internal
class LocalTrackOptionsUpdatedEvent with TrackEvent, InternalEvent {
  final LocalTrack track;
  final LocalTrackOptions options;
  const LocalTrackOptionsUpdatedEvent({
    required this.track,
    required this.options,
  });
}

// Used to notify muted state from Track to TrackPublication.
@internal
class InternalTrackMuteUpdatedEvent with TrackEvent, InternalEvent {
  final Track track;
  final bool muted;
  final bool shouldSendSignal;
  const InternalTrackMuteUpdatedEvent({
    required this.track,
    required this.muted,
    required this.shouldSendSignal,
  });

  @override
  String toString() =>
      'TrackMuteUpdatedEvent(track: ${track}, muted: ${muted})';
}

//
// Signal events
//

@internal
// Received a JoinResponse from the server.
class SignalJoinResponseEvent with SignalEvent, InternalEvent {
  final lk_rtc.JoinResponse response;
  const SignalJoinResponseEvent({
    required this.response,
  });
}

@internal
// Received a ReconnectResponse from the server.
class SignalReconnectResponseEvent with SignalEvent, InternalEvent {
  final lk_rtc.ReconnectResponse response;
  const SignalReconnectResponseEvent({
    required this.response,
  });
}

@internal
class SignalConnectivityChangedEvent with SignalEvent, InternalEvent {
  final List<ConnectivityResult> oldState;
  final List<ConnectivityResult> state;
  const SignalConnectivityChangedEvent({
    required this.oldState,
    required this.state,
  });
}

@internal
class EngineJoinResponseEvent with EngineEvent, InternalEvent {
  final lk_rtc.JoinResponse response;
  const EngineJoinResponseEvent({
    required this.response,
  });
}

@internal
class EngineConnectingEvent with InternalEvent, EngineEvent {
  const EngineConnectingEvent();
}

@internal
class EngineConnectedEvent with InternalEvent, SignalEvent, EngineEvent {
  const EngineConnectedEvent();
}

@internal
class EngineDisconnectedEvent with InternalEvent, EngineEvent {
  DisconnectReason? reason;
  EngineDisconnectedEvent({
    this.reason,
  });
}

@internal
class EngineClosingEvent with InternalEvent, EngineEvent {
  const EngineClosingEvent();
}

@internal
class EngineLocalTrackSubscribedEvent with InternalEvent, EngineEvent {
  final String trackSid;
  const EngineLocalTrackSubscribedEvent({
    required this.trackSid,
  });
}

@internal
class EngineFullRestartingEvent with InternalEvent, EngineEvent {
  const EngineFullRestartingEvent();
}

@internal
class EngineAttemptReconnectEvent with InternalEvent, EngineEvent {
  int attempt;
  int maxAttempts;
  int nextRetryDelaysInMs;
  EngineAttemptReconnectEvent({
    required this.attempt,
    required this.maxAttempts,
    required this.nextRetryDelaysInMs,
  });
}

@internal
class EngineRestartedEvent with InternalEvent, EngineEvent {
  const EngineRestartedEvent();
}

@internal
class EngineReconnectingEvent with InternalEvent, EngineEvent {
  const EngineReconnectingEvent();
}

@internal
class EngineResumedEvent with InternalEvent, EngineEvent {
  const EngineResumedEvent();
}

@internal
class EngineResumingEvent with InternalEvent, EngineEvent {
  const EngineResumingEvent();
}

@internal
class SignalConnectedEvent with SignalEvent, InternalEvent {
  const SignalConnectedEvent();
}

@internal
class SignalConnectingEvent with SignalEvent, InternalEvent {
  const SignalConnectingEvent();
}

@internal
class SignalReconnectingEvent with SignalEvent, InternalEvent {
  const SignalReconnectingEvent();
}

@internal
class SignalReconnectedEvent with SignalEvent, InternalEvent, EngineEvent {
  const SignalReconnectedEvent();
}

@internal
class SignalDisconnectedEvent with SignalEvent, InternalEvent {
  DisconnectReason? reason;
  SignalDisconnectedEvent({
    this.reason,
  });
}

@internal
class SignalOfferEvent with SignalEvent, InternalEvent {
  final rtc.RTCSessionDescription sd;
  const SignalOfferEvent({
    required this.sd,
  });
}

@internal
class SignalAnswerEvent with SignalEvent, InternalEvent {
  final rtc.RTCSessionDescription sd;
  const SignalAnswerEvent({
    required this.sd,
  });
}

@internal
class SignalTrickleEvent with SignalEvent, InternalEvent {
  final rtc.RTCIceCandidate candidate;
  final lk_rtc.SignalTarget target;
  const SignalTrickleEvent({
    required this.candidate,
    required this.target,
  });
}

@internal
// relayed by Engine
class SignalParticipantUpdateEvent with SignalEvent, InternalEvent {
  final List<lk_models.ParticipantInfo> participants;
  const SignalParticipantUpdateEvent({
    required this.participants,
  });
}

@internal
class SignalConnectionQualityUpdateEvent with SignalEvent, InternalEvent {
  final List<lk_rtc.ConnectionQualityInfo> updates;
  const SignalConnectionQualityUpdateEvent({
    required this.updates,
  });
}

@internal
class SignalLocalTrackPublishedEvent with SignalEvent, InternalEvent {
  final String cid;
  final lk_models.TrackInfo track;

  const SignalLocalTrackPublishedEvent({
    required this.cid,
    required this.track,
  });
}

@internal
class SignalTrackUnpublishedEvent with SignalEvent, InternalEvent {
  final String trackSid;

  const SignalTrackUnpublishedEvent({
    required this.trackSid,
  });
}

@internal
class SignalLocalTrackSubscribedEvent with SignalEvent, InternalEvent {
  final String trackSid;

  const SignalLocalTrackSubscribedEvent({
    required this.trackSid,
  });
}

@internal
class SignalRoomUpdateEvent with SignalEvent, InternalEvent {
  final lk_models.Room room;

  const SignalRoomUpdateEvent({required this.room});
}

@internal
// Speaker update received through websocket
// relayed by Engine
class SignalSpeakersChangedEvent with SignalEvent, InternalEvent {
  final List<lk_models.SpeakerInfo> speakers;

  const SignalSpeakersChangedEvent({
    required this.speakers,
  });
}

@internal
// Event received through data channel
class EngineActiveSpeakersUpdateEvent with EngineEvent, InternalEvent {
  final List<lk_models.SpeakerInfo> speakers;
  const EngineActiveSpeakersUpdateEvent({
    required this.speakers,
  });
}

@internal
class SignalLeaveEvent with SignalEvent, InternalEvent {
  bool get canReconnect => request.canReconnect;
  lk_rtc.LeaveRequest_Action get action => request.action;
  lk_models.DisconnectReason get reason => request.reason;
  lk_rtc.RegionSettings? get regions =>
      request.hasReason() ? request.regions : null;
  final lk_rtc.LeaveRequest request;
  const SignalLeaveEvent({
    required this.request,
  });
}

@internal
class SignalRemoteMuteTrackEvent with SignalEvent, InternalEvent {
  final String sid;
  final bool muted;
  const SignalRemoteMuteTrackEvent({
    required this.sid,
    required this.muted,
  });
}

@internal
class SignalStreamStateUpdatedEvent with SignalEvent, InternalEvent {
  final List<lk_rtc.StreamStateInfo> updates;
  const SignalStreamStateUpdatedEvent({
    required this.updates,
  });
}

@internal
class SignalSubscribedQualityUpdatedEvent with SignalEvent, InternalEvent {
  final String trackSid;
  final List<lk_rtc.SubscribedQuality> subscribedQualities;
  final List<lk_rtc.SubscribedCodec> subscribedCodecs;
  const SignalSubscribedQualityUpdatedEvent({
    required this.trackSid,
    required this.subscribedCodecs,
    required this.subscribedQualities,
  });
}

@internal
class SignalSubscriptionPermissionUpdateEvent with SignalEvent, InternalEvent {
  final String participantSid;
  final String trackSid;
  final bool allowed;
  const SignalSubscriptionPermissionUpdateEvent({
    required this.participantSid,
    required this.trackSid,
    required this.allowed,
  });
}

@internal
class SignalTokenUpdatedEvent with SignalEvent, InternalEvent {
  final String token;
  const SignalTokenUpdatedEvent({
    required this.token,
  });
}

// ----------------------------------------------------------------------
// Engine events
// ----------------------------------------------------------------------

@internal
class EngineTrackAddedEvent with EngineEvent, InternalEvent {
  final rtc.MediaStreamTrack track;
  final rtc.MediaStream stream;
  final rtc.RTCRtpReceiver? receiver;
  const EngineTrackAddedEvent({
    required this.track,
    required this.stream,
    required this.receiver,
  });
}

@internal
class EngineDataPacketReceivedEvent with EngineEvent, InternalEvent {
  final lk_models.UserPacket packet;
  final lk_models.DataPacket_Kind kind;
  final String identity;
  const EngineDataPacketReceivedEvent({
    required this.packet,
    required this.kind,
    required this.identity,
  });
}

@internal
class EngineTranscriptionReceivedEvent with EngineEvent, InternalEvent {
  final lk_models.Transcription transcription;
  final String identity;
  const EngineTranscriptionReceivedEvent({
    required this.transcription,
    required this.identity,
  });
}

@internal
class EngineSipDtmfReceivedEvent with EngineEvent, InternalEvent {
  final lk_models.SipDTMF dtmf;
  final String identity;
  const EngineSipDtmfReceivedEvent({
    required this.dtmf,
    required this.identity,
  });
}

@internal
class EngineRPCRequestReceivedEvent with EngineEvent, InternalEvent {
  final lk_models.RpcRequest request;
  String get requestId => request.id;
  final String identity;
  const EngineRPCRequestReceivedEvent({
    required this.request,
    required this.identity,
  });
}

@internal
class EngineRPCResponseReceivedEvent with EngineEvent, InternalEvent {
  final lk_models.RpcResponse response;
  String get requestId => response.requestId;
  final String identity;
  lk_models.RpcError? get error => response.error;
  String get payload => response.payload;
  const EngineRPCResponseReceivedEvent({
    required this.response,
    required this.identity,
  });
}

@internal
class EngineRPCAckReceivedEvent with EngineEvent, InternalEvent {
  final lk_models.RpcAck ack;
  String get requestId => ack.requestId;
  final String identity;
  const EngineRPCAckReceivedEvent({
    required this.ack,
    required this.identity,
  });
}

@internal
class EngineDataStreamHeaderEvent with EngineEvent, InternalEvent {
  final lk_models.DataStream_Header header;
  final String identity;
  const EngineDataStreamHeaderEvent({
    required this.header,
    required this.identity,
  });
}

@internal
class EngineDataStreamChunkEvent with EngineEvent, InternalEvent {
  final lk_models.DataStream_Chunk chunk;
  final String identity;
  const EngineDataStreamChunkEvent({
    required this.chunk,
    required this.identity,
  });
}

@internal
class EngineDataStreamTrailerEvent with EngineEvent, InternalEvent {
  final lk_models.DataStream_Trailer trailer;
  final String identity;
  const EngineDataStreamTrailerEvent({
    required this.trailer,
    required this.identity,
  });
}

@internal
abstract class DataChannelStateUpdatedEvent with EngineEvent, InternalEvent {
  final bool isPrimary;
  final Reliability type;
  final rtc.RTCDataChannelState state;
  const DataChannelStateUpdatedEvent({
    required this.isPrimary,
    required this.type,
    required this.state,
  });
}

@internal
class PublisherDataChannelStateUpdatedEvent
    extends DataChannelStateUpdatedEvent {
  PublisherDataChannelStateUpdatedEvent({
    required bool isPrimary,
    required Reliability type,
    required rtc.RTCDataChannelState state,
  }) : super(
          isPrimary: isPrimary,
          type: type,
          state: state,
        );
}

@internal
class SubscriberDataChannelStateUpdatedEvent
    extends DataChannelStateUpdatedEvent {
  SubscriberDataChannelStateUpdatedEvent({
    required bool isPrimary,
    required Reliability type,
    required rtc.RTCDataChannelState state,
  }) : super(
          isPrimary: isPrimary,
          type: type,
          state: state,
        );
}

@internal
class TrackEndedEvent with TrackEvent {
  final Track track;
  const TrackEndedEvent({
    required this.track,
  });

  @override
  String toString() => '${runtimeType}'
      '(track: ${track})';
}
