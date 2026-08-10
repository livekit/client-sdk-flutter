// Copyright 2026 LiveKit, Inc.
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
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart' show basename;
import 'package:uuid/uuid.dart';

import '../core/room.dart';
import '../e2ee/options.dart';
import '../internal/events.dart';
import '../logger.dart';
import '../options.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../types/data_stream.dart';
import '../types/other.dart';
import 'data_streams.dart';
import 'errors.dart';
import 'stream_reader.dart';
import 'stream_writer.dart';

DataStreams createDataStreams(Room room) => WebDataStreams(room);

/// The original pure-Dart data-stream implementation, retained for web.
///
/// `package:livekit_uniffi` ships a cdylib and cannot run in a browser, so web stays on the v1
/// wire format: no single-packet inline sends, no compression. That interoperates cleanly — web
/// advertises [ClientProtocolVersion.v1], and a v2 sender seeing a pre-v2 recipient falls back to
/// uncompressed multi-packet framing, which this code understands.
///
/// This is a move of the logic that previously lived in `Room` and `LocalParticipant`, unchanged
/// in behavior.
class WebDataStreams implements DataStreams {
  WebDataStreams(this._room);

  final Room _room;

  @override
  final Map<String, TextStreamHandler> textStreamHandlers = {};

  @override
  final Map<String, ByteStreamHandler> byteStreamHandlers = {};

  final Map<String, DataStreamController<lk_models.DataStream_Chunk>> _byteStreamControllers = {};
  final Map<String, DataStreamController<lk_models.DataStream_Chunk>> _textStreamControllers = {};

  /// Content bytes delivered so far per stream id, checked against
  /// [DataStreamOptions.maxPayloadByteLength].
  final Map<String, int> _receivedBytes = {};

  int get _maxPayloadByteLength => _room.connectOptions.dataStream.maxPayloadByteLength ?? kDefaultMaxPayloadByteLength;

  /// Whether a stream declaring [totalLength] is over the payload cap. Streams of unknown length
  /// pass here and are capped as their chunks arrive instead.
  bool _declaresOverCap(int? totalLength) => totalLength != null && totalLength > _maxPayloadByteLength;

  /// Fails an oversized stream's reader, after its handler has been given it.
  ///
  /// Matches the Rust core, which emits the stream-opened event before applying the cap: the
  /// consumer is told the stream failed rather than never hearing about it.
  Future<void> _failOverCap(
    DataStreamController<lk_models.DataStream_Chunk> controller,
    String streamId,
  ) async {
    logger.warning(
      'incoming stream $streamId exceeds the maxPayloadByteLength of $_maxPayloadByteLength',
    );
    controller.error(_payloadTooLarge());
    await controller.close();
    _forgetStream(streamId);
  }

  @override
  void registerTextStreamHandler(String topic, TextStreamHandler callback) => textStreamHandlers[topic] = callback;

  @override
  void unregisterTextStreamHandler(String topic) => textStreamHandlers.remove(topic);

  @override
  void registerByteStreamHandler(String topic, ByteStreamHandler callback) => byteStreamHandlers[topic] = callback;

  @override
  void unregisterByteStreamHandler(String topic) => byteStreamHandlers.remove(topic);

  // MARK: - Receive

  @override
  void handleIncomingPacket(lk_models.DataPacket packet, EncryptionType encryptionType) {
    if (packet.hasStreamHeader()) {
      unawaited(_handleStreamHeader(packet.streamHeader, packet.participantIdentity, encryptionType));
    } else if (packet.hasStreamChunk()) {
      _handleStreamChunk(packet.streamChunk, encryptionType);
    } else if (packet.hasStreamTrailer()) {
      unawaited(_handleStreamTrailer(packet.streamTrailer, encryptionType));
    }
  }

  Future<void> _handleStreamHeader(
    lk_models.DataStream_Header streamHeader,
    String participantIdentity,
    EncryptionType encryptionType,
  ) async {
    if (streamHeader.hasByteHeader()) {
      final streamHandlerCallback = byteStreamHandlers[streamHeader.topic];

      if (streamHandlerCallback == null) {
        logger.info('ignoring incoming byte stream due to no handler for topic ${streamHeader.topic}');
        return;
      }

      final info = ByteStreamInfo(
        id: streamHeader.streamId,
        name: streamHeader.byteHeader.name,
        mimeType: streamHeader.mimeType,
        size: streamHeader.hasTotalLength() ? streamHeader.totalLength.toInt() : 0,
        topic: streamHeader.topic,
        timestamp: streamHeader.timestamp.toInt(),
        attributes: streamHeader.attributes,
        sendingParticipantIdentity: participantIdentity,
        encryptionType: encryptionType,
      );

      if (_byteStreamControllers.containsKey(streamHeader.streamId)) {
        throw DataStreamError(
          message: 'A byte stream with id "${streamHeader.streamId}" is already open.',
          reason: DataStreamErrorReason.AlreadyOpened,
        );
      }

      final controller = DataStreamController<lk_models.DataStream_Chunk>(
        info: info,
        streamController: StreamController<lk_models.DataStream_Chunk>(),
        startTime: DateTime.timestamp().millisecondsSinceEpoch,
      );
      _byteStreamControllers[streamHeader.streamId] = controller;

      streamHandlerCallback(ByteStreamReader(info, controller, info.size), participantIdentity);
      if (_declaresOverCap(streamHeader.hasTotalLength() ? info.size : null)) {
        await _failOverCap(controller, streamHeader.streamId);
      }
      return;
    }

    if (streamHeader.hasTextHeader()) {
      final streamHandlerCallback = textStreamHandlers[streamHeader.topic];

      if (streamHandlerCallback == null) {
        logger.warning('ignoring incoming text stream due to no handler for topic ${streamHeader.topic}');
        return;
      }

      final info = TextStreamInfo(
        id: streamHeader.streamId,
        mimeType: streamHeader.mimeType,
        size: streamHeader.hasTotalLength() ? streamHeader.totalLength.toInt() : 0,
        topic: streamHeader.topic,
        timestamp: streamHeader.timestamp.toInt(),
        attributes: streamHeader.attributes,
        replyToStreamId: streamHeader.textHeader.replyToStreamId,
        attachedStreamIds: streamHeader.textHeader.attachedStreamIds,
        version: streamHeader.textHeader.version,
        generated: streamHeader.textHeader.generated,
        operationType: TextStreamOperationType.fromPBType(streamHeader.textHeader.operationType),
        sendingParticipantIdentity: participantIdentity,
        encryptionType: encryptionType,
      );

      if (_textStreamControllers.containsKey(streamHeader.streamId)) {
        throw DataStreamError(
          message: 'A text stream with id "${streamHeader.streamId}" is already open.',
          reason: DataStreamErrorReason.AlreadyOpened,
        );
      }

      final controller = DataStreamController<lk_models.DataStream_Chunk>(
        info: info,
        streamController: StreamController<lk_models.DataStream_Chunk>(),
        startTime: DateTime.timestamp().millisecondsSinceEpoch,
      );
      _textStreamControllers[streamHeader.streamId] = controller;

      streamHandlerCallback(TextStreamReader(info, controller, info.size), participantIdentity);
      if (_declaresOverCap(streamHeader.hasTotalLength() ? info.size : null)) {
        await _failOverCap(controller, streamHeader.streamId);
      }
    }
  }

  void _handleStreamChunk(lk_models.DataStream_Chunk chunk, EncryptionType encryptionType) {
    final textController = _textStreamControllers[chunk.streamId];
    if (textController != null) {
      if (textController.info.encryptionType != encryptionType) {
        textController.error(_encryptionMismatch());
        _forgetStream(chunk.streamId);
      } else if (chunk.content.isNotEmpty) {
        if (_exceedsPayloadCap(chunk)) {
          textController.error(_payloadTooLarge());
          unawaited(textController.close());
          _forgetStream(chunk.streamId);
          return;
        }
        textController.write(chunk);
      }
    }

    final byteController = _byteStreamControllers[chunk.streamId];
    if (byteController != null) {
      if (byteController.info.encryptionType != encryptionType) {
        byteController.error(_encryptionMismatch());
        _forgetStream(chunk.streamId);
      } else if (chunk.content.isNotEmpty) {
        if (_exceedsPayloadCap(chunk)) {
          byteController.error(_payloadTooLarge());
          unawaited(byteController.close());
          _forgetStream(chunk.streamId);
          return;
        }
        byteController.write(chunk);
      }
    }
  }

  /// Accumulates this chunk against the stream's running total, returning true once the payload
  /// cap is passed.
  bool _exceedsPayloadCap(lk_models.DataStream_Chunk chunk) {
    final total = (_receivedBytes[chunk.streamId] ?? 0) + chunk.content.length;
    _receivedBytes[chunk.streamId] = total;
    return total > _maxPayloadByteLength;
  }

  DataStreamError _payloadTooLarge() => DataStreamError(
    message: 'Stream payload exceeds the maxPayloadByteLength of $_maxPayloadByteLength',
    reason: DataStreamErrorReason.LengthExceeded,
  );

  void _forgetStream(String streamId) {
    _textStreamControllers.remove(streamId);
    _byteStreamControllers.remove(streamId);
    _receivedBytes.remove(streamId);
  }

  Future<void> _handleStreamTrailer(lk_models.DataStream_Trailer trailer, EncryptionType encryptionType) async {
    final textController = _textStreamControllers[trailer.streamId];
    if (textController != null) {
      if (textController.info.encryptionType != encryptionType) {
        textController.error(_encryptionMismatch());
        _forgetStream(trailer.streamId);
        return;
      }
      textController.info.attributes = {...textController.info.attributes, ...trailer.attributes};
      await textController.close();
      _forgetStream(trailer.streamId);
    }

    final byteController = _byteStreamControllers[trailer.streamId];
    if (byteController != null) {
      if (byteController.info.encryptionType != encryptionType) {
        byteController.error(_encryptionMismatch());
        _forgetStream(trailer.streamId);
        return;
      }
      byteController.info.attributes = {...byteController.info.attributes, ...trailer.attributes};
      await byteController.close();
      _forgetStream(trailer.streamId);
    }
  }

  DataStreamError _encryptionMismatch() => DataStreamError(
    message: 'Encryption type mismatch',
    reason: DataStreamErrorReason.EncryptionTypeMismatch,
  );

  // MARK: - Send

  @override
  Future<TextStreamInfo> sendText(String text, SendTextOptions? options) async {
    final streamId = const Uuid().v4();
    final totalTextLength = text.codeUnits.length;

    final fileIds = options?.attachments.map((f) => const Uuid().v4()).toList();
    final len = (fileIds != null && fileIds.isNotEmpty) ? fileIds.length + 1 : 1;
    final progresses = List<num>.filled(len, 0);

    void handleProgress(num progress, int idx) {
      progresses[idx] = progress;
      final totalProgress = progresses.reduce((acc, val) => acc + val);
      options?.onProgress?.call(totalProgress.toDouble() / len);
    }

    final writer = await streamText(
      StreamTextOptions(
        streamId: streamId,
        totalSize: totalTextLength,
        destinationIdentities: options?.destinationIdentities ?? [],
        topic: options?.topic,
        attachedStreamIds: fileIds ?? [],
        attributes: options?.attributes ?? {},
      ),
    );

    await writer.write(text);
    handleProgress(1, 0);
    await writer.close();

    if (options?.attachments != null) {
      var idx = 0;
      await Future.wait<void>(
        options?.attachments.map((file) {
              final curIdx = idx++;
              return _sendFile(
                fileIds![curIdx],
                file,
                SendFileOptions(
                  topic: options.topic,
                  mimeType: mime(basename(file.path)),
                  onProgress: (progress) => handleProgress(progress, curIdx + 1),
                ),
              );
            }).toList() ??
            [],
      );
    }
    return writer.info;
  }

  @override
  Future<ByteStreamInfo> sendBytes(List<int> bytes, SendBytesOptions? options) async {
    final writer = await streamBytes(
      StreamBytesOptions(
        name: options?.name ?? 'unknown',
        mimeType: options?.mimeType ?? 'application/octet-stream',
        topic: options?.topic,
        destinationIdentities: options?.destinationIdentities ?? [],
        attributes: options?.attributes ?? {},
        totalSize: bytes.length,
      ),
    );
    await writer.write(Uint8List.fromList(bytes));
    await writer.close();
    return writer.info;
  }

  @override
  Future<Map<String, String>> sendFile(File file, SendFileOptions options) async {
    final streamId = const Uuid().v4();
    await _sendFile(streamId, file, options);
    return {'id': streamId};
  }

  Future<void> _sendFile(String streamId, File file, SendFileOptions options) async {
    final totalLength = await file.length();
    final writer = await streamBytes(
      StreamBytesOptions(
        streamId: streamId,
        totalSize: totalLength,
        name: basename(file.path),
        mimeType: options.mimeType,
        topic: options.topic,
        destinationIdentities: options.destinationIdentities,
        encryptionType: options.encryptionType,
      ),
    );

    final totalChunks = (totalLength / kStreamChunkSize).ceil();
    final reader = ChunkedStreamReader(file.openRead());
    try {
      for (var i = 0; i < totalChunks; i++) {
        final chunk = await reader.readBytes(kStreamChunkSize);
        if (chunk.isEmpty) break;
        await writer.write(Uint8List.fromList(chunk));
        options.onProgress?.call((i + 1) / totalChunks);
      }
    } finally {
      await reader.cancel();
      await writer.close();
    }
  }

  @override
  Future<TextStreamWriter> streamText(StreamTextOptions? options) async {
    final streamId = options?.streamId ?? const Uuid().v4();
    final timestamp = DateTime.timestamp().millisecondsSinceEpoch;

    final info = TextStreamInfo(
      id: streamId,
      mimeType: 'text/plain',
      timestamp: timestamp,
      topic: options?.topic ?? '',
      size: options?.totalSize ?? 0,
      replyToStreamId: options?.replyToStreamId,
      attachedStreamIds: options?.attachedStreamIds ?? [],
      version: options?.version,
      generated: options?.generated ?? false,
      operationType: options?.type,
      sendingParticipantIdentity: _room.localParticipant?.identity ?? '',
      attributes: options?.attributes ?? {},
    );

    final header = lk_models.DataStream_Header(
      streamId: streamId,
      mimeType: info.mimeType,
      topic: info.topic,
      timestamp: Int64(timestamp),
      totalLength: options?.totalSize != null ? Int64(options!.totalSize!) : null,
      attributes: options?.attributes.entries,
      textHeader: lk_models.DataStream_TextHeader(
        version: options?.version,
        attachedStreamIds: options?.attachedStreamIds,
        replyToStreamId: options?.replyToStreamId,
        generated: options?.generated ?? false,
        operationType: options?.type?.toPBType(),
      ),
    );

    final destinationIdentities = options?.destinationIdentities ?? const <String>[];
    final packet = lk_models.DataPacket(
      kind: lk_models.DataPacket_Kind.RELIABLE,
      destinationIdentities: destinationIdentities,
      streamHeader: header,
    );
    await _room.engine.sendDataPacket(packet, reliability: Reliability.reliable);

    final writableStream = WritableStream<String>(
      destinationIdentities: destinationIdentities,
      engine: _room.engine,
      streamId: streamId,
    );

    return TextStreamWriter(
      writableStream: writableStream,
      info: info,
      onClose: _closeOnEngineClose(writableStream),
    );
  }

  @override
  Future<ByteStreamWriter> streamBytes(StreamBytesOptions? options) async {
    final streamId = options?.streamId ?? const Uuid().v4();
    final timestamp = DateTime.timestamp().millisecondsSinceEpoch;

    final info = ByteStreamInfo(
      id: streamId,
      name: options?.name ?? 'unknown',
      mimeType: options?.mimeType ?? 'application/octet-stream',
      timestamp: timestamp,
      topic: options?.topic ?? '',
      size: options?.totalSize ?? 0,
      attributes: options?.attributes ?? {},
      sendingParticipantIdentity: _room.localParticipant?.identity ?? '',
    );

    final header = lk_models.DataStream_Header(
      streamId: streamId,
      mimeType: info.mimeType,
      topic: info.topic,
      timestamp: Int64(timestamp),
      totalLength: options?.totalSize != null ? Int64(options!.totalSize!) : null,
      attributes: options?.attributes.entries,
      encryptionType: options?.encryptionType,
      byteHeader: lk_models.DataStream_ByteHeader(name: info.name),
    );

    final destinationIdentities = options?.destinationIdentities ?? const <String>[];
    final packet = lk_models.DataPacket(
      kind: lk_models.DataPacket_Kind.RELIABLE,
      destinationIdentities: destinationIdentities,
      streamHeader: header,
    );
    await _room.engine.sendDataPacket(packet, reliability: Reliability.reliable);

    final writableStream = WritableStream<Uint8List>(
      destinationIdentities: destinationIdentities,
      engine: _room.engine,
      streamId: streamId,
    );

    return ByteStreamWriter(
      writableStream: writableStream,
      info: info,
      onClose: _closeOnEngineClose(writableStream),
    );
  }

  /// Closes the stream if the engine shuts down first, and unsubscribes that listener once the
  /// writer closes normally.
  Future<void> Function() _closeOnEngineClose(WritableStream<dynamic> writableStream) {
    final cancel = _room.engine.events.once<EngineClosingEvent>((_) {
      unawaited(writableStream.close());
    });
    return () async => cancel?.call();
  }

  // MARK: - Lifecycle

  @override
  Future<void> closeStreamsFrom(String participantIdentity) async {
    final texts = _textStreamControllers.values
        .where((c) => c.info.sendingParticipantIdentity == participantIdentity)
        .toList();
    final bytes = _byteStreamControllers.values
        .where((c) => c.info.sendingParticipantIdentity == participantIdentity)
        .toList();
    if (texts.isEmpty && bytes.isEmpty) return;

    final abnormalEndError = DataStreamError(
      message: 'Participant $participantIdentity unexpectedly disconnected in the middle of sending data',
      reason: DataStreamErrorReason.AbnormalEnd,
    );
    for (final controller in bytes) {
      controller.error(abnormalEndError);
      await controller.close();
      _forgetStream(controller.info.id);
    }
    for (final controller in texts) {
      controller.error(abnormalEndError);
      await controller.close();
      _forgetStream(controller.info.id);
    }
  }

  @override
  Future<void> reset() async {
    for (final controller in [..._textStreamControllers.values, ..._byteStreamControllers.values]) {
      await controller.close();
    }
    _textStreamControllers.clear();
    _byteStreamControllers.clear();
    _receivedBytes.clear();
  }

  @override
  Future<void> dispose() => reset();
}
