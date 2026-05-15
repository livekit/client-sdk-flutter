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

@Timeout(Duration(seconds: 10))
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';

void main() {
  E2EContainer? container;
  late Room room;

  group('rpc tests', () {
    test('test rpc handler register', () async {
      container = E2EContainer();
      room = container!.room;
      await container!.connectRoom();

      room.registerRpcMethod('echo', (RpcInvocationData data) async {
        return 'echo: => ${data.callerIdentity} ${data.payload}';
      });

      expect(room.rpcHandlers.keys.first, 'echo');

      final response = await room.rpcHandlers['echo']!(RpcInvocationData(
        requestId: '1',
        callerIdentity: room.localParticipant!.identity,
        payload: 'hello',
        responseTimeoutMs: 10000,
      ));

      expect(response, 'echo: => ${room.localParticipant!.identity} hello');

      room.unregisterRpcMethod('echo');

      expect(room.rpcHandlers.keys.length, 0);
    });

    test('test rpc perform', () async {
      room.registerRpcMethod('echo', (RpcInvocationData data) async {
        return 'echo: => ${data.callerIdentity} ${data.payload}';
      });

      /// test performRpc
      final response = await room.localParticipant?.performRpc(PerformRpcParams(
        destinationIdentity: room.localParticipant!.identity,
        method: 'echo',
        payload: 'hello',
      ));

      expect(response, 'echo: => ${room.localParticipant!.identity} hello');

      RpcError? error;

      /// test unsupported server version
      try {
        room.engine.serverInfo?.version = '1.7.9';

        await room.localParticipant?.performRpc(PerformRpcParams(
          destinationIdentity: room.localParticipant!.identity,
          method: 'echo',
          payload: 'hello',
        ));
      } catch (e) {
        if (e is RpcError) {
          error = e;

          /// set back to supported version
          room.engine.serverInfo?.version = '1.8.0';
          room.unregisterRpcMethod('echo');
        }
      }

      expect(
        RpcError.unsupportedServer,
        error?.code,
      );
    });

    test('test rpc perform with error', () async {
      room.registerRpcMethod('echo', (RpcInvocationData data) async {
        return throw RpcError(
          message: 'error',
          code: 1,
          data: 'error data',
        );
      });
      RpcError? error;
      try {
        await room.localParticipant?.performRpc(PerformRpcParams(
          destinationIdentity: room.localParticipant!.identity,
          method: 'echo',
          payload: 'hello',
        ));
      } catch (e) {
        if (e is RpcError) {
          error = e;
        }
      }

      expect(error!.code, 1);
      expect(error.message, 'error');
      expect(error.data, 'error data');

      room.unregisterRpcMethod('echo');
    });

    test('test unpupported method error', () async {
      RpcError? error;

      try {
        await room.localParticipant?.performRpc(PerformRpcParams(
          destinationIdentity: room.localParticipant!.identity,
          method: 'no_method',
          payload: 'hello',
        ));
      } catch (e) {
        if (e is RpcError) {
          error = e;
        }
      }

      expect(
        RpcError.unsupportedMethod,
        error?.code,
      );
    });

    test('test request playload too large', () async {
      RpcError? error;
      try {
        await room.localParticipant?.performRpc(PerformRpcParams(
          destinationIdentity: room.localParticipant!.identity,
          method: 'echo',
          payload: 'a' * 1024 * 1024,
        ));
      } catch (e) {
        if (e is RpcError) {
          error = e;
        }
      }

      expect(
        RpcError.requestPayloadTooLarge,
        error?.code,
      );
    });

    test('test response playload too large', () async {
      room.registerRpcMethod('echo', (RpcInvocationData data) async {
        return 'a' * 1024 * 1024;
      });
      RpcError? error;
      try {
        await room.localParticipant?.performRpc(PerformRpcParams(
          destinationIdentity: room.localParticipant!.identity,
          method: 'echo',
          payload: 'hello',
        ));
      } catch (e) {
        if (e is RpcError) {
          error = e;
        }
      }

      expect(error!.code, RpcError.responsePayloadTooLarge);

      room.unregisterRpcMethod('echo');
    });

    test('test application error', () async {
      RpcError? error;
      room.registerRpcMethod('echo', (RpcInvocationData data) async {
        throw Exception('application error');
      });

      try {
        await room.localParticipant?.performRpc(PerformRpcParams(
          destinationIdentity: room.localParticipant!.identity,
          method: 'echo',
          payload: 'hello',
        ));
      } catch (e) {
        if (e is RpcError) {
          error = e;
        }
      }

      expect(
        RpcError.applicationError,
        error?.code,
      );

      room.unregisterRpcMethod('echo');
    });
    test('test response timeout', () async {
      room.registerRpcMethod('echo', (RpcInvocationData data) async {
        await Future.delayed(Duration(seconds: 10));
        return 'echo: => ${data.callerIdentity} ${data.payload}';
      });
      RpcError? error;
      try {
        await room.localParticipant?.performRpc(PerformRpcParams(
          destinationIdentity: room.localParticipant!.identity,
          method: 'echo',
          payload: 'hello',
          responseTimeoutMs: Duration(seconds: 2),
        ));
      } catch (e) {
        if (e is RpcError) {
          error = e;
        }
      }

      expect(
        RpcError.responseTimeout,
        error?.code,
      );
    });
  });

  // RPC v2 tests run with the local participant advertising
  // `clientProtocol = kClientProtocolDataStreamRpc`, so the self-loop path
  // routes through the data-stream transport instead of the v1 packet path.
  group('rpc v2 tests', () {
    late E2EContainer v2Container;
    late Room v2Room;

    setUpAll(() async {
      // Tear down any previous container's data channels so the new pair gets wired.
      resetMockDataChannels();
      v2Container = E2EContainer();
      v2Room = v2Container.room;
      await v2Container.connectRoom(
        localClientProtocol: kClientProtocolDataStreamRpc,
        captureOutbound: true,
      );
    });

    bool hasOutboundPacketWhere(bool Function(lk_models.DataPacket) test) => v2Container.capturedDataPackets.any(test);

    test('v2 caller happy path (short payload)', () async {
      v2Container.capturedDataPackets.clear();
      v2Room.registerRpcMethod('echo-v2', (RpcInvocationData data) async {
        return 'echo: ${data.payload}';
      });

      final response = await v2Room.localParticipant!.performRpc(PerformRpcParams(
        destinationIdentity: v2Room.localParticipant!.identity,
        method: 'echo-v2',
        payload: 'hello v2',
      ));

      expect(response, 'echo: hello v2');
      // Spec: v2 requests must use data streams, never the rpcRequest packet.
      expect(
        hasOutboundPacketWhere((p) => p.whichValue() == lk_models.DataPacket_Value.rpcRequest),
        isFalse,
        reason: 'v2 caller should not produce any RpcRequest packets',
      );
      // Spec: v2 success responses use data streams, not the rpcResponse packet.
      expect(
        hasOutboundPacketWhere((p) => p.whichValue() == lk_models.DataPacket_Value.rpcResponse),
        isFalse,
        reason: 'v2 success response should not produce any RpcResponse packets',
      );
      // The request and response both flow as text streams on the reserved topics.
      expect(
        hasOutboundPacketWhere((p) =>
            p.whichValue() == lk_models.DataPacket_Value.streamHeader && p.streamHeader.topic == kRpcRequestTopic),
        isTrue,
      );
      expect(
        hasOutboundPacketWhere((p) =>
            p.whichValue() == lk_models.DataPacket_Value.streamHeader && p.streamHeader.topic == kRpcResponseTopic),
        isTrue,
      );

      v2Room.unregisterRpcMethod('echo-v2');
    });

    test('v2 large payload (> 15 KB) succeeds without size error', () async {
      v2Container.capturedDataPackets.clear();
      final big = 'a' * 20000; // exceeds kRpcMaxPayloadBytes (15360)

      v2Room.registerRpcMethod('echo-big', (RpcInvocationData data) async {
        // Confirm the handler sees the full payload.
        expect(data.payload.length, 20000);
        return data.payload; // echo a 20k response
      });

      final response = await v2Room.localParticipant!.performRpc(PerformRpcParams(
        destinationIdentity: v2Room.localParticipant!.identity,
        method: 'echo-big',
        payload: big,
        responseTimeoutMs: const Duration(seconds: 30),
      ));

      expect(response.length, 20000);
      expect(response, big);

      v2Room.unregisterRpcMethod('echo-big');
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('v2 unregistered method: ack then v1 error packet', () async {
      v2Container.capturedDataPackets.clear();
      RpcError? error;
      try {
        await v2Room.localParticipant!.performRpc(PerformRpcParams(
          destinationIdentity: v2Room.localParticipant!.identity,
          method: 'method-does-not-exist',
          payload: 'x',
        ));
      } catch (e) {
        if (e is RpcError) error = e;
      }

      expect(error?.code, RpcError.unsupportedMethod);

      // An ack packet must be observed regardless (handler is alive).
      expect(
        hasOutboundPacketWhere((p) => p.whichValue() == lk_models.DataPacket_Value.rpcAck),
        isTrue,
        reason: 'handler must ack before rejecting unknown method',
      );
      // Error responses are always packets, never streams.
      expect(
        hasOutboundPacketWhere((p) =>
            p.whichValue() == lk_models.DataPacket_Value.rpcResponse &&
            p.rpcResponse.hasError() &&
            p.rpcResponse.error.code == RpcError.unsupportedMethod),
        isTrue,
      );
      // No v2 response stream should be opened on the response topic.
      expect(
        hasOutboundPacketWhere((p) =>
            p.whichValue() == lk_models.DataPacket_Value.streamHeader && p.streamHeader.topic == kRpcResponseTopic),
        isFalse,
      );
    });

    test('v2 unhandled error returns APPLICATION_ERROR via packet', () async {
      v2Container.capturedDataPackets.clear();
      v2Room.registerRpcMethod('throws-generic', (_) async {
        throw Exception('boom');
      });

      RpcError? error;
      try {
        await v2Room.localParticipant!.performRpc(PerformRpcParams(
          destinationIdentity: v2Room.localParticipant!.identity,
          method: 'throws-generic',
          payload: 'x',
        ));
      } catch (e) {
        if (e is RpcError) error = e;
      }

      expect(error?.code, RpcError.applicationError);
      // Error responses always travel as packets, even between v2 peers.
      expect(
        hasOutboundPacketWhere((p) =>
            p.whichValue() == lk_models.DataPacket_Value.rpcResponse &&
            p.rpcResponse.hasError() &&
            p.rpcResponse.error.code == RpcError.applicationError),
        isTrue,
      );
      expect(
        hasOutboundPacketWhere((p) =>
            p.whichValue() == lk_models.DataPacket_Value.streamHeader && p.streamHeader.topic == kRpcResponseTopic),
        isFalse,
        reason: 'error responses must not use a data stream',
      );

      v2Room.unregisterRpcMethod('throws-generic');
    });

    test('v2 RpcError passthrough preserves code and message', () async {
      v2Container.capturedDataPackets.clear();
      v2Room.registerRpcMethod('throws-rpc-error', (_) async {
        throw RpcError(code: 101, message: 'Custom error', data: 'extra');
      });

      RpcError? error;
      try {
        await v2Room.localParticipant!.performRpc(PerformRpcParams(
          destinationIdentity: v2Room.localParticipant!.identity,
          method: 'throws-rpc-error',
          payload: 'x',
        ));
      } catch (e) {
        if (e is RpcError) error = e;
      }

      expect(error?.code, 101);
      expect(error?.message, 'Custom error');
      expect(error?.data, 'extra');

      v2Room.unregisterRpcMethod('throws-rpc-error');
    });

    test('v2 response timeout', () async {
      v2Container.capturedDataPackets.clear();
      v2Room.registerRpcMethod('hangs', (_) async {
        await Future.delayed(const Duration(seconds: 10));
        return 'never';
      });

      RpcError? error;
      try {
        await v2Room.localParticipant!.performRpc(PerformRpcParams(
          destinationIdentity: v2Room.localParticipant!.identity,
          method: 'hangs',
          payload: 'x',
          responseTimeoutMs: const Duration(seconds: 2),
        ));
      } catch (e) {
        if (e is RpcError) error = e;
      }

      expect(error?.code, RpcError.responseTimeout);
      v2Room.unregisterRpcMethod('hangs');
    });

    test('v2 concurrent performRpc calls resolve independently', () async {
      v2Container.capturedDataPackets.clear();
      v2Room.registerRpcMethod('echo-concurrent', (RpcInvocationData data) async {
        return 'r-${data.payload}';
      });

      final futures = List.generate(
        5,
        (i) => v2Room.localParticipant!.performRpc(PerformRpcParams(
          destinationIdentity: v2Room.localParticipant!.identity,
          method: 'echo-concurrent',
          payload: '$i',
        )),
      );

      final results = await Future.wait(futures);
      expect(results, ['r-0', 'r-1', 'r-2', 'r-3', 'r-4']);
      // Five distinct outbound request streams.
      final requestHeaders = v2Container.capturedDataPackets.where(
          (p) => p.whichValue() == lk_models.DataPacket_Value.streamHeader && p.streamHeader.topic == kRpcRequestTopic);
      expect(requestHeaders.length, greaterThanOrEqualTo(5));

      v2Room.unregisterRpcMethod('echo-concurrent');
    });

    test('v2 participant disconnect rejects pending RPCs', () async {
      // Inject a remote participant that supports v2.
      await v2Container.simulateRemoteParticipantJoin('alice', clientProtocol: kClientProtocolDataStreamRpc);

      // Register a handler that never completes so the request never resolves on its own.
      // The remote 'alice' is fake; our local engine will still see the v2 request
      // stream via loopback and try to invoke the handler — which hangs forever.
      v2Room.registerRpcMethod('hangs-for-alice', (_) async {
        await Future.delayed(const Duration(seconds: 60));
        return 'never';
      });

      // Attach the catch handler synchronously so the future's eventual rejection
      // isn't reported as an unhandled async error if it lands before `await`.
      RpcError? error;
      final caught = v2Room.localParticipant!
          .performRpc(PerformRpcParams(
        destinationIdentity: 'alice',
        method: 'hangs-for-alice',
        payload: 'x',
        responseTimeoutMs: const Duration(seconds: 30),
      ))
          .catchError((e) {
        if (e is RpcError) error = e;
        return '';
      });

      // Let the publish settle so pending is registered.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Simulate alice disconnecting.
      await v2Container.simulateRemoteParticipantDisconnect('alice');

      await caught;
      expect(error?.code, RpcError.recipientDisconnected);

      v2Room.unregisterRpcMethod('hangs-for-alice');
    });

    test('v2 response stream from wrong sender is ignored', () async {
      v2Container.capturedDataPackets.clear();
      // Inject the legitimate destination.
      await v2Container.simulateRemoteParticipantJoin('bob', clientProtocol: kClientProtocolDataStreamRpc);

      // Register a hanging handler so the legit response never arrives during the test window.
      v2Room.registerRpcMethod('hangs-for-bob', (_) async {
        await Future.delayed(const Duration(seconds: 60));
        return 'never';
      });

      bool resolved = false;
      RpcError? caught;
      final future = v2Room.localParticipant!
          .performRpc(PerformRpcParams(
            destinationIdentity: 'bob',
            method: 'hangs-for-bob',
            payload: 'x',
            responseTimeoutMs: const Duration(seconds: 30),
          ))
          .then((_) => resolved = true)
          .catchError((e) {
        if (e is RpcError) caught = e;
        return false;
      });

      // Let the publish settle and the request stream loop back.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Extract the request_id the SDK generated, from the outbound request stream header.
      final requestHeader = v2Container.capturedDataPackets.firstWhere(
        (p) => p.whichValue() == lk_models.DataPacket_Value.streamHeader && p.streamHeader.topic == kRpcRequestTopic,
      );
      final requestId = requestHeader.streamHeader.attributes[kRpcAttrRequestId]!;

      // Inject a v2 response from "mallory" — wrong sender. Should be ignored.
      v2Container.simulateInboundV2RpcResponseStream('mallory', requestId, 'evil payload');

      // Give the response handler time to run and discard.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Pending must still be unresolved.
      expect(resolved, isFalse);
      expect(caught, isNull);

      // Now disconnect bob to release the pending entry cleanly.
      await v2Container.simulateRemoteParticipantDisconnect('bob');
      await future;
      // After disconnect, the pending should resolve to recipientDisconnected — not the
      // payload "evil payload" from mallory.
      expect(caught?.code, RpcError.recipientDisconnected);

      v2Room.unregisterRpcMethod('hangs-for-bob');
    });
  });
}
