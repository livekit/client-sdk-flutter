import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'extensions.dart';
import 'logger.dart';
import 'participant/local_participant.dart';
import 'participant/participant.dart';
import 'participant/remote_participant.dart';
import 'proto/livekit_models.pb.dart';
import 'proto/livekit_rtc.pb.dart';
import 'rtc_engine.dart';
import 'signal_client.dart';

enum RoomState {
  Disconnected,
  Connected,
  Reconnecting,
}

class Room {
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

  RTCEngine _engine;

  Completer<Room>? _connectCompleter;

  Room(SignalClient client, RTCConfiguration? rtcConfig)
      : _engine = new RTCEngine(client, rtcConfig) {
    _engine.onTrack = _onTrackAdded;
    _engine.onDisconnected = _handleDisconnect;
    _engine.onParticipantUpdateCallback = _handleParticipantUpdate;
    _engine.onActiveSpeakerchangedCallback = _handleSpeakerUpdate;
    _engine.onDataMessageCallback = _handleDataPacket;

    // TODO: handle reconnecting & reconnected events
  }

  Future<Room> _connect(String url, String token, JoinOptions? opts) async {
    var completer = new Completer<Room>();
    _connectCompleter = completer;

    var joinResponse = await _engine.join(url, token, opts);
    logger.fine(
        'connected to LiveKit server, version: ${joinResponse.serverVersion}');

    state = RoomState.Connected;
    var pi = joinResponse.participant;
    localParticipant = new LocalParticipant(pi.sid, pi.identity, _engine);

    return completer.future;
  }

  _handleDisconnect() {}

  _handleParticipantUpdate(List<ParticipantInfo> participants) {}

  _handleSpeakerUpdate(List<SpeakerInfo> speakers) {}

  _handleDataPacket(UserPacket packet, DataPacket_Kind kind) {}

  _onTrackAdded(
      MediaStreamTrack track, MediaStream? stream, RTCRtpReceiver? receiver) {}
}
