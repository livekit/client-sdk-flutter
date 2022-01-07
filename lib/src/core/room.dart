import 'dart:collection';

import 'package:collection/collection.dart';

import '../constants.dart';
import '../events.dart';
import '../exceptions.dart';
import '../extensions.dart';
import '../internal/events.dart';
import '../logger.dart';
import '../managers/event.dart';
import '../options.dart';
import '../participant/local.dart';
import '../participant/participant.dart';
import '../participant/remote.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../support/disposable.dart';
import '../track/track.dart';
import '../types.dart';
import '../core/signal_client.dart';
import 'engine.dart';

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

  ConnectOptions? connectOptions;

  RoomOptions? roomOptions;

  /// the current participant
  LocalParticipant? localParticipant;

  /// name of the room
  String? name;

  /// sid of the room
  String? sid;

  /// Server version
  String? get serverVersion => _serverVersion;
  String? _serverVersion;

  List<Participant> _activeSpeakers = [];

  /// a list of participants that are actively speaking, including local participant.
  UnmodifiableListView<Participant> get activeSpeakers =>
      UnmodifiableListView<Participant>(_activeSpeakers);

  late final engine = Engine(room: this);

  // suppport for multiple event listeners
  late final _engineListener = engine.createListener();

  Room({
    this.connectOptions,
    this.roomOptions,
  }) {
    //
    _setUpListeners();

    // Any event emitted will trigger ChangeNotifier
    events.listen((event) {
      logger.fine('[RoomEvent] $event, will notifyListeners()');
      notifyListeners();
    });

    onDispose(() async {
      // dispose events
      await events.dispose();
      // dispose local participant
      await localParticipant?.dispose();
      // dispose all listeners for RTCEngine
      await _engineListener.dispose();
      // dispose the engine
      await engine.dispose();
    });
  }

  Future<void> connect(
    String url,
    String token, {
    ConnectOptions? connectOptions,
    RoomOptions? roomOptions,
  }) async {
    // update options if provided
    this.connectOptions = connectOptions ?? this.connectOptions;
    this.roomOptions = roomOptions ?? this.roomOptions;

    final joinResponse = await engine.connect(
      url,
      token,
    );

    sid = joinResponse.room.sid;
    name = joinResponse.room.name;
    _serverVersion = joinResponse.serverVersion;

    logger.fine(
        'Connected to LiveKit server, version: ${joinResponse.serverVersion}');

    localParticipant = LocalParticipant(
      room: this,
      info: joinResponse.participant,
    );

    for (final info in joinResponse.otherParticipants) {
      logger.fine('Creating RemoteParticipant: ${info.sid}(${info.identity}) '
          'tracks:${info.tracks.map((e) => e.sid)}');
      _getOrCreateRemoteParticipant(info.sid, info);
    }

    logger.fine('Waiting to engine connect...');

    // wait until engine is connected
    await _engineListener.waitFor<EngineConnectedEvent>(
      duration: Timeouts.connection,
      onTimeout: () => throw ConnectException(),
    );

    logger.fine('Room Connect completed');
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
    ..on<SignalParticipantUpdateEvent>(
        (event) => _onParticipantUpdateEvent(event.participants))
    ..on<EngineActiveSpeakersUpdateEvent>(
        (event) => _onEngineActiveSpeakersUpdateEvent(event.speakers))
    ..on<SignalSpeakersChangedEvent>(
        (event) => _onSignalSpeakersChangedEvent(event.speakers))
    ..on<SignalConnectionQualityUpdateEvent>(
        (event) => _onSignalConnectionQualityUpdateEvent(event.updates))
    ..on<SignalStreamStateUpdatedEvent>(
        (event) => _onSignalStreamStateUpdateEvent(event.updates))
    ..on<EngineDataPacketReceivedEvent>(_onDataMessageEvent)
    ..on<EngineRemoteMuteChangedEvent>((event) async {
      final publication = localParticipant?.trackPublications[event.sid];
      if (event.muted) {
        await publication?.mute();
      } else {
        await publication?.unmute();
      }
    })
    ..on<SignalSubscribedQualityUpdatedEvent>((event) {
      // Signal for Dynacast
      final options = roomOptions ?? const RoomOptions();
      // Dynacast is off or is unsupported
      if (!options.dynacast || _serverVersion == '0.15.1') {
        logger.fine('Received subscribed quality update'
            ' but Dynacast is off or server version is not supported.');
        return;
      }
      // Find the publication
      final publication = localParticipant?.trackPublications[event.trackSid];
      if (publication == null) {
        logger.warning(
            'Received subscribed quality update for unknown track (${event.trackSid})');
        return;
      }
      publication.updatePublishingLayers(event.updates);
    })
    ..on<SubscriptionPermissionUpdateEvent>((event) {
      // find participant
      final participant = _participants[event.participantSid];
      if (participant == null) {
        return;
      }
      // find track
      final publication = participant.trackPublications[event.trackSid];
      if (publication == null) {
        return;
      }
      //
      if (publication.updateAllowedToSubscribe(event.allowed)) {
        [participant.events, events]
            .emit(TrackSubscriptionPermissionChangedEvent(
          participant: participant,
          trackPublication: publication,
          state: publication.subscriptionState(),
        ));
      }
    })
    ..on<EngineTrackAddedEvent>((event) async {
      logger.fine('EngineTrackAddedEvent trackSid:${event.track.id}');

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
        logger.severe('addSubscribedMediaTrack() throwed ${event}');
        [participant.room.events, participant.events].emit(event);
      } catch (exception) {
        // We don't want to pass up any exception so catch everything here.
        logger.warning(
            'Unknown exception on addSubscribedMediaTrack() ${exception}');
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

  RemoteParticipant _getOrCreateRemoteParticipant(
      String sid, lk_models.ParticipantInfo? info) {
    RemoteParticipant? participant = _participants[sid];
    if (participant != null) {
      return participant;
    }

    if (info == null) {
      logger.warning('RemoteParticipant.info is null trackSid: $sid');
      participant = RemoteParticipant(
        room: this,
        sid: sid,
        identity: '',
        name: '',
      );
    } else {
      participant = RemoteParticipant.fromInfo(
        room: this,
        info: info,
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
    await localParticipant?.unpublishAllTracks();

    // clean up engine
    await engine.close();

    _activeSpeakers.clear();

    // only notify if was not disconnected
    if (_connectionState != ConnectionState.disconnected) {
      _connectionState = ConnectionState.disconnected;
      events.emit(const RoomDisconnectedEvent());
    }
  }

  Future<void> _onParticipantUpdateEvent(
      List<lk_models.ParticipantInfo> updates) async {
    // trigger change notifier only if list of participants membership is changed
    var hasChanged = false;
    for (final info in updates) {
      if (localParticipant?.sid == info.sid) {
        localParticipant?.updateFromInfo(info);
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
      if (speaker.sid == localParticipant?.sid) p = localParticipant;
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
  void _onEngineActiveSpeakersUpdateEvent(
      List<lk_models.SpeakerInfo> speakers) {
    List<Participant> activeSpeakers = [];

    // localParticipant & remote participants
    final allParticipants = <String, Participant>{
      if (localParticipant != null) localParticipant!.sid: localParticipant!,
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

  void _onSignalConnectionQualityUpdateEvent(
      List<lk_rtc.ConnectionQualityInfo> updates) {
    for (final entry in updates) {
      Participant? participant;
      if (entry.participantSid == localParticipant?.sid) {
        participant = localParticipant;
      } else {
        participant = _participants[entry.participantSid];
      }

      if (participant != null) {
        // update the connection quality if the participant is found
        participant.updateConnectionQuality(entry.quality.toLKType());
      }
    }
  }

  void _onSignalStreamStateUpdateEvent(
      List<lk_rtc.StreamStateInfo> updates) async {
    for (final update in updates) {
      // try to find RemoteParticipant
      final participant = participants[update.participantSid];
      if (participant == null) continue;
      // try to find RemoteTrackPublication
      final trackPublication = participant.trackPublications[update.trackSid];
      if (trackPublication == null) continue;
      // update the stream state
      await trackPublication.updateStreamState(update.state.toLKType());
    }
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
