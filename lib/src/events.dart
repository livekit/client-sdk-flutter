//
//
//
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'proto/livekit_models.pb.dart' as lk_models;

abstract class LKEvent {}

abstract class LKRoomEvent implements LKEvent {
  const LKRoomEvent();
}

abstract class LKParticipantEvent implements LKEvent {
  const LKParticipantEvent();
}

abstract class LKEngineEvent implements LKEvent {
  const LKEngineEvent();
}

abstract class LKTrackEvent implements LKEvent {
  const LKTrackEvent();
}

//
// Room events
//
class LKRoomReconnectingEvent extends LKRoomEvent {}

class LKRoomReconnectedEvent extends LKRoomEvent {}

class LKRoomDisconnectedEvent extends LKRoomEvent {}

class LKRoomParticipantConnectedEvent extends LKRoomEvent {}

class LKRoomParticipantDisconnectedEvent extends LKRoomEvent {}

class LKRoomTrackPublishedEvent extends LKRoomEvent {}

class LKRoomTrackSubscribedEvent extends LKRoomEvent {}

class LKRoomTrackSubscriptionFailedEvent extends LKRoomEvent {}

class LKRoomTrackUnpublishedEvent extends LKRoomEvent {}

class LKRoomTrackUnsubscribedEvent extends LKRoomEvent {}

class LKRoomTrackMutedEvent extends LKRoomEvent {}

class LKRoomTrackUnmutedEvent extends LKRoomEvent {}

class LKRoomActiveSpeakerChangedEvent extends LKRoomEvent {}

class LKRoomMetadataChangedEvent extends LKRoomEvent {}

class LKRoomDataReceivedEvent extends LKRoomEvent {}

class LKRoomAudioPlaybackChangedEvent extends LKRoomEvent {}

//
// Participant events
//
class LKParticipantTrackPublishedEvent extends LKParticipantEvent {}

class LKParticipantTrackSubscribedEvent extends LKParticipantEvent {}

class LKParticipantTrackSubscriptionFailedEvent extends LKParticipantEvent {}

class LKParticipantTrackUnpublishedEvent extends LKParticipantEvent {}

class LKParticipantTrackUnsubscribedEvent extends LKParticipantEvent {}

class LKParticipantTrackMutedEvent extends LKParticipantEvent {}

class LKParticipantTrackUnmutedEvent extends LKParticipantEvent {}

class LKParticipantMetadataChangedEvent extends LKParticipantEvent {}

class LKParticipantDataReceivedEvent extends LKParticipantEvent {}

class LKParticipantSpeakingChangedEvent extends LKParticipantEvent {}

//
// Engine events
//
class LKEngineConnectedEvent extends LKEngineEvent {}

class LKEngineDisconnectedEvent extends LKEngineEvent {}

class LKEngineReconnectingEvent extends LKEngineEvent {}

class LKEngineReconnectedEvent extends LKEngineEvent {}

class LKEngineParticipantUpdateEvent extends LKEngineEvent {
  final List<lk_models.ParticipantInfo> participants;
  const LKEngineParticipantUpdateEvent({
    required this.participants,
  });
}

class LKEngineMediaTrackAddedEvent extends LKEngineEvent {
  final rtc.MediaStreamTrack track;
  final rtc.MediaStream? stream;
  final rtc.RTCRtpReceiver? receiver;
  const LKEngineMediaTrackAddedEvent({
    required this.track,
    required this.stream,
    required this.receiver,
  });
}

class LKEngineSpeakersUpdateEvent extends LKEngineEvent {
  final List<lk_models.SpeakerInfo> speakers;
  const LKEngineSpeakersUpdateEvent({
    required this.speakers,
  });
}

class LKEngineDataPacketReceivedEvent extends LKEngineEvent {
  final lk_models.UserPacket packet;
  final lk_models.DataPacket_Kind kind;
  const LKEngineDataPacketReceivedEvent({
    required this.packet,
    required this.kind,
  });
}

class LKEngineRemoteMuteChangedEvent extends LKEngineEvent {
  final String sid;
  final bool muted;
  const LKEngineRemoteMuteChangedEvent({
    required this.sid,
    required this.muted,
  });
}

enum LKTransportType {
  subscriber,
  publisher,
}

// added
class LKEngineIceStateUpdatedEvent extends LKEngineEvent {
  final LKTransportType type;
  final rtc.RTCIceConnectionState state;
  final bool isPrimary;
  const LKEngineIceStateUpdatedEvent({
    required this.type,
    required this.state,
    required this.isPrimary,
  });
}

//
// Track events
//

class LKTrackMessageEvent extends LKTrackEvent {}

class LKTrackMutedEvent extends LKTrackEvent {}

class LKTrackUnmutedEvent extends LKTrackEvent {}

class LKTrackUpdateSettingsEvent extends LKTrackEvent {}

class LKTrackUpdateSubscriptionEvent extends LKTrackEvent {}

class LKTrackAudioPlaybackStartedEvent extends LKTrackEvent {}

class LKTrackAudioPlaybackFailedEvent extends LKTrackEvent {}
