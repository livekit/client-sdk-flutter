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

import 'package:flutter/foundation.dart' show kIsWeb;

import '../proto/livekit_models.pb.dart' as lk_models;

/// An optional feature a client advertises to its peers.
///
/// Distinct from `clientProtocol`, which is a monotonic baseline version: capabilities cover
/// features a client may or may not support depending on its platform, and each is advertised
/// independently. Wire values match `livekit.ClientInfo.Capability`.
enum ClientCapability {
  /// The client understands packet trailers.
  packetTrailer(1),

  /// The client can decompress a deflate-raw compressed data stream.
  compressionDeflateRaw(2)
  ;

  const ClientCapability(this.wireValue);

  final int wireValue;

  /// The capabilities this SDK advertises.
  ///
  /// Compression is advertised unconditionally on native, where the Rust core always provides
  /// deflate-raw. Web has no Rust core and so advertises nothing — a v2 sender then falls back to
  /// uncompressed multi-packet for it, which every client understands.
  static const List<ClientCapability> advertised = kIsWeb
      ? <ClientCapability>[]
      : [ClientCapability.compressionDeflateRaw];

  static ClientCapability? fromProto(lk_models.ClientInfo_Capability value) {
    for (final capability in ClientCapability.values) {
      if (capability.wireValue == value.value) return capability;
    }
    // CAP_UNUSED, and anything newer than this SDK knows about.
    return null;
  }

  /// The name the server expects for this capability in the signal URL's `capabilities` param.
  String toWireName() => switch (this) {
    ClientCapability.packetTrailer => 'CAP_PACKET_TRAILER',
    ClientCapability.compressionDeflateRaw => 'CAP_COMPRESSION_DEFLATE_RAW',
  };
}
