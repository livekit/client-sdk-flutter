import 'dart:async';
import 'dart:convert';

import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;

class _StubLocalParticipant extends Fake implements LocalParticipant {
  _StubLocalParticipant(this.identity);

  @override
  final String identity;
}

class _StubRoom extends Fake implements Room {
  _StubRoom({required String localIdentity}) : localParticipant = _StubLocalParticipant(localIdentity);

  final Map<String, TextStreamHandler> _handlers = {};

  @override
  final LocalParticipant? localParticipant;

  void register(String topic, TextStreamHandler callback) {
    _handlers[topic] = callback;
  }

  void unregister(String topic) {
    _handlers.remove(topic);
  }

  @override
  Map<String, TextStreamHandler> get textStreamHandlers => _handlers;
}

lk_models.DataStream_Chunk _chunk(String streamId, String text) {
  return lk_models.DataStream_Chunk(
    streamId: streamId,
    chunkIndex: fixnum.Int64(0),
    content: utf8.encode(text),
    version: 0,
  );
}

TextStreamReader _reader({
  required String streamId,
  required String segmentId,
  required bool isFinal,
  required String participantIdentity,
}) {
  final info = TextStreamInfo(
    id: streamId,
    mimeType: 'text/plain',
    topic: 'lk.transcription',
    timestamp: DateTime.timestamp().millisecondsSinceEpoch,
    size: 0,
    attributes: {
      'lk.segment_id': segmentId,
      'lk.transcription_final': isFinal ? 'true' : 'false',
    },
    sendingParticipantIdentity: participantIdentity,
  );

  final controller = DataStreamController<lk_models.DataStream_Chunk>(
    info: info,
    streamController: StreamController<lk_models.DataStream_Chunk>(),
    startTime: DateTime.timestamp().millisecondsSinceEpoch,
  );

  return TextStreamReader(info, controller, null);
}

TextStreamReader _readerWithoutSegmentId({
  required String streamId,
  required bool isFinal,
  required String participantIdentity,
}) {
  final info = TextStreamInfo(
    id: streamId,
    mimeType: 'text/plain',
    topic: 'lk.transcription',
    timestamp: DateTime.timestamp().millisecondsSinceEpoch,
    size: 0,
    attributes: {
      'lk.transcription_final': isFinal ? 'true' : 'false',
    },
    sendingParticipantIdentity: participantIdentity,
  );

  final controller = DataStreamController<lk_models.DataStream_Chunk>(
    info: info,
    streamController: StreamController<lk_models.DataStream_Chunk>(),
    startTime: DateTime.timestamp().millisecondsSinceEpoch,
  );

  return TextStreamReader(info, controller, null);
}

void main() {
  group('TranscriptionStreamReceiver', () {
    test('aggregates agent and user transcripts with segment replacement', () async {
      final room = _StubRoom(localIdentity: 'local');
      final receiver = TranscriptionStreamReceiver(
        room: room,
        registerHandler: room.register,
        unregisterHandler: room.unregister,
      );

      final messages = <ReceivedMessage>[];
      final subscription = receiver.messages().listen(messages.add);

      final handler = room.textStreamHandlers['lk.transcription'];
      expect(handler, isNotNull);

      // Agent sends partial, then final replacement for same segment.
      final agentReader1 = _reader(streamId: 's1', segmentId: 'seg-1', isFinal: false, participantIdentity: 'agent-1');
      handler!(agentReader1, 'agent-1');
      agentReader1.reader!.write(_chunk('s1', 'Hello'));

      final agentReader2 = _reader(streamId: 's2', segmentId: 'seg-1', isFinal: true, participantIdentity: 'agent-1');
      handler(agentReader2, 'agent-1');
      agentReader2.reader!.write(_chunk('s2', 'Hello world'));

      // Local participant transcript should be classified as user transcript.
      final userReader = _reader(streamId: 's3', segmentId: 'seg-2', isFinal: true, participantIdentity: 'local');
      handler(userReader, 'local');
      userReader.reader!.write(_chunk('s3', 'User said hi'));

      // Allow stream microtasks to flush.
      await Future<void>.delayed(Duration.zero);

      await subscription.cancel();

      expect(messages.length, 3);
      expect(messages[0].content, isA<AgentTranscript>());
      expect((messages[0].content as AgentTranscript).text, 'Hello');

      expect(messages[1].content, isA<AgentTranscript>());
      expect((messages[1].content as AgentTranscript).text, 'Hello world');

      expect(messages[2].content, isA<UserTranscript>());
      expect((messages[2].content as UserTranscript).text, 'User said hi');
    });

    test('cleans up previous partials per participant and handles missing segment id', () async {
      final room = _StubRoom(localIdentity: 'local');
      final receiver = TranscriptionStreamReceiver(
        room: room,
        registerHandler: room.register,
        unregisterHandler: room.unregister,
      );

      final messages = <ReceivedMessage>[];
      final errors = <Object>[];
      final subscription = receiver.messages().listen(messages.add, onError: errors.add);

      final handler = room.textStreamHandlers['lk.transcription'];
      expect(handler, isNotNull);

      // Participant A starts seg-A then seg-B; seg-A should be cleaned up once seg-B arrives.
      final readerA1 = _reader(streamId: 'a1', segmentId: 'seg-A', isFinal: false, participantIdentity: 'agent-A');
      handler!(readerA1, 'agent-A');
      readerA1.reader!.write(_chunk('a1', 'Partial A'));

      final readerA2 = _reader(streamId: 'a2', segmentId: 'seg-B', isFinal: true, participantIdentity: 'agent-A');
      handler(readerA2, 'agent-A');
      readerA2.reader!.write(_chunk('a2', 'Final B'));

      // Participant B sends without segment id; fallback to stream id.
      final readerB = _readerWithoutSegmentId(streamId: 'b1', isFinal: true, participantIdentity: 'agent-B');
      handler(readerB, 'agent-B');
      readerB.reader!.write(_chunk('b1', 'No segment id'));

      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(errors, isEmpty);
      expect(messages.length, 3);
      expect(messages.where((m) => m.id == 'seg-A').length, 1); // received partial before cleanup

      // seg-B final, seg-A partial should have been removed.
      expect(messages.where((m) => m.id == 'seg-B').length, 1);
      final segB = messages.firstWhere((m) => m.id == 'seg-B');
      expect(segB.content, isA<AgentTranscript>());
      expect((segB.content as AgentTranscript).text, 'Final B');

      // Stream id used when segment id missing.
      final b1 = messages.firstWhere((m) => m.id == 'b1');
      expect((b1.content as AgentTranscript).text, 'No segment id');
    });
  });
}
