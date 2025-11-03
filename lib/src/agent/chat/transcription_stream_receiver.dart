// Copyright 2025 LiveKit, Inc.
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

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import '../../core/room.dart';
import '../../data_stream/stream_reader.dart';
import '../../logger.dart';
import '../../types/data_stream.dart';
import 'message.dart';
import 'message_receiver.dart';

/// Converts LiveKit transcription text streams into [ReceivedMessage]s.
///
/// Each stream corresponds to a single message (agent or user). The stream
/// yields textual updates which are aggregated until the message is finalized.
/// When a new message for the same participant arrives, previous partial
/// content is purged so that memory usage remains bounded.
class TranscriptionStreamReceiver implements MessageReceiver {
  TranscriptionStreamReceiver({
    required Room room,
    this.topic = 'lk.transcription',
  }) : _room = room;

  final Room _room;
  final String topic;

  StreamController<ReceivedMessage>? _controller;
  bool _registered = false;
  bool _controllerClosed = false;

  final Map<_PartialMessageId, _PartialMessage> _partialMessages = HashMap();

  @override
  Stream<ReceivedMessage> messages() {
    if (_controller != null) {
      return _controller!.stream;
    }

    _controller = StreamController<ReceivedMessage>.broadcast(
      onListen: _registerHandler,
      onCancel: _handleCancel,
    );
    _controllerClosed = false;
    return _controller!.stream;
  }

  void _registerHandler() {
    if (_registered) {
      return;
    }
    _registered = true;

    _room.registerTextStreamHandler(topic, (TextStreamReader reader, String participantIdentity) {
      reader.listen(
        (chunk) {
          final info = reader.info;
          if (info == null) {
            logger.warning('Received transcription chunk without metadata.');
            return;
          }

          if (chunk.content.isEmpty) {
            return;
          }

          final String text;
          try {
            text = utf8.decode(chunk.content);
          } catch (error) {
            logger.warning('Failed to decode transcription chunk: $error');
            return;
          }

          if (text.isEmpty) {
            return;
          }

          final message = _processIncoming(
            text,
            info,
            participantIdentity,
          );
          if (!_controller!.isClosed) {
            _controller!.add(message);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!_controller!.isClosed) {
            _controller!.addError(error, stackTrace);
          }
        },
        onDone: () {
          final info = reader.info;
          if (info != null) {
            final attributes = info.attributes;
            final segmentId = _extractSegmentId(attributes, info.id);
            final key = _PartialMessageId(segmentId: segmentId, participantId: participantIdentity);
            _partialMessages.remove(key);
          }
        },
        cancelOnError: true,
      );
    });
  }

  void _handleCancel() {
    if (_registered) {
      _room.unregisterTextStreamHandler(topic);
      _registered = false;
    }
    _partialMessages.clear();
    if (_controllerClosed) {
      return;
    }
    _controllerClosed = true;
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(controller.close());
    }
  }

  ReceivedMessage _processIncoming(
    String chunk,
    TextStreamInfo info,
    String participantIdentity,
  ) {
    final attributes = _TranscriptionAttributes.from(info.attributes);
    final segmentId = _extractSegmentId(info.attributes, info.id);
    final key = _PartialMessageId(segmentId: segmentId, participantId: participantIdentity);
    final currentStreamId = info.id;

    final DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(info.timestamp, isUtc: true).toLocal();

    final existing = _partialMessages[key];
    if (existing != null) {
      if (existing.streamId == currentStreamId) {
        existing.append(chunk);
      } else {
        existing.replace(chunk, currentStreamId);
      }
    } else {
      _partialMessages[key] = _PartialMessage(
        content: chunk,
        timestamp: timestamp,
        streamId: currentStreamId,
      );
      _cleanupPreviousTurn(participantIdentity, segmentId);
    }

    final currentPartial = _partialMessages[key];

    if (attributes.isFinal == true) {
      _partialMessages.remove(key);
    }

    final partial = attributes.isFinal == true ? currentPartial : _partialMessages[key];
    final displayContent = partial?.content ?? chunk;
    final displayTimestamp = partial?.timestamp ?? timestamp;
    final isLocalParticipant = _room.localParticipant?.identity == participantIdentity;

    final ReceivedMessageContent content =
        isLocalParticipant ? UserTranscript(displayContent) : AgentTranscript(displayContent);

    return ReceivedMessage(
      id: segmentId,
      timestamp: displayTimestamp,
      content: content,
    );
  }

  void _cleanupPreviousTurn(String participantId, String currentSegmentId) {
    final keysToRemove = _partialMessages.keys
        .where((key) => key.participantId == participantId && key.segmentId != currentSegmentId)
        .toList(growable: false);

    for (final key in keysToRemove) {
      _partialMessages.remove(key);
    }
  }

  String _extractSegmentId(Map<String, String> attributes, String fallback) {
    return attributes[_AttributeKeys.segmentId] ?? fallback;
  }

  @override
  Future<void> dispose() async {
    if (_registered) {
      _room.unregisterTextStreamHandler(topic);
      _registered = false;
    }
    _partialMessages.clear();
    if (!_controllerClosed) {
      _controllerClosed = true;
      final controller = _controller;
      _controller = null;
      if (controller != null) {
        await controller.close();
      }
    }
  }
}

class _PartialMessageId {
  _PartialMessageId({
    required this.segmentId,
    required this.participantId,
  });

  final String segmentId;
  final String participantId;

  @override
  bool operator ==(Object other) =>
      other is _PartialMessageId && other.segmentId == segmentId && other.participantId == participantId;

  @override
  int get hashCode => Object.hash(segmentId, participantId);
}

class _PartialMessage {
  _PartialMessage({
    required this.content,
    required this.timestamp,
    required this.streamId,
  });

  String content;
  DateTime timestamp;
  String streamId;

  void append(String chunk) {
    content += chunk;
  }

  void replace(String chunk, String newStreamId) {
    content = chunk;
    streamId = newStreamId;
  }
}

class _TranscriptionAttributes {
  _TranscriptionAttributes({
    required this.segmentId,
    required this.isFinal,
  });

  final String? segmentId;
  final bool? isFinal;

  static _TranscriptionAttributes from(Map<String, String> attributes) {
    return _TranscriptionAttributes(
      segmentId: attributes[_AttributeKeys.segmentId],
      isFinal: _parseBool(attributes[_AttributeKeys.transcriptionFinal]),
    );
  }

  static bool? _parseBool(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
    return null;
  }
}

class _AttributeKeys {
  static const segmentId = 'lk.segment_id';
  static const transcriptionFinal = 'lk.transcription_final';
}
