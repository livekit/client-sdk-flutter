// Copyright 2025 LiveKit, Inc.
// Lightweight pre-connect audio buffer (scaffold). Captures bytes externally
// and uploads via byte stream once an agent is ready.

import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:uuid/uuid.dart';

import '../support/native.dart';

typedef PreConnectOnError = void Function(Object error);

class AudioFrame {
  final List<Int16List> data;
  final int sampleRate;
  final int channelCount;
  final int frameLength;
  final String format;

  AudioFrame({
    required this.data,
    required this.sampleRate,
    required this.channelCount,
    required this.frameLength,
    required this.format,
  });

  factory AudioFrame.fromMap(Map<String, dynamic> map) => AudioFrame(
        data: (map['data'] as List<dynamic>)
            .map<Int16List>((channel) => (channel as List).map<int>((e) => e as int).toList() as Int16List)
            .toList(),
        sampleRate: (map['sampleRate'] as int),
        channelCount: (map['channelCount'] as int),
        frameLength: (map['frameLength'] as int),
        format: map['format'] as String,
      );
}

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

  PreConnectAudioBuffer(
    this._room, {
    PreConnectOnError? onError,
    int sampleRate = defaultSampleRate,
  })  : _onError = onError,
        _sampleRate = sampleRate;

  // Getters
  bool get isRecording => _isRecording;
  int get bufferedSize => _bytes.length;

  Future<void> startRecording({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_isRecording) {
      logger.warning('Already recording');
      return;
    }
    _isRecording = true;

    _localTrack = await LocalAudioTrack.create();
    print('localTrack: ${_localTrack!.mediaStreamTrack.id}');

    final rendererId = Uuid().v4();
    logger.info('Starting audio renderer with rendererId: $rendererId');

    final result = await Native.startAudioRenderer(
      trackId: _localTrack!.mediaStreamTrack.id!,
      rendererId: rendererId,
    );

    _rendererId = rendererId;

    logger.info('startAudioRenderer result: $result');

    _eventChannel = EventChannel('io.livekit.audio.renderer/channel-$rendererId');
    _streamSubscription = _eventChannel?.receiveBroadcastStream().listen((event) {
      try {
        // logger.info('event: $event');
        // {sampleRate: 32000, format: int16, frameLength: 320, channelCount: 1}
        final dataChannels = event['data'] as List<dynamic>;
        final monoData = dataChannels[0].cast<int>();
        _bytes.add(monoData);
        log('bufferedSize: ${_bytes.length}');
      } catch (e) {
        logger.warning('Error parsing event: $e');
      }
    });

    // Listen for agent readiness; when active, attempt to send buffer once.
    _participantStateListener = _room.events.on<ParticipantStateUpdatedEvent>((event) async {
      if (event.participant.kind == ParticipantKind.AGENT && event.state == ParticipantState.active) {
        logger.info('Agent is active: ${event.participant.identity}');
        try {
          await sendAudioData(agents: [event.participant.identity]);
        } catch (e) {
          _onError?.call(e);
        } finally {
          await reset();
        }
      }
    });

    _remoteSubscribedListener = _room.events.on<LocalTrackSubscribedEvent>((event) async {
      logger.info('Remote track subscribed: ${event.trackSid}');
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
  }

  Future<void> sendAudioData({
    required List<String> agents,
    String topic = dataTopic,
  }) async {
    if (_isSent) return;
    if (agents.isEmpty) return;

    final data = _bytes.takeBytes();
    if (data.length <= 1024) {
      throw StateError('Audio data too small to send (${data.length} bytes)');
    }
    _isSent = true;

    final streamOptions = StreamBytesOptions(
      topic: topic,
      attributes: {
        'sampleRate': '$_sampleRate',
        'channels': '1',
        'trackId': _localTrack!.mediaStreamTrack.id!,
      },
      destinationIdentities: agents,
    );

    final writer = await _room.localParticipant!.streamBytes(streamOptions);
    await writer.write(data);
    await writer.close();
    logger.info('[preconnect] sent ${(data.length / 1024).toStringAsFixed(1)}KB of audio to ${agents.length} agent(s)');
  }
}
