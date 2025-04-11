import 'dart:async';
import 'dart:io' show File;

import '../data_stream/stream_reader.dart';
import '../proto/livekit_models.pb.dart' show Encryption_Type, DataStream_Chunk;

const kStreamChunkSize = 15_000;

class SendTextOptions {
  String? topic;

  List<String> destinationIdentities = [];
  List<File> attachments = [];

  Function(double)? onProgress;

  SendTextOptions({
    this.topic,
    this.destinationIdentities = const [],
    this.attachments = const [],
    this.onProgress,
  });
}

class SendFileOptions {
  String? mimeType;
  String? topic;
  List<String> destinationIdentities = [];
  Encryption_Type? encryptionType;

  Function(double)? onProgress;

  SendFileOptions({
    this.mimeType,
    this.topic,
    this.destinationIdentities = const [],
    this.encryptionType = Encryption_Type.NONE,
    this.onProgress,
  });
}

class StreamTextOptions {
  String? topic;
  List<String> destinationIdentities = [];
  String? streamId;
  int? version;
  List<String> attachedStreamIds = [];
  String? replyToStreamId;
  int? totalSize;

  /// 'create' | 'update'
  String? type;

  StreamTextOptions({
    this.topic,
    this.destinationIdentities = const [],
    this.streamId,
    this.version,
    this.attachedStreamIds = const [],
    this.replyToStreamId,
    this.totalSize,
    this.type,
  });
}

class StreamBytesOptions {
  String? name;
  String? mimeType;
  String? topic;
  List<String> destinationIdentities;
  Map<String, String> attributes;
  String? streamId;
  int? totalSize;
  Encryption_Type? encryptionType;
  StreamBytesOptions({
    this.name,
    this.mimeType,
    this.topic,
    this.destinationIdentities = const [],
    this.attributes = const {},
    this.streamId,
    this.totalSize,
    this.encryptionType = Encryption_Type.NONE,
  });
}

class ChatMessage {
  String id;
  int timestamp;
  String message;
  int? editTimestamp;
  List<File> attachedFiles;
  ChatMessage({
    required this.id,
    required this.timestamp,
    required this.message,
    this.editTimestamp,
    this.attachedFiles = const [],
  });
}

class BaseStreamInfo {
  String id;
  String mimeType;
  String topic;
  int timestamp;
  int size;
  Map<String, String> attributes;
  BaseStreamInfo({
    required this.id,
    required this.mimeType,
    required this.topic,
    required this.timestamp,
    required this.size,
    this.attributes = const {},
  });
}

class DataStreamController<T extends DataStream_Chunk> {
  late BaseStreamInfo info;
  late StreamController<T> streamController;
  late num startTime;
  num? endTime;
  DataStreamController({
    required this.info,
    required this.streamController,
    required this.startTime,
    this.endTime,
  });

  Future<void> close() => streamController.close();

  void write(T chunk) => streamController.add(chunk);
}

class ByteStreamInfo extends BaseStreamInfo {
  String name;
  ByteStreamInfo({
    required this.name,
    required String id,
    required String mimeType,
    required String topic,
    required int timestamp,
    required int size,
    Map<String, String> attributes = const {},
  }) : super(
          id: id,
          mimeType: mimeType,
          topic: topic,
          timestamp: timestamp,
          size: size,
          attributes: attributes,
        );
}

class TextStreamInfo extends BaseStreamInfo {
  TextStreamInfo({
    required String id,
    required String mimeType,
    required String topic,
    required int timestamp,
    required int size,
    Map<String, String> attributes = const {},
  }) : super(
          id: id,
          mimeType: mimeType,
          topic: topic,
          timestamp: timestamp,
          size: size,
          attributes: attributes,
        );
}

abstract class StreamWriter<T> {
  Future<void> close();

  Future<void> write(T chunk);
}

typedef ByteStreamHandler = void Function(
    ByteStreamReader reader, String participantIdentity);

typedef TextStreamHandler = Function(
    TextStreamReader reader, String participantIdentity);
