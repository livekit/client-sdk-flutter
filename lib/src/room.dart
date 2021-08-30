import 'dart:async';
import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:tuple/tuple.dart';

import 'errors.dart';
import 'extensions.dart';
import 'logger.dart';
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
  Disconnected,
  Connected,
  Reconnecting,
}

mixin RoomDelegate {
  // room level callbacks
  void onReconnecting() {}
  void onReconnected() {}
  void onDisconnected() {}
  void onParticipantConnected(Participant participant) {}
  void onParticipantDisconnected(Participant participant) {}
  void onActiveSpeakersChanged(List<Participant> participants) {}

  // callbacks about participant events
  void onMetadataChanged(Participant participant) {}
  void onTrackMuted(Participant participant, TrackPublication publication) {}
  void onTrackUnmuted(Participant participant, TrackPublication publication) {}
  void onTrackPublished(
      RemoteParticipant participant, RemoteTrackPublication publication) {}
  void onTrackUnpublished(
      RemoteParticipant participant, RemoteTrackPublication publication) {}
  void onTrackSubscribed(RemoteParticipant participant, Track track,
      RemoteTrackPublication publication) {}
  void onTrackUnsubscribed(RemoteParticipant participant, Track track,
      RemoteTrackPublication publication) {}
  void onDataReceived(RemoteParticipant participant, List<int> data) {}
  void onTrackSubscriptionFailed(
      RemoteParticipant participant, String sid, String? message) {}
}

/// Room is the main entrypoint to working with LiveKit. It provides
/// updates to its state via two ways, by assigning a delegate, or using
/// it as a provider.
/// Room will trigger a change update when
/// * state changes
/// * participant membership changes
/// * active speakers are different
class Room extends ChangeNotifier with ParticipantDelegate {
  RoomState _state = RoomState.Disconnected;

  /// connection state of the room
  RoomState get state => _state;

  final Map<String, RemoteParticipant> _participants = {};

  /// map of SID to RemoteParticipant
  UnmodifiableMapView<String, RemoteParticipant> get participants =>
      UnmodifiableMapView(_participants);

  /// the current participant
  late LocalParticipant localParticipant;

  /// name of the room
  late String name;

  /// sid of the room
  late String sid;

  List<Participant> _activeSpeakers = [];

  /// a list of participants that are actively speaking, including local participant.
  UnmodifiableListView<Participant> get activeSpeakers =>
      UnmodifiableListView<Participant>(_activeSpeakers);

  /// delegate for room events
  RoomDelegate? delegate;

  final RTCEngine _engine;

  Completer<Room>? _connectCompleter;

  Room([RTCConfiguration? rtcConfig])
      : _engine = RTCEngine(SignalClient(), rtcConfig) {
    _engine.onTrack = _onTrackAdded;
    _engine.onICEConnected = _handleICEConnected;
    _engine.onDisconnected = _handleDisconnect;
    _engine.onParticipantUpdateCallback = _handleParticipantUpdate;
    _engine.onActiveSpeakerchangedCallback = _handleSpeakerUpdate;
    _engine.onDataMessageCallback = _handleDataPacket;
    _engine.onReconnected = () {
      _state = RoomState.Connected;
      delegate?.onReconnected();
      notifyListeners();
    };
    _engine.onReconnecting = () {
      _state = RoomState.Reconnecting;
      delegate?.onReconnecting();
      notifyListeners();
    };
  }

  Future<Room> connect(String url, String token, [JoinOptions? opts]) async {
    var completer = Completer<Room>();
    _connectCompleter = completer;

    var joinResponse = await _engine.join(url, token, opts);
    logger.fine(
        'connected to LiveKit server, version: ${joinResponse.serverVersion}');

    localParticipant = LocalParticipant(
      engine: _engine,
      info: joinResponse.participant,
    );
    localParticipant.roomDelegate = this;

    sid = joinResponse.room.sid;
    name = joinResponse.room.name;

    for (var info in joinResponse.otherParticipants) {
      _getOrCreateRemoteParticipant(info.sid, info);
    }

    // room is not ready until ICE is connected. so we would return a completer for now
    // if it times out, we'll fail the completer
    Timer(const Duration(seconds: 5), () {
      if (_state != RoomState.Disconnected) {
        return;
      }
      _state = RoomState.Disconnected;
      _connectCompleter?.completeError(ConnectError());
      _connectCompleter = null;
      notifyListeners();
    });

    return completer.future;
  }

  disconnect() {
    _engine.client.sendLeave();
    _handleDisconnect();
  }

  RemoteParticipant _getOrCreateRemoteParticipant(
      String sid, ParticipantInfo? info) {
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

  _handleICEConnected() {
    _connectCompleter?.complete(this);
    _connectCompleter = null;
    _state = RoomState.Connected;
    notifyListeners();
  }

  _handleDisconnect() {
    if (_state == RoomState.Disconnected) {
      return;
    }

    for (var p in _participants.values) {
      var tracks = List<TrackPublication>.from(p.tracks.values);
      for (var pub in tracks) {
        p.unpublishTrack(pub.sid);
      }
    }
    for (var pub in localParticipant.tracks.values) {
      pub.track?.stop();
    }

    _engine.close();
    _participants.clear();
    _activeSpeakers.clear();
    _state = RoomState.Disconnected;
    notifyListeners();
    delegate?.onDisconnected();
  }

  _handleParticipantUpdate(List<ParticipantInfo> updates) {
    // trigger change notifier only if list of participants membership is changed
    var hasChanged = false;
    for (var info in updates) {
      if (localParticipant.sid == info.sid) {
        localParticipant.updateFromInfo(info);
        continue;
      }

      if (info.state == ParticipantInfo_State.DISCONNECTED) {
        hasChanged = true;
        _handleParticipantDisconnect(info.sid);
        continue;
      }

      var isNew = !_participants.containsKey(info.sid);
      var participant = _getOrCreateRemoteParticipant(info.sid, info);

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

  _handleSpeakerUpdate(List<SpeakerInfo> speakers) {
    var seenSids = <String>{};
    List<Participant> newSpeakers = [];
    for (var info in speakers) {
      seenSids.add(info.sid);

      if (info.sid == localParticipant.sid) {
        localParticipant.audioLevel = info.level;
        localParticipant.isSpeaking = true;
        newSpeakers.add(localParticipant);
        continue;
      }

      var participant = participants[info.sid];
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
    for (var participant in _participants.values) {
      if (!seenSids.contains(participant.sid)) {
        participant.audioLevel = 0;
        participant.isSpeaking = false;
      }
    }

    _activeSpeakers = newSpeakers;
    delegate?.onActiveSpeakersChanged(newSpeakers);
    notifyListeners();
  }

  _handleDataPacket(UserPacket packet, DataPacket_Kind kind) {
    var participant = participants[packet.participantSid];
    if (participant == null) {
      return;
    }

    participant.delegate?.onDataReceived(participant, packet.payload);
    delegate?.onDataReceived(participant, packet.payload);
  }

  _onTrackAdded(
      MediaStreamTrack track, MediaStream? stream, RTCRtpReceiver? receiver) {
    if (stream == null) {
      // we need the stream to get the track's id
      logger.severe('received track without mediastream');
      return;
    }

    var parsed = unpackStreamId(stream.id);
    var trackSid = parsed.item2 ?? track.id;

    var participant = _getOrCreateRemoteParticipant(parsed.item1, null);
    participant.addSubscribedMediaTrack(track, stream, trackSid);
  }

  _handleParticipantDisconnect(String sid) {
    var participant = _participants.remove(sid);
    if (participant == null) {
      return;
    }

    var toRemove = List.from(participant.tracks.values);
    for (var track in toRemove) {
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
  void onTrackPublished(
      RemoteParticipant participant, RemoteTrackPublication publication) {
    delegate?.onTrackPublished(participant, publication);
  }

  @override
  void onTrackUnpublished(
      RemoteParticipant participant, RemoteTrackPublication publication) {
    delegate?.onTrackUnpublished(participant, publication);
  }

  @override
  void onTrackSubscribed(RemoteParticipant participant, Track track,
      RemoteTrackPublication publication) {
    delegate?.onTrackSubscribed(participant, track, publication);
  }

  @override
  void onTrackUnsubscribed(RemoteParticipant participant, Track track,
      RemoteTrackPublication publication) {
    delegate?.onTrackUnsubscribed(participant, track, publication);
  }

  // omitted because data dispatching is handled in _handleDataPacket
  @override
  void onDataReceived(RemoteParticipant participant, List<int> data) {}

  @override
  void onTrackSubscriptionFailed(
      RemoteParticipant participant, String sid, String? message) {
    delegate?.onTrackSubscriptionFailed(participant, sid, message);
  }
}

Tuple2<String, String?> unpackStreamId(String streamId) {
  var parts = streamId.split('|');
  if (parts.length != 2) {
    return Tuple2(parts[0], null);
  }
  return Tuple2(parts[0], parts[1]);
}
