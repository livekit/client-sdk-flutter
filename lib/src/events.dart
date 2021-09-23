import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';

import 'participant/participant.dart';
import 'participant/remote_participant.dart';
import 'proto/livekit_models.pb.dart' as lk_models;
import 'proto/livekit_rtc.pb.dart' as lk_rtc;
import 'track/remote_track_publication.dart';
import 'track/track.dart';
import 'types.dart';

abstract class LiveKitEvent {
  const LiveKitEvent();
}

//
// Room events
//

/// When the connection to the server has been interrupted and it's attempting
/// to reconnect.
class RoomReconnectingEvent extends LiveKitEvent {}

/// Connection to room is re-established. All existing state is preserved.
class RoomReconnectedEvent extends LiveKitEvent {}

/// Disconnected from the room
class RoomDisconnectedEvent extends LiveKitEvent {}

/// When a new [RemoteParticipant] joins *after* the current participant has connected
/// It will not fire for participants that are already in the room
class RoomParticipantConnectedEvent extends LiveKitEvent {
  final RemoteParticipant participant;
  const RoomParticipantConnectedEvent({
    required this.participant,
  });
}

/// When a [RemoteParticipant] leaves the room
class RoomParticipantDisconnectedEvent extends LiveKitEvent {
  final RemoteParticipant participant;
  const RoomParticipantDisconnectedEvent({
    required this.participant,
  });
}

/// When a new track is published to room *after* the current participant has
/// joined. It will not fire for tracks that are already published
// (Relayed from LiveKitEvent)
class RoomTrackPublishedEvent extends LiveKitEvent {}

/// A [RemoteParticipant] has unpublished a track
// (Relayed from LiveKitEvent)
class RoomTrackUnpublishedEvent extends LiveKitEvent {}

/// A subscribed track is no longer available.
// (Relayed from LiveKitEvent)
// class RoomTrackUnsubscribedEvent extends LiveKitEvent {}

/// Encountered failure attempting to subscribe to track.
// (Relayed from LiveKitEvent)
// class RoomTrackSubscriptionFailedEvent extends LiveKitEvent {}

/// A track that was muted, fires on both [RemoteParticipant]s and
/// [LocalParticipant]
// (Relayed from LiveKitEvent)
// class RoomTrackMutedEvent extends LiveKitEvent {}

/// A track that was unmuted, fires on both [RemoteParticipant]s and
/// [LocalParticipant]
// (Relayed from LiveKitEvent)
// class RoomTrackUnmutedEvent extends LiveKitEvent {}

/// Active speakers changed. List of speakers are ordered by their audio level.
/// loudest speakers first. This will include the [LocalParticipant] too.
class ActiveSpeakersChangedEvent extends LiveKitEvent {
  final List<Participant> speakers;
  const ActiveSpeakersChangedEvent({
    required this.speakers,
  });
}

class RoomAudioPlaybackChangedEvent extends LiveKitEvent {}

//
// Participant events
//

/// This participant has published a new [Track] to the [Room].
class TrackPublishedEvent extends LiveKitEvent {
  final RemoteParticipant participant;
  final RemoteTrackPublication publication;
  const TrackPublishedEvent({
    required this.participant,
    required this.publication,
  });
}

/// The [LocalParticipant] has subscribed to a new track published by this
/// [RemoteParticipant]
class TrackSubscribedEvent extends LiveKitEvent {
  final RemoteParticipant participant;
  final Track track;
  final RemoteTrackPublication publication;
  const TrackSubscribedEvent({
    required this.participant,
    required this.track,
    required this.publication,
  });
}

/// An error has occured during track subscription.
class TrackSubscriptionFailedEvent extends LiveKitEvent {
  final RemoteParticipant participant;
  final String? sid;
  final TrackSubscribeFailReason reason;
  const TrackSubscriptionFailedEvent({
    required this.participant,
    this.sid,
    required this.reason,
  });
}

/// This participant has unpublished one of their [Track].
class TrackUnpublishedEvent extends LiveKitEvent {
  final RemoteParticipant participant;

  final RemoteTrackPublication publication;
  const TrackUnpublishedEvent({
    required this.participant,
    required this.publication,
  });
}

/// The [LocalParticipant] has unsubscribed from a track published by this
/// [RemoteParticipant]. This event is fired when the track was unpublished
class TrackUnsubscribedEvent extends LiveKitEvent {
  final RemoteParticipant participant;
  final Track track;
  final RemoteTrackPublication publication;
  const TrackUnsubscribedEvent({
    required this.participant,
    required this.track,
    required this.publication,
  });
}

/// This participant has muted one of their tracks
class TrackMutedEvent extends LiveKitEvent {
  final Participant participant;
  final TrackPublication track;
  const TrackMutedEvent({
    required this.participant,
    required this.track,
  });
}

/// This participant has unmuted one of their tracks
class TrackUnmutedEvent extends LiveKitEvent {
  final Participant participant;
  final TrackPublication track;
  const TrackUnmutedEvent({
    required this.participant,
    required this.track,
  });
}

//
// common events for both Room/Participant.
//

/// Participant metadata is a simple way for app-specific state to be pushed to
/// all users.
/// When RoomService.UpdateParticipantMetadata is called to change a
/// participant's state, *all*  participants in the room will fire this event.

class MetadataChangedEvent extends LiveKitEvent {
  final Participant participant;
  const MetadataChangedEvent({
    required this.participant,
  });
}

/// Data received from  [RemoteParticipant].
/// Data packets provides the ability to use LiveKit to send/receive arbitrary
/// payloads.
class DataReceivedEvent extends LiveKitEvent {
  /// participant may be null if data is sent from Server API
  final RemoteParticipant? participant;
  final List<int> data;
  const DataReceivedEvent({
    required this.participant,
    required this.data,
  });
}

/// The participant's isSpeaking property has changed
class SpeakingChangedEvent extends LiveKitEvent {
  final Participant participant;
  final bool speaking;
  const SpeakingChangedEvent({
    required this.participant,
    required this.speaking,
  });
}

//
// Engine events
//
class EngineConnectedEvent extends LiveKitEvent {}

class EngineDisconnectedEvent extends LiveKitEvent {}

class EngineReconnectingEvent extends LiveKitEvent {}

class EngineReconnectedEvent extends LiveKitEvent {}

class EngineParticipantUpdateEvent extends LiveKitEvent {
  final List<lk_models.ParticipantInfo> participants;
  const EngineParticipantUpdateEvent({
    required this.participants,
  });
}

class EngineTrackAddedEvent extends LiveKitEvent {
  final rtc.MediaStreamTrack track;
  final rtc.MediaStream stream;
  final rtc.RTCRtpReceiver? receiver;
  const EngineTrackAddedEvent({
    required this.track,
    required this.stream,
    required this.receiver,
  });
}

class EngineSpeakersUpdateEvent extends LiveKitEvent {
  final List<lk_models.SpeakerInfo> speakers;
  const EngineSpeakersUpdateEvent({
    required this.speakers,
  });
}

class EngineDataPacketReceivedEvent extends LiveKitEvent {
  final lk_models.UserPacket packet;
  final lk_models.DataPacket_Kind kind;
  const EngineDataPacketReceivedEvent({
    required this.packet,
    required this.kind,
  });
}

class EngineRemoteMuteChangedEvent extends LiveKitEvent {
  final String sid;
  final bool muted;
  const EngineRemoteMuteChangedEvent({
    required this.sid,
    required this.muted,
  });
}

// added
abstract class EngineIceStateUpdatedEvent implements LiveKitEvent {
  final rtc.RTCIceConnectionState iceState;
  final bool isPrimary;
  const EngineIceStateUpdatedEvent({
    required this.iceState,
    required this.isPrimary,
  });
}

class EngineSubscriberIceStateUpdatedEvent extends EngineIceStateUpdatedEvent {
  const EngineSubscriberIceStateUpdatedEvent({
    required rtc.RTCIceConnectionState state,
    required bool isPrimary,
  }) : super(
          iceState: state,
          isPrimary: isPrimary,
        );
}

class EnginePublisherIceStateUpdatedEvent extends EngineIceStateUpdatedEvent {
  const EnginePublisherIceStateUpdatedEvent({
    required rtc.RTCIceConnectionState state,
    required bool isPrimary,
  }) : super(
          iceState: state,
          isPrimary: isPrimary,
        );
}

//
// Track events
//

class TrackMessageEvent extends LiveKitEvent {}

// class TrackMutedEvent extends LiveKitEvent {}

// class TrackUnmutedEvent extends LiveKitEvent {}

class TrackUpdateSettingsEvent extends LiveKitEvent {}

class TrackUpdateSubscriptionEvent extends LiveKitEvent {}

class TrackAudioPlaybackStartedEvent extends LiveKitEvent {}

class TrackAudioPlaybackFailedEvent extends LiveKitEvent {}

//
// Signal events
//
class SignalConnectedEvent extends LiveKitEvent {
  final lk_rtc.JoinResponse response;
  const SignalConnectedEvent({
    required this.response,
  });
}

class SignalCloseEvent extends LiveKitEvent {
  final CloseReason? reason;
  const SignalCloseEvent({
    this.reason,
  });
}

class SignalOfferEvent extends LiveKitEvent {
  final rtc.RTCSessionDescription sd;
  const SignalOfferEvent({
    required this.sd,
  });
}

class SignalAnswerEvent extends LiveKitEvent {
  final rtc.RTCSessionDescription sd;
  const SignalAnswerEvent({
    required this.sd,
  });
}

class SignalTrickleEvent extends LiveKitEvent {
  final rtc.RTCIceCandidate candidate;
  final lk_rtc.SignalTarget target;
  const SignalTrickleEvent({
    required this.candidate,
    required this.target,
  });
}

class SignalParticipantUpdateEvent extends LiveKitEvent {
  final List<lk_models.ParticipantInfo> updates;
  const SignalParticipantUpdateEvent({
    required this.updates,
  });
}

class SignalLocalTrackPublishedEvent extends LiveKitEvent {
  final String cid;
  final lk_models.TrackInfo track;
  const SignalLocalTrackPublishedEvent({
    required this.cid,
    required this.track,
  });
}

class SignalActiveSpeakersChangedEvent extends LiveKitEvent {
  final List<lk_models.SpeakerInfo> speakers;
  const SignalActiveSpeakersChangedEvent({
    required this.speakers,
  });
}

class SignalLeaveEvent extends LiveKitEvent {
  final bool canReconnect;
  const SignalLeaveEvent({
    required this.canReconnect,
  });
}

class SignalMuteTrackEvent extends LiveKitEvent {
  final lk_rtc.MuteTrackRequest req;
  const SignalMuteTrackEvent({
    required this.req,
  });
}
