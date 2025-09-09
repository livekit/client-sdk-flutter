// Copyright 2025 LiveKit, Inc.
// Lightweight pre-connect audio buffer (scaffold). Captures bytes externally
// and uploads via byte stream once an agent is ready.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:uuid/uuid.dart';

import '../core/room.dart';
import '../events.dart';
import '../logger.dart';
import '../participant/local.dart';
import '../support/completer_manager.dart';
import '../support/native.dart';
import '../track/local/audio.dart';
import '../types/data_stream.dart';
import '../types/other.dart';
import '../types/participant_state.dart';

typedef PreConnectOnError = void Function(Object error);

class PreConnectAudioBuffer {
  static const String dataTopic = 'lk.agent.pre-connect-audio-buffer';

  static const int defaultMaxSize = 10 * 1024 * 1024; // 10MB
  static const int defaultSampleRate = 24000; // Hz
  static const int defaultChunkSize = 64 * 1024; // 64KB chunks for streaming

  // Reference to the room
  final Room _room;

  // Internal states
  bool _isRecording = false;
  bool _isBufferSent = false;
  String? _rendererId;

  LocalAudioTrack? _localTrack;
  EventChannel? _eventChannel;
  StreamSubscription? _streamSubscription;

  final PreConnectOnError? _onError;
  final int _requestSampleRate;
  int? _renderedSampleRate;

  final BytesBuilder _buffer = BytesBuilder(copy: false);
  Timer? _timeoutTimer;
  CancelListenFunc? _participantStateListener;

  final CompleterManager<void> _agentReadyManager = CompleterManager<void>();

  PreConnectAudioBuffer(
    this._room, {
    PreConnectOnError? onError,
    int sampleRate = defaultSampleRate,
  })  : _onError = onError,
        _requestSampleRate = sampleRate;

  // Getters
  bool get isRecording => _isRecording;
  int get bufferedSize => _buffer.length;
  LocalAudioTrack? get localTrack => _localTrack;

  Future<LocalTrackPublishedEvent>? _localTrackPublishedEvent;

  /// Future that completes when an agent is ready.
  Future<void> get agentReadyFuture => _agentReadyManager.future;

  Future<void> startRecording({
    Duration timeout = const Duration(seconds: 20),
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
        'sampleRate': _requestSampleRate,
        'channels': 1,
      },
    );

    await webrtc.NativeAudioManagement.startLocalRecording();

    _rendererId = rendererId;

    logger.info('startAudioRenderer result: $result');

    _eventChannel = EventChannel('io.livekit.audio.renderer/channel-$rendererId');
    _streamSubscription = _eventChannel?.receiveBroadcastStream().listen((event) {
      try {
        // Actual sample rate of the audio data, can differ from the request sample rate
        _renderedSampleRate = event['sampleRate'] as int;
        final dataChannels = event['data'] as List<dynamic>;
        final monoData = dataChannels[0].cast<int>();
        // Convert Int16 values to bytes using typed data view
        final int16List = Int16List.fromList(monoData);
        final bytes = int16List.buffer.asUint8List();
        _buffer.add(bytes);
      } catch (e) {
        logger.warning('[Preconnect audio] Error parsing event: $e');
      }
    });

    // Listen for agent readiness; when active, attempt to send buffer once.
    _participantStateListener = _room.events.on<ParticipantStateUpdatedEvent>(
        filter: (event) => event.participant.kind == ParticipantKind.AGENT && event.state == ParticipantState.active,
        (event) async {
      logger.info('[Preconnect audio] Agent is active: ${event.participant.identity}');
      try {
        await sendAudioData(agents: [event.participant.identity]);
        _agentReadyManager.complete();
      } catch (error) {
        _agentReadyManager.completeError(error);
        _onError?.call(error);
      }
    });

    _localTrackPublishedEvent = _room.events.waitFor<LocalTrackPublishedEvent>(
      duration: Duration(seconds: 10),
      filter: (event) => event.participant == _room.localParticipant,
    );

    // Emit the started event
    _room.events.emit(PreConnectAudioBufferStartedEvent(
      sampleRate: _requestSampleRate,
      timeout: timeout,
    ));
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
    if (rendererId != null) {
      await Native.stopAudioRenderer(
        rendererId: rendererId,
      );
    }

    _rendererId = null;

    // Complete agent ready future if not already completed
    _agentReadyManager.complete();

    // Emit the stopped event
    _room.events.emit(PreConnectAudioBufferStoppedEvent(
      bufferedSize: _buffer.length,
      isBufferSent: _isBufferSent,
    ));

    logger.info('[Preconnect audio] stopped recording');
  }

  // Clean-up & reset for re-use
  Future<void> reset() async {
    await stopRecording();
    _timeoutTimer?.cancel();
    _participantStateListener?.call();
    _participantStateListener = null;
    _buffer.clear();

    // Don't stop the local track - it will continue to be used by the Room
    _localTrack = null;

    _agentReadyManager.reset();
    _localTrackPublishedEvent = null;

    // Reset the _isSent flag to allow data sending on next use
    _isBufferSent = false;

    logger.info('[Preconnect audio] reset');
  }

  // Dispose the audio buffer and clean up all resources.
  Future<void> dispose() async {
    await reset();
    logger.info('[Preconnect audio] disposed');
  }

  Future<void> sendAudioData({
    required List<String> agents,
    String topic = dataTopic,
  }) async {
    if (_isBufferSent) return;
    if (agents.isEmpty) return;

    final sampleRate = _renderedSampleRate;
    if (sampleRate == null) {
      logger.severe('[Preconnect audio] renderedSampleRate is null');
      return;
    }

    // Wait for local track published event
    final localTrackPublishedEvent = await _localTrackPublishedEvent;
    logger.info('[Preconnect audio] localTrackPublishedEvent: $localTrackPublishedEvent');

    final localTrackSid = localTrackPublishedEvent?.publication.track?.sid;
    if (localTrackSid == null) {
      logger.severe('[Preconnect audio] localTrackPublishedEvent is null');
      return;
    }

    logger.info('[Preconnect audio] sending audio data to ${agents.map((e) => e).join(', ')} agent(s)');

    final data = _buffer.takeBytes();
    logger.info('[Preconnect audio] data.length: ${data.length}, bytes.length: ${_buffer.length}');

    _isBufferSent = true;

    final streamOptions = StreamBytesOptions(
      topic: topic,
      attributes: {
        'sampleRate': sampleRate.toString(),
        'channels': '1',
        'trackId': localTrackSid,
      },
      totalSize: data.length,
      destinationIdentities: agents,
    );

    logger.info('[Preconnect audio] streamOptions: $streamOptions');

    final writer = await _room.localParticipant!.streamBytes(streamOptions);
    await writer.write(data);
    await writer.close();

    // Compute seconds of audio data sent
    final int bytesPerSample = 2; // Assuming 16-bit audio
    final int totalSamples = data.length ~/ bytesPerSample;
    final double secondsOfAudio = totalSamples / sampleRate;

    logger.info(
        '[Preconnect audio] sent ${(data.length / 1024).toStringAsFixed(1)}KB of audio (${secondsOfAudio.toStringAsFixed(2)} seconds) to ${agents} agent(s)');
  }
}
