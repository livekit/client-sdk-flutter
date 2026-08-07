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

import 'package:livekit_uniffi/livekit_uniffi.dart' as ffi;

import '../e2ee/options.dart';
import '../types/client_capability.dart';
import '../types/data_stream.dart';
import 'errors.dart';

/// Conversions between this SDK's public data-stream types and the generated `livekit_uniffi`
/// ones.
///
/// Mirrors the `FFIBridged` marker the Swift SDK uses: bridging lives here rather than on the
/// public types, so those stay free of any `livekit_uniffi` import. Dart has no `internal import`
/// to enforce that, so the rule is by convention — see AGENTS.md.
///
/// The FFI's stream info carries no encryption type (the Rust core normalizes it to `none` and
/// expects already-decrypted packets), so callers inject the room's current one.
extension FfiTextStreamInfo on ffi.TextStreamInfo {
  TextStreamInfo toLK({
    required String sendingParticipantIdentity,
    required EncryptionType encryptionType,
  }) => TextStreamInfo(
    id: id,
    mimeType: mimeType,
    topic: topic,
    timestamp: timestampMs,
    size: totalLength ?? 0,
    attributes: attributes,
    replyToStreamId: replyToStreamId,
    attachedStreamIds: attachedStreamIds,
    version: version,
    generated: generated,
    operationType: operationType.toLK(),
    sendingParticipantIdentity: sendingParticipantIdentity,
    encryptionType: encryptionType,
  );
}

extension FfiByteStreamInfo on ffi.ByteStreamInfo {
  ByteStreamInfo toLK({
    required String sendingParticipantIdentity,
    required EncryptionType encryptionType,
  }) => ByteStreamInfo(
    id: id,
    mimeType: mimeType,
    topic: topic,
    timestamp: timestampMs,
    size: totalLength ?? 0,
    attributes: attributes,
    name: name,
    sendingParticipantIdentity: sendingParticipantIdentity,
    encryptionType: encryptionType,
  );
}

extension FfiOperationType on ffi.OperationType {
  TextStreamOperationType toLK() => switch (this) {
    ffi.OperationType.create => TextStreamOperationType.create,
    ffi.OperationType.update => TextStreamOperationType.update,
    ffi.OperationType.delete => TextStreamOperationType.delete,
    ffi.OperationType.reaction => TextStreamOperationType.reaction,
  };
}

extension LKTextStreamOperationType on TextStreamOperationType {
  ffi.OperationType toFfi() => switch (this) {
    TextStreamOperationType.create => ffi.OperationType.create,
    TextStreamOperationType.update => ffi.OperationType.update,
    TextStreamOperationType.delete => ffi.OperationType.delete,
    TextStreamOperationType.reaction => ffi.OperationType.reaction,
  };
}

extension LKClientCapability on ClientCapability {
  ffi.ClientCapability toFfi() => switch (this) {
    ClientCapability.packetTrailer => ffi.ClientCapability.packetTrailer,
    ClientCapability.compressionDeflateRaw => ffi.ClientCapability.compressionDeflateRaw,
  };
}

/// Maps an FFI error onto the public [DataStreamError] set.
///
/// Lossy: the public reasons predate the Rust core and don't cover every case, so several collapse
/// onto the closest existing one. The FFI's own message is kept so nothing is lost for debugging.
DataStreamError toLKError(ffi.DataStreamException e) {
  final reason = switch (e) {
    ffi.AbnormalEndDataStreamException() => DataStreamErrorReason.AbnormalEnd,
    ffi.IoDataStreamException() => DataStreamErrorReason.AbnormalEnd,
    ffi.Utf8DataStreamException() => DataStreamErrorReason.DecodeFailed,
    ffi.DecompressionDataStreamException() => DataStreamErrorReason.DecodeFailed,
    ffi.LengthExceededDataStreamException() => DataStreamErrorReason.LengthExceeded,
    ffi.HeaderTooLargeDataStreamException() => DataStreamErrorReason.LengthExceeded,
    ffi.PayloadTooLargeDataStreamException() => DataStreamErrorReason.LengthExceeded,
    ffi.IncompleteDataStreamException() => DataStreamErrorReason.Incomplete,
    ffi.EncryptionTypeMismatchDataStreamException() => DataStreamErrorReason.EncryptionTypeMismatch,
    _ => DataStreamErrorReason.AbnormalEnd,
  };
  return DataStreamError(reason: reason, message: e.toString());
}

/// Runs [body], translating any FFI error into the public [DataStreamError].
Future<T> mappingFfiErrors<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on ffi.DataStreamException catch (e) {
    throw toLKError(e);
  }
}
