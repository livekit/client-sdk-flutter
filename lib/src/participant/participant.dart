// Copyright 2023 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../core/room.dart';
import '../e2ee/options.dart';
import '../events.dart';
import '../extensions.dart';
import '../logger.dart';
import '../managers/event.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../publication/track_publication.dart';
import '../support/disposable.dart';
import '../types/other.dart';
import '../types/participant_permissions.dart';

/// Represents a Participant in the room, notifies changes via delegates as
/// well as ChangeNotifier/providers.
/// A change notification is triggered when
/// - speaking status changed
/// - mute status changed
/// - added/removed subscribed tracks
/// - metadata changed

/// Base for [RemoteParticipant] and [LocalParticipant],
/// can not be instantiated directly.
abstract class Participant<T extends TrackPublication>
    extends DisposableChangeNotifier with EventsEmittable<ParticipantEvent> {
  /// Reference to [Room]
  @internal
  final Room room;

  /// Map of track sid => published track
  final Map<String, T> trackPublications = {};

  /// Audio level between 0-1, 1 being the loudest.
  double audioLevel = 0;

  /// Server assigned unique id.
  String sid;

  /// User-assigned identity.
  String identity;

  /// Name of the participant (readonly).
  String get name => _name;
  String _name;

  /// Client-assigned metadata, opaque to livekit.
  String? metadata;

  /// When the participant had last spoken.
  DateTime? lastSpokeAt;

  lk_models.ParticipantInfo? _participantInfo;
  bool _isSpeaking = false;

  /// Connection quality between the [Participant] and the server.
  ConnectionQuality _connectionQuality = ConnectionQuality.unknown;

  ParticipantPermissions _permissions = const ParticipantPermissions();
  ParticipantPermissions get permissions => _permissions;

  /// when the participant joined the room
  DateTime get joinedAt {
    final pi = _participantInfo;
    if (pi != null) {
      return DateTime.fromMillisecondsSinceEpoch(pi.joinedAt.toInt() * 1000,
          isUtc: true);
    }
    return DateTime.now();
  }

  /// if [Participant] is currently speaking.
  bool get isSpeaking => _isSpeaking;

  /// true if [Participant] is publishing an [AudioTrack] and is muted.
  bool get isMuted => audioTracks.firstOrNull?.muted ?? true;

  /// true if this [Participant] has more than 1 [AudioTrack].
  bool get hasAudio => audioTracks.isNotEmpty;

  /// true if this [Participant] has more than 1 [VideoTrack].
  bool get hasVideo => videoTracks.isNotEmpty;

  /// Connection quality between the [Participant] and the Server.
  ConnectionQuality get connectionQuality => _connectionQuality;

  // Must be implemented by child class.
  List<T> get videoTracks;

  // Must be implemented by child class.
  List<T> get audioTracks;

  EncryptionType get firstTrackEncryptionType {
    if (hasAudio) {
      return audioTracks.first.encryptionType;
    } else if (hasVideo) {
      return videoTracks.first.encryptionType;
    } else {
      return EncryptionType.kNone;
    }
  }

  bool get isEncrypted => [...audioTracks, ...videoTracks]
      .every((track) => track.encryptionType != EncryptionType.kNone);

  @internal
  bool get hasInfo => _participantInfo != null;

  @internal
  Participant({
    required this.room,
    required this.sid,
    required this.identity,
    required String name,
  }) : _name = name {
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
      [events, room.events].emit(ParticipantMetadataUpdatedEvent(
        participant: this,
      ));
    }
  }

  @internal
  void updateConnectionQuality(ConnectionQuality quality) {
    if (_connectionQuality == quality) return;
    _connectionQuality = quality;
    [events, room.events].emit(ParticipantConnectionQualityUpdatedEvent(
      participant: this,
      connectionQuality: _connectionQuality,
    ));
  }

  /// for internal use
  /// {@nodoc}
  @internal
  void updateFromInfo(lk_models.ParticipantInfo info) {
    identity = info.identity;
    sid = info.sid;
    updateName(info.name);
    if (info.metadata.isNotEmpty) {
      _setMetadata(info.metadata);
    }
    _participantInfo = info;
    setPermissions(info.permission.toLKType());
  }

  @internal
  // returns oldValue (if updated)
  ParticipantPermissions? setPermissions(ParticipantPermissions newValue) {
    if (_permissions == newValue) return null;
    final oldValue = _permissions;
    _permissions = newValue;
    return oldValue;
  }

  @internal
  void updateName(String name) {
    if (_name == name) return;
    _name = name;
    [events, room.events].emit(ParticipantNameUpdatedEvent(
      participant: this,
      name: name,
    ));
  }

  /// for internal use
  /// {@nodoc}
  @internal
  void addTrackPublication(T pub) {
    pub.track?.sid = pub.sid;
    trackPublications[pub.sid] = pub;
  }

  // Must be implemented by subclasses.
  Future<void> unpublishTrack(String trackSid, {bool notify = true});

  /// Convenience method to unpublish all tracks.
  Future<void> unpublishAllTracks(
      {bool notify = true, bool? stopOnUnpublish}) async {
    final trackSids = trackPublications.keys.toSet();
    for (final trackid in trackSids) {
      await unpublishTrack(trackid, notify: notify);
    }
  }

  /// Convenience property to check whether [TrackSource.camera] is published or not.
  bool isCameraEnabled() {
    return !(getTrackPublicationBySource(TrackSource.camera)?.muted ?? true);
  }

  /// Convenience property to check whether [TrackSource.microphone] is published or not.
  bool isMicrophoneEnabled() {
    return !(getTrackPublicationBySource(TrackSource.microphone)?.muted ??
        true);
  }

  /// Convenience property to check whether [TrackSource.screenShareVideo] is published or not.
  bool isScreenShareEnabled() {
    return !(getTrackPublicationBySource(TrackSource.screenShareVideo)?.muted ??
        true);
  }

  /// Tries to find a [TrackPublication] by its [TrackSource]. Otherwise, will
  /// return a compatible type of [TrackPublication] for the [TrackSource] specified.
  /// returns null when not found.
  T? getTrackPublicationBySource(TrackSource source) {
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
                e.kind == lk_models.TrackType.VIDEO) ||
            (source == TrackSource.screenShareVideo &&
                e.kind == lk_models.TrackType.VIDEO) ||
            (source == TrackSource.screenShareAudio &&
                e.kind == lk_models.TrackType.AUDIO));
  }

  /// (Equality operator) [Participant.hashCode] is same as [sid.hashCode].
  @override
  int get hashCode => sid.hashCode;

  /// (Equality operator) [Participant] is considered equal when [sid]'s are equal.
  @override
  bool operator ==(Object other) => other is Participant && sid == other.sid;

  @override
  String toString() => '${runtimeType}(sid: ${sid}, identity: ${identity})';
}
