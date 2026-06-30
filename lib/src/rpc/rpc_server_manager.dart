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

import 'package:meta/meta.dart';

import '../core/room.dart';
import '../data_stream/stream_reader.dart';
import '../logger.dart';
import '../participant/local.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../types/data_stream.dart';
import '../types/other.dart';
import '../types/rpc.dart';

/// Handler-side RPC dispatcher. Owns the registered-method map and routes incoming
/// requests (v1 packets and v2 data streams) to user handlers, choosing the response
/// transport per the spec's negotiation table.
@internal
class RpcServerManager {
  RpcServerManager(this._room);

  final Room _room;
  final Map<String, RpcRequestHandler> handlers = {};

  void registerMethod(String method, RpcRequestHandler handler) {
    if (handlers.containsKey(method)) {
      throw Exception('Method $method already registered');
    }
    handlers[method] = handler;
  }

  void unregisterMethod(String method) {
    handlers.remove(method);
  }

  // ---------- v1 inbound (packet) ----------

  Future<void> handleIncomingV1Request(
    String callerIdentity,
    String requestId,
    String method,
    String payload,
    num responseTimeoutMs,
    num version,
  ) async {
    await _publishAck(destinationIdentity: callerIdentity, requestId: requestId);

    if (version != kRpcVersion) {
      await _sendResponse(
        callerIdentity: callerIdentity,
        requestId: requestId,
        error: RpcError.builtIn(RpcError.unsupportedVersion),
        callerIsV2: false,
      );
      return;
    }

    await _dispatch(
      callerIdentity: callerIdentity,
      requestId: requestId,
      method: method,
      payload: payload,
      responseTimeoutMs: responseTimeoutMs,
      callerIsV2: false,
    );
  }

  // ---------- v2 inbound (text data stream on lk.rpc_request) ----------

  Future<void> handleIncomingV2RequestStream(TextStreamReader reader, String callerIdentity) async {
    final attrs = reader.info?.attributes ?? const <String, String>{};
    final requestId = attrs[kRpcAttrRequestId];
    final method = attrs[kRpcAttrMethod];
    final timeoutMsStr = attrs[kRpcAttrResponseTimeoutMs];
    final versionStr = attrs[kRpcAttrVersion];

    if (requestId == null || method == null || timeoutMsStr == null || versionStr == null) {
      logger.warning('v2 RPC request stream missing required attribute(s); ignoring');
      return;
    }
    if (versionStr != kRpcRequestVersionV2) {
      logger.warning('v2 RPC request stream has unexpected version "$versionStr"; ignoring');
      return;
    }

    final responseTimeoutMs = int.tryParse(timeoutMsStr) ?? 0;

    // Send ack first so the caller cancels its 7s ack timer even if the payload is huge
    // or no handler is registered for this method.
    await _publishAck(destinationIdentity: callerIdentity, requestId: requestId);

    final payload = await reader.readAll();

    await _dispatch(
      callerIdentity: callerIdentity,
      requestId: requestId,
      method: method,
      payload: payload,
      responseTimeoutMs: responseTimeoutMs,
      callerIsV2: true,
    );
  }

  // ---------- shared dispatch ----------

  Future<void> _dispatch({
    required String callerIdentity,
    required String requestId,
    required String method,
    required String payload,
    required num responseTimeoutMs,
    required bool callerIsV2,
  }) async {
    final handler = handlers[method];
    if (handler == null) {
      await _sendResponse(
        callerIdentity: callerIdentity,
        requestId: requestId,
        error: RpcError.builtIn(RpcError.unsupportedMethod),
        callerIsV2: callerIsV2,
      );
      return;
    }

    String? responsePayload;
    RpcError? responseError;

    try {
      final response = await handler(RpcInvocationData(
        requestId: requestId,
        callerIdentity: callerIdentity,
        payload: payload,
        responseTimeoutMs: responseTimeoutMs.toInt(),
      ));
      responsePayload = response;
    } catch (error) {
      if (error is RpcError) {
        responseError = error;
      } else {
        logger.warning(
            'Uncaught error returned by RPC handler for $method. Returning RpcError.applicationError instead. $error');
        responseError = RpcError(code: RpcError.applicationError, message: error.toString());
      }
    }

    await _sendResponse(
      callerIdentity: callerIdentity,
      requestId: requestId,
      payload: responsePayload,
      error: responseError,
      callerIsV2: callerIsV2,
    );

    logger.fine('RPC request $method handled');
  }

  // ---------- transport selection ----------

  Future<void> _sendResponse({
    required String callerIdentity,
    required String requestId,
    String? payload,
    RpcError? error,
    required bool callerIsV2,
  }) async {
    if (error != null) {
      // Errors always travel as v1 RpcResponse packets, even between two v2 peers.
      await _publishV1Response(
        callerIdentity: callerIdentity,
        requestId: requestId,
        error: _truncateForWire(error),
      );
      return;
    }

    final body = payload ?? '';

    if (callerIsV2) {
      // v2 success: payload over data stream, no size limit.
      await _publishV2Response(callerIdentity: callerIdentity, requestId: requestId, payload: body);
      return;
    }

    // v1 caller: enforce the legacy size limit on success payloads.
    if (body.length > kRpcMaxPayloadBytes) {
      logger.warning('RPC response payload too large for v1 caller; converting to error');
      await _publishV1Response(
        callerIdentity: callerIdentity,
        requestId: requestId,
        error: RpcError.builtIn(RpcError.responsePayloadTooLarge),
      );
      return;
    }

    await _publishV1Response(
      callerIdentity: callerIdentity,
      requestId: requestId,
      payload: body,
    );
  }

  // ---------- low-level publishers ----------

  Future<void> _publishAck({
    required String destinationIdentity,
    required String requestId,
  }) async {
    final packet = lk_models.DataPacket(
      kind: lk_models.DataPacket_Kind.RELIABLE,
      rpcAck: lk_models.RpcAck(requestId: requestId),
      destinationIdentities: [destinationIdentity],
      participantIdentity: _room.localParticipant?.identity,
    );
    await _room.engine.sendDataPacket(packet, reliability: Reliability.reliable);
  }

  Future<void> _publishV1Response({
    required String callerIdentity,
    required String requestId,
    String? payload,
    RpcError? error,
  }) async {
    final packet = lk_models.DataPacket(
      kind: lk_models.DataPacket_Kind.RELIABLE,
      rpcResponse: lk_models.RpcResponse(
        requestId: requestId,
        payload: error == null ? payload : null,
        error: error?.toProto(),
      ),
      destinationIdentities: [callerIdentity],
      participantIdentity: _room.localParticipant?.identity,
    );
    await _room.engine.sendDataPacket(packet, reliability: Reliability.reliable);
  }

  Future<void> _publishV2Response({
    required String callerIdentity,
    required String requestId,
    required String payload,
  }) async {
    final local = _room.localParticipant;
    if (local == null) {
      logger.warning('Cannot send v2 RPC response: no local participant');
      return;
    }
    final writer = await local.streamText(StreamTextOptions(
      topic: kRpcResponseTopic,
      destinationIdentities: [callerIdentity],
      attributes: {kRpcAttrRequestId: requestId},
    ));
    await writer.write(payload);
    await writer.close();
  }

  // Errors are always sent as packets. Cap both message and data at the v1 payload
  // limit so an oversize error from a misbehaving handler cannot blow the packet budget.
  RpcError _truncateForWire(RpcError error) {
    final originalMessage = error.message;
    final originalData = error.data;

    final truncatedMessage = originalMessage.length > kRpcMaxPayloadBytes
        ? originalMessage.substring(0, kRpcMaxPayloadBytes)
        : originalMessage;

    String? truncatedData;
    if (originalData != null) {
      truncatedData =
          originalData.length > kRpcMaxPayloadBytes ? originalData.substring(0, kRpcMaxPayloadBytes) : originalData;
    }

    if (truncatedMessage.length != originalMessage.length ||
        (originalData != null && truncatedData!.length != originalData.length)) {
      logger.fine('RPC error fields truncated to fit v1 packet limit');
      return RpcError(code: error.code, message: truncatedMessage, data: truncatedData);
    }
    return error;
  }
}
