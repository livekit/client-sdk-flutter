import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../events.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../track/track.dart';
import '../types.dart';

abstract class InternalEvent implements LiveKitEvent {}

@internal
abstract class EngineIceStateUpdatedEvent with EngineEvent, InternalEvent {
  final rtc.RTCIceConnectionState iceState;
  final bool isPrimary;
  const EngineIceStateUpdatedEvent({
    required this.iceState,
    required this.isPrimary,
  });
}

@internal
class EngineSubscriberIceStateUpdatedEvent extends EngineIceStateUpdatedEvent {
  const EngineSubscriberIceStateUpdatedEvent({
    required rtc.RTCIceConnectionState iceState,
    required bool isPrimary,
  }) : super(
          iceState: iceState,
          isPrimary: isPrimary,
        );

  @override
  String toString() =>
      '${runtimeType}(state: ${iceState}, isPrimary: ${isPrimary})';
}

@internal
class EnginePublisherIceStateUpdatedEvent extends EngineIceStateUpdatedEvent {
  const EnginePublisherIceStateUpdatedEvent({
    required rtc.RTCIceConnectionState state,
    required bool isPrimary,
  }) : super(
          iceState: state,
          isPrimary: isPrimary,
        );
  @override
  String toString() =>
      '${runtimeType}(state: ${iceState}, isPrimary: ${isPrimary})';
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
class SignalConnectedEvent with SignalEvent, InternalEvent {
  final lk_rtc.JoinResponse response;
  const SignalConnectedEvent({
    required this.response,
  });
}

@internal
class SignalCloseEvent with SignalEvent, InternalEvent {
  final CloseReason? reason;
  const SignalCloseEvent({
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
class SignalParticipantUpdateEvent
    with SignalEvent, EngineEvent, InternalEvent {
  final List<lk_models.ParticipantInfo> participants;
  const SignalParticipantUpdateEvent({
    required this.participants,
  });
}

@internal
class SignalConnectionQualityUpdateEvent
    with SignalEvent, EngineEvent, InternalEvent {
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
// Speaker update received through websocket
// relayed by Engine
class SignalSpeakersChangedEvent with SignalEvent, EngineEvent, InternalEvent {
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
  final bool canReconnect;
  const SignalLeaveEvent({
    required this.canReconnect,
  });
}

@internal
class SignalMuteTrackEvent with SignalEvent, InternalEvent {
  final String sid;
  final bool muted;
  const SignalMuteTrackEvent({
    required this.sid,
    required this.muted,
  });
}

@internal
class SignalStreamStateUpdatedEvent
    with SignalEvent, EngineEvent, InternalEvent {
  final List<lk_rtc.StreamStateInfo> updates;
  const SignalStreamStateUpdatedEvent({
    required this.updates,
  });
}

@internal
class SignalSubscribedQualityUpdatedEvent
    with SignalEvent, EngineEvent, InternalEvent {
  final String trackSid;
  final List<lk_rtc.SubscribedQuality> updates;
  const SignalSubscribedQualityUpdatedEvent({
    required this.trackSid,
    required this.updates,
  });
}

// ----------------------------------------------------------------------
// Engine events
// ----------------------------------------------------------------------

@internal
class EngineConnectedEvent with EngineEvent, InternalEvent {
  const EngineConnectedEvent();
}

@internal
class EngineDisconnectedEvent with EngineEvent, InternalEvent {
  const EngineDisconnectedEvent();
}

@internal
class EngineReconnectingEvent with EngineEvent, InternalEvent {
  const EngineReconnectingEvent();
}

@internal
class EngineReconnectedEvent with EngineEvent, InternalEvent {
  const EngineReconnectedEvent();
}

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
  const EngineDataPacketReceivedEvent({
    required this.packet,
    required this.kind,
  });
}

@internal
class EngineRemoteMuteChangedEvent with EngineEvent, InternalEvent {
  final String sid;
  final bool muted;
  const EngineRemoteMuteChangedEvent({
    required this.sid,
    required this.muted,
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
