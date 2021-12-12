// added

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';
import 'package:visibility_detector/visibility_detector.dart';

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
    required rtc.RTCIceConnectionState state,
    required bool isPrimary,
  }) : super(
          iceState: state,
          isPrimary: isPrimary,
        );
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
class TrackVisibilityUpdatedEvent with TrackEvent, InternalEvent {
  final String rendererId;
  final Track track;
  final VisibilityInfo? info; // null means disposed
  const TrackVisibilityUpdatedEvent({
    required this.rendererId,
    required this.track,
    required this.info,
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
class SignalConnectedEvent with SignalEvent {
  final lk_rtc.JoinResponse response;
  const SignalConnectedEvent({
    required this.response,
  });
}

@internal
class SignalCloseEvent with SignalEvent {
  final CloseReason? reason;
  const SignalCloseEvent({
    this.reason,
  });
}

@internal
class SignalOfferEvent with SignalEvent {
  final rtc.RTCSessionDescription sd;
  const SignalOfferEvent({
    required this.sd,
  });
}

@internal
class SignalAnswerEvent with SignalEvent {
  final rtc.RTCSessionDescription sd;
  const SignalAnswerEvent({
    required this.sd,
  });
}

@internal
class SignalTrickleEvent with SignalEvent {
  final rtc.RTCIceCandidate candidate;
  final lk_rtc.SignalTarget target;
  const SignalTrickleEvent({
    required this.candidate,
    required this.target,
  });
}

@internal
// relayed by Engine
class SignalParticipantUpdateEvent with SignalEvent, EngineEvent {
  final List<lk_models.ParticipantInfo> participants;
  const SignalParticipantUpdateEvent({
    required this.participants,
  });
}

@internal
class SignalConnectionQualityUpdateEvent with SignalEvent, EngineEvent {
  final List<lk_rtc.ConnectionQualityInfo> updates;
  const SignalConnectionQualityUpdateEvent({
    required this.updates,
  });
}

@internal
class SignalLocalTrackPublishedEvent with SignalEvent {
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
class SignalSpeakersChangedEvent with SignalEvent, EngineEvent {
  final List<lk_models.SpeakerInfo> speakers;
  const SignalSpeakersChangedEvent({
    required this.speakers,
  });
}

@internal
// Event received through data channel
class EngineActiveSpeakersUpdateEvent with EngineEvent {
  final List<lk_models.SpeakerInfo> speakers;
  const EngineActiveSpeakersUpdateEvent({
    required this.speakers,
  });
}

@internal
class SignalLeaveEvent with SignalEvent {
  final bool canReconnect;
  const SignalLeaveEvent({
    required this.canReconnect,
  });
}

@internal
class SignalMuteTrackEvent with SignalEvent {
  final String sid;
  final bool muted;
  const SignalMuteTrackEvent({
    required this.sid,
    required this.muted,
  });
}

@internal
class SignalStreamStateUpdatedEvent with SignalEvent, EngineEvent {
  final List<lk_rtc.StreamStateInfo> updates;
  const SignalStreamStateUpdatedEvent({
    required this.updates,
  });
}
