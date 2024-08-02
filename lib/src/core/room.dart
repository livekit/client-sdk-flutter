// Copyright 2024 LiveKit, Inc.
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

// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../core/signal_client.dart';
import '../e2ee/e2ee_manager.dart';
import '../events.dart';
import '../exceptions.dart';
import '../extensions.dart';
import '../hardware/hardware.dart';
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
import '../support/platform.dart';
import '../track/local/audio.dart';
import '../track/local/video.dart';
import '../track/track.dart';
import '../types/other.dart';
import '../utils.dart';
import 'engine.dart';

import '../track/web/_audio_api.dart'
    if (dart.library.html) '../track/web/_audio_html.dart' as audio;

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
  // expose engine's params
  /// connection state of the room
  ConnectionState get connectionState => engine.connectionState;
  ConnectOptions get connectOptions => engine.connectOptions;
  RoomOptions get roomOptions => engine.roomOptions;

  /// map of identity: [[RemoteParticipant]]
  UnmodifiableMapView<String, RemoteParticipant> get remoteParticipants =>
      UnmodifiableMapView(_remoteParticipants);
  final _remoteParticipants = <String, RemoteParticipant>{};
  final Map<String, String> _sidToIdentity = <String, String>{};

  /// the current participant
  LocalParticipant? get localParticipant => _localParticipant;
  LocalParticipant? _localParticipant;

  /// name of the room
  String? get name => _name;
  String? _name;

  /// metadata of the room
  String? get metadata => _metadata;
  String? _metadata;

  /// Server version
  String? get serverVersion => _serverVersion;
  String? _serverVersion;

  /// Server region
  String? get serverRegion => _serverRegion;
  String? _serverRegion;

  E2EEManager? get e2eeManager => _e2eeManager;

  E2EEManager? _e2eeManager;
  bool get isRecording => _isRecording;
  bool _isRecording = false;
  bool _audioEnabled = true;

  lk_models.Room? _roomInfo;

  /// a list of participants that are actively speaking, including local participant.
  UnmodifiableListView<Participant> get activeSpeakers =>
      UnmodifiableListView<Participant>(_activeSpeakers);
  List<Participant> _activeSpeakers = [];

  final Engine engine;
  // suppport for multiple event listeners
  late final EventsListener<EngineEvent> _engineListener;
  //
  late EventsListener<SignalEvent> _signalListener;

  Room({
    ConnectOptions connectOptions = const ConnectOptions(),
    RoomOptions roomOptions = const RoomOptions(),
    Engine? engine,
  }) : engine = engine ??
            Engine(
              connectOptions: connectOptions,
              roomOptions: roomOptions,
            ) {
    //
    _engineListener = this.engine.createListener();
    _setUpEngineListeners();

    _signalListener = this.engine.signalClient.createListener();
    _setUpSignalListeners();

    // Any event emitted will trigger ChangeNotifier
    events.listen((event) {
      logger.fine('[RoomEvent] $event, will notifyListeners()');
      notifyListeners();
    });

    onDispose(() async {
      // clean up routine
      await _cleanUp();
      // dispose events
      await events.dispose();
      // dispose local participant
      await localParticipant?.dispose();
      // dispose all listeners for SignalClient
      await _signalListener.dispose();
      // dispose all listeners for Engine
      await _engineListener.dispose();
      // dispose the engine
      await this.engine.dispose();
    });
  }

  Future<void> connect(
    String url,
    String token, {
    ConnectOptions? connectOptions,
    RoomOptions? roomOptions,
    FastConnectOptions? fastConnectOptions,
  }) async {
    roomOptions ??= this.roomOptions;
    if (roomOptions.e2eeOptions != null) {
      if (!lkPlatformSupportsE2EE()) {
        throw LiveKitE2EEException('E2EE is not supported on this platform');
      }
      _e2eeManager = E2EEManager(roomOptions.e2eeOptions!.keyProvider);
      await _e2eeManager!.setup(this);

      // Disable backup codec when e2ee is enabled
      roomOptions = roomOptions.copyWith(
        defaultVideoPublishOptions:
            roomOptions.defaultVideoPublishOptions.copyWith(
          backupVideoCodec: const BackupVideoCodec(enabled: false),
        ),
      );
    }

    await engine.connect(
      url,
      token,
      connectOptions: connectOptions,
      roomOptions: roomOptions,
      fastConnectOptions: fastConnectOptions,
    );
  }

  void _setUpSignalListeners() => _signalListener
    ..on<SignalJoinResponseEvent>((event) {
      _roomInfo = event.response.room;
      _name = event.response.room.name;
      _metadata = event.response.room.metadata;
      _serverVersion = event.response.serverVersion;
      _serverRegion = event.response.serverRegion;

      if (_isRecording != event.response.room.activeRecording) {
        _isRecording = event.response.room.activeRecording;
        emitWhenConnected(
            RoomRecordingStatusChanged(activeRecording: _isRecording));
      }

      logger.fine('[Engine] Received JoinResponse, '
          'serverVersion: ${event.response.serverVersion}');

      _localParticipant ??= LocalParticipant(
        room: this,
        info: event.response.participant,
      );

      if (engine.fullReconnectOnNext) {
        _localParticipant!.updateFromInfo(event.response.participant);
      }

      if (connectOptions.protocolVersion.index >= ProtocolVersion.v8.index &&
          engine.fastConnectOptions != null &&
          !engine.fullReconnectOnNext) {
        var options = engine.fastConnectOptions!;

        var audio = options.microphone;
        bool audioEnabled = audio.enabled == true || audio.track != null;
        if (audioEnabled) {
          if (audio.track != null) {
            _localParticipant!.publishAudioTrack(audio.track as LocalAudioTrack,
                publishOptions: roomOptions.defaultAudioPublishOptions);
          } else {
            _localParticipant!.setMicrophoneEnabled(true,
                audioCaptureOptions: roomOptions.defaultAudioCaptureOptions);
          }
        }

        var video = options.camera;
        bool videoEnabled = video.enabled == true || video.track != null;
        if (videoEnabled) {
          if (video.track != null) {
            _localParticipant!.publishVideoTrack(video.track as LocalVideoTrack,
                publishOptions: roomOptions.defaultVideoPublishOptions);
          } else {
            _localParticipant!.setCameraEnabled(true,
                cameraCaptureOptions: roomOptions.defaultCameraCaptureOptions);
          }
        }

        var screen = options.screen;
        bool screenEnabled = screen.enabled == true || screen.track != null;
        if (screenEnabled) {
          if (screen.track != null) {
            _localParticipant!.publishVideoTrack(
                screen.track as LocalVideoTrack,
                publishOptions: roomOptions.defaultVideoPublishOptions);
          } else {
            _localParticipant!.setScreenShareEnabled(true,
                screenShareCaptureOptions:
                    roomOptions.defaultScreenShareCaptureOptions);
          }
        }
      }

      for (final info in event.response.otherParticipants) {
        logger.fine(
            'Creating RemoteParticipant: sid = ${info.sid}(identity:${info.identity}) '
            'tracks:${info.tracks.map((e) => e.sid)}');
        _getOrCreateRemoteParticipant(info.identity, info);
      }

      if (e2eeManager != null && event.response.sifTrailer.isNotEmpty) {
        e2eeManager!.keyProvider
            .setSifTrailer(Uint8List.fromList(event.response.sifTrailer));
      }

      logger.fine('Room Connect completed');

      events.emit(RoomConnectedEvent(room: this, metadata: _metadata));
    })
    ..on<SignalParticipantUpdateEvent>(
        (event) => _onParticipantUpdateEvent(event.participants))
    ..on<SignalSpeakersChangedEvent>(
        (event) => _onSignalSpeakersChangedEvent(event.speakers))
    ..on<SignalConnectionQualityUpdateEvent>(
        (event) => _onSignalConnectionQualityUpdateEvent(event.updates))
    ..on<SignalStreamStateUpdatedEvent>(
        (event) => _onSignalStreamStateUpdateEvent(event.updates))
    ..on<SignalSubscribedQualityUpdatedEvent>((event) async {
      // Dynacast is off or is unsupported
      if (!roomOptions.dynacast || _serverVersion == '0.15.1') {
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
      if (event.subscribedCodecs.isNotEmpty) {
        if (publication.track! is! LocalVideoTrack) {
          return;
        }
        var videoTrack = publication.track as LocalVideoTrack;
        final newCodecs = await videoTrack.setPublishingCodecs(
            event.subscribedCodecs, videoTrack);
        for (var codec in newCodecs) {
          if (isBackupCodec(codec)) {
            logger.info(
                'publishing backup codec ${codec} for ${publication.track?.sid}');
            await localParticipant?.publishAdditionalCodecForPublication(
                publication, codec);
          }
        }
      } else if (event.subscribedQualities.isNotEmpty) {
        var videoTrack = publication.track as LocalVideoTrack;
        await videoTrack.updatePublishingLayers(
            videoTrack, event.subscribedQualities);
      }
    })
    ..on<SignalSubscriptionPermissionUpdateEvent>((event) async {
      logger.fine('SignalSubscriptionPermissionUpdateEvent '
          'participantSid:${event.participantSid} '
          'trackSid:${event.trackSid} '
          'allowed:${event.allowed}');

      // find participant
      final participant = _getRemoteParticipantBySid(event.participantSid);
      if (participant == null) {
        return;
      }
      // find track
      final publication = participant.getTrackPublicationBySid(event.trackSid);
      if (publication == null) {
        return;
      }
      //
      await publication.updateSubscriptionAllowed(event.allowed);
      emitWhenConnected(TrackSubscriptionPermissionChangedEvent(
        participant: participant,
        publication: publication,
        state: publication.subscriptionState,
      ));
    })
    ..on<SignalRoomUpdateEvent>((event) async {
      _metadata = event.room.metadata;
      _roomInfo = event.room;
      emitWhenConnected(
          RoomMetadataChangedEvent(metadata: event.room.metadata));
      if (_isRecording != event.room.activeRecording) {
        _isRecording = event.room.activeRecording;
        emitWhenConnected(
            RoomRecordingStatusChanged(activeRecording: _isRecording));
      }
    })
    ..on<SignalRemoteMuteTrackEvent>((event) async {
      final publication = localParticipant?.trackPublications[event.sid];

      final stopOnMute = switch (publication?.source) {
        TrackSource.camera =>
          roomOptions.defaultCameraCaptureOptions.stopCameraCaptureOnMute,
        TrackSource.microphone =>
          roomOptions.defaultAudioCaptureOptions.stopAudioCaptureOnMute,
        _ => true,
      };

      if (event.muted) {
        await publication?.mute(stopOnMute: stopOnMute);
      } else {
        await publication?.unmute(stopOnMute: stopOnMute);
      }
    })
    ..on<SignalTrackUnpublishedEvent>((event) async {
      // unpublish local track
      await localParticipant?.removePublishedTrack(event.trackSid);
    });

  void _setUpEngineListeners() => _engineListener
    ..on<EngineResumedEvent>((event) async {
      // re-send tracks permissions
      localParticipant?.sendTrackSubscriptionPermissions();
      notifyListeners();
    })
    ..on<EngineFullRestartingEvent>((event) async {
      events.emit(const RoomReconnectingEvent());

      // clean up RemoteParticipants
      var copy = _remoteParticipants.values.toList();

      _remoteParticipants.clear();
      _sidToIdentity.clear();
      _activeSpeakers.clear();
      // reset params
      _name = null;
      _metadata = null;
      _serverVersion = null;
      _serverRegion = null;

      for (final participant in copy) {
        events.emit(ParticipantDisconnectedEvent(participant: participant));
        await participant.removeAllPublishedTracks(notify: false);
        await participant.dispose();
      }
      notifyListeners();
    })
    ..on<EngineRestartedEvent>((event) async {
      // re-publish all tracks
      await localParticipant?.rePublishAllTracks();

      for (var participant in remoteParticipants.values) {
        for (var pub in participant.trackPublications.values) {
          if (pub.subscribed) {
            pub.sendUpdateTrackSettings();
          }
        }
      }
      events.emit(const RoomReconnectedEvent());
      notifyListeners();
    })
    ..on<EngineResumingEvent>((event) async {
      await _sendSyncState();
      notifyListeners();
    })
    ..on<EngineAttemptReconnectEvent>((event) async {
      events.emit(RoomAttemptReconnectEvent(
        attempt: event.attempt,
        maxAttemptsRetry: event.maxAttempts,
        nextRetryDelaysInMs: event.nextRetryDelaysInMs,
      ));
      notifyListeners();
    })
    ..on<EngineDisconnectedEvent>((event) async {
      if (!engine.fullReconnectOnNext &&
          ![
            DisconnectReason.signalingConnectionFailure,
            DisconnectReason.joinFailure,
            DisconnectReason.noInternetConnection
          ].contains(event.reason)) {
        await _cleanUp();
        events.emit(RoomDisconnectedEvent(reason: event.reason));
        notifyListeners();
      }
    })
    ..on<EngineActiveSpeakersUpdateEvent>(
        (event) => _onEngineActiveSpeakersUpdateEvent(event.speakers))
    ..on<EngineDataPacketReceivedEvent>(_onDataMessageEvent)
    ..on<EngineTranscriptionReceivedEvent>(_onTranscriptionEvent)
    ..on<AudioPlaybackStarted>((event) {
      _handleAudioPlaybackStarted();
    })
    ..on<AudioPlaybackFailed>((event) {
      _handleAudioPlaybackFailed();
    })
    ..on<EngineTrackAddedEvent>((event) async {
      logger.fine('EngineTrackAddedEvent trackSid:${event.track.id}');

      final idParts = unpackStreamId(event.stream.id);
      final participantSid = idParts[0];
      var streamId = idParts[1];
      var trackSid = event.track.id;

      // firefox will get streamId (pID|trackId) instead of (pID|streamId) as it doesn't support sync tracks by stream
      // and generates its own track id instead of infer from sdp track id.
      if (streamId.isNotEmpty && streamId.startsWith('TR')) {
        trackSid = streamId;
      }

      final participant = _getRemoteParticipantBySid(participantSid);
      try {
        if (trackSid == null || trackSid.isEmpty) {
          throw TrackSubscriptionExceptionEvent(
            participant: participant,
            reason: TrackSubscribeFailReason.invalidServerResponse,
          );
        }
        if (participant == null) {
          throw TrackSubscriptionExceptionEvent(
            participant: participant,
            sid: trackSid,
            reason: TrackSubscribeFailReason.noParticipantFound,
          );
        }
        await participant.addSubscribedMediaTrack(
          event.track,
          event.stream,
          trackSid,
          receiver: event.receiver,
          audioOutputOptions: roomOptions.defaultAudioOutputOptions,
        );
      } on TrackSubscriptionExceptionEvent catch (event) {
        logger.severe('addSubscribedMediaTrack() throwed ${event}');
        events.emit(event);
      } catch (exception) {
        // We don't want to pass up any exception so catch everything here.
        logger.warning(
            'Unknown exception on addSubscribedMediaTrack() ${exception}');
      }
    });

  /// Disconnects from the room, notifying server of disconnection.
  Future<void> disconnect() async {
    if (engine.isClosed &&
        engine.connectionState == ConnectionState.disconnected) {
      events.emit(RoomDisconnectedEvent(reason: DisconnectReason.unknown));
      return;
    }
    await engine.disconnect();
    await _engineListener.waitFor<EngineDisconnectedEvent>(
        duration: const Duration(seconds: 10));
    await _cleanUp();
  }

  Future<void> setE2EEEnabled(bool enabled) async {
    if (_e2eeManager != null) {
      await _e2eeManager!.setEnabled(enabled);
    } else {
      throw LiveKitE2EEException('_e2eeManager not setup!');
    }
  }

  /// retrieves a participant by identity
  Participant? getParticipantByIdentity(String identity) {
    if (_localParticipant?.identity == identity) {
      return _localParticipant;
    }
    return remoteParticipants[identity];
  }

  RemoteParticipant? _getRemoteParticipantBySid(String sid) {
    final identity = _sidToIdentity[sid];
    if (identity != null) {
      return remoteParticipants[identity];
    }
    return null;
  }

  RemoteParticipant _getOrCreateRemoteParticipant(
      String identity, lk_models.ParticipantInfo? info) {
    RemoteParticipant? participant = _remoteParticipants[identity];
    if (participant != null) {
      if (info != null) {
        participant.updateFromInfo(info);
      }
      return participant;
    }

    if (info == null) {
      logger.warning('RemoteParticipant.info is null identity: $identity');
      participant = RemoteParticipant(
        room: this,
        sid: '',
        identity: identity,
        name: '',
      );
    } else {
      participant = RemoteParticipant.fromInfo(
        room: this,
        info: info,
      );
    }

    _remoteParticipants[identity] = participant;
    _sidToIdentity[participant.sid] = identity;
    return participant;
  }

  Future<void> _onParticipantUpdateEvent(
      List<lk_models.ParticipantInfo> updates) async {
    // trigger change notifier only if list of participants membership is changed
    var hasChanged = false;
    for (final info in updates) {
      if (localParticipant?.identity == info.identity) {
        await localParticipant?.updateFromInfo(info);
        continue;
      }

      final isNew = !_remoteParticipants.containsKey(info.identity);

      if (info.state == lk_models.ParticipantInfo_State.DISCONNECTED) {
        hasChanged = await _handleParticipantDisconnect(info.identity);
        continue;
      }

      final participant = _getOrCreateRemoteParticipant(info.identity, info);

      if (isNew) {
        hasChanged = true;
        // fire connected event
        emitWhenConnected(ParticipantConnectedEvent(participant: participant));
      } else {
        final wasUpdated = await participant.updateFromInfo(info);
        if (wasUpdated) {
          _sidToIdentity[info.sid] = info.identity;
        }
      }
    }

    if (hasChanged) {
      notifyListeners();
    }
  }

  void _onSignalSpeakersChangedEvent(List<lk_models.SpeakerInfo> speakers) {
    final lastSpeakers = {
      for (final p in _activeSpeakers) p.sid: p,
    };

    for (final speaker in speakers) {
      Participant? p = _getRemoteParticipantBySid(speaker.sid);
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
    emitWhenConnected(ActiveSpeakersChangedEvent(speakers: activeSpeakers));
  }

  // from data channel
  // updates are sent only when there's a change to speaker ordering
  void _onEngineActiveSpeakersUpdateEvent(
      List<lk_models.SpeakerInfo> speakers) {
    List<Participant> activeSpeakers = [];

    // localParticipant & remote participants
    final allParticipants = <String, Participant>{
      if (localParticipant != null) localParticipant!.sid: localParticipant!,
      ..._remoteParticipants,
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
    emitWhenConnected(ActiveSpeakersChangedEvent(speakers: activeSpeakers));
  }

  void _onSignalConnectionQualityUpdateEvent(
      List<lk_rtc.ConnectionQualityInfo> updates) {
    for (final entry in updates) {
      Participant? participant;
      if (entry.participantSid == localParticipant?.sid) {
        participant = localParticipant;
      } else {
        participant = _getRemoteParticipantBySid(entry.participantSid);
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
      final participant = remoteParticipants[update.participantSid];
      if (participant == null) continue;
      // try to find RemoteTrackPublication
      final trackPublication = participant.trackPublications[update.trackSid];
      if (trackPublication == null) continue;
      // update the stream state
      await trackPublication.updateStreamState(update.state.toLKType());
      emitWhenConnected(TrackStreamStateUpdatedEvent(
        participant: participant,
        publication: trackPublication,
        streamState: update.state.toLKType(),
      ));
    }
  }

  void _onTranscriptionEvent(EngineTranscriptionReceivedEvent event) {
    final participant = getParticipantByIdentity(
        event.transcription.transcribedParticipantIdentity);
    if (participant == null) {
      return;
    }

    final publication =
        participant.getTrackPublicationBySid(event.transcription.trackId);

    var segments = event.transcription.segments.map((e) {
      return TranscriptionSegment(
        text: e.text,
        id: e.id,
        startTime: DateTime.fromMillisecondsSinceEpoch(e.startTime.toInt()),
        endTime: DateTime.fromMillisecondsSinceEpoch(e.endTime.toInt()),
        isFinal: e.final_5,
        language: e.language,
      );
    }).toList();

    final transcription = TranscriptionEvent(
      participant: participant,
      publication: publication,
      segments: segments,
    );

    participant.events.emit(transcription);
    events.emit(transcription);
  }

  void _onDataMessageEvent(EngineDataPacketReceivedEvent dataPacketEvent) {
    // participant may be null if data is sent from Server-API
    final senderSid = dataPacketEvent.packet.participantSid;
    RemoteParticipant? senderParticipant;
    if (senderSid.isNotEmpty) {
      senderParticipant =
          _getRemoteParticipantBySid(dataPacketEvent.packet.participantSid);
    }

    // participant.delegate?.onDataReceived(participant, event.packet.payload);

    final event = DataReceivedEvent(
      participant: senderParticipant,
      data: dataPacketEvent.packet.payload,
      topic: dataPacketEvent.packet.topic,
    );

    senderParticipant?.events.emit(event);
    events.emit(event);
  }

  Future<bool> _handleParticipantDisconnect(String identity) async {
    final participant = _remoteParticipants.remove(identity);
    if (participant == null) {
      return false;
    }

    await participant.removeAllPublishedTracks(notify: true);

    emitWhenConnected(ParticipantDisconnectedEvent(participant: participant));
    return true;
  }

  Future<void> _sendSyncState() async {
    final autoSubscribe = connectOptions.autoSubscribe;

    final trackSids = <String>[];
    final trackSidsDisabled = <String>[];

    for (var participant in remoteParticipants.values) {
      for (var track in participant.trackPublications.values) {
        if (track.subscribed != autoSubscribe) {
          trackSids.add(track.sid);
        }
        if (!track.enabled) {
          trackSidsDisabled.add(track.sid);
        }
      }
    }

    engine.sendSyncState(
      subscription: lk_rtc.UpdateSubscription(
        participantTracks: [],
        trackSids: trackSids,
        subscribe: !autoSubscribe,
      ),
      trackSidsDisabled: trackSidsDisabled,
      publishTracks: localParticipant?.publishedTracksInfo(),
    );
  }
}

extension RoomPrivateMethods on Room {
  // resets internal state to a re-usable state
  Future<void> _cleanUp() async {
    logger.fine('[${objectId}] cleanUp()');

    // clean up RemoteParticipants
    var participants = _remoteParticipants.values.toList();
    for (final participant in participants) {
      await participant.removeAllPublishedTracks(notify: false);
      // RemoteParticipant is responsible for disposing resources
      await participant.dispose();
    }
    _remoteParticipants.clear();
    _sidToIdentity.clear();

    // clean up LocalParticipant
    await localParticipant?.unpublishAllTracks();

    _activeSpeakers.clear();

    // clean up engine
    await engine.cleanUp();

    // reset params
    _name = null;
    _metadata = null;
    _serverVersion = null;
    _serverRegion = null;
  }

  @internal
  void emitWhenConnected(RoomEvent event) {
    if (connectionState == ConnectionState.connected) {
      events.emit(event);
    }
  }

  /// server assigned unique room id.
  /// returns once a sid has been issued by the server.
  Future<String> getSid() async {
    if (engine.connectionState == ConnectionState.disconnected) {
      return '';
    }

    if (_roomInfo != null && _roomInfo!.sid.isNotEmpty) {
      return _roomInfo!.sid;
    }

    final completer = Completer<String>();

    events.on<SignalRoomUpdateEvent>((event) {
      if (event.room.sid.isNotEmpty && !completer.isCompleted) {
        completer.complete(event.room.sid);
      }
    });

    events.once<RoomDisconnectedEvent>((event) {
      if (!completer.isCompleted) {
        completer.complete('');
      }
    });

    return completer.future;
  }
}

extension RoomDebugMethods on Room {
  /// To be used for internal testing purposes only.
  Future<void> sendSimulateScenario({
    int? speakerUpdate,
    bool? nodeFailure,
    bool? migration,
    bool? serverLeave,
    bool? switchCandidate,
    bool? signalReconnect,
    bool? fullReconnect,
    int? subscriberBandwidth,
  }) async {
    if (signalReconnect != null && signalReconnect) {
      await engine.signalClient.cleanUp();
      return;
    }
    if (fullReconnect != null && fullReconnect) {
      engine.fullReconnectOnNext = true;
      await engine.signalClient.cleanUp();
      return;
    }
    engine.signalClient.sendSimulateScenario(
        speakerUpdate: speakerUpdate,
        nodeFailure: nodeFailure,
        migration: migration,
        serverLeave: serverLeave,
        switchCandidate: switchCandidate);
  }
}

/// Room extension methods for managing audio, video.
extension RoomHardwareManagementMethods on Room {
  /// Get current audio output device.
  String? get selectedAudioOutputDeviceId =>
      roomOptions.defaultAudioOutputOptions.deviceId ??
      Hardware.instance.selectedAudioOutput?.deviceId;

  /// Get current audio input device.
  String? get selectedAudioInputDeviceId =>
      roomOptions.defaultAudioCaptureOptions.deviceId ??
      Hardware.instance.selectedAudioInput?.deviceId;

  /// Get current video input device.
  String? get selectedVideoInputDeviceId =>
      roomOptions.defaultCameraCaptureOptions.deviceId ??
      Hardware.instance.selectedVideoInput?.deviceId;

  /// Get mobile device's speaker status.
  bool? get speakerOn => roomOptions.defaultAudioOutputOptions.speakerOn;

  /// Set audio output device.
  Future<void> setAudioOutputDevice(MediaDevice device) async {
    if (lkPlatformIs(PlatformType.web)) {
      remoteParticipants.forEach((_, participant) {
        for (var audioTrack in participant.audioTrackPublications) {
          audioTrack.track?.setSinkId(device.deviceId);
        }
      });
      Hardware.instance.selectedAudioOutput = device;
    } else {
      await Hardware.instance.selectAudioOutput(device);
    }
    engine.roomOptions = engine.roomOptions.copyWith(
      defaultAudioOutputOptions: roomOptions.defaultAudioOutputOptions.copyWith(
        deviceId: device.deviceId,
      ),
    );
  }

  /// Set audio input device.
  Future<void> setAudioInputDevice(MediaDevice device) async {
    if (lkPlatformIs(PlatformType.web) && localParticipant != null) {
      for (var audioTrack in localParticipant!.audioTrackPublications) {
        await audioTrack.track?.setDeviceId(device.deviceId);
      }
      Hardware.instance.selectedAudioInput = device;
    } else {
      await Hardware.instance.selectAudioInput(device);
    }
    engine.roomOptions = engine.roomOptions.copyWith(
      defaultAudioCaptureOptions:
          roomOptions.defaultAudioCaptureOptions.copyWith(
        deviceId: device.deviceId,
      ),
    );
  }

  /// Set video input device.
  Future<void> setVideoInputDevice(MediaDevice device) async {
    final track = localParticipant?.videoTrackPublications.firstOrNull?.track;
    if (track == null) return;
    if (selectedVideoInputDeviceId != device.deviceId) {
      await track.switchCamera(device.deviceId);
      Hardware.instance.selectedVideoInput = device;
    }
    engine.roomOptions = engine.roomOptions.copyWith(
      defaultCameraCaptureOptions:
          roomOptions.defaultCameraCaptureOptions.copyWith(
        deviceId: device.deviceId,
      ),
    );
  }

  Future<void> setSpeakerOn(bool speakerOn) async {
    if (lkPlatformIs(PlatformType.iOS) || lkPlatformIs(PlatformType.android)) {
      await Hardware.instance.setSpeakerphoneOn(speakerOn);
      engine.roomOptions = engine.roomOptions.copyWith(
        defaultAudioOutputOptions:
            roomOptions.defaultAudioOutputOptions.copyWith(
          speakerOn: speakerOn,
        ),
      );
    }
  }

  /// Apply audio output device settings.
  @internal
  Future<void> applyAudioSpeakerSettings() async {
    if (roomOptions.defaultAudioOutputOptions.speakerOn != null) {
      if (lkPlatformIs(PlatformType.iOS) ||
          lkPlatformIs(PlatformType.android)) {
        await Hardware.instance.setSpeakerphoneOn(
            roomOptions.defaultAudioOutputOptions.speakerOn!);
      }
    }
  }

  Future<void> startAudio() async {
    try {
      var audioContextRunning = await audio.startAllAudioElement();
      if (audioContextRunning) {
        _handleAudioPlaybackStarted();
      } else {
        _handleAudioPlaybackFailed();
      }
    } catch (err) {
      logger.warning('could not playback audio $err');
      _handleAudioPlaybackFailed();
    }
  }

  bool get canPlaybackAudio {
    return _audioEnabled;
  }

  void _handleAudioPlaybackStarted() {
    if (canPlaybackAudio) {
      return;
    }
    _audioEnabled = true;
    events.emit(const AudioPlaybackStatusChanged(isPlaying: true));
  }

  void _handleAudioPlaybackFailed() {
    if (!canPlaybackAudio) {
      return;
    }
    _audioEnabled = false;
    events.emit(const AudioPlaybackStatusChanged(isPlaying: false));
  }
}
