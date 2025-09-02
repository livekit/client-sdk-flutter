// Copyright 2025 LiveKit, Inc.
// Lightweight pre-connect audio buffer (scaffold). Captures bytes externally
// and uploads via byte stream once an agent is ready.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:uuid/uuid.dart';

import '../support/completer_manager.dart';
import '../support/native.dart';

typedef PreConnectOnError = void Function(Object error);

class PreConnectAudioBuffer {
  static const String dataTopic = 'lk.agent.pre-connect-audio-buffer';

  static const int defaultMaxSize = 10 * 1024 * 1024; // 10MB
  static const int defaultSampleRate = 24000; // Hz

  // Reference to the room
  final Room _room;

  // Internal states
  bool _isRecording = false;
  bool _isSent = false;
  String? _rendererId;

  LocalAudioTrack? _localTrack;
  EventChannel? _eventChannel;
  StreamSubscription? _streamSubscription;

  final PreConnectOnError? _onError;
  final int _sampleRate;

  final BytesBuilder _bytes = BytesBuilder(copy: false);
  Timer? _timeoutTimer;
  CancelListenFunc? _participantStateListener;
  CancelListenFunc? _remoteSubscribedListener;

  final CompleterManager<void> _agentReadyManager = CompleterManager<void>();

  PreConnectAudioBuffer(
    this._room, {
    PreConnectOnError? onError,
    int sampleRate = defaultSampleRate,
  })  : _onError = onError,
        _sampleRate = sampleRate;

  // Getters
  bool get isRecording => _isRecording;
  int get bufferedSize => _bytes.length;

  /// Future that completes when an agent is ready.
  Future<void> get agentReadyFuture => _agentReadyManager.future;

  Future<void> startRecording({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_isRecording) {
      logger.warning('Already recording');
      return;
    }
    _isRecording = true;

    // Set up timeout for agent readiness
    _agentReadyManager.setTimer(timeout, timeoutReason: 'Agent did not become ready within timeout');

    _localTrack = await LocalAudioTrack.create();
    print('localTrack: ${_localTrack!.mediaStreamTrack.id}');

    final rendererId = Uuid().v4();
    logger.info('Starting audio renderer with rendererId: $rendererId');

    final result = await Native.startAudioRenderer(
      trackId: _localTrack!.mediaStreamTrack.id!,
      rendererId: rendererId,
      format: {
        'commonFormat': 'int16',
        'sampleRate': _sampleRate,
        'channels': 1,
      },
    );

    _rendererId = rendererId;

    logger.info('startAudioRenderer result: $result');

    _eventChannel = EventChannel('io.livekit.audio.renderer/channel-$rendererId');
    _streamSubscription = _eventChannel?.receiveBroadcastStream().listen((event) {
      try {
        final dataChannels = event['data'] as List<dynamic>;
        final monoData = dataChannels[0].cast<int>();
        // Convert Int16 values to bytes using typed data view
        final int16List = Int16List.fromList(monoData);
        _bytes.add(int16List.buffer.asUint8List());
      } catch (e) {
        logger.warning('Error parsing event: $e');
      }
    });

    // Listen for agent readiness; when active, attempt to send buffer once.
    _participantStateListener = _room.events.on<ParticipantStateUpdatedEvent>((event) async {
      // logger.info('[Preconnect audio] State event ${event}');

      if (event.participant.kind == ParticipantKind.AGENT && event.state == ParticipantState.active) {
        logger.info('[Preconnect audio] Agent is active: ${event.participant.identity}');
        try {
          await sendAudioData(agents: [event.participant.identity]);
          _agentReadyManager.complete();
        } catch (e) {
          _agentReadyManager.completeError(e);
          _onError?.call(e);
        } finally {
          // await reset();
        }
      }
    });

    _remoteSubscribedListener = _room.events.on<LocalTrackSubscribedEvent>((event) async {
      logger.info('[Preconnect audio] Remote track subscribed: ${event.trackSid}');
      await stopRecording();
    });
  }

  Future<void> stopRecording() async {
    if (!_isRecording) {
      logger.warning('Not recording');
      return;
    }
    _isRecording = false;

    // Cancel the stream subscription.
    await _streamSubscription?.cancel();
    _streamSubscription = null;

    // Dispose the event channel.
    _eventChannel = null;

    final rendererId = _rendererId;
    if (rendererId == null) {
      logger.warning('No rendererId');
      return;
    }

    await Native.stopAudioRenderer(
      rendererId: rendererId,
    );

    _rendererId = null;

    // Complete agent ready future if not already completed
    _agentReadyManager.complete();

    logger.info('[Preconnect audio] stopped recording');
  }

  // Clean-up & reset for re-use
  Future<void> reset() async {
    await stopRecording();
    _timeoutTimer?.cancel();
    _participantStateListener?.call();
    _participantStateListener = null;
    _remoteSubscribedListener?.call();
    _remoteSubscribedListener = null;
    _bytes.clear();
    _localTrack = null;
    _agentReadyManager.reset();

    logger.info('[Preconnect audio] reset');
  }

  /// Dispose the audio buffer and clean up all resources.
  void dispose() {
    _agentReadyManager.dispose();
    _timeoutTimer?.cancel();
    _participantStateListener?.call();
    _remoteSubscribedListener?.call();
  }

  Future<void> sendAudioData({
    required List<String> agents,
    String topic = dataTopic,
  }) async {
    if (_isSent) return;
    if (agents.isEmpty) return;

    logger.info('[Preconnect audio] sending audio data to ${agents.map((e) => e).join(', ')} agent(s)');

    final data = _bytes.takeBytes();
    logger.info('[Preconnect audio] data.length: ${data.length}, bytes.length: ${_bytes.length}');

    _isSent = true;

    final streamOptions = StreamBytesOptions(
      topic: topic,
      attributes: {
        'sampleRate': _sampleRate.toString(),
        'channels': '1',
        'trackId': _localTrack!.mediaStreamTrack.id!,
      },
      destinationIdentities: agents,
    );

    logger.info('[Preconnect audio] streamOptions: $streamOptions');

    final writer = await _room.localParticipant!.streamBytes(streamOptions);
    await writer.write(data);
    await writer.close();

    // Compute seconds of audio data sent
    final int bytesPerSample = 2; // Assuming 16-bit audio
    final int totalSamples = data.length ~/ bytesPerSample;
    final double secondsOfAudio = totalSamples / _sampleRate!;

    logger.info(
        '[Preconnect audio] sent ${(data.length / 1024).toStringAsFixed(1)}KB of audio (${secondsOfAudio.toStringAsFixed(2)} seconds) to ${agents} agent(s)');
  }
}
