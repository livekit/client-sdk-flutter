import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import 'package:livekit_client/src/core/engine.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../types/data_stream.dart';

class BaseStreamWriter<T, InfoType extends BaseStreamInfo> {
  final StreamWriter<T> writableStream;
  Function()? onClose;

  final InfoType info;

  BaseStreamWriter(
      {required this.writableStream, required this.info, this.onClose});

  Future<void> write(T chunk) async {
    return writableStream.write(chunk);
  }

  Future<void> close() async {
    await writableStream.close();
    this.onClose?.call();
  }
}

class TextStreamWriter extends BaseStreamWriter<String, TextStreamInfo> {
  TextStreamWriter(
      {required super.writableStream,
      required super.info,
      required super.onClose});
}

class BinaryStreamWriter extends BaseStreamWriter<Uint8List, ByteStreamInfo> {
  BinaryStreamWriter(
      {required super.writableStream,
      required super.info,
      required super.onClose});
}

class StreamWriterImpl implements StreamWriter<String> {
  String streamId;

  int chunkId = 0;

  List<String> destinationIdentities;

  Engine engine;

  StreamWriterImpl({
    required this.streamId,
    required this.destinationIdentities,
    required this.engine,
  });

  @override
  Future<void> close() async {
    final trailer = lk_models.DataStream_Trailer(
      streamId: streamId,
    );
    final trailerPacket = lk_models.DataPacket(
      kind: lk_models.DataPacket_Kind.RELIABLE,
      destinationIdentities: destinationIdentities,
      streamTrailer: trailer,
    );
    await engine.sendDataPacket(trailerPacket);
  }

  @override
  Future<void> write(String text) async {
    for (final textByteChunk in splitUtf8(text, kStreamChunkSize)) {
      await engine.waitForBufferStatusLow(lk_models.DataPacket_Kind.RELIABLE);
      final chunk = lk_models.DataStream_Chunk(
        content: textByteChunk,
        streamId: streamId,
        chunkIndex: Int64(chunkId),
      );
      final chunkPacket = lk_models.DataPacket(
        kind: lk_models.DataPacket_Kind.RELIABLE,
        destinationIdentities: destinationIdentities,
        streamChunk: chunk,
      );
      await engine.sendDataPacket(chunkPacket);

      chunkId += 1;
    }
  }
}

List<Uint8List> splitUtf8(String text, int chunkSize) {
  final utf8Bytes = utf8.encode(text);
  final chunks = <Uint8List>[];
  if(text.length <= chunkSize) {
    chunks.add(Uint8List.fromList(utf8Bytes));
    return chunks;
  }
  for (var i = 0; i < utf8Bytes.length; i += chunkSize) {
    final end = i + chunkSize;
    if(end > utf8Bytes.length) {
      chunks.add(Uint8List.fromList(utf8Bytes.sublist(i)));
      break;
    }
    chunks.add(Uint8List.fromList(utf8Bytes.sublist(i, end)));
  }
  return chunks;
}
