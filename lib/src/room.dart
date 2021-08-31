import 'dart:async';
import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:tuple/tuple.dart';

import 'errors.dart';
import 'extensions.dart';
import 'logger.dart';
import 'options.dart';
import 'participant/local_participant.dart';
import 'participant/participant.dart';
import 'participant/remote_participant.dart';
import 'proto/livekit_models.pb.dart';
import 'proto/livekit_rtc.pb.dart';
import 'rtc_engine.dart';
import 'signal_client.dart';
import 'track/remote_track_publication.dart';
import 'track/track.dart';
import 'track/track_publication.dart';

enum RoomState {
  disconnected,
  connected,
  reconnecting,
}

/// Delegate for [Room] callbacks
mixin RoomDelegate {
  // room level callbacks
  /// When the connection to the server has been interrupted and it's attempting
  /// to reconnect.
  void onReconnecting() {}

  /// Connection to room is re-established. All existing state is preserved.
  void onReconnected() {}

  /// Disconnected from the room
  void onDisconnected() {}

  /// When a new [RemoteParticipant] joins *after* the current participant has connected
  /// It will not fire for participants that are already in the room
  void onParticipantConnected(Participant participant) {}

  /// When a [RemoteParticipant] leaves the room
  void onParticipantDisconnected(Participant participant) {}

  /// Active speakers changed. List of speakers are ordered by their audio level.
  /// loudest speakers first. This will include the [LocalParticipant] too.
  void onActiveSpeakersChanged(List<Participant> participants) {}

  // callbacks about participant events

  /// Participant metadata is a simple way for app-specific state to be pushed to
  /// all users.
  /// When RoomService.UpdateParticipantMetadata is called to change a
  /// participant's state, *all*  participants in the room will fire this event.
  void onMetadataChanged(Participant participant) {}

  /// A track that was muted, fires on both [RemoteParticipant]s and
  /// [LocalParticipant]
  void onTrackMuted(Participant participant, TrackPublication publication) {}

  /// A track that was unmuted, fires on both [RemoteParticipant]s and
  /// [LocalParticipant]
  void onTrackUnmuted(Participant participant, TrackPublication publication) {}

  /// When a new track is published to room *after* the current participant has
  /// joined. It will not fire for tracks that are already published
  void onTrackPublished(RemoteParticipant participant, RemoteTrackPublication publication) {}

  /// A [RemoteParticipant] has unpublished a track
  void onTrackUnpublished(RemoteParticipant participant, RemoteTrackPublication publication) {}

  /// The [LocalParticipant] has subscribed to a new track. This event will **always**
  /// fire as long as new tracks are ready for use.
  void onTrackSubscribed(RemoteParticipant participant, Track track, RemoteTrackPublication publication) {}

  /// A subscribed track is no longer available.
  void onTrackUnsubscribed(RemoteParticipant participant, Track track, RemoteTrackPublication publication) {}

  /// Data received from another [RemoteParticipant].
  /// Data packets provides the ability to use LiveKit to send/receive arbitrary
  /// payloads.
  void onDataReceived(RemoteParticipant participant, List<int> data) {}

  /// Encountered failure attempting to subscribe to track.
  void onTrackSubscriptionFailed(RemoteParticipant participant, String sid, String? message) {}
}

/// Room is the primary construct for LiveKit conferences. It contains a
/// group of [Participant]s, each publishing and subscribing to [Track]s.
/// Notifies changes to its state via two ways, by assigning a delegate, or using
/// it as a provider.
/// Room will trigger a change notification update when
/// * state changes
/// * participant membership changes
/// * active speakers are different
/// {@category Room}
class Room extends ChangeNotifier with ParticipantDelegate {
  RoomState _state = RoomState.disconnected;

  /// connection state of the room
  RoomState get state => _state;

  final Map<String, RemoteParticipant> _participants = {};

  /// map of SID to RemoteParticipant
  UnmodifiableMapView<String, RemoteParticipant> get participants => UnmodifiableMapView(_participants);

  /// the current participant
  late LocalParticipant localParticipant;

  /// name of the room
  late String name;

  /// sid of the room
  late String sid;

  List<Participant> _activeSpeakers = [];

  /// a list of participants that are actively speaking, including local participant.
  UnmodifiableListView<Participant> get activeSpeakers => UnmodifiableListView<Participant>(_activeSpeakers);

  /// delegate for room events
  RoomDelegate? delegate;

  final RTCEngine _engine;

  Completer<Room>? _connectCompleter;

  /// internal use
  /// {@nodoc}
  Room([RTCConfiguration? rtcConfig]) : _engine = RTCEngine(SignalClient(), rtcConfig) {
    _engine.onTrack = _onTrackAdded;
    _engine.onICEConnected = _handleICEConnected;
    _engine.onDisconnected = _handleDisconnect;
    _engine.onParticipantUpdateCallback = _handleParticipantUpdate;
    _engine.onActiveSpeakerchangedCallback = _handleSpeakerUpdate;
    _engine.onDataMessageCallback = _handleDataPacket;
    _engine.onReconnected = () {
      _state = RoomState.connected;
      delegate?.onReconnected();
      notifyListeners();
    };
    _engine.onReconnecting = () {
      _state = RoomState.reconnecting;
      delegate?.onReconnecting();
      notifyListeners();
    };
  }

  Future<Room> connect(String url, String token, [ConnectOptions? opts]) async {
    final completer = Completer<Room>();
    _connectCompleter = completer;

    final joinResponse = await _engine.join(url, token, opts);
    logger.fine('connected to LiveKit server, version: ${joinResponse.serverVersion}');

    localParticipant = LocalParticipant(
      engine: _engine,
      info: joinResponse.participant,
    );
    localParticipant.roomDelegate = this;

    sid = joinResponse.room.sid;
    name = joinResponse.room.name;

    for (final info in joinResponse.otherParticipants) {
      _getOrCreateRemoteParticipant(info.sid, info);
    }

    // room is not ready until ICE is connected. so we would return a completer for now
    // if it times out, we'll fail the completer
    Timer(const Duration(seconds: 5), () {
      if (_state != RoomState.disconnected) {
        return;
      }
      _state = RoomState.disconnected;
      _connectCompleter?.completeError(ConnectError());
      _connectCompleter = null;
      notifyListeners();
    });

    return completer.future;
  }

  /// Disconnects from the room, notifying server of disconnection.
  void disconnect() {
    _engine.client.sendLeave();
    _handleDisconnect();
  }

  RemoteParticipant _getOrCreateRemoteParticipant(String sid, ParticipantInfo? info) {
    var participant = _participants[sid];
    if (participant != null) {
      return participant;
    }

    if (info == null) {
      participant = RemoteParticipant(_engine.client, sid, '');
    } else {
      participant = RemoteParticipant.fromInfo(_engine.client, info);
    }
    participant.roomDelegate = this;
    _participants[sid] = participant;

    return participant;
  }

  void _handleICEConnected() {
    _connectCompleter?.complete(this);
    _connectCompleter = null;
    _state = RoomState.connected;
    notifyListeners();
  }

  void _handleDisconnect() {
    if (_state == RoomState.disconnected) {
      return;
    }

    for (final p in _participants.values) {
      final tracks = List<TrackPublication>.from(p.tracks.values);
      for (final pub in tracks) {
        p.unpublishTrack(pub.sid);
      }
    }
    for (final pub in localParticipant.tracks.values) {
      pub.track?.stop();
    }

    _engine.close();
    _participants.clear();
    _activeSpeakers.clear();
    _state = RoomState.disconnected;
    notifyListeners();
    delegate?.onDisconnected();
  }

  void _handleParticipantUpdate(List<ParticipantInfo> updates) {
    // trigger change notifier only if list of participants membership is changed
    var hasChanged = false;
    for (final info in updates) {
      if (localParticipant.sid == info.sid) {
        localParticipant.updateFromInfo(info);
        continue;
      }

      if (info.state == ParticipantInfo_State.DISCONNECTED) {
        hasChanged = true;
        _handleParticipantDisconnect(info.sid);
        continue;
      }

      final isNew = !_participants.containsKey(info.sid);
      final participant = _getOrCreateRemoteParticipant(info.sid, info);

      if (isNew) {
        hasChanged = true;
        delegate?.onParticipantConnected(participant);
      } else {
        participant.updateFromInfo(info);
      }
    }

    if (hasChanged) {
      notifyListeners();
    }
  }

  void _handleSpeakerUpdate(List<SpeakerInfo> speakers) {
    final seenSids = <String>{};
    List<Participant> newSpeakers = [];
    for (final info in speakers) {
      seenSids.add(info.sid);

      if (info.sid == localParticipant.sid) {
        localParticipant.audioLevel = info.level;
        localParticipant.isSpeaking = true;
        newSpeakers.add(localParticipant);
        continue;
      }

      final participant = participants[info.sid];
      if (participant != null) {
        participant.audioLevel = info.level;
        participant.isSpeaking = true;
        newSpeakers.add(participant);
      }
    }

    // clear previous speakers
    if (seenSids.contains(localParticipant.sid)) {
      localParticipant.audioLevel = 0;
      localParticipant.isSpeaking = false;
    }
    for (final participant in _participants.values) {
      if (!seenSids.contains(participant.sid)) {
        participant.audioLevel = 0;
        participant.isSpeaking = false;
      }
    }

    _activeSpeakers = newSpeakers;
    delegate?.onActiveSpeakersChanged(newSpeakers);
    notifyListeners();
  }

  void _handleDataPacket(UserPacket packet, DataPacket_Kind kind) {
    final participant = participants[packet.participantSid];
    if (participant == null) {
      return;
    }

    participant.delegate?.onDataReceived(participant, packet.payload);
    delegate?.onDataReceived(participant, packet.payload);
  }

  void _onTrackAdded(MediaStreamTrack track, MediaStream? stream, RTCRtpReceiver? receiver) {
    if (stream == null) {
      // we need the stream to get the track's id
      logger.severe('received track without mediastream');
      return;
    }

    var parsed = _unpackStreamId(stream.id);
    var trackSid = parsed.item2 ?? track.id;

    final participant = _getOrCreateRemoteParticipant(parsed.item1, null);
    participant.addSubscribedMediaTrack(track, stream, trackSid);
  }

  void _handleParticipantDisconnect(String sid) {
    final participant = _participants.remove(sid);
    if (participant == null) {
      return;
    }

    final toRemove = List<TrackPublication>.from(participant.tracks.values);
    for (final track in toRemove) {
      participant.unpublishTrack(track.sid, true);
    }
    delegate?.onParticipantDisconnected(participant);
  }

  //----------------- forward participant delegate calls ---------------------//

  @override
  void onMetadataChanged(Participant participant) {
    delegate?.onMetadataChanged(participant);
  }

  @override
  void onTrackMuted(Participant participant, TrackPublication publication) {
    delegate?.onTrackMuted(participant, publication);
  }

  @override
  void onTrackUnmuted(Participant participant, TrackPublication publication) {
    delegate?.onTrackUnmuted(participant, publication);
  }

  @override
  void onTrackPublished(RemoteParticipant participant, RemoteTrackPublication publication) {
    delegate?.onTrackPublished(participant, publication);
  }

  @override
  void onTrackUnpublished(RemoteParticipant participant, RemoteTrackPublication publication) {
    delegate?.onTrackUnpublished(participant, publication);
  }

  @override
  void onTrackSubscribed(RemoteParticipant participant, Track track, RemoteTrackPublication publication) {
    delegate?.onTrackSubscribed(participant, track, publication);
  }

  @override
  void onTrackUnsubscribed(RemoteParticipant participant, Track track, RemoteTrackPublication publication) {
    delegate?.onTrackUnsubscribed(participant, track, publication);
  }

  // omitted because data dispatching is handled in _handleDataPacket
  @override
  void onDataReceived(RemoteParticipant participant, List<int> data) {}

  @override
  void onTrackSubscriptionFailed(RemoteParticipant participant, String sid, String? message) {
    delegate?.onTrackSubscriptionFailed(participant, sid, message);
  }
}

Tuple2<String, String?> _unpackStreamId(String streamId) {
  var parts = streamId.split('|');
  if (parts.length != 2) {
    return Tuple2(parts[0], null);
  }
  return Tuple2(parts[0], parts[1]);
}
