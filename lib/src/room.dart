import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'classes/change_notifier.dart';
import 'constants.dart';
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
import 'proto/livekit_rtc.pb.dart' as lk_rtc;
import 'rtc_engine.dart';
import 'signal_client.dart';
import 'track/track.dart';
import 'track/track_publication.dart';
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
class Room extends LKChangeNotifier {
  // Room is only instantiated if connected, so defaults to connected.
  ConnectionState _connectionState = ConnectionState.connected;

  /// connection state of the room
  ConnectionState get connectionState => _connectionState;

  final Map<String, RemoteParticipant> _participants = {};

  /// map of SID to RemoteParticipant
  UnmodifiableMapView<String, RemoteParticipant> get participants =>
      UnmodifiableMapView(_participants);

  /// the current participant
  late final LocalParticipant localParticipant;

  /// name of the room
  late final String name;

  /// sid of the room
  late final String sid;

  List<Participant> _activeSpeakers = [];

  /// a list of participants that are actively speaking, including local participant.
  UnmodifiableListView<Participant> get activeSpeakers =>
      UnmodifiableListView<Participant>(_activeSpeakers);

  final RTCEngine engine;

  // suppport for multiple event listeners
  final events = EventsEmitter<RoomEvent>();
  late final _engineListener = EventsListener<LiveKitEvent>(engine.events);

  /// internal use
  /// {@nodoc}
  Room._({
    required this.engine,
    required lk_rtc.JoinResponse joinResponse,
    ConnectOptions? connectOptions,
  }) {
    //
    _setUpListeners();

    localParticipant = LocalParticipant(
      engine: engine,
      info: joinResponse.participant,
      defaultPublishOptions: connectOptions?.defaultPublishOptions,
      roomEvents: events,
    );

    sid = joinResponse.room.sid;
    name = joinResponse.room.name;

    for (final info in joinResponse.otherParticipants) {
      _getOrCreateRemoteParticipant(info.sid, info);
    }

    if (kDebugMode) {
      // log all RoomEvents
      events.listen((event) => logger.fine('[RoomEvent] $objectId ${event.runtimeType}'));
    }
  }

  @override
  Future<void> dispose() async {
    // dispose local participant
    await localParticipant.dispose();
    // dispose Room's events emitter
    await events.dispose();
    // dispose all listeners for RTCEngine
    await _engineListener.dispose();
    // dispose the engine
    await engine.dispose();

    super.dispose();
  }

  static Future<Room> connect(
    String url,
    String token, {
    ConnectOptions? options,
    RTCConfiguration? rtcConfig,
  }) async {
    //
    final engine = RTCEngine(
      SignalClient(),
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
      notifyListeners();
    })
    ..on<EngineReconnectingEvent>((event) async {
      _connectionState = ConnectionState.reconnecting;
      events.emit(const RoomReconnectingEvent());
      notifyListeners();
    })
    ..on<EngineDisconnectedEvent>((event) => _onDisconnectedEvent())
    ..on<EngineParticipantUpdateEvent>((event) => _onParticipantUpdateEvent(event.participants))
    ..on<EngineSpeakersUpdateEvent>((event) => _onSpeakerUpdateEvent(event.speakers))
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
    engine.signalClient.sendLeave();
    await _onDisconnectedEvent();
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

  Future<void> _onDisconnectedEvent() async {
    if (_connectionState == ConnectionState.disconnected) {
      logger.fine('$objectId: _handleDisconnect() already disconnected');
      return;
    }
    // we need to flag room as disconnected immediately to avoid
    // this method firing multiple times since the following code
    // is being awaited
    _connectionState = ConnectionState.disconnected;

    // clean up RemoteParticipants
    for (final _ in _participants.values) {
      // RemoteParticipant is responsible for disposing resources
      await _.unpublishAllTracks();
      await _.dispose();
    }
    _participants.clear();

    // clean up LocalParticipant
    // for (final pub in localParticipant.tracks.values) {
    //   await pub.track?.stop();
    // }
    await localParticipant.unpublishAllTracks();

    // await localParticipant.dispose();
    // localParticipant = null;

    await engine.close();

    _activeSpeakers.clear();

    notifyListeners();
    events.emit(const RoomDisconnectedEvent());
  }

  void _onParticipantUpdateEvent(List<lk_models.ParticipantInfo> updates) async {
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
        events.emit(ParticipantConnectedEvent(participant: participant));
      } else {
        await participant.updateFromInfo(info);
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

    events.emit(ActiveSpeakersChangedEvent(speakers: newSpeakers));

    _activeSpeakers = newSpeakers;
    notifyListeners();
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

  void _handleParticipantDisconnect(String sid) {
    final participant = _participants.remove(sid);
    if (participant == null) {
      return;
    }

    final toRemove = List<TrackPublication>.from(participant.trackPublications.values);
    for (final track in toRemove) {
      participant.unpublishTrack(track.sid, notify: true);
    }

    events.emit(ParticipantDisconnectedEvent(participant: participant));
  }
}
