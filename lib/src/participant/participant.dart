import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import '../classes/change_notifier.dart';
import '../events.dart';
import '../extensions.dart';
import '../logger.dart';
import '../managers/event.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../track/track_publication.dart';
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
abstract class Participant extends LKChangeNotifier {
  /// map of track sid => published track
  Map<String, TrackPublication> tracks = {};

  /// audio level between 0-1, 1 being the loudest
  double audioLevel = 0;

  /// server assigned unique id
  String sid;

  /// user-assigned identity
  String identity;

  /// client-assigned metadata, opaque to livekit
  String? metadata;

  /// when the participant had last spoken
  DateTime? lastSpokeAt;

  // ParticipantDelegate? roomDelegate;

  /// delegate to receive participant callbacks
  // ParticipantDelegate? delegate;

  lk_models.ParticipantInfo? _participantInfo;
  bool _isSpeaking = false;

  // suppport for multiple event listeners
  final events = EventsEmitter<ParticipantEvent>();
  final EventsEmitter<LiveKitEvent> roomEvents;

  /// when the participant joined the room
  DateTime get joinedAt {
    final pi = _participantInfo;
    if (pi != null) {
      return DateTime.fromMillisecondsSinceEpoch(pi.joinedAt.toInt() * 1000, isUtc: true);
    }
    return DateTime.now();
  }

  /// if participant is currently speaking
  bool get isSpeaking => _isSpeaking;

  /// true if participant is publishing an audio track and is muted
  bool get isMuted {
    if (audioTracks.isEmpty) return false;
    return audioTracks.first.muted;
  }

  bool get hasAudio => audioTracks.isNotEmpty;

  bool get hasVideo => videoTracks.isNotEmpty;

  /// tracks that are subscribed to
  List<TrackPublication> get subscribedTracks => tracks.values.where((e) => e.subscribed).toList();

  /// for internal use
  /// {@nodoc}
  @internal
  bool get hasInfo => _participantInfo != null;

  Participant(
    this.sid,
    this.identity, {
    required this.roomEvents,
  }) {
    // any event emitted will trigger ChangeNotifier
    events.listen((_) {
      logger.fine('will notifyListeners()');
      notifyListeners();
    });
  }

  @override
  @mustCallSuper
  Future<void> dispose() async {
    logger.fine('$objectId dispose()');
    await events.dispose();
    super.dispose();
  }

  /// for internal use
  /// {@nodoc}
  set isSpeaking(bool speaking) {
    if (_isSpeaking == speaking) {
      return;
    }
    _isSpeaking = speaking;
    if (speaking) {
      lastSpokeAt = DateTime.now();
    }

    final event = SpeakingChangedEvent(
      participant: this,
      speaking: speaking,
    );

    events.emit(event);
    roomEvents.emit(event);
  }

  void _setMetadata(String md) {
    final changed = _participantInfo?.metadata != md;
    metadata = md;
    if (changed) {
      final event = MetadataChangedEvent(
        participant: this,
      );

      events.emit(event);
      roomEvents.emit(event);
    }
  }

  /// for internal use
  /// {@nodoc}
  @internal
  void updateFromInfo(lk_models.ParticipantInfo info) {
    identity = info.identity;
    sid = info.sid;
    if (info.metadata.isNotEmpty) {
      _setMetadata(info.metadata);
    }
    _participantInfo = info;
  }

  /// for internal use
  /// {@nodoc}
  void muteChanged() {
    notifyListeners();
  }

  /// for internal use
  /// {@nodoc}
  void addTrackPublication(TrackPublication pub) {
    pub.track?.sid = pub.sid;
    tracks[pub.sid] = pub;
  }

  // Must implement
  Future<void> unpublishTrack(String trackSid, [bool notify = false]);

  Future<void> unpublishAllTracks() async {
    final _ = List<TrackPublication>.from(tracks.values);
    for (final track in _) {
      await unpublishTrack(track.sid);
    }
  }
}

// Convenience extension
extension ParticipantExt on Participant {
  List<TrackPublication> get videoTracks =>
      tracks.values.where((e) => e.kind == lk_models.TrackType.VIDEO).toList();

  List<TrackPublication> get audioTracks =>
      tracks.values.where((e) => e.kind == lk_models.TrackType.AUDIO).toList();
}
