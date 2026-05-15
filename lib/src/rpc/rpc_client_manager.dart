// Copyright 2024 LiveKit, Inc.
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

import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../core/room.dart';
import '../data_stream/stream_reader.dart';
import '../extensions.dart';
import '../logger.dart';
import '../participant/local.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../types/data_stream.dart';
import '../types/other.dart';
import '../types/rpc.dart';
import '../utils.dart' show compareVersions;

class _PendingRpc {
  _PendingRpc({
    required this.destinationIdentity,
    required this.completer,
  });

  final String destinationIdentity;
  final Completer<String> completer;
  Timer? ackTimer;
  Timer? responseTimer;
  bool done = false;
}

/// Caller-side RPC state machine. Owns pending request bookkeeping, transport
/// selection (v1 packet vs v2 data stream), and idempotent completion.
@internal
class RpcClientManager {
  RpcClientManager(this._room);

  final Room _room;
  final _uuid = Uuid();
  final Map<String, _PendingRpc> _pending = {};

  /// Initiate an RPC call. Resolves with the response payload, or completes with
  /// an [RpcError] on failure. Transport version is chosen per-call based on the
  /// destination participant's advertised `clientProtocol`.
  Future<String> performRpc(PerformRpcParams params) async {
    final requestId = _uuid.v4();
    final completer = Completer<String>();

    const maxRoundTripLatency = Duration(seconds: 7);
    const minEffectiveTimeout = Duration(milliseconds: 1000);
    final effectiveTimeout = Duration(
      milliseconds: (params.responseTimeoutMs.inMilliseconds - maxRoundTripLatency.inMilliseconds)
          .clamp(minEffectiveTimeout.inMilliseconds, double.infinity)
          .toInt(),
    );

    final destination = params.destinationIdentity;
    final remoteParticipant = _room.getParticipantByIdentity(destination);
    final remoteProtocol = remoteParticipant?.clientProtocol ?? ClientProtocolVersion.v0.toIntValue();
    final useV2 = remoteProtocol >= ClientProtocolVersion.v1.toIntValue();

    // Register pending bookkeeping BEFORE any await so that a fast inline ack/response
    // (delivered while we're still publishing) cannot land before we are ready to match it.
    final pending = _PendingRpc(destinationIdentity: destination, completer: completer);
    _pending[requestId] = pending;
    pending.ackTimer = Timer(maxRoundTripLatency, () {
      _complete(requestId, error: RpcError.builtIn(RpcError.connectionTimeout));
    });
    pending.responseTimer = Timer(params.responseTimeoutMs, () {
      _complete(requestId, error: RpcError.builtIn(RpcError.responseTimeout));
    });

    // v1 payload size check must reject before any packet leaves the wire.
    if (!useV2 && params.payload.length > kRpcMaxPayloadBytes) {
      _complete(requestId, error: RpcError.builtIn(RpcError.requestPayloadTooLarge));
      return completer.future;
    }

    // Server gating: RPC requires server >= 1.8.0. Same check exists on v1; apply uniformly.
    final serverVersion = _room.engine.serverInfo?.version;
    if (serverVersion != null && serverVersion.isNotEmpty && compareVersions(serverVersion, '1.8.0') < 0) {
      _complete(requestId, error: RpcError.builtIn(RpcError.unsupportedServer));
      return completer.future;
    }

    // Kick off the publish without blocking the caller's future on the publish itself.
    // The completer is what the caller awaits; the publish branch only resolves the
    // completer with an error if publishing fails.
    unawaited(() async {
      try {
        if (useV2) {
          await _publishV2Request(
            destinationIdentity: destination,
            requestId: requestId,
            method: params.method,
            payload: params.payload,
            responseTimeout: effectiveTimeout,
          );
        } else {
          await _publishV1Request(
            destinationIdentity: destination,
            requestId: requestId,
            method: params.method,
            payload: params.payload,
            responseTimeout: effectiveTimeout,
          );
        }
      } catch (e) {
        final err = e is RpcError ? e : RpcError(code: RpcError.sendFailed, message: e.toString());
        _complete(requestId, error: err);
      }
    }());

    return completer.future;
  }

  Future<void> _publishV1Request({
    required String destinationIdentity,
    required String requestId,
    required String method,
    required String payload,
    required Duration responseTimeout,
  }) async {
    final packet = lk_models.DataPacket(
      kind: lk_models.DataPacket_Kind.RELIABLE,
      rpcRequest: lk_models.RpcRequest(
        id: requestId,
        method: method,
        payload: payload,
        responseTimeoutMs: responseTimeout.inMilliseconds,
        version: kRpcVesion,
      ),
      participantIdentity: _room.localParticipant?.identity,
      destinationIdentities: [destinationIdentity],
    );
    await _room.engine.sendDataPacket(packet, reliability: Reliability.reliable);
  }

  Future<void> _publishV2Request({
    required String destinationIdentity,
    required String requestId,
    required String method,
    required String payload,
    required Duration responseTimeout,
  }) async {
    final local = _room.localParticipant;
    if (local == null) {
      throw RpcError(code: RpcError.sendFailed, message: 'No local participant');
    }

    final writer = await local.streamText(StreamTextOptions(
      topic: kRpcRequestTopic,
      destinationIdentities: [destinationIdentity],
      attributes: {
        kRpcAttrRequestId: requestId,
        kRpcAttrMethod: method,
        kRpcAttrResponseTimeoutMs: responseTimeout.inMilliseconds.toString(),
        kRpcAttrVersion: kRpcRequestVersionV2,
      },
    ));
    await writer.write(payload);
    await writer.close();
  }

  /// Match an incoming `RpcAck` packet to a pending request. Cancels the ack timer.
  /// Unknown request IDs are logged and ignored (covers late-ack-after-timeout).
  void handleIncomingRpcAck(String requestId) {
    final pending = _pending[requestId];
    if (pending == null) {
      logger.fine('Ack received for unknown RPC request $requestId');
      return;
    }
    pending.ackTimer?.cancel();
    pending.ackTimer = null;
  }

  /// Match an incoming v1 `RpcResponse` packet to a pending request.
  /// Used for both success and error responses from v1 peers, and for error
  /// responses from v2 peers (errors are always packets per spec).
  void handleIncomingRpcResponse(String requestId, String? payload, RpcError? error) {
    final pending = _pending[requestId];
    if (pending == null) {
      logger.fine('Response received for unknown RPC request $requestId');
      return;
    }
    _complete(requestId, payload: payload, error: error);
  }

  /// Registered as the text stream handler for `lk.rpc_response`. Reads the request ID
  /// attribute, validates the sender against the pending entry's destination identity,
  /// drains the stream, and resolves the matching pending RPC.
  Future<void> handleIncomingV2ResponseStream(TextStreamReader reader, String senderIdentity) async {
    final requestId = reader.info?.attributes[kRpcAttrRequestId];
    if (requestId == null) {
      logger.warning('v2 RPC response stream missing $kRpcAttrRequestId attribute; ignoring');
      // Drain to avoid leaking the controller.
      await reader.readAll();
      return;
    }

    final pending = _pending[requestId];
    if (pending == null) {
      logger.fine('v2 RPC response stream for unknown request $requestId; ignoring');
      await reader.readAll();
      return;
    }

    if (senderIdentity != pending.destinationIdentity) {
      // Identity spoof / cross-talk guard. Do NOT resolve; leave pending entry intact
      // so the legitimate response (or timeout) can still complete it.
      logger.warning('v2 RPC response sender "$senderIdentity" does not match expected destination '
          '"${pending.destinationIdentity}" for request $requestId; ignoring');
      await reader.readAll();
      return;
    }

    final payload = await reader.readAll();
    _complete(requestId, payload: payload);
  }

  /// Reject any pending RPCs targeting a participant that has just disconnected.
  void onParticipantDisconnected(String identity) {
    final affected = _pending.entries.where((e) => e.value.destinationIdentity == identity).map((e) => e.key).toList();
    for (final requestId in affected) {
      _complete(requestId, error: RpcError.builtIn(RpcError.recipientDisconnected));
    }
  }

  /// Single resolution path. Guarantees the completer is settled exactly once and that
  /// both timers are cancelled before the entry is removed.
  void _complete(String requestId, {String? payload, RpcError? error}) {
    final pending = _pending[requestId];
    if (pending == null || pending.done) {
      return;
    }
    pending.done = true;
    pending.ackTimer?.cancel();
    pending.responseTimer?.cancel();
    _pending.remove(requestId);

    if (error != null) {
      pending.completer.completeError(error);
    } else {
      pending.completer.complete(payload ?? '');
    }
  }

  /// Clean up on room disposal. Pending requests are rejected with `connectionTimeout`.
  void dispose() {
    final pending = _pending.keys.toList();
    for (final requestId in pending) {
      _complete(requestId, error: RpcError.builtIn(RpcError.connectionTimeout));
    }
    _pending.clear();
  }

  @visibleForTesting
  bool hasPending(String requestId) => _pending.containsKey(requestId);

  @visibleForTesting
  int get pendingCount => _pending.length;
}
