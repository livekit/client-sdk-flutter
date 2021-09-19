import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';

import 'participant/participant.dart';
import 'participant/remote_participant.dart';
import 'proto/livekit_models.pb.dart' as lk_models;
import 'proto/livekit_rtc.pb.dart' as lk_rtc;
import 'track/remote_track_publication.dart';
import 'track/track.dart';
import 'types.dart';

abstract class LiveKitEvent {}

abstract class RoomEvent implements LiveKitEvent {
  const RoomEvent();
}

abstract class ParticipantEvent implements LiveKitEvent {
  const ParticipantEvent();
}

abstract class EngineEvent implements LiveKitEvent {
  const EngineEvent();
}

abstract class SignalEvent implements LiveKitEvent {
  const SignalEvent();
}

abstract class TrackEvent implements LiveKitEvent {
  const TrackEvent();
}

//
// Room events
//

/// When the connection to the server has been interrupted and it's attempting
/// to reconnect.
class RoomReconnectingEvent extends RoomEvent {}

/// Connection to room is re-established. All existing state is preserved.
class RoomReconnectedEvent extends RoomEvent {}

/// Disconnected from the room
class RoomDisconnectedEvent extends RoomEvent {}

/// When a new [RemoteParticipant] joins *after* the current participant has connected
/// It will not fire for participants that are already in the room
class RoomParticipantConnectedEvent extends RoomEvent {
  final RemoteParticipant participant;
  const RoomParticipantConnectedEvent({
    required this.participant,
  });
}

/// When a [RemoteParticipant] leaves the room
class RoomParticipantDisconnectedEvent extends RoomEvent {
  final RemoteParticipant participant;
  const RoomParticipantDisconnectedEvent({
    required this.participant,
  });
}

/// When a new track is published to room *after* the current participant has
/// joined. It will not fire for tracks that are already published
// (Relayed from ParticipantEvent)
class RoomTrackPublishedEvent extends RoomEvent {}

/// A [RemoteParticipant] has unpublished a track
// (Relayed from ParticipantEvent)
class RoomTrackUnpublishedEvent extends RoomEvent {}

/// The [LocalParticipant] has subscribed to a new track. This event will **always**
/// fire as long as new tracks are ready for use.
// (Relayed from ParticipantEvent)
// class RoomTrackSubscribedEvent extends RoomEvent {}

/// A subscribed track is no longer available.
// (Relayed from ParticipantEvent)
// class RoomTrackUnsubscribedEvent extends RoomEvent {}

/// Encountered failure attempting to subscribe to track.
// (Relayed from ParticipantEvent)
// class RoomTrackSubscriptionFailedEvent extends RoomEvent {}

/// A track that was muted, fires on both [RemoteParticipant]s and
/// [LocalParticipant]
// (Relayed from ParticipantEvent)
// class RoomTrackMutedEvent extends RoomEvent {}

/// A track that was unmuted, fires on both [RemoteParticipant]s and
/// [LocalParticipant]
// (Relayed from ParticipantEvent)
// class RoomTrackUnmutedEvent extends RoomEvent {}

/// Active speakers changed. List of speakers are ordered by their audio level.
/// loudest speakers first. This will include the [LocalParticipant] too.
class ActiveSpeakersChangedEvent extends RoomEvent {
  final List<Participant> speakers;
  const ActiveSpeakersChangedEvent({
    required this.speakers,
  });
}

/// Participant metadata is a simple way for app-specific state to be pushed to
/// all users.
/// When RoomService.UpdateParticipantMetadata is called to change a
/// participant's state, *all*  participants in the room will fire this event.
// class RoomMetadataChangedEvent extends RoomEvent {}

/// Data received from another [RemoteParticipant].
/// Data packets provides the ability to use LiveKit to send/receive arbitrary
/// payloads.
// class RoomDataReceivedEvent extends RoomEvent {
//   final RemoteParticipant participant;
//   final List<int> data;
//   const RoomDataReceivedEvent({
//     required this.participant,
//     required this.data,
//   });
// }

class RoomAudioPlaybackChangedEvent extends RoomEvent {}

//
// Participant events
//

/// This participant has published a new [Track] to the [Room].
class TrackPublishedEvent extends ParticipantEvent {
  final RemoteParticipant participant;
  final RemoteTrackPublication publication;
  const TrackPublishedEvent({
    required this.participant,
    required this.publication,
  });
}

/// The [LocalParticipant] has subscribed to a new track published by this
/// [RemoteParticipant]
class TrackSubscribedEvent extends ParticipantEvent {
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
class TrackSubscriptionFailedEvent extends ParticipantEvent {
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
class TrackUnpublishedEvent extends ParticipantEvent {
  final RemoteParticipant participant;

  final RemoteTrackPublication publication;
  const TrackUnpublishedEvent({
    required this.participant,
    required this.publication,
  });
}

/// The [LocalParticipant] has unsubscribed from a track published by this
/// [RemoteParticipant]. This event is fired when the track was unpublished
class TrackUnsubscribedEvent extends ParticipantEvent {
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
class TrackMutedEvent extends ParticipantEvent {
  final Participant participant;
  final TrackPublication track;
  const TrackMutedEvent({
    required this.participant,
    required this.track,
  });
}

/// This participant has unmuted one of their tracks
class TrackUnmutedEvent extends ParticipantEvent {
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

/// The participant's metadata has changed
class MetadataChangedEvent extends ParticipantEvent {
  final Participant participant;
  const MetadataChangedEvent({
    required this.participant,
  });
}

/// Data received from this [RemoteParticipant].
class DataReceivedEvent extends ParticipantEvent {
  /// participant may be null if data is sent from Server API
  final RemoteParticipant? participant;
  final List<int> data;
  const DataReceivedEvent({
    required this.participant,
    required this.data,
  });
}

/// The participant's isSpeaking property has changed
class SpeakingChangedEvent extends ParticipantEvent {
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
class EngineConnectedEvent extends EngineEvent {}

class EngineDisconnectedEvent extends EngineEvent {}

class EngineReconnectingEvent extends EngineEvent {}

class EngineReconnectedEvent extends EngineEvent {}

class EngineParticipantUpdateEvent extends EngineEvent {
  final List<lk_models.ParticipantInfo> participants;
  const EngineParticipantUpdateEvent({
    required this.participants,
  });
}

class EngineTrackAddedEvent extends EngineEvent {
  final rtc.MediaStreamTrack track;
  final rtc.MediaStream stream;
  final rtc.RTCRtpReceiver? receiver;
  const EngineTrackAddedEvent({
    required this.track,
    required this.stream,
    required this.receiver,
  });
}

class EngineSpeakersUpdateEvent extends EngineEvent {
  final List<lk_models.SpeakerInfo> speakers;
  const EngineSpeakersUpdateEvent({
    required this.speakers,
  });
}

class EngineDataPacketReceivedEvent extends EngineEvent {
  final lk_models.UserPacket packet;
  final lk_models.DataPacket_Kind kind;
  const EngineDataPacketReceivedEvent({
    required this.packet,
    required this.kind,
  });
}

class EngineRemoteMuteChangedEvent extends EngineEvent {
  final String sid;
  final bool muted;
  const EngineRemoteMuteChangedEvent({
    required this.sid,
    required this.muted,
  });
}

// added
abstract class EngineIceStateUpdatedEvent implements EngineEvent {
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

class TrackMessageEvent extends TrackEvent {}

// class TrackMutedEvent extends TrackEvent {}

// class TrackUnmutedEvent extends TrackEvent {}

class TrackUpdateSettingsEvent extends TrackEvent {}

class TrackUpdateSubscriptionEvent extends TrackEvent {}

class TrackAudioPlaybackStartedEvent extends TrackEvent {}

class TrackAudioPlaybackFailedEvent extends TrackEvent {}

//
// Signal events
//
class SignalConnectedEvent extends SignalEvent {
  final lk_rtc.JoinResponse response;
  const SignalConnectedEvent({
    required this.response,
  });
}

class SignalCloseEvent extends SignalEvent {
  final CloseReason? reason;
  const SignalCloseEvent({
    this.reason,
  });
}

class SignalOfferEvent extends SignalEvent {
  final rtc.RTCSessionDescription sd;
  const SignalOfferEvent({
    required this.sd,
  });
}

class SignalAnswerEvent extends SignalEvent {
  final rtc.RTCSessionDescription sd;
  const SignalAnswerEvent({
    required this.sd,
  });
}

class SignalTrickleEvent extends SignalEvent {
  final rtc.RTCIceCandidate candidate;
  final lk_rtc.SignalTarget target;
  const SignalTrickleEvent({
    required this.candidate,
    required this.target,
  });
}

class SignalParticipantUpdateEvent extends SignalEvent {
  final List<lk_models.ParticipantInfo> updates;
  const SignalParticipantUpdateEvent({
    required this.updates,
  });
}

class SignalLocalTrackPublishedEvent extends SignalEvent {
  final String cid;
  final lk_models.TrackInfo track;
  const SignalLocalTrackPublishedEvent({
    required this.cid,
    required this.track,
  });
}

class SignalActiveSpeakersChangedEvent extends SignalEvent {
  final List<lk_models.SpeakerInfo> speakers;
  const SignalActiveSpeakersChangedEvent({
    required this.speakers,
  });
}

class SignalLeaveEvent extends SignalEvent {
  final bool canReconnect;
  const SignalLeaveEvent({
    required this.canReconnect,
  });
}

class SignalMuteTrackEvent extends SignalEvent {
  final lk_rtc.MuteTrackRequest req;
  const SignalMuteTrackEvent({
    required this.req,
  });
}
