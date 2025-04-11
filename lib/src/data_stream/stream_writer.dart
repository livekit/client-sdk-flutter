import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import 'package:livekit_client/src/core/engine.dart';
import 'package:livekit_client/src/types/other.dart';
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

class ByteStreamWriter extends BaseStreamWriter<Uint8List, ByteStreamInfo> {
  ByteStreamWriter({
    required super.writableStream,
    required super.info,
    required super.onClose,
  });
}

class WritableStream<T> implements StreamWriter<T> {
  String streamId;
  int chunkId = 0;
  List<String>? destinationIdentities;
  Engine engine;
  WritableStream({
    required this.streamId,
    required this.engine,
    this.destinationIdentities,
  });

  @override
  Future<void> close() async {
    final trailer = lk_models.DataStream_Trailer(
      streamId: streamId,
    );
    final trailerPacket = lk_models.DataPacket(
      destinationIdentities: destinationIdentities,
      streamTrailer: trailer,
    );
    await engine.sendDataPacket(trailerPacket, reliability: true);
  }

  @override
  Future<void> write(T chunk) async {
    for (final content in splitUTF8List(chunk, kStreamChunkSize)) {
      await engine.waitForBufferStatusLow(Reliability.reliable);
      final chunk = lk_models.DataStream_Chunk(
        content: content,
        streamId: streamId,
        chunkIndex: Int64(chunkId),
      );
      final chunkPacket = lk_models.DataPacket(
        destinationIdentities: destinationIdentities,
        streamChunk: chunk,
      );
      await engine.sendDataPacket(chunkPacket, reliability: true);
      chunkId += 1;
    }
  }

  List<Uint8List> splitUTF8List(T chunk, int chunkSize) {
    Uint8List utf8Bytes = Uint8List(0);

    if (chunk is String) {
      utf8Bytes = utf8.encode(chunk as String);
    } else if (chunk is Uint8List) {
      utf8Bytes = chunk as Uint8List;
    }

    final chunks = <Uint8List>[];
    if (utf8Bytes.length <= chunkSize) {
      chunks.add(Uint8List.fromList(utf8Bytes));
      return chunks;
    }
    for (var i = 0; i < utf8Bytes.length; i += chunkSize) {
      final end = i + chunkSize;
      if (end > utf8Bytes.length) {
        chunks.add(Uint8List.fromList(utf8Bytes.sublist(i)));
        break;
      }
      chunks.add(Uint8List.fromList(utf8Bytes.sublist(i, end)));
    }
    return chunks;
  }
}
