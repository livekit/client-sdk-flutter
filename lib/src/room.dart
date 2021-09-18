import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'errors.dart';
import 'events.dart';
import 'extensions.dart';
import 'logger.dart';
import 'managers/event.dart';
import 'options.dart';
import 'participant/local_participant.dart';
import 'participant/participant.dart';
import 'participant/remote_participant.dart';
import 'proto/livekit_models.pb.dart' as lk_models;
import 'rtc_engine.dart';
import 'signal_client.dart';
import 'track/track.dart';
import 'track/track_publication.dart';
import 'types.dart';

enum RoomState {
  disconnected,
  connected,
  reconnecting,
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
  RoomState _connectionState = RoomState.disconnected;

  /// connection state of the room
  RoomState get state => _connectionState;

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

  final RTCEngine _engine;

  // suppport for multiple event listeners
  final events = EventsEmitter<RoomEvent>();
  late final _engineListener = EventsListener<EngineEvent>(_engine.events);

  /// internal use
  /// {@nodoc}
  Room([RTCConfiguration? rtcConfig]) : _engine = RTCEngine(SignalClient(), rtcConfig) {
    if (kDebugMode) {
      // log all RoomEvents
      events.listen((event) => logger.fine('[RoomEvent] $objectId ${event.runtimeType}'));
    }

    _setUpListeners();
  }

  void _setUpListeners() => _engineListener
    ..on<EngineConnectedEvent>((event) async {
      _connectionState = RoomState.connected;
      notifyListeners();
    })
    ..on<EngineReconnectedEvent>((event) async {
      _connectionState = RoomState.connected;
      events.emit(RoomReconnectedEvent());
      notifyListeners();
    })
    ..on<EngineReconnectingEvent>((event) async {
      _connectionState = RoomState.reconnecting;
      events.emit(RoomReconnectingEvent());
      notifyListeners();
    })
    ..on<EngineDisconnectedEvent>((event) => _onDisconnectedEvent())
    ..on<EngineParticipantUpdateEvent>((event) => _onParticipantUpdateEvent(event.participants))
    ..on<EngineSpeakersUpdateEvent>((event) => _onSpeakerUpdateEvent(event.speakers))
    ..on<EngineDataPacketReceivedEvent>(_onDataMessageEvent)
    ..on<EngineRemoteMuteChangedEvent>((event) async {
      final track = localParticipant.tracks[event.sid];
      track?.muted = event.muted;
    })
    ..on<EngineTrackAddedEvent>((event) async {
      final idParts = event.stream.id.split('|');
      final participantSid = idParts[0];
      final trackSid = idParts.elementAtOrNull(1) ?? event.track.id;

      final participant = _getOrCreateRemoteParticipant(participantSid, null);
      participant.addSubscribedMediaTrack(event.track, event.stream, trackSid);
    });

  @override
  Future<void> dispose() async {
    await events.dispose();
    await _engineListener.dispose();
    super.dispose();
  }

  Future<Room> connect(
    String url,
    String token, {
    ConnectOptions? options,
  }) async {
    final joinResponse = await _engine.join(
      url,
      token,
      options: options,
    );

    logger.fine('connected to LiveKit server, version: ${joinResponse.serverVersion}');

    localParticipant = LocalParticipant(
      engine: _engine,
      info: joinResponse.participant,
      defaultPublishOptions: options?.defaultPublishOptions,
    );
    localParticipant.roomDelegate = this;

    sid = joinResponse.room.sid;
    name = joinResponse.room.name;

    for (final info in joinResponse.otherParticipants) {
      _getOrCreateRemoteParticipant(info.sid, info);
    }

    // room is not ready until ICE is connected.
    try {
      await _engineListener.waitFor<EngineIceStateUpdatedEvent>(
        filter: (event) => event.iceState.isConnected(),
        duration: const Duration(seconds: 5),
        onTimeout: () => throw ConnectException(),
      );

      // catch any exception
    } catch (_) {
      _connectionState = RoomState.disconnected;
      notifyListeners();

      // pass on the exception
      rethrow;
    }

    return this;
  }

  /// Disconnects from the room, notifying server of disconnection.
  Future<void> disconnect() async {
    _engine.client.sendLeave();
    await _onDisconnectedEvent();
  }

  Future<void> reconnect() async {
    await _engine.reconnect();
  }

  RemoteParticipant _getOrCreateRemoteParticipant(String sid, lk_models.ParticipantInfo? info) {
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

  Future<void> _onDisconnectedEvent() async {
    if (_connectionState == RoomState.disconnected) {
      logger.fine('$objectId: _handleDisconnect() already disconnected');
      return;
    }
    // we need to flag room as disconnected immediately to avoid
    // this method firing multiple times since the following code
    // is being awaited
    _connectionState = RoomState.disconnected;

    for (final p in _participants.values) {
      final tracks = List<TrackPublication>.from(p.tracks.values);
      for (final pub in tracks) {
        await p.unpublishTrack(pub.sid);
      }
    }
    for (final pub in localParticipant.tracks.values) {
      await pub.track?.stop();
    }

    await _engine.close();
    _participants.clear();
    _activeSpeakers.clear();

    notifyListeners();
    events.emit(RoomDisconnectedEvent());
  }

  void _onParticipantUpdateEvent(List<lk_models.ParticipantInfo> updates) {
    // trigger change notifier only if list of participants membership is changed
    var hasChanged = false;
    for (final info in updates) {
      if (localParticipant.sid == info.sid) {
        localParticipant.updateFromInfo(info);
        continue;
      }

      if (info.state == lk_models.ParticipantInfo_State.DISCONNECTED) {
        hasChanged = true;
        _handleParticipantDisconnect(info.sid);
        continue;
      }

      final isNew = !_participants.containsKey(info.sid);
      final participant = _getOrCreateRemoteParticipant(info.sid, info);

      if (isNew) {
        hasChanged = true;
        events.emit(RoomParticipantConnectedEvent(participant: participant));
      } else {
        participant.updateFromInfo(info);
      }
    }

    if (hasChanged) {
      notifyListeners();
    }
  }

  void _onSpeakerUpdateEvent(List<lk_models.SpeakerInfo> speakers) {
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

    events.emit(RoomActiveSpeakerChangedEvent(speakers: newSpeakers));

    _activeSpeakers = newSpeakers;
    notifyListeners();
  }

  void _onDataMessageEvent(EngineDataPacketReceivedEvent event) {
    final participant = participants[event.packet.participantSid];
    if (participant == null) {
      return;
    }

    participant.delegate?.onDataReceived(participant, event.packet.payload);
    events.emit(RoomDataReceivedEvent(
      participant: participant,
      data: event.packet.payload,
    ));
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

    events.emit(RoomParticipantDisconnectedEvent(participant: participant));
  }

  // //----------------- forward participant delegate calls ---------------------//

  // @override
  // void onMetadataChanged(Participant participant) {
  //   delegate?.onMetadataChanged(participant);
  // }

  // @override
  // void onTrackMuted(Participant participant, TrackPublication publication) {
  //   delegate?.onTrackMuted(participant, publication);
  // }

  // @override
  // void onTrackUnmuted(Participant participant, TrackPublication publication) {
  //   delegate?.onTrackUnmuted(participant, publication);
  // }

  // @override
  // void onTrackPublished(RemoteParticipant participant, RemoteTrackPublication publication) {
  //   delegate?.onTrackPublished(participant, publication);
  // }

  // @override
  // void onTrackUnpublished(RemoteParticipant participant, RemoteTrackPublication publication) {
  //   delegate?.onTrackUnpublished(participant, publication);
  // }

  // @override
  // void onTrackSubscribed(
  //     RemoteParticipant participant, Track track, RemoteTrackPublication publication) {
  //   delegate?.onTrackSubscribed(participant, track, publication);
  // }

  // @override
  // void onTrackUnsubscribed(
  //     RemoteParticipant participant, Track track, RemoteTrackPublication publication) {
  //   delegate?.onTrackUnsubscribed(participant, track, publication);
  // }

  // // omitted because data dispatching is handled in _handleDataPacket
  // @override
  // void onDataReceived(RemoteParticipant participant, List<int> data) {}

  // @override
  // void onTrackSubscriptionFailed(RemoteParticipant participant, String sid, String? message) {
  //   delegate?.onTrackSubscriptionFailed(participant, sid, message);
  // }
}
