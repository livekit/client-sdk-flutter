import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:collection/collection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../events.dart';
import '../exceptions.dart';
import '../extensions.dart';
import '../internal/events.dart';
import '../internal/types.dart';
import '../logger.dart';
import '../managers/event.dart';
import '../options.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../support/disposable.dart';
import '../support/websocket.dart';
import '../types/other.dart';
import '../types/video_dimensions.dart';
import '../utils.dart';
import 'room.dart';
import 'signal_client.dart';
import 'transport.dart';

class Engine extends Disposable with EventsEmittable<EngineEvent> {
  static const _lossyDCLabel = '_lossy';
  static const _reliableDCLabel = '_reliable';
  final SignalClient signalClient;

  final PeerConnectionCreate _peerConnectionCreate;

  @internal
  Transport? publisher;

  @internal
  Transport? subscriber;

  @internal
  Transport? get primary => _subscriberPrimary ? subscriber : publisher;

  rtc.RTCDataChannel? get dataChannel => _subscriberPrimary
      ? _reliableDCSub ?? _lossyDCSub
      : _reliableDCPub ?? _lossyDCPub;

  // data channels for packets
  rtc.RTCDataChannel? _reliableDCPub;
  rtc.RTCDataChannel? _lossyDCPub;
  rtc.RTCDataChannel? _reliableDCSub;
  rtc.RTCDataChannel? _lossyDCSub;

  ConnectionState _connectionState = ConnectionState.disconnected;

  /// Connection state of the [Room].
  ConnectionState get connectionState => _connectionState;

  // true if publisher connection has already been established.
  // this is helpful to know if we need to restart ICE on the publisher connection
  bool _hasPublished = false;

  lk_models.ClientConfiguration? _clientConfiguration;

  // remember url and token for reconnect
  String? url;
  String? token;

  ConnectOptions connectOptions;
  RoomOptions roomOptions;
  FastConnectOptions? fastConnectOptions;

  bool _subscriberPrimary = false;
  String? _participantSid;

  String? _connectedServerAddress;
  String? get connectedServerAddress => _connectedServerAddress;

  bool fullReconnect = false;

  // server-provided ice servers
  List<RTCIceServer> _serverProvidedIceServers = [];

  late EventsListener<SignalEvent> _signalListener =
      signalClient.createListener(synchronized: true);

  Engine({
    required this.connectOptions,
    required this.roomOptions,
    SignalClient? signalClient,
    PeerConnectionCreate? peerConnectionCreate,
  })  : signalClient = signalClient ?? SignalClient(LiveKitWebSocket.connect),
        _peerConnectionCreate =
            peerConnectionCreate ?? rtc.createPeerConnection {
    if (kDebugMode) {
      // log all EngineEvents
      events.listen((event) => logger.fine('[EngineEvent] $objectId $event'));
    }

    _setUpEngineListeners();
    _setUpSignalListeners();

    onDispose(() async {
      await cleanUp();
      await events.dispose();
      await _signalListener.dispose();
    });
  }

  Future<void> connect(
    String url,
    String token, {
    ConnectOptions? connectOptions,
    RoomOptions? roomOptions,
    FastConnectOptions? fastConnectOptions,
  }) async {
    this.url = url;
    this.token = token;
    // update new options (if exists)
    this.connectOptions = connectOptions ?? this.connectOptions;
    this.roomOptions = roomOptions ?? this.roomOptions;
    this.fastConnectOptions = fastConnectOptions;

    _updateConnectionState(ConnectionState.connecting);

    try {
      // wait for socket to connect rtc server
      await signalClient.connect(
        url,
        token,
        connectOptions: this.connectOptions,
        roomOptions: this.roomOptions,
      );

      // wait for join response
      await _signalListener.waitFor<SignalJoinResponseEvent>(
        duration: this.connectOptions.timeouts.connection,
        onTimeout: () => throw ConnectException(
            'Timed out waiting for SignalJoinResponseEvent'),
      );

      logger.fine('Waiting for engine to connect...');

      // wait until engine is connected
      await events.waitFor<EnginePeerStateUpdatedEvent>(
        filter: (event) => event.isPrimary && event.state.isConnected(),
        duration: this.connectOptions.timeouts.connection,
        onTimeout: () => throw ConnectException(
            'Timed out waiting for EnginePeerStateUpdatedEvent'),
      );

      _updateConnectionState(ConnectionState.connected);
    } catch (error) {
      logger.fine('Connect Error $error');
      _updateConnectionState(ConnectionState.disconnected);
      rethrow;
    }
  }

  // resets internal state to a re-usable state
  Future<void> cleanUp() async {
    logger.fine('[$objectId] cleanUp()');

    await publisher?.dispose();
    publisher = null;
    _hasPublished = false;

    await subscriber?.dispose();
    subscriber = null;

    await signalClient.cleanUp();

    _updateConnectionState(ConnectionState.disconnected);
  }

  @internal
  Future<lk_models.TrackInfo> addTrack({
    required String cid,
    required String name,
    required lk_models.TrackType kind,
    required lk_models.TrackSource source,
    VideoDimensions? dimensions,
    bool? dtx,
    Iterable<lk_models.VideoLayer>? videoLayers,
  }) async {
    // TODO: Check if cid already published

    // send request to add track
    signalClient.sendAddTrack(
      cid: cid,
      name: name,
      type: kind,
      source: source,
      dimensions: dimensions,
      dtx: dtx,
      videoLayers: videoLayers,
    );

    // wait for response, or timeout
    final event = await _signalListener.waitFor<SignalLocalTrackPublishedEvent>(
      filter: (event) => event.cid == cid,
      duration: connectOptions.timeouts.publish,
      onTimeout: () => throw TrackPublishException(),
    );

    return event.track;
  }

  @internal
  Future<void> negotiate({bool? iceRestart}) async {
    if (publisher == null) {
      return;
    }
    _hasPublished = true;
    try {
      publisher!.negotiate(null);
    } catch (error) {
      if (error is NegotiationError) {
        fullReconnect = true;
      }
      await handleDisconnect(DisconnectReason.negotiationFailed);
    }
  }

  @internal
  Future<void> sendDataPacket(
    lk_models.DataPacket packet,
  ) async {
    //
    final reliability = packet.kind.toSDKType();

    // construct the data channel message
    final message =
        rtc.RTCDataChannelMessage.fromBinary(packet.writeToBuffer());

    if (_subscriberPrimary) {
      // make sure publisher transport is connected

      if (publisher?.pc.connectionState?.isConnected() != true) {
        logger.fine('Publisher is not connected...');

        // start negotiation
        if (publisher?.pc.connectionState !=
            rtc.RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
          await negotiate();
        }

        logger.fine('Waiting for publisher to ice-connect...');
        await events.waitFor<EnginePublisherPeerStateUpdatedEvent>(
          filter: (event) => event.state.isConnected(),
          duration: connectOptions.timeouts.peerConnection,
        );
      }

      // wait for data channel to open (if not already)
      if (_publisherDataChannelState(packet.kind.toSDKType()) !=
          rtc.RTCDataChannelState.RTCDataChannelOpen) {
        logger.fine('Waiting for data channel ${reliability} to open...');
        await events.waitFor<PublisherDataChannelStateUpdatedEvent>(
          filter: (event) => event.type == reliability,
          duration: connectOptions.timeouts.connection,
        );
      }
    }

    // chose data channel
    final rtc.RTCDataChannel? channel = _publisherDataChannel(reliability);

    if (channel == null) {
      throw UnexpectedStateException(
          'Data channel for ${packet.kind.toSDKType()} is null');
    }

    logger.fine('sendDataPacket(label:${channel.label})');
    await channel.send(message);
  }

  Future<void> _configurePeerConnections(
      {required lk_models.ClientConfigSetting forceRelay,
      required List<RTCIceServer> serverProvidedIceServers}) async {
    if (publisher != null || subscriber != null) {
      logger.warning('Already configured');
      return;
    }

    // RTCConfiguration? config;
    RTCConfiguration rtcConfiguration = connectOptions.rtcConfiguration;

    // The server provided iceServers are only used if
    // the client's iceServers are not set.
    if (rtcConfiguration.iceServers == null &&
        serverProvidedIceServers.isNotEmpty) {
      rtcConfiguration = connectOptions.rtcConfiguration
          .copyWith(iceServers: serverProvidedIceServers);
    }

    // set forceRelay
    if (rtcConfiguration.iceTransportPolicy == null) {
      switch (forceRelay) {
        case lk_models.ClientConfigSetting.ENABLED:
          rtcConfiguration = rtcConfiguration.copyWith(
            iceTransportPolicy: RTCIceTransportPolicy.relay,
          );
          break;
        case lk_models.ClientConfigSetting.DISABLED:
          rtcConfiguration = rtcConfiguration.copyWith(
            iceTransportPolicy: RTCIceTransportPolicy.all,
          );
          break;
        case lk_models.ClientConfigSetting.UNSET:
          // do nothing
          break;
      }
    }

    publisher = await Transport.create(_peerConnectionCreate,
        rtcConfig: rtcConfiguration, connectOptions: connectOptions);
    subscriber = await Transport.create(_peerConnectionCreate,
        rtcConfig: rtcConfiguration, connectOptions: connectOptions);

    publisher?.pc.onIceCandidate = (rtc.RTCIceCandidate candidate) {
      logger.fine('publisher onIceCandidate');
      signalClient.sendIceCandidate(candidate, lk_rtc.SignalTarget.PUBLISHER);
    };

    publisher?.pc.onIceConnectionState =
        (rtc.RTCIceConnectionState state) async {
      logger.fine('publisher iceConnectionState: $state');
      if (state == rtc.RTCIceConnectionState.RTCIceConnectionStateConnected) {
        await _handleGettingConnectedServerAddress(publisher!.pc);
      }
    };

    subscriber?.pc.onIceCandidate = (rtc.RTCIceCandidate candidate) {
      logger.fine('subscriber onIceCandidate');
      signalClient.sendIceCandidate(candidate, lk_rtc.SignalTarget.SUBSCRIBER);
    };

    subscriber?.pc.onIceConnectionState =
        (rtc.RTCIceConnectionState state) async {
      logger.fine('subscriber iceConnectionState: $state');
      if (state == rtc.RTCIceConnectionState.RTCIceConnectionStateConnected) {
        await _handleGettingConnectedServerAddress(subscriber!.pc);
      }
    };

    publisher?.onOffer = (offer) {
      logger.fine('publisher onOffer');
      signalClient.sendOffer(offer);
    };

    // in subscriber primary mode, server side opens sub data channels.
    if (_subscriberPrimary) {
      subscriber?.pc.onDataChannel = _onDataChannel;
    }

    subscriber?.pc.onConnectionState =
        (state) => events.emit(EngineSubscriberPeerStateUpdatedEvent(
              state: state,
              isPrimary: _subscriberPrimary,
            ));

    publisher?.pc.onConnectionState =
        (state) => events.emit(EnginePublisherPeerStateUpdatedEvent(
              state: state,
              isPrimary: !_subscriberPrimary,
            ));

    events.on<EnginePeerStateUpdatedEvent>((event) {
      if (event.state.isDisconnectedOrFailed()) {
        handleDisconnect(DisconnectReason.reconnect);
      } else if (event.state.isClosed()) {
        handleDisconnect(DisconnectReason.peerConnectionClosed);
      }
    });

    subscriber?.pc.onTrack = (rtc.RTCTrackEvent event) {
      logger.fine('[WebRTC] pc.onTrack');

      final stream = event.streams.firstOrNull;
      if (stream == null) {
        // we need the stream to get the track's id
        logger.severe('received track without mediastream');
        return;
      }

      // doesn't get called reliably
      event.track.onEnded = () {
        logger.fine('[WebRTC] track.onEnded');
      };

      // doesn't get called reliably
      stream.onRemoveTrack = (_) {
        logger.fine('[WebRTC] stream.onRemoveTrack');
      };

      if (connectionState == ConnectionState.reconnecting ||
          connectionState == ConnectionState.connecting) {
        final track = event.track;
        final receiver = event.receiver;
        events.on<EngineConnectionStateUpdatedEvent>((event) async {
          Timer(const Duration(milliseconds: 10), () {
            events.emit(EngineTrackAddedEvent(
              track: track,
              stream: stream,
              receiver: receiver,
            ));
          });
        });
        return;
      }

      if (connectionState == ConnectionState.disconnected) {
        logger.warning('skipping incoming track after Room disconnected');
        return;
      }

      events.emit(EngineTrackAddedEvent(
        track: event.track,
        stream: stream,
        receiver: event.receiver,
      ));
    };

    // doesn't get called reliably, doesn't work on mac
    subscriber?.pc.onRemoveTrack =
        (rtc.MediaStream stream, rtc.MediaStreamTrack track) {
      logger.fine('[WebRTC] ${track.id} pc.onRemoveTrack');
    };

    // also handle messages over the pub channel, for backwards compatibility
    try {
      final lossyInit = rtc.RTCDataChannelInit()
        ..binaryType = 'binary'
        ..ordered = true
        ..maxRetransmits = 0;
      _lossyDCPub =
          await publisher?.pc.createDataChannel(_lossyDCLabel, lossyInit);
      _lossyDCPub?.onMessage = _onDCMessage;
      _lossyDCPub?.stateChangeStream
          .listen((state) => events.emit(PublisherDataChannelStateUpdatedEvent(
                isPrimary: !_subscriberPrimary,
                state: state,
                type: Reliability.lossy,
              )));
      // _onDCStateUpdated(Reliability.lossy, state)
    } catch (_) {
      logger.severe('[$objectId] createDataChannel() did throw $_');
    }

    try {
      final reliableInit = rtc.RTCDataChannelInit()
        ..binaryType = 'binary'
        ..ordered = true;
      _reliableDCPub =
          await publisher?.pc.createDataChannel(_reliableDCLabel, reliableInit);
      _reliableDCPub?.onMessage = _onDCMessage;
      _reliableDCPub?.stateChangeStream
          .listen((state) => events.emit(PublisherDataChannelStateUpdatedEvent(
                isPrimary: !_subscriberPrimary,
                state: state,
                type: Reliability.reliable,
              )));
    } catch (_) {
      logger.severe('[$objectId] createDataChannel() did throw $_');
    }
  }

  void _onDataChannel(rtc.RTCDataChannel dc) {
    switch (dc.label) {
      case _reliableDCLabel:
        logger.fine('Server opened DC label: ${dc.label}');
        _reliableDCSub = dc;
        _reliableDCSub?.onMessage = _onDCMessage;
        _reliableDCSub?.stateChangeStream.listen((state) =>
            _reliableDCPub?.stateChangeStream.listen(
                (state) => events.emit(SubscriberDataChannelStateUpdatedEvent(
                      isPrimary: _subscriberPrimary,
                      state: state,
                      type: Reliability.reliable,
                    ))));
        break;
      case _lossyDCLabel:
        logger.fine('Server opened DC label: ${dc.label}');
        _lossyDCSub = dc;
        _lossyDCSub?.onMessage = _onDCMessage;
        _lossyDCSub?.stateChangeStream.listen((event) =>
            _reliableDCPub?.stateChangeStream.listen(
                (state) => events.emit(SubscriberDataChannelStateUpdatedEvent(
                      isPrimary: _subscriberPrimary,
                      state: state,
                      type: Reliability.lossy,
                    ))));
        break;
      default:
        logger.warning('Unknown DC label: ${dc.label}');
        break;
    }
  }

  Future<void> _handleGettingConnectedServerAddress(
      rtc.RTCPeerConnection pc) async {
    try {
      var remoteAddress = await getConnectedAddress(publisher!.pc);
      logger.fine('Connected address: $remoteAddress');
      if (_connectedServerAddress == null ||
          _connectedServerAddress != remoteAddress) {
        _connectedServerAddress = remoteAddress;
      }
    } catch (e) {
      logger.warning('could not get connected server address ${e.toString()}');
    }
  }

  void _onDCMessage(rtc.RTCDataChannelMessage message) {
    // always expect binary
    if (!message.isBinary) {
      logger.warning('Data message is not binary');
      return;
    }

    final dp = lk_models.DataPacket.fromBuffer(message.binary);
    if (dp.whichValue() == lk_models.DataPacket_Value.speaker) {
      // Speaker packet
      events.emit(EngineActiveSpeakersUpdateEvent(
        speakers: dp.speaker.speakers,
      ));
    } else if (dp.whichValue() == lk_models.DataPacket_Value.user) {
      // User packet
      events.emit(EngineDataPacketReceivedEvent(
        packet: dp.user,
        kind: dp.kind,
      ));
    }
  }

  Future<void> handleDisconnect(DisconnectReason reason) async {
    logger
        .info('onDisconnected state:${_connectionState} reason:${reason.name}');

    if (!fullReconnect) {
      fullReconnect = _clientConfiguration?.resumeConnection ==
              lk_models.ClientConfigSetting.DISABLED ||
          [
            DisconnectReason.leaveReconnect,
            DisconnectReason.negotiationFailed,
            DisconnectReason.peerConnectionClosed
          ].contains(reason);
    }

    if (_connectionState == ConnectionState.reconnecting && !fullReconnect) {
      logger.fine('[$objectId] Already reconnecting...');
      return;
    }

    if (_connectionState == ConnectionState.disconnected) {
      logger.fine('[$objectId] Already disconnected... $reason');
      return;
    }

    logger.fine('[$runtimeType] Should attempt reconnect sequence...');
    if (fullReconnect) {
      await restartConnection();
    } else {
      await resumeConnection();
    }
  }

  Future<void> resumeConnection() async {
    if (_connectionState == ConnectionState.disconnected) {
      logger.fine('resumeConnection: Already closed.');
      return;
    }

    if (url == null || token == null) {
      throw ConnectException(
          'could not resume connection without url and token');
    }

    Future<void> sequence() async {
      await signalClient.connect(
        url!,
        token!,
        connectOptions: connectOptions,
        roomOptions: roomOptions,
        reconnect: true,
        sid: _participantSid,
      );

      if (publisher == null || subscriber == null) {
        throw UnexpectedStateException('publisher or subscribers is null');
      }

      subscriber!.restartingIce = true;

      if (_hasPublished) {
        logger.fine('resumeConnection: negotiating publisher...');
        await publisher!.createAndSendOffer(const RTCOfferOptions(
          iceRestart: true,
        ));
      }

      final iceConnected = primary?.pc.connectionState?.isConnected() ?? false;

      logger.fine('resumeConnection: iceConnected: $iceConnected');

      if (!iceConnected) {
        logger.fine('resumeConnection: Waiting for primary to connect...');

        await events.waitFor<EnginePeerStateUpdatedEvent>(
          filter: (event) => event.isPrimary && event.state.isConnected(),
          duration: connectOptions.timeouts.iceRestart,
          onTimeout: () => throw ConnectException(),
        );
      }
    }

    try {
      _updateConnectionState(ConnectionState.reconnecting);
      await Utils.retry<void>(
        (tries, errors) {
          logger.fine('Retrying connect sequence remaining ${tries} tries...');
          return sequence();
        },
        retryCondition: (_, __) =>
            _connectionState == ConnectionState.reconnecting,
        tries: 3,
        delay: const Duration(seconds: 3),
      );
      _updateConnectionState(ConnectionState.connected);
    } catch (error) {
      _updateConnectionState(ConnectionState.disconnected);
    }
  }

  Future<void> restartConnection([bool signalEvents = false]) async {
    await publisher?.dispose();
    publisher = null;
    _hasPublished = false;

    await subscriber?.dispose();
    subscriber = null;

    _reliableDCSub = null;
    _reliableDCPub = null;
    _lossyDCSub = null;
    _lossyDCPub = null;
    await _signalListener.cancelAll();
    _signalListener = signalClient.createListener(synchronized: true);
    _setUpSignalListeners();

    await connect(
      url!,
      token!,
      roomOptions: roomOptions,
      connectOptions: connectOptions,
      fastConnectOptions: fastConnectOptions,
    );

    fullReconnect = false;
  }

  @internal
  void sendSyncState({
    required lk_rtc.UpdateSubscription subscription,
    required Iterable<lk_rtc.TrackPublishedResponse>? publishTracks,
  }) async {
    final answer = (await subscriber?.pc.getLocalDescription())?.toPBType();
    signalClient.sendSyncState(
      answer: answer,
      subscription: subscription,
      publishTracks: publishTracks,
      dataChannelInfo: dataChannelInfo(),
    );
  }

  void _setUpEngineListeners() =>
      events.on<EngineConnectionStateUpdatedEvent>((event) async {
        if (event.didReconnect) {
          // send queued requests if engine re-connected
          signalClient.sendQueuedRequests();
        }
      });

  void _setUpSignalListeners() => _signalListener
    ..on<SignalJoinResponseEvent>((event) async {
      // create peer connections
      _subscriberPrimary = event.response.subscriberPrimary;
      _participantSid = event.response.participant.sid;
      var iceServersFromServer =
          event.response.iceServers.map((e) => e.toSDKType()).toList();

      if (iceServersFromServer.isNotEmpty) {
        _serverProvidedIceServers = iceServersFromServer;
      }

      _clientConfiguration = event.response.clientConfiguration;

      logger.fine('onConnected subscriberPrimary: ${_subscriberPrimary}, '
          'serverVersion: ${event.response.serverVersion}, '
          'iceServers: ${event.response.iceServers}, '
          'forceRelay: $event.response.clientConfiguration.forceRelay');

      await _configurePeerConnections(
          forceRelay: event.response.clientConfiguration.forceRelay,
          serverProvidedIceServers: _serverProvidedIceServers);

      if (!_subscriberPrimary) {
        // for subscriberPrimary, we negotiate when necessary (lazy)
        await negotiate();
      }
    })
    ..on<SignalConnectionStateUpdatedEvent>((event) async {
      if (event.newState == ConnectionState.disconnected) {
        await handleDisconnect(DisconnectReason.signal);
      }
    })
    ..on<SignalOfferEvent>((event) async {
      if (subscriber == null) {
        logger.warning('[$objectId] subscriber is null');
        return;
      }

      logger.fine('[$objectId] Received server offer(type: ${event.sd.type}, '
          '${subscriber!.pc.signalingState})');
      logger.finer('sdp: ${event.sd.sdp}');

      await subscriber!.setRemoteDescription(event.sd);

      try {
        final answer = await subscriber!.pc.createAnswer();
        logger.fine('Created answer');
        logger.finer('sdp: ${answer.sdp}');
        await subscriber!.pc.setLocalDescription(answer);
        signalClient.sendAnswer(answer);
      } catch (_) {
        logger.severe('[$objectId] Failed to createAnswer()');
      }
    })
    ..on<SignalAnswerEvent>((event) async {
      if (publisher == null) {
        return;
      }
      logger.fine('received answer (type: ${event.sd.type})');
      logger.finer('sdp: ${event.sd.sdp}');
      await publisher!.setRemoteDescription(event.sd);
    })
    ..on<SignalTrickleEvent>((event) async {
      if (publisher == null || subscriber == null) {
        logger.warning(
            'Received ${SignalTrickleEvent} but publisher or subscriber was null.');
        return;
      }
      logger.fine('got ICE candidate from peer');
      if (event.target == lk_rtc.SignalTarget.SUBSCRIBER) {
        await subscriber!.addIceCandidate(event.candidate);
      } else if (event.target == lk_rtc.SignalTarget.PUBLISHER) {
        await publisher!.addIceCandidate(event.candidate);
      }
    })
    ..on<SignalTokenUpdatedEvent>((event) {
      logger.fine('Server refreshed the token');
      token = event.token;
    })
    ..on<SignalLeaveEvent>((event) async {
      if (event.canReconnect) {
        fullReconnect = true;
        // reconnect immediately instead of waiting for next attempt
        _connectionState = ConnectionState.reconnecting;
        await handleDisconnect(DisconnectReason.leaveReconnect);
      } else {
        if (_connectionState == ConnectionState.reconnecting) {
          logger.warning(
              '[Signal] Received Leave while engine is reconnecting, ignoring...');
          return;
        }
        _updateConnectionState(ConnectionState.disconnected);
        await cleanUp();
      }
    });
}

extension EnginePrivateMethods on Engine {
  // publisher data channel for the reliability
  rtc.RTCDataChannel? _publisherDataChannel(Reliability reliability) =>
      reliability == Reliability.reliable ? _reliableDCPub : _lossyDCPub;

  // state of the publisher data channel
  rtc.RTCDataChannelState _publisherDataChannelState(Reliability reliability) =>
      _publisherDataChannel(reliability)?.state ??
      rtc.RTCDataChannelState.RTCDataChannelClosed;

  void _updateConnectionState(ConnectionState newValue) {
    if (_connectionState == newValue) return;

    logger.fine('Engine ConnectionState '
        '${_connectionState.name} -> ${newValue.name}');

    bool didReconnect = _connectionState == ConnectionState.reconnecting &&
        newValue == ConnectionState.connected;
    // update internal value
    final oldState = _connectionState;
    _connectionState = newValue;

    events.emit(EngineConnectionStateUpdatedEvent(
      newState: _connectionState,
      oldState: oldState,
      didReconnect: didReconnect,
      fullReconnect: fullReconnect,
    ));
  }
}

extension EngineInternalMethods on Engine {
  @internal
  List<lk_rtc.DataChannelInfo> dataChannelInfo() =>
      [_reliableDCPub, _lossyDCPub]
          .whereNotNull()
          .where((e) => e.id != -1)
          .map((e) => e.toLKInfoType())
          .toList();
}

Future<String?> getConnectedAddress(rtc.RTCPeerConnection pc) async {
  var selectedCandidatePairId = '';
  final candidatePairs = <String, rtc.StatsReport>{};
  // id -> candidate ip
  final candidates = <String, String>{};
  final List<rtc.StatsReport> stats = await pc.getStats();
  for (var v in stats) {
    switch (v.type) {
      case 'transport':
        selectedCandidatePairId = v.values['selectedCandidatePairId'] as String;
        break;
      case 'candidate-pair':
        if (selectedCandidatePairId == '') {
          if (v.values['selected'] != null && v.values['selected'] == true) {
            selectedCandidatePairId = v.id;
          }
        }
        candidatePairs[v.id] = v;
        break;
      case 'remote-candidate':
        var address = '';
        var port = 0;
        if (v.values['address'] != null) {
          address = v.values['address'] as String;
        }
        if (v.values['port'] != null) {
          port = v.values['port'] as int;
        }
        candidates[v.id] = '$address:$port';
        break;
      default:
    }
  }

  if (selectedCandidatePairId == '') {
    return null;
  }

  final report = candidatePairs[selectedCandidatePairId];
  if (report == null) {
    return null;
  }
  final selectedID = report.values['remoteCandidateId'] as String;
  return candidates[selectedID];
}
