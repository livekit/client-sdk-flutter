// added
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:visibility_detector/visibility_detector.dart';
import 'package:meta/meta.dart';

import '../events.dart';
import '../track/track.dart';

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

@internal
class TrackMuteUpdatedEvent with TrackEvent, InternalEvent {
  final Track track;
  final bool muted;
  const TrackMuteUpdatedEvent({
    required this.track,
    required this.muted,
  });
}
