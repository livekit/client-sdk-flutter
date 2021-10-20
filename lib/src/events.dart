import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'participant/participant.dart';
import 'participant/remote_participant.dart';
import 'proto/livekit_models.pb.dart' as lk_models;
import 'proto/livekit_rtc.pb.dart' as lk_rtc;
import 'track/remote_track_publication.dart';
import 'track/track.dart';
import 'track/track_publication.dart';
import 'types.dart';

abstract class LiveKitEvent {}

abstract class RoomEvent implements LiveKitEvent {}

abstract class ParticipantEvent implements LiveKitEvent {}

abstract class TrackEvent implements LiveKitEvent {}

abstract class EngineEvent implements LiveKitEvent {}

abstract class SignalEvent implements LiveKitEvent {}

/// When the connection to the server has been interrupted and it's attempting
/// to reconnect.
/// Emitted by [Room].
class RoomReconnectingEvent with RoomEvent {
  const RoomReconnectingEvent();
}

/// Connection to room is re-established. All existing state is preserved.
/// Emitted by [Room].
class RoomReconnectedEvent with RoomEvent {
  const RoomReconnectedEvent();
}

/// Disconnected from the room
/// Emitted by [Room].
class RoomDisconnectedEvent with RoomEvent {
  const RoomDisconnectedEvent();
}

/// When a new [RemoteParticipant] joins *after* the current participant has connected
/// It will not fire for participants that are already in the room
/// Emitted by [Room].
class ParticipantConnectedEvent with RoomEvent {
  final RemoteParticipant participant;
  const ParticipantConnectedEvent({
    required this.participant,
  });
}

/// When a [RemoteParticipant] leaves the room
/// Emitted by [Room].
class ParticipantDisconnectedEvent with RoomEvent {
  final RemoteParticipant participant;
  const ParticipantDisconnectedEvent({
    required this.participant,
  });
}

/// Active speakers changed. List of speakers are ordered by their audio level.
/// loudest speakers first. This will include the [LocalParticipant] too.
class ActiveSpeakersChangedEvent with RoomEvent {
  final List<Participant> speakers;
  const ActiveSpeakersChangedEvent({
    required this.speakers,
  });
}

/// When a new [Track] is published to [Room] *after* the current participant has
/// joined. It will not fire for tracks that are already published.
/// Emitted by [Room] and [RemoteParticipant].
class TrackPublishedEvent with RoomEvent, ParticipantEvent {
  final RemoteParticipant participant;
  final RemoteTrackPublication publication;
  const TrackPublishedEvent({
    required this.participant,
    required this.publication,
  });
}

/// The participant has unpublished one of their [Track].
/// Emitted by [Room] and [RemoteParticipant].
class TrackUnpublishedEvent with RoomEvent, ParticipantEvent {
  final Participant participant;
  final TrackPublication publication;
  const TrackUnpublishedEvent({
    required this.participant,
    required this.publication,
  });
}

/// [LocalParticipant] has subscribed to a new track published by a
/// [RemoteParticipant].
/// Emitted by [Room] and [RemoteParticipant].
class TrackSubscribedEvent with RoomEvent, ParticipantEvent {
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
/// Emitted by [Room] and [RemoteParticipant].
class TrackSubscriptionExceptionEvent with RoomEvent, ParticipantEvent {
  final RemoteParticipant participant;
  final String? sid;
  final TrackSubscribeFailReason reason;
  const TrackSubscriptionExceptionEvent({
    required this.participant,
    this.sid,
    required this.reason,
  });
}

/// The [LocalParticipant] has unsubscribed from a track published by a
/// [RemoteParticipant]. This event is fired when the track was unpublished.
/// Emitted by [Room] and [RemoteParticipant].
class TrackUnsubscribedEvent with RoomEvent, ParticipantEvent {
  final RemoteParticipant participant;
  final Track track;
  final RemoteTrackPublication publication;
  const TrackUnsubscribedEvent({
    required this.participant,
    required this.track,
    required this.publication,
  });
}

/// A Participant has muted one of the track.
/// Emitted by [RemoteParticipant] and [LocalParticipant].
class TrackMutedEvent with RoomEvent, ParticipantEvent {
  final Participant participant;
  final TrackPublication track;
  const TrackMutedEvent({
    required this.participant,
    required this.track,
  });
}

/// This participant has unmuted one of their tracks
/// Emitted by [RemoteParticipant] and [LocalParticipant].
class TrackUnmutedEvent with RoomEvent, ParticipantEvent {
  final Participant participant;
  final TrackPublication track;
  const TrackUnmutedEvent({
    required this.participant,
    required this.track,
  });
}

/// Participant metadata is a simple way for app-specific state to be pushed to
/// all users. When RoomService.UpdateParticipantMetadata is called to change a
/// [Participant]'s state, *all* [Participant]s in the room will fire this event.
/// Emitted by [Room] and [Participant].
class ParticipantMetadataUpdatedEvent with RoomEvent, ParticipantEvent {
  final Participant participant;
  const ParticipantMetadataUpdatedEvent({
    required this.participant,
  });
}

/// Data received from  [RemoteParticipant].
/// Data packets provides the ability to use LiveKit to send/receive arbitrary
/// payloads.
/// Emitted by [Room] and [RemoteParticipant].
class DataReceivedEvent with RoomEvent, ParticipantEvent {
  /// Sender of the data. This may be null if data is sent from Server API.
  final RemoteParticipant? participant;
  final List<int> data;
  const DataReceivedEvent({
    required this.participant,
    required this.data,
  });
}

/// The participant's isSpeaking property has changed
/// Emitted by [Participant].
class SpeakingChangedEvent with ParticipantEvent {
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
class EngineConnectedEvent with EngineEvent {
  const EngineConnectedEvent();
}

class EngineDisconnectedEvent with EngineEvent {
  const EngineDisconnectedEvent();
}

class EngineReconnectingEvent with EngineEvent {
  const EngineReconnectingEvent();
}

class EngineReconnectedEvent with EngineEvent {
  const EngineReconnectedEvent();
}

class EngineTrackAddedEvent with EngineEvent {
  final rtc.MediaStreamTrack track;
  final rtc.MediaStream stream;
  final rtc.RTCRtpReceiver? receiver;
  const EngineTrackAddedEvent({
    required this.track,
    required this.stream,
    required this.receiver,
  });
}

class EngineDataPacketReceivedEvent with EngineEvent {
  final lk_models.UserPacket packet;
  final lk_models.DataPacket_Kind kind;
  const EngineDataPacketReceivedEvent({
    required this.packet,
    required this.kind,
  });
}

class EngineRemoteMuteChangedEvent with EngineEvent {
  final String sid;
  final bool muted;
  const EngineRemoteMuteChangedEvent({
    required this.sid,
    required this.muted,
  });
}

//
// Signal events
//
class SignalConnectedEvent with SignalEvent {
  final lk_rtc.JoinResponse response;
  const SignalConnectedEvent({
    required this.response,
  });
}

class SignalCloseEvent with SignalEvent {
  final CloseReason? reason;
  const SignalCloseEvent({
    this.reason,
  });
}

class SignalOfferEvent with SignalEvent {
  final rtc.RTCSessionDescription sd;
  const SignalOfferEvent({
    required this.sd,
  });
}

class SignalAnswerEvent with SignalEvent {
  final rtc.RTCSessionDescription sd;
  const SignalAnswerEvent({
    required this.sd,
  });
}

class SignalTrickleEvent with SignalEvent {
  final rtc.RTCIceCandidate candidate;
  final lk_rtc.SignalTarget target;
  const SignalTrickleEvent({
    required this.candidate,
    required this.target,
  });
}

// relayed by Engine
class SignalParticipantUpdateEvent with SignalEvent, EngineEvent {
  final List<lk_models.ParticipantInfo> participants;
  const SignalParticipantUpdateEvent({
    required this.participants,
  });
}

class SignalLocalTrackPublishedEvent with SignalEvent {
  final String cid;
  final lk_models.TrackInfo track;
  const SignalLocalTrackPublishedEvent({
    required this.cid,
    required this.track,
  });
}

// speaker update received through websocket
// relayed by Engine
class SignalSpeakersChangedEvent with SignalEvent, EngineEvent {
  final List<lk_models.SpeakerInfo> speakers;
  const SignalSpeakersChangedEvent({
    required this.speakers,
  });
}

// Event received through data channel
class EngineActiveSpeakersUpdateEvent with EngineEvent {
  final List<lk_models.SpeakerInfo> speakers;
  const EngineActiveSpeakersUpdateEvent({
    required this.speakers,
  });
}

class SignalLeaveEvent with SignalEvent {
  final bool canReconnect;
  const SignalLeaveEvent({
    required this.canReconnect,
  });
}

class SignalMuteTrackEvent with SignalEvent {
  final String sid;
  final bool muted;
  const SignalMuteTrackEvent({
    required this.sid,
    required this.muted,
  });
}
