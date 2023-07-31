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

import 'package:meta/meta.dart';

import '../../livekit_client.dart';
import '../core/signal_client.dart';
import '../extensions.dart';
import '../internal/events.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../support/disposable.dart';

/// Represents a track that's published to the server. This class contains
/// metadata associated with tracks.
///
/// Base for [RemoteTrackPublication] and [LocalTrackPublication],
/// can not be instantiated directly.

abstract class TrackPublication<T extends Track> extends Disposable {
  final String sid;
  final String name;
  final lk_models.TrackType kind;
  final TrackSource source;

  /// The current [Track] for this publication (readonly).
  T? get track => _track;
  T? _track;

  /// The [Participant] this publication belongs to.
  abstract final Participant participant;

  bool get muted => track?.muted ?? false;

  /// If the [Track] is published with simulcast, only for video. (readonly)
  bool get simulcasted => _simulcasted;
  bool _simulcasted;

  /// The MIME type of the [Track] (readonly)
  String get mimeType => _mimeType;
  String _mimeType;

  /// The video dimensions of the [Track], reported by publisher.
  /// Only available for [VideoTrack]s. (readonly)
  VideoDimensions? get dimensions => _dimensions;
  VideoDimensions? _dimensions;

  bool get subscribed => track != null;

  EncryptionType get encryptionType {
    if (latestInfo == null) return EncryptionType.kNone;
    return latestInfo!.encryption.toLkType();
  }

  @internal
  lk_models.TrackInfo? latestInfo;

  TrackPublication({
    required lk_models.TrackInfo info,
  })  : sid = info.sid,
        name = info.name,
        kind = info.type,
        source = info.source.toLKType(),
        _simulcasted = info.simulcast,
        _mimeType = info.mimeType {
    updateFromInfo(info);
  }

  /// True when the track is published with source [TrackSource.screenShareVideo].
  bool get isScreenShare =>
      kind == lk_models.TrackType.VIDEO &&
      source == TrackSource.screenShareVideo;

  void updateFromInfo(lk_models.TrackInfo info) {
    _simulcasted = info.simulcast;
    _mimeType = info.mimeType;
    if (info.type == lk_models.TrackType.VIDEO) {
      _dimensions = VideoDimensions(info.width, info.height);
    }
    latestInfo = info;
  }

  // Equality operators
  // Object is considered equal when sid is equal
  @override
  int get hashCode => sid.hashCode;

  @override
  bool operator ==(Object other) =>
      other is TrackPublication && sid == other.sid;

  // Update track to new value, dispose previous if exists.
  // Returns true if value has changed.
  // Intended for internal use only.
  @internal
  Future<bool> updateTrack(T? newValue) async {
    if (_track == newValue) return false;
    // dispose previous track (if exists)
    await _track?.dispose();
    _track = newValue;

    if (newValue != null) {
      // listen for Track's muted events
      final listener = newValue.createListener()
        ..on<InternalTrackMuteUpdatedEvent>(
            (event) => _onTrackMuteUpdatedEvent(event));
      // dispose listener when the track is disposed
      newValue.onDispose(() => listener.dispose());
    }

    return true;
  }

  void _onTrackMuteUpdatedEvent(InternalTrackMuteUpdatedEvent event) {
    // send signal to server (if mute initiated by local user)
    if (event.shouldSendSignal) {
      logger.fine(
          '${this} Sending mute signal... sid:${sid}, muted:${event.muted}');
      participant.room.engine.signalClient.sendMuteTrack(sid, event.muted);
    }
    // emit events
    final newEvent = event.muted
        ? TrackMutedEvent(participant: participant, publication: this)
        : TrackUnmutedEvent(participant: participant, publication: this);
    [participant.events, participant.room.events].emit(newEvent);
  }

  @override
  String toString() => '${runtimeType}(sid: ${sid}, source: ${source})';
}
