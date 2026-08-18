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
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:livekit_uniffi/livekit_uniffi.dart' as ffi;
import 'package:meta/meta.dart';
import 'package:path/path.dart' show basename;
import 'package:uuid/uuid.dart';

import '../core/room.dart';
import '../e2ee/options.dart';
import '../extensions.dart';
import '../logger.dart';
import '../participant/participant.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../types/data_stream.dart';
import '../types/other.dart';
import 'data_streams.dart';
import 'errors.dart';
import 'ffi_bridged.dart';
import 'stream_reader.dart';
import 'stream_writer.dart';

DataStreams createDataStreams(Room room) => NativeDataStreams(room);

/// Data streams backed by the Rust core in `package:livekit_uniffi`, which implements v2:
/// single-packet inline sends, deflate-raw compression, UTF-8-aware chunking and MTU-bounded
/// headers. This layer owns topic routing, the public type conversions, and the transport hop —
/// the wire format itself is entirely Rust's.
///
/// The FFI boundary is serialized `DataPacket` bytes in both directions. Inbound, [Room] hands over
/// already-decrypted packets; outbound, packets come back encoded and are re-sent through
/// [Engine.sendDataPacket] so E2EE wrapping, reliable sequencing and resume-resend all still apply.
///
/// Both managers are built through the core's `polled*` adapters rather than constructed directly.
/// The core normally pushes its output to a foreign delegate from its tokio runtime, which Dart
/// cannot accept: uniffi compiles a callback interface to `Pointer.fromFunction`, valid only on the
/// thread owning the isolate, so such a call aborts the VM outright with "Cannot invoke native
/// callback outside an isolate". The adapters keep the delegate on the Rust side and buffer into a
/// channel we await, so nothing crosses the FFI until we pull.
///
/// [ffi.RemoteParticipantRegistryDelegate] is the one callback we do implement, and it is safe: it
/// is only ever called synchronously inside a `send*` future, and uniffi polls those from whichever
/// thread called `rust_future_poll` — us.
class NativeDataStreams implements DataStreams {
  NativeDataStreams(Room room) : _room = WeakReference(room) {
    final outgoing = ffi.polledOutgoingDataStreamManager(registry: _Registry(room));
    _outgoing = outgoing.manager;
    _outgoingPackets = outgoing.packets;
    unawaited(_pumpOutgoing());
  }

  /// Weak so the Rust-side strong reference to the registry delegate can't keep the [Room] alive.
  final WeakReference<Room> _room;

  late final ffi.OutgoingDataStreamManager _outgoing;
  late final ffi.OutgoingPacketQueue _outgoingPackets;

  /// Created on the first inbound packet rather than here, so a
  /// [DataStreamOptions.maxPayloadByteLength] supplied at connect time is picked up.
  ffi.IncomingDataStreamManager? _incoming;
  ffi.IncomingStreamQueue? _incomingStreams;

  final Map<String, TextStreamHandler> _textStreamHandlers = {};
  final Map<String, ByteStreamHandler> _byteStreamHandlers = {};

  /// Serializes outbound sends so packet order survives the hop from the pump into the engine's
  /// async send.
  Future<void> _sendChain = Future.value();

  bool _disposed = false;

  @override
  Map<String, TextStreamHandler> get textStreamHandlers => _textStreamHandlers;

  @override
  Map<String, ByteStreamHandler> get byteStreamHandlers => _byteStreamHandlers;

  @override
  void registerTextStreamHandler(String topic, TextStreamHandler callback) => _textStreamHandlers[topic] = callback;

  @override
  void unregisterTextStreamHandler(String topic) => _textStreamHandlers.remove(topic);

  @override
  void registerByteStreamHandler(String topic, ByteStreamHandler callback) => _byteStreamHandlers[topic] = callback;

  @override
  void unregisterByteStreamHandler(String topic) => _byteStreamHandlers.remove(topic);

  // MARK: - Send

  @override
  Future<TextStreamInfo> sendText(String text, SendTextOptions? options) async {
    // Attachments are still composed here: the core sends one stream, and each attachment is its
    // own byte stream referenced by `attachedStreamIds` in the text header.
    final attachments = options?.attachments ?? const <File>[];
    final attachmentIds = [for (var i = 0; i < attachments.length; i++) const Uuid().v4()];

    final info = await mappingFfiErrors(
      () => _outgoing.sendText(
        text: text,
        options: ffi.StreamTextOptions(
          topic: options?.topic ?? '',
          attributes: options?.attributes ?? const {},
          destinationIdentities: options?.destinationIdentities ?? const [],
          attachedStreamIds: attachmentIds,
          compress: options?.compress,
        ),
      ),
    );

    // The core does its own chunking, so there is no per-chunk progress to report; the text part
    // is simply done. Attachments still report individually.
    options?.onProgress?.call(attachments.isEmpty ? 1 : 1 / (attachments.length + 1));

    for (var i = 0; i < attachments.length; i++) {
      await _sendFileWithId(
        attachmentIds[i],
        attachments[i],
        SendFileOptions(topic: options?.topic, destinationIdentities: options?.destinationIdentities ?? const []),
      );
      options?.onProgress?.call((i + 2) / (attachments.length + 1));
    }

    return info.toLK(
      sendingParticipantIdentity: _localIdentity,
      encryptionType: _currentEncryptionType,
    );
  }

  @override
  Future<ByteStreamInfo> sendBytes(List<int> bytes, SendBytesOptions? options) async {
    final info = await mappingFfiErrors(
      () => _outgoing.sendBytes(
        data: Uint8List.fromList(bytes),
        options: ffi.StreamByteOptions(
          topic: options?.topic ?? '',
          attributes: options?.attributes ?? const {},
          destinationIdentities: options?.destinationIdentities ?? const [],
          name: options?.name,
          mimeType: options?.mimeType,
          compress: options?.compress,
        ),
      ),
    );
    return info.toLK(
      sendingParticipantIdentity: _localIdentity,
      encryptionType: _currentEncryptionType,
    );
  }

  @override
  Future<Map<String, String>> sendFile(File file, SendFileOptions options) async {
    final id = const Uuid().v4();
    await _sendFileWithId(id, file, options);
    return {'id': id};
  }

  Future<void> _sendFileWithId(String id, File file, SendFileOptions options) async {
    await mappingFfiErrors(
      () => _outgoing.sendFile(
        // The core streams the file from disk rather than buffering it.
        path: file.path,
        options: ffi.StreamByteOptions(
          topic: options.topic ?? '',
          attributes: const {},
          destinationIdentities: options.destinationIdentities,
          id: id,
          mimeType: options.mimeType,
          name: basename(file.path),
        ),
      ),
    );
    options.onProgress?.call(1);
  }

  @override
  Future<TextStreamWriter> streamText(StreamTextOptions? options) async {
    final writer = await mappingFfiErrors(
      () => _outgoing.streamText(
        options: ffi.StreamTextOptions(
          topic: options?.topic ?? '',
          attributes: options?.attributes ?? const {},
          destinationIdentities: options?.destinationIdentities ?? const [],
          id: options?.streamId,
          operationType: options?.type?.toFfi(),
          version: options?.version,
          replyToStreamId: options?.replyToStreamId,
          attachedStreamIds: options?.attachedStreamIds ?? const [],
          generated: options?.generated,
        ),
      ),
    );
    return TextStreamWriter(
      writableStream: _FfiTextStreamWriter(writer),
      info: writer.info().toLK(
        sendingParticipantIdentity: _localIdentity,
        encryptionType: _currentEncryptionType,
      ),
      onClose: () async => writer.dispose(),
    );
  }

  @override
  Future<ByteStreamWriter> streamBytes(StreamBytesOptions? options) async {
    final writer = await mappingFfiErrors(
      () => _outgoing.streamBytes(
        options: ffi.StreamByteOptions(
          topic: options?.topic ?? '',
          attributes: options?.attributes ?? const {},
          destinationIdentities: options?.destinationIdentities ?? const [],
          id: options?.streamId,
          mimeType: options?.mimeType,
          name: options?.name,
          totalLength: options?.totalSize,
        ),
      ),
    );
    return ByteStreamWriter(
      writableStream: _FfiByteStreamWriter(writer),
      info: writer.info().toLK(
        sendingParticipantIdentity: _localIdentity,
        encryptionType: _currentEncryptionType,
      ),
      onClose: () async => writer.dispose(),
    );
  }

  /// Drains outbound packets from the core and puts them on the wire, in order.
  ///
  /// The pump owns the queue's lifetime and is the only thing that may dispose it — freeing it
  /// while a `nextPackets` is in flight is a use-after-free. [dispose] wakes us by closing the
  /// queue rather than releasing it.
  Future<void> _pumpOutgoing() async {
    try {
      while (true) {
        final batch = await _outgoingPackets.nextPackets();
        if (batch == null) break; // closed or shutting down
        for (final encoded in batch) {
          _enqueueSend(encoded);
        }
      }
    } catch (e) {
      logger.warning('[DataStreams] outgoing pump failed: $e');
    } finally {
      _outgoingPackets.dispose();
    }
  }

  void _enqueueSend(Uint8List encoded) {
    _sendChain = _sendChain.then((_) async {
      final room = _room.target;
      if (room == null || _disposed) return;
      try {
        // Back through the engine rather than the data channel directly, so E2EE wrapping,
        // reliable sequencing and resume-resend all still apply.
        await room.engine.sendDataPacket(
          lk_models.DataPacket.fromBuffer(encoded),
          reliability: Reliability.reliable,
        );
      } catch (e) {
        // The core acknowledges sends unconditionally, so there is nobody to propagate this to.
        logger.warning('[DataStreams] failed to send outbound packet: $e');
      }
    });
  }

  // MARK: - Receive

  ffi.IncomingDataStreamManager _incomingManager() {
    final existing = _incoming;
    if (existing != null) return existing;
    // Read now rather than at construction: this runs on the first inbound packet, i.e. after
    // connect, so a cap supplied via `connect(connectOptions:)` is in effect by this point.
    final incoming = ffi.polledIncomingDataStreamManager(
      maxPayloadByteLength: _room.target?.connectOptions.dataStream.maxPayloadByteLength,
    );
    _incoming = incoming.manager;
    _incomingStreams = incoming.streams;
    // The two pumps share one queue object, so neither may dispose it on its own way out --
    // the other might still have a call in flight (a use-after-free, not a Dart exception).
    // Dispose exactly once, after both have exited; close() wakes them both.
    final streams = incoming.streams;
    unawaited(
      Future.wait([_pumpIncoming(streams), _pumpClosed(streams)]).whenComplete(streams.dispose),
    );
    return incoming.manager;
  }

  @override
  void handleIncomingPacket(lk_models.DataPacket packet, EncryptionType encryptionType) {
    if (_disposed) return;
    // The core decodes the header/chunk/trailer itself, so hand it the whole packet.
    // [encryptionType] is how the packet actually arrived, as determined by the engine; the core
    // cannot recover it from the bytes (decryption replaces the encrypted_packet oneof member)
    // and uses it to hold every stream to the encryption its header arrived under.
    _incomingManager().handlePacketReceived(
      packet: packet.writeToBuffer(),
      encryptionType: encryptionType.toFfi(),
    );
  }

  /// Drains opened streams from the core and dispatches them to the registered topic handler.
  ///
  /// Queue disposal is coordinated in [_incomingManager], not here: the closed-stream pump shares
  /// the queue object.
  Future<void> _pumpIncoming(ffi.IncomingStreamQueue streams) async {
    try {
      while (true) {
        final opened = await streams.nextOpenedStream();
        if (opened == null) break; // closed or shutting down
        try {
          _dispatchOpenedStream(opened);
        } catch (e) {
          logger.warning('[DataStreams] failed to dispatch opened stream: $e');
        }
      }
    } catch (e) {
      logger.warning('[DataStreams] incoming pump failed: $e');
    }
  }

  /// Drains stream-closed notifications and discards them.
  ///
  /// Nothing consumes the signal yet -- it exists for ordered per-topic delivery, which this SDK
  /// does not implement -- but the queue is unbounded on the Rust side, so leaving it undrained
  /// would grow memory with every stream received for the manager's lifetime.
  Future<void> _pumpClosed(ffi.IncomingStreamQueue streams) async {
    try {
      while (await streams.nextClosedStream() != null) {}
    } catch (e) {
      logger.warning('[DataStreams] closed-stream pump failed: $e');
    }
  }

  void _dispatchOpenedStream(ffi.OpenedStream opened) {
    final identity = opened.identity;

    final textReader = opened.textReader;
    if (textReader != null) {
      final ffiInfo = textReader.info();
      // The core stamps incoming infos with the encryption the stream's header arrived under, so
      // a plaintext stream is reported as plaintext even in a room with encryption enabled.
      final info = ffiInfo.toLK(
        sendingParticipantIdentity: identity,
        encryptionType: ffiInfo.encryptionType.toLK(),
      );
      final handler = _textStreamHandlers[info.topic];
      if (handler == null) {
        logger.info('[DataStreams] ignoring text stream on unhandled topic "${info.topic}"');
        textReader.dispose();
        return;
      }
      // The core yields decoded pieces; re-frame them as protobuf chunks so the public reader —
      // which is a Stream<DataStream_Chunk> — behaves exactly as it did before.
      final controller = _controllerFor<String>(
        info: info,
        next: textReader.next,
        toBytes: (piece) => Uint8List.fromList(utf8.encode(piece)),
        streamId: info.id,
        dispose: textReader.dispose,
      );
      handler(TextStreamReader(info, controller, info.size), identity);
      return;
    }

    final byteReader = opened.byteReader;
    if (byteReader != null) {
      final ffiInfo = byteReader.info();
      final info = ffiInfo.toLK(
        sendingParticipantIdentity: identity,
        encryptionType: ffiInfo.encryptionType.toLK(),
      );
      final handler = _byteStreamHandlers[info.topic];
      if (handler == null) {
        logger.info('[DataStreams] ignoring byte stream on unhandled topic "${info.topic}"');
        byteReader.dispose();
        return;
      }
      final controller = _controllerFor<Uint8List>(
        info: info,
        next: byteReader.next,
        toBytes: (piece) => piece,
        streamId: info.id,
        dispose: byteReader.dispose,
      );
      handler(ByteStreamReader(info, controller, info.size), identity);
    }
  }

  /// Adapts the core's pull-based reader onto the [DataStreamController] the public readers wrap.
  ///
  /// Pulling is driven by the subscription: nothing is read until someone listens, and the loop
  /// stops while the subscription is paused, so the core's backpressure is preserved rather than
  /// buffering the whole stream into Dart.
  ///
  /// The pump owns the reader's lifetime and is the only thing that may dispose it. Disposing from
  /// `onCancel` instead would free the Rust handle while a `next()` is still in flight — a
  /// use-after-free that shows up as a SIGBUS, not a Dart exception.
  DataStreamController<lk_models.DataStream_Chunk> _controllerFor<T extends Object>({
    required BaseStreamInfo info,
    required Future<T?> Function() next,
    required Uint8List Function(T piece) toBytes,
    required String streamId,
    required void Function() dispose,
  }) {
    late final StreamController<lk_models.DataStream_Chunk> controller;
    late final DataStreamController<lk_models.DataStream_Chunk> wrapper;
    var chunkIndex = 0;
    var running = false;
    var cancelled = false;
    var disposed = false;

    void disposeOnce() {
      if (disposed) return;
      disposed = true;
      dispose();
    }

    Future<void> pump() async {
      if (running) return;
      running = true;
      try {
        while (!cancelled && !controller.isClosed && !controller.isPaused) {
          final piece = await next();
          if (piece == null) break;
          if (cancelled || controller.isClosed) break;
          wrapper.write(
            lk_models.DataStream_Chunk(
              streamId: streamId,
              chunkIndex: Int64(chunkIndex++),
              content: toBytes(piece),
            ),
          );
        }
        // Paused means the consumer will resume us later, so leave the reader open.
        if (cancelled || (!controller.isPaused && !controller.isClosed)) {
          await wrapper.close();
          disposeOnce();
        }
      } on ffi.DataStreamException catch (e) {
        wrapper.error(toLKError(e));
        await wrapper.close();
        disposeOnce();
      } catch (e) {
        wrapper.error(
          DataStreamError(
            reason: DataStreamErrorReason.AbnormalEnd,
            message: 'Data stream failed: $e',
          ),
        );
        await wrapper.close();
        disposeOnce();
      } finally {
        running = false;
      }
    }

    controller = StreamController<lk_models.DataStream_Chunk>(
      onListen: () => unawaited(pump()),
      onResume: () => unawaited(pump()),
      // Only flag it: the pump disposes once it has stopped touching the reader. If it is blocked
      // in `next()` the reader stays alive until that resolves, which is the safe order.
      onCancel: () {
        cancelled = true;
        if (!running) disposeOnce();
      },
    );
    wrapper = DataStreamController<lk_models.DataStream_Chunk>(
      info: info,
      streamController: controller,
      startTime: DateTime.timestamp().millisecondsSinceEpoch,
    );
    return wrapper;
  }

  // MARK: - Lifecycle

  @override
  Future<void> closeStreamsFrom(String identity) async {
    _incoming?.abortStreamsFrom(identity: identity);
  }

  @override
  Future<void> reset() async {
    // Discard the manager rather than reuse it: its payload cap is fixed at construction, and
    // the connect options it came from can change between sessions of the same Room. The next
    // inbound packet builds a fresh one against the current options; handler registrations live
    // on this class and survive.
    final incoming = _incoming;
    final streams = _incomingStreams;
    _incoming = null;
    _incomingStreams = null;
    if (incoming == null) return;
    // Fail blocked readers first, then wake the pumps by closing the queue; they dispose the
    // queue they share once both have exited. The manager itself has nothing awaiting it.
    incoming.abortAllStreams();
    streams?.close();
    incoming.dispose();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    // Error out open readers first so their handlers unwind, then close the queues so each pump
    // wakes, exits and disposes the queue it owns. The managers have nothing awaiting them, so
    // they can be released here.
    _incoming?.abortAllStreams();
    _incomingStreams?.close();
    _incomingStreams = null;
    _outgoingPackets.close();
    _incoming?.dispose();
    _incoming = null;
    _outgoing.dispose();
  }

  // MARK: - Helpers

  /// Number of incoming streams the core currently has open: announced by a header and still
  /// awaiting more packets. Answered on the core's loop in order with the packets and aborts fed
  /// before it, so a test can wait deterministically for one to land instead of polling. Zero
  /// when no manager exists (before the first packet, or after [reset]).
  @visibleForTesting
  Future<int> debugOpenStreamCount() async => await _incoming?.openStreamCount() ?? 0;

  String get _localIdentity => _room.target?.localParticipant?.identity ?? '';

  /// The room's data-channel encryption, stamped onto OUTGOING streams only: payload crypto
  /// happens in the engine after the core, so the core normalizes outgoing infos to none.
  /// Incoming streams need no fixup — the core stamps them with the encryption their header
  /// actually arrived under, as passed to [handleIncomingPacket].
  EncryptionType get _currentEncryptionType {
    final room = _room.target;
    final enabled = room?.e2eeManager?.isDataChannelEncryptionEnabled ?? false;
    return enabled ? EncryptionType.kGcm : EncryptionType.kNone;
  }
}

/// Answers the core's per-send eligibility questions from the room's current participant list.
///
/// A separate object rather than [NativeDataStreams] itself because the Rust manager retains its
/// registry strongly; holding the room weakly here keeps that from pinning the room alive.
class _Registry implements ffi.RemoteParticipantRegistryDelegate {
  _Registry(Room room) : _room = WeakReference(room);

  final WeakReference<Room> _room;

  @override
  int remoteClientProtocol(String identity) =>
      _participant(identity)?.clientProtocol.toIntValue() ?? ClientProtocolVersion.v0.wireValue;

  @override
  List<ffi.ClientCapability> remoteCapabilities(String identity) =>
      _participant(identity)?.capabilities.map((c) => c.toFfi()).toList() ?? const [];

  @override
  List<String> remoteIdentities() => _room.target?.remoteParticipants.keys.toList() ?? const [];

  Participant? _participant(String identity) => _room.target?.remoteParticipants[identity];
}

/// Bridges the core's text writer onto the [StreamWriter] the public writer wraps.
class _FfiTextStreamWriter implements StreamWriter<String> {
  _FfiTextStreamWriter(this._writer);

  final ffi.TextStreamWriter _writer;

  @override
  Future<void> write(String chunk) => mappingFfiErrors(() => _writer.write(text: chunk));

  @override
  Future<void> close() => mappingFfiErrors(() => _writer.close());
}

class _FfiByteStreamWriter implements StreamWriter<Uint8List> {
  _FfiByteStreamWriter(this._writer);

  final ffi.ByteStreamWriter _writer;

  @override
  Future<void> write(Uint8List chunk) => mappingFfiErrors(() => _writer.write(data: chunk));

  @override
  Future<void> close() => mappingFfiErrors(() => _writer.close());
}
