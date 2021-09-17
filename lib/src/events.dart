import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'proto/livekit_models.pb.dart' as lk_models;

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

abstract class TrackEvent implements LiveKitEvent {
  const TrackEvent();
}

//
// Room events
//
class RoomReconnectingEvent extends RoomEvent {}

class RoomReconnectedEvent extends RoomEvent {}

class RoomDisconnectedEvent extends RoomEvent {}

class RoomParticipantConnectedEvent extends RoomEvent {}

class RoomParticipantDisconnectedEvent extends RoomEvent {}

class RoomTrackPublishedEvent extends RoomEvent {}

class RoomTrackSubscribedEvent extends RoomEvent {}

class RoomTrackSubscriptionFailedEvent extends RoomEvent {}

class RoomTrackUnpublishedEvent extends RoomEvent {}

class RoomTrackUnsubscribedEvent extends RoomEvent {}

class RoomTrackMutedEvent extends RoomEvent {}

class RoomTrackUnmutedEvent extends RoomEvent {}

class RoomActiveSpeakerChangedEvent extends RoomEvent {}

class RoomMetadataChangedEvent extends RoomEvent {}

class RoomDataReceivedEvent extends RoomEvent {}

class RoomAudioPlaybackChangedEvent extends RoomEvent {}

//
// Participant events
//
class ParticipantTrackPublishedEvent extends ParticipantEvent {}

class ParticipantTrackSubscribedEvent extends ParticipantEvent {}

class ParticipantTrackSubscriptionFailedEvent extends ParticipantEvent {}

class ParticipantTrackUnpublishedEvent extends ParticipantEvent {}

class ParticipantTrackUnsubscribedEvent extends ParticipantEvent {}

class ParticipantTrackMutedEvent extends ParticipantEvent {}

class ParticipantTrackUnmutedEvent extends ParticipantEvent {}

class ParticipantMetadataChangedEvent extends ParticipantEvent {}

class ParticipantDataReceivedEvent extends ParticipantEvent {}

class ParticipantSpeakingChangedEvent extends ParticipantEvent {}

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

class EngineMediaTrackAddedEvent extends EngineEvent {
  final rtc.MediaStreamTrack track;
  final rtc.MediaStream? stream;
  final rtc.RTCRtpReceiver? receiver;
  const EngineMediaTrackAddedEvent({
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

class TrackMutedEvent extends TrackEvent {}

class TrackUnmutedEvent extends TrackEvent {}

class TrackUpdateSettingsEvent extends TrackEvent {}

class TrackUpdateSubscriptionEvent extends TrackEvent {}

class TrackAudioPlaybackStartedEvent extends TrackEvent {}

class TrackAudioPlaybackFailedEvent extends TrackEvent {}
