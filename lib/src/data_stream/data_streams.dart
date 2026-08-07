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

import 'dart:io';

import '../core/room.dart';
import '../e2ee/options.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../types/data_stream.dart';
import 'data_streams_native.dart' if (dart.library.js_interop) 'data_streams_web.dart' as impl;
import 'stream_writer.dart';

/// Owns the data-stream subsystem for one [Room]: the topic→handler registry, the send path, and
/// the routing of inbound packets to open readers.
///
/// Two implementations sit behind this interface, chosen by conditional import:
///
/// - **native** ([createDataStreams] in `data_streams_native.dart`) delegates to the Rust core in
///   `package:livekit_uniffi`, which implements data streams v2 — single-packet inline sends,
///   deflate-raw compression, and MTU-bounded headers.
/// - **web** (`data_streams_web.dart`) keeps the original Dart implementation. There is no way to
///   load a cdylib in a browser, so web stays on the v1 wire format. That interoperates: a v2
///   sender sees web's pre-v2 `clientProtocol` and falls back to uncompressed multi-packet.
///
/// A [Room] owns exactly one of these for its whole lifetime, created eagerly in the constructor.
/// It outlives connect/disconnect because handler registrations must survive a reconnect and be
/// registrable before the first connect.
abstract class DataStreams {
  /// Handlers registered for incoming text streams, keyed by topic.
  Map<String, TextStreamHandler> get textStreamHandlers;

  /// Handlers registered for incoming byte streams, keyed by topic.
  Map<String, ByteStreamHandler> get byteStreamHandlers;

  void registerTextStreamHandler(String topic, TextStreamHandler callback);

  void unregisterTextStreamHandler(String topic);

  void registerByteStreamHandler(String topic, ByteStreamHandler callback);

  void unregisterByteStreamHandler(String topic);

  Future<TextStreamInfo> sendText(String text, SendTextOptions? options);

  /// Sends an in-memory byte payload. Returns info about the stream created for it.
  Future<ByteStreamInfo> sendBytes(List<int> bytes, SendBytesOptions? options);

  Future<Map<String, String>> sendFile(File file, SendFileOptions options);

  Future<TextStreamWriter> streamText(StreamTextOptions? options);

  Future<ByteStreamWriter> streamBytes(StreamBytesOptions? options);

  /// Routes one already-decrypted inbound [lk_models.DataPacket] carrying a stream header, chunk
  /// or trailer.
  void handleIncomingPacket(lk_models.DataPacket packet, EncryptionType encryptionType);

  /// Fails every open stream sent by [identity] — they disconnected mid-send, so their readers
  /// error rather than hanging.
  Future<void> closeStreamsFrom(String identity);

  /// Fails every open stream, e.g. on disconnect. Handler registrations survive, so streams
  /// arriving after a reconnect are still handled.
  Future<void> reset();

  /// Releases the underlying resources. The owning [Room] is being disposed.
  Future<void> dispose();
}

/// Builds the implementation for the current platform.
DataStreams createDataStreams(Room room) => impl.createDataStreams(room);
