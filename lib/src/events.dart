import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'participant/local_participant.dart';
import 'participant/participant.dart';
import 'participant/remote_participant.dart';
import 'proto/livekit_models.pb.dart' as lk_models;
import 'publication/local_track_publication.dart';
import 'publication/remote_track_publication.dart';
import 'publication/track_publication.dart';
import 'room.dart';
import 'rtc_engine.dart';
import 'signal_client.dart';
import 'track/track.dart';
import 'types.dart';

/// Base type for all LiveKit events.
abstract class LiveKitEvent {}

/// Base type for all [Room] events.
abstract class RoomEvent implements LiveKitEvent {}

/// Base type for all [Participant] events.
abstract class ParticipantEvent implements LiveKitEvent {}

/// Base type for all [Track] events.
abstract class TrackEvent implements LiveKitEvent {}

/// Base type for all [RTCEngine] events.
abstract class EngineEvent implements LiveKitEvent {}

/// Base type for all [SignalClient] events.
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
  final RemoteParticipant participant;
  final RemoteTrackPublication publication;
  const TrackUnpublishedEvent({
    required this.participant,
    required this.publication,
  });
}

/// When the local participant publishes a new [Track] to the room.
/// Emitted by [Room] and [LocalParticipant].
class LocalTrackPublishedEvent with RoomEvent, ParticipantEvent {
  final LocalParticipant participant;
  final LocalTrackPublication publication;
  const LocalTrackPublishedEvent({
    required this.participant,
    required this.publication,
  });
}

/// The local participant has unpublished one of their [Track].
/// Emitted by [Room] and [LocalParticipant].
class LocalTrackUnpublishedEvent with RoomEvent, ParticipantEvent {
  final LocalParticipant participant;
  final LocalTrackPublication publication;
  const LocalTrackUnpublishedEvent({
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

/// The [StreamState] on the [RemoteTrackPublication] has updated by the server.
/// Emitted by [Room] and [RemoteParticipant].
class TrackStreamStateUpdatedEvent with RoomEvent, ParticipantEvent {
  final RemoteParticipant participant;
  final RemoteTrackPublication trackPublication;
  final StreamState streamState;
  const TrackStreamStateUpdatedEvent({
    required this.participant,
    required this.trackPublication,
    required this.streamState,
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

/// [Pariticpant]'s [ConnectionQuality] has updated.
/// Emitted by [Room] and [Participant].
class ParticipantConnectionQualityUpdatedEvent
    with RoomEvent, ParticipantEvent {
  final Participant participant;
  final ConnectionQuality connectionQuality;
  const ParticipantConnectionQualityUpdatedEvent({
    required this.participant,
    required this.connectionQuality,
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
