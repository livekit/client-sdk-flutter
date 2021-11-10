import 'package:collection/collection.dart';
import 'package:livekit_client/src/track/track.dart';
import 'package:meta/meta.dart';

import '../events.dart';
import '../extensions.dart';
import '../logger.dart';
import '../managers/event.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../support/disposable.dart';
import '../track/track_publication.dart';
import '../types.dart';
import 'remote_participant.dart';

/// Represents a Participant in the room, notifies changes via delegates as
/// well as ChangeNotifier/providers.
/// A change notification is triggered when
/// - speaking status changed
/// - mute status changed
/// - added/removed subscribed tracks
/// - metadata changed

/// Base for [RemoteParticipant] and [LocalParticipant],
/// can not be instantiated directly.
abstract class Participant extends DisposableChangeNotifier
    with EventsEmittable<ParticipantEvent> {
  /// map of track sid => published track
  final trackPublications = <String, TrackPublication>{};

  /// audio level between 0-1, 1 being the loudest
  double audioLevel = 0;

  /// server assigned unique id
  final String sid;

  /// user-assigned identity
  String identity;

  /// client-assigned metadata, opaque to livekit
  String? metadata;

  /// when the participant had last spoken
  DateTime? lastSpokeAt;

  lk_models.ParticipantInfo? _participantInfo;
  bool _isSpeaking = false;

  ConnectionQuality _connectionQuality = ConnectionQuality.unknown;

  // suppport for multiple event listeners
  final EventsEmitter<RoomEvent> roomEvents;

  /// when the participant joined the room
  DateTime get joinedAt {
    final pi = _participantInfo;
    if (pi != null) {
      return DateTime.fromMillisecondsSinceEpoch(pi.joinedAt.toInt() * 1000,
          isUtc: true);
    }
    return DateTime.now();
  }

  /// if participant is currently speaking
  bool get isSpeaking => _isSpeaking;

  /// true if participant is publishing an audio track and is muted
  bool get isMuted => audioTracks.firstOrNull?.muted ?? true;

  bool get hasAudio => audioTracks.isNotEmpty;

  bool get hasVideo => videoTracks.isNotEmpty;

  /// Connection quality of the participant
  ConnectionQuality get connectionQuality => _connectionQuality;

  /// tracks that are subscribed to
  List<TrackPublication> get subscribedTracks =>
      trackPublications.values.where((e) => e.subscribed).toList();

  /// for internal use
  /// {@nodoc}
  @internal
  bool get hasInfo => _participantInfo != null;

  Participant(
    this.sid,
    this.identity, {
    required this.roomEvents,
  }) {
    // Any event emitted will trigger ChangeNotifier
    events.listen((event) {
      logger.fine('[ParticipantEvent] $event, will notifyListeners()');
      notifyListeners();
    });

    onDispose(() async {
      await events.dispose();
      await unpublishAllTracks();
    });
  }

  /// for internal use
  /// {@nodoc}
  @internal
  set isSpeaking(bool speaking) {
    if (_isSpeaking == speaking) {
      return;
    }
    _isSpeaking = speaking;
    if (speaking) {
      lastSpokeAt = DateTime.now();
    }

    events.emit(SpeakingChangedEvent(
      participant: this,
      speaking: speaking,
    ));
  }

  void _setMetadata(String md) {
    final changed = _participantInfo?.metadata != md;
    metadata = md;
    if (changed) {
      [events, roomEvents].emit(ParticipantMetadataUpdatedEvent(
        participant: this,
      ));
    }
  }

  @internal
  void updateConnectionQuality(ConnectionQuality quality) {
    if (_connectionQuality == quality) return;
    _connectionQuality = quality;
    [events, roomEvents].emit(ParticipantConnectionQualityUpdatedEvent(
      participant: this,
      connectionQuality: _connectionQuality,
    ));
  }

  /// for internal use
  /// {@nodoc}
  @internal
  void updateFromInfo(lk_models.ParticipantInfo info) {
    identity = info.identity;
    // participantSid = info.sid;
    if (info.metadata.isNotEmpty) {
      _setMetadata(info.metadata);
    }
    _participantInfo = info;
  }

  /// for internal use
  /// {@nodoc}
  @internal
  void addTrackPublication(TrackPublication pub) {
    pub.track?.sid = pub.sid;
    trackPublications[pub.sid] = pub;
  }

  // Must implement
  Future<void> unpublishTrack(String trackSid, {bool notify = true});

  Future<void> unpublishAllTracks({bool notify = true}) async {
    final trackSids = trackPublications.keys.toSet();
    for (final trackid in trackSids) {
      await unpublishTrack(trackid, notify: notify);
    }
  }

  //
  // Equality operators
  // Object is considered equal when sid is equal
  //
  @override
  int get hashCode => sid.hashCode;

  @override
  bool operator ==(Object other) => other is Participant && sid == other.sid;
}

// Convenience extension
extension ParticipantExt on Participant {
  List<TrackPublication> get videoTracks => trackPublications.values
      .where((e) => e.kind == lk_models.TrackType.VIDEO)
      .toList();

  List<TrackPublication> get audioTracks => trackPublications.values
      .where((e) => e.kind == lk_models.TrackType.AUDIO)
      .toList();
}

extension ParticipantTrackSourceExt on Participant {
  bool isCameraEnabled() {
    return !(getTrackPublicationBySource(TrackSource.camera)?.muted ?? true);
  }

  bool isMicrophoneEnabled() {
    return !(getTrackPublicationBySource(TrackSource.microphone)?.muted ??
        true);
  }

  /// Find a track publication by its [TrackSource]
  TrackPublication? getTrackPublicationBySource(TrackSource source) {
    if (source == TrackSource.unknown) return null;
    // try to find by source
    final result =
        trackPublications.values.firstWhereOrNull((e) => e.source == source);
    if (result != null) return result;
    // try to find by compatibility
    return trackPublications.values
        .where((e) => e.source == TrackSource.unknown)
        .firstWhereOrNull((e) =>
            (source == TrackSource.microphone &&
                e.kind == lk_models.TrackType.AUDIO) ||
            (source == TrackSource.camera &&
                e.kind == lk_models.TrackType.VIDEO &&
                e.name != Track.screenShareName) ||
            (source == TrackSource.screenShare &&
                e.kind == lk_models.TrackType.VIDEO &&
                e.name == Track.screenShareName));
  }
}
