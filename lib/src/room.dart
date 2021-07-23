import 'dart:async';
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

class Room with ParticipantDelegate {
  RoomState state = RoomState.Disconnected;

  /// map of SID to RemoteParticipant
  Map<String, RemoteParticipant> participants = {};

  /// the current participant
  late LocalParticipant localParticipant;

  /// name of the room
  late String name;

  /// sid of the room
  late String sid;

  /// a list of participants that are actively speaking, including local participant.
  List<Participant> activeSpeakers = [];

  /// delegate for room events
  RoomDelegate? delegate;

  RTCEngine _engine;

  Completer<Room>? _connectCompleter;

  Room(SignalClient client, RTCConfiguration? rtcConfig)
      : _engine = new RTCEngine(client, rtcConfig) {
    _engine.onTrack = _onTrackAdded;
    _engine.onICEConnected = _handleICEConnected;
    _engine.onDisconnected = _handleDisconnect;
    _engine.onParticipantUpdateCallback = _handleParticipantUpdate;
    _engine.onActiveSpeakerchangedCallback = _handleSpeakerUpdate;
    _engine.onDataMessageCallback = _handleDataPacket;

    // TODO: handle reconnecting & reconnected events
  }

  Future<Room> connect(String url, String token, JoinOptions? opts) async {
    var completer = new Completer<Room>();
    _connectCompleter = completer;

    var joinResponse = await _engine.join(url, token, opts);
    logger.fine(
        'connected to LiveKit server, version: ${joinResponse.serverVersion}');

    state = RoomState.Connected;
    localParticipant = new LocalParticipant(
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
    Timer(Duration(seconds: 5), () {
      _connectCompleter?.completeError(ConnectError());
      _connectCompleter = null;
    });

    return completer.future;
  }

  disconnect() {
    _engine.client.sendLeave();
    _handleDisconnect();
  }

  RemoteParticipant _getOrCreateRemoteParticipant(
      String sid, ParticipantInfo? info) {
    var participant = participants[sid];
    if (participant != null) {
      return participant;
    }

    if (info == null) {
      participant = RemoteParticipant(_engine.client, sid, '');
    } else {
      participant = RemoteParticipant.fromInfo(_engine.client, info);
    }
    participant.roomDelegate = this;
    participants[sid] = participant;

    return participant;
  }

  _handleICEConnected() {
    _connectCompleter?.complete(this);
    _connectCompleter = null;
  }

  _handleDisconnect() {
    if (state == RoomState.Disconnected) {
      return;
    }

    for (var p in participants.values) {
      for (var pub in p.tracks.values) {
        p.unpublishTrack(pub.sid);
      }
    }
    for (var pub in localParticipant.tracks.values) {
      pub.track?.stop();
    }

    _engine.close();
    participants.clear();
    activeSpeakers.clear();
    state = RoomState.Disconnected;
    delegate?.onDisconnected();
  }

  _handleParticipantUpdate(List<ParticipantInfo> updates) {
    for (var info in updates) {
      if (localParticipant.sid == info.sid) {
        localParticipant.updateFromInfo(info);
        continue;
      }

      if (info.state == ParticipantInfo_State.DISCONNECTED) {
        _handleParticipantDisconnect(info.sid);
        continue;
      }

      var isNew = !participants.containsKey(info.sid);
      var participant = _getOrCreateRemoteParticipant(info.sid, info);

      if (isNew) {
        delegate?.onParticipantConnected(participant);
      } else {
        participant.updateFromInfo(info);
      }
    }
  }

  _handleSpeakerUpdate(List<SpeakerInfo> speakers) {
    var seenSids = Set<String>();
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
    for (var participant in participants.values) {
      if (!seenSids.contains(participant.sid)) {
        participant.audioLevel = 0;
        participant.isSpeaking = false;
      }
    }
    activeSpeakers = newSpeakers;
    delegate?.onActiveSpeakersChanged(newSpeakers);
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
    var trackSid = parsed.item2;
    if (trackSid == null) {
      trackSid = track.id;
    }

    var participant = _getOrCreateRemoteParticipant(parsed.item1, null);
    participant.addSubscribedMediaTrack(track, trackSid);
  }

  _handleParticipantDisconnect(String sid) {
    var participant = participants.remove(sid);
    if (participant == null) {
      return;
    }

    for (var track in participant.tracks.values) {
      participant.unpublishTrack(track.sid, true);
    }
    delegate?.onParticipantDisconnected(participant);
  }

  //----------------- forward participant delegate calls ---------------------//

  void onMetadataChanged(Participant participant) {
    delegate?.onMetadataChanged(participant);
  }

  void onTrackMuted(Participant participant, TrackPublication publication) {
    delegate?.onTrackMuted(participant, publication);
  }

  void onTrackUnmuted(Participant participant, TrackPublication publication) {
    delegate?.onTrackUnmuted(participant, publication);
  }

  void onTrackPublished(
      RemoteParticipant participant, RemoteTrackPublication publication) {
    delegate?.onTrackPublished(participant, publication);
  }

  void onTrackUnpublished(
      RemoteParticipant participant, RemoteTrackPublication publication) {
    delegate?.onTrackUnpublished(participant, publication);
  }

  void onTrackSubscribed(RemoteParticipant participant, Track track,
      RemoteTrackPublication publication) {
    delegate?.onTrackSubscribed(participant, track, publication);
  }

  void onTrackUnsubscribed(RemoteParticipant participant, Track track,
      RemoteTrackPublication publication) {
    delegate?.onTrackUnsubscribed(participant, track, publication);
  }

  // omitted because data dispatching is handled in _handleDataPacket
  void onDataReceived(RemoteParticipant participant, List<int> data) {}

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
