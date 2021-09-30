import 'dart:collection';

import 'package:collection/collection.dart';

import 'constants.dart';
import 'events.dart';
import 'exceptions.dart';
import 'extensions.dart';
import 'logger.dart';
import 'managers/event.dart';
import 'options.dart';
import 'participant/local_participant.dart';
import 'participant/participant.dart';
import 'participant/remote_participant.dart';
import 'proto/livekit_models.pb.dart' as lk_models;
import 'proto/livekit_rtc.pb.dart' as lk_rtc;
import 'rtc_engine.dart';
import 'support/disposable.dart';
import 'track/track.dart';
import 'types.dart';

/// Room is the primary construct for LiveKit conferences. It contains a
/// group of [Participant]s, each publishing and subscribing to [Track]s.
/// Notifies changes to its state via two ways, by assigning a delegate, or using
/// it as a provider.
/// Room will trigger a change notification update when
/// * state changes
/// * participant membership changes
/// * active speakers are different
/// {@category Room}
class Room extends DisposableChangeNotifier with EventsEmittable<RoomEvent> {
  // Room is only instantiated if connected, so defaults to connected.
  ConnectionState _connectionState = ConnectionState.connected;

  /// connection state of the room
  ConnectionState get connectionState => _connectionState;

  final _participants = <String, RemoteParticipant>{};

  /// map of SID to RemoteParticipant
  UnmodifiableMapView<String, RemoteParticipant> get participants =>
      UnmodifiableMapView(_participants);

  /// the current participant
  late final LocalParticipant localParticipant;

  /// name of the room
  final String name;

  /// sid of the room
  final String sid;

  List<Participant> _activeSpeakers = [];

  /// a list of participants that are actively speaking, including local participant.
  UnmodifiableListView<Participant> get activeSpeakers =>
      UnmodifiableListView<Participant>(_activeSpeakers);

  final RTCEngine engine;

  // suppport for multiple event listeners
  late final _engineListener = engine.createListener();

  /// internal use
  /// {@nodoc}
  Room._({
    required this.engine,
    required lk_rtc.JoinResponse joinResponse,
    ConnectOptions? connectOptions,
  })  : sid = joinResponse.room.sid,
        name = joinResponse.room.name {
    //
    _setUpListeners();

    localParticipant = LocalParticipant(
      engine: engine,
      info: joinResponse.participant,
      defaultPublishOptions: connectOptions?.defaultPublishOptions,
      roomEvents: events,
    );

    for (final info in joinResponse.otherParticipants) {
      _getOrCreateRemoteParticipant(info.sid, info);
    }

    // Any event emitted will trigger ChangeNotifier
    events.listen((event) {
      logger.fine('[RoomEvent] $event, will notifyListeners()');
      notifyListeners();
    });

    onDispose(() async {
      // dispose events
      await events.dispose();
      // dispose local participant
      await localParticipant.dispose();
      // dispose all listeners for RTCEngine
      await _engineListener.dispose();
      // dispose the engine
      await engine.dispose();
    });
  }

  static Future<Room> connect(
    String url,
    String token, {
    ConnectOptions? options,
    RTCConfiguration? rtcConfig,
  }) async {
    //
    final engine = RTCEngine(
      rtcConfig,
    );

    Room? room;

    try {
      final joinResponse = await engine.join(
        url,
        token,
        options: options,
      );

      logger.fine('Connected to LiveKit server, version: ${joinResponse.serverVersion}');

      // create Room first to listen to events
      room = Room._(
        engine: engine,
        joinResponse: joinResponse,
      );

      logger.fine('Waiting to engine connect...');

      // wait until engine is connected
      await room._engineListener.waitFor<EngineConnectedEvent>(
        duration: Timeouts.connection,
        onTimeout: () => throw ConnectException(),
      );

      return room;
      // catch any exception
    } catch (_) {
      // dispose engine if there was any exception while connecting
      if (room != null) {
        // room.dispose will also dispose engine
        await room.dispose();
      } else {
        await engine.dispose();
      }
      rethrow;
    }
  }

  void _setUpListeners() => _engineListener
    ..on<EngineConnectedEvent>((event) async {
      _connectionState = ConnectionState.connected;
      notifyListeners();
    })
    ..on<EngineReconnectedEvent>((event) async {
      _connectionState = ConnectionState.connected;
      events.emit(const RoomReconnectedEvent());
    })
    ..on<EngineReconnectingEvent>((event) async {
      _connectionState = ConnectionState.reconnecting;
      events.emit(const RoomReconnectingEvent());
    })
    ..on<EngineDisconnectedEvent>((event) => _handleClose())
    ..on<SignalParticipantUpdateEvent>((event) => _onParticipantUpdateEvent(event.participants))
    ..on<EngineActiveSpeakersUpdateEvent>(
        (event) => _onEngineActiveSpeakersUpdateEvent(event.speakers))
    ..on<SignalSpeakersChangedEvent>((event) => _onSignalSpeakersChangedEvent(event.speakers))
    ..on<EngineDataPacketReceivedEvent>(_onDataMessageEvent)
    ..on<EngineRemoteMuteChangedEvent>((event) async {
      final track = localParticipant.trackPublications[event.sid];
      track?.muted = event.muted;
    })
    ..on<EngineTrackAddedEvent>((event) async {
      final idParts = event.stream.id.split('|');
      final participantSid = idParts[0];
      final trackSid = idParts.elementAtOrNull(1) ?? event.track.id;
      final participant = _getOrCreateRemoteParticipant(participantSid, null);
      try {
        if (trackSid == null || trackSid.isEmpty) {
          throw TrackSubscriptionExceptionEvent(
            participant: participant,
            reason: TrackSubscribeFailReason.invalidServerResponse,
          );
        }
        await participant.addSubscribedMediaTrack(
          event.track,
          event.stream,
          trackSid,
        );
      } on TrackSubscriptionExceptionEvent catch (event) {
        logger.warning('addSubscribedMediaTrack() throwed ${event}');
        [participant.roomEvents, participant.events].emit(event);
      } catch (exception) {
        // We don't want to pass up any exception so catch everything here.
        logger.warning('Unknown exception on addSubscribedMediaTrack() ${exception}');
      }
    });

  /// Disconnects from the room, notifying server of disconnection.
  Future<void> disconnect() async {
    if (_connectionState != ConnectionState.disconnected) {
      engine.signalClient.sendLeave();
    }
    await _handleClose();
  }

  Future<void> reconnect() async {
    await engine.reconnect();
  }

  RemoteParticipant _getOrCreateRemoteParticipant(String sid, lk_models.ParticipantInfo? info) {
    RemoteParticipant? participant = _participants[sid];
    if (participant != null) {
      return participant;
    }

    if (info == null) {
      participant = RemoteParticipant(
        engine.signalClient,
        sid,
        '',
        roomEvents: events,
      );
    } else {
      participant = RemoteParticipant.fromInfo(
        engine.signalClient,
        info,
        roomEvents: events,
      );
    }

    _participants[sid] = participant;

    return participant;
  }

  // there should be no problem calling this method multiple times
  Future<void> _handleClose() async {
    logger.fine('[$objectId] _handleClose()');
    if (_connectionState == ConnectionState.disconnected) {
      logger.warning('[$objectId]: close() already disconnected');
    }

    // clean up RemoteParticipants
    for (final _ in _participants.values.toList()) {
      // RemoteParticipant is responsible for disposing resources
      await _.dispose();
    }
    _participants.clear();

    // clean up LocalParticipant
    await localParticipant.unpublishAllTracks();

    // clean up engine
    await engine.close();

    _activeSpeakers.clear();

    // only notify if was not disconnected
    if (_connectionState != ConnectionState.disconnected) {
      _connectionState = ConnectionState.disconnected;
      events.emit(const RoomDisconnectedEvent());
    }
  }

  Future<void> _onParticipantUpdateEvent(List<lk_models.ParticipantInfo> updates) async {
    // trigger change notifier only if list of participants membership is changed
    var hasChanged = false;
    for (final info in updates) {
      if (localParticipant.sid == info.sid) {
        localParticipant.updateFromInfo(info);
        continue;
      }

      if (info.state == lk_models.ParticipantInfo_State.DISCONNECTED) {
        hasChanged = true;
        await _handleParticipantDisconnect(info.sid);
        continue;
      }

      final isNew = !_participants.containsKey(info.sid);
      final participant = _getOrCreateRemoteParticipant(info.sid, info);

      if (isNew) {
        hasChanged = true;
        events.emit(ParticipantConnectedEvent(participant: participant));
      } else {
        await participant.updateFromInfo(info);
      }
    }

    if (hasChanged) {
      notifyListeners();
    }
  }

  void _onSignalSpeakersChangedEvent(List<lk_models.SpeakerInfo> speakers) {
    //
    final lastSpeakers = {
      for (final p in _activeSpeakers) p.sid: p,
    };

    for (final speaker in speakers) {
      Participant? p = _participants[speaker.sid];
      if (speaker.sid == localParticipant.sid) p = localParticipant;
      if (p == null) continue;

      p.audioLevel = speaker.level;
      p.isSpeaking = speaker.active;
      if (speaker.active) {
        lastSpeakers[speaker.sid] = p;
      } else {
        lastSpeakers.remove(speaker.sid);
      }
    }

    final activeSpeakers = lastSpeakers.values.toList();
    activeSpeakers.sort((a, b) => b.audioLevel.compareTo(a.audioLevel));
    _activeSpeakers = activeSpeakers;
    events.emit(ActiveSpeakersChangedEvent(speakers: activeSpeakers));
  }

  // from data channel
  // updates are sent only when there's a change to speaker ordering
  void _onEngineActiveSpeakersUpdateEvent(List<lk_models.SpeakerInfo> speakers) {
    List<Participant> activeSpeakers = [];

    // localParticipant & remote participants
    final allParticipants = <String, Participant>{
      localParticipant.sid: localParticipant,
      ..._participants,
    };

    for (final speaker in speakers) {
      final p = allParticipants[speaker.sid];
      if (p != null) {
        p.audioLevel = speaker.level;
        p.isSpeaking = true;
        activeSpeakers.add(p);
      }
    }

    // clear if not in the speakers list
    final speakerSids = speakers.map((e) => e.sid).toSet();
    for (final p in allParticipants.values) {
      if (!speakerSids.contains(p.sid)) {
        p.audioLevel = 0;
        p.isSpeaking = false;
      }
    }

    _activeSpeakers = activeSpeakers;
    events.emit(ActiveSpeakersChangedEvent(speakers: activeSpeakers));
  }

  void _onDataMessageEvent(EngineDataPacketReceivedEvent dataPacketEvent) {
    // participant may be null if data is sent from Server-API
    final senderSid = dataPacketEvent.packet.participantSid;
    RemoteParticipant? senderParticipant;
    if (senderSid.isNotEmpty) {
      senderParticipant = participants[dataPacketEvent.packet.participantSid];
    }

    // participant.delegate?.onDataReceived(participant, event.packet.payload);

    final event = DataReceivedEvent(
      participant: senderParticipant,
      data: dataPacketEvent.packet.payload,
    );

    senderParticipant?.events.emit(event);
    events.emit(event);
  }

  Future<void> _handleParticipantDisconnect(String sid) async {
    final participant = _participants.remove(sid);
    if (participant == null) {
      return;
    }

    await participant.unpublishAllTracks(notify: true);

    events.emit(ParticipantDisconnectedEvent(participant: participant));
  }
}
