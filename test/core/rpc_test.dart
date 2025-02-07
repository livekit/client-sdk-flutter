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

@Timeout(Duration(seconds: 5))
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import '../mock/e2e_container.dart';

void main() {
  E2EContainer? container;
  late Room room;

  group('rpc tests', () {
    test('test rpc handler register', () async {
      container = E2EContainer();
      room = container!.room;
      await container!.connectRoom();

      room.registerRpcHandler('echo', (RpcInvocationData data) async {
        return 'echo: => ${data.callerIdentity} ${data.payload}';
      });

      expect(room.rpcHandlers.keys.first, 'echo');

      var response = await room.rpcHandlers['echo']!(RpcInvocationData(
        requestId: '1',
        callerIdentity: room.localParticipant!.identity,
        payload: 'hello',
        responseTimeoutMs: 10000,
      ));

      expect(response, 'echo: => ${room.localParticipant!.identity} hello');

      room.unregisterRpcHandler('echo');

      expect(room.rpcHandlers.keys.length, 0);
    });

    test('test rpc perform', () async {
      room.registerRpcHandler('echo', (RpcInvocationData data) async {
        return 'echo: => ${data.callerIdentity} ${data.payload}';
      });

      expect(room.rpcHandlers.keys.first, 'echo');

      /// test performRpc
      var response = await room.performRpc(PerformRpcParams(
        destinationIdentity: room.localParticipant!.identity,
        method: 'echo',
        payload: 'hello',
      ));

      expect(response, 'echo: => ${room.localParticipant!.identity} hello');

      /// test unsupported server version
      try {
        room.engine.serverInfo?.version = '1.7.9';

        await room.performRpc(PerformRpcParams(
          destinationIdentity: room.localParticipant!.identity,
          method: 'echo',
          payload: 'hello',
        ));
      } catch (e) {
        if (e is RpcError) {
          expect(e.code, RpcError.unsupportedServer);

          /// set back to supported version
          room.engine.serverInfo?.version = '1.8.0';
        }
      }
    });

    test('test rpc perform with error', () async {
      room.registerRpcHandler('echo', (RpcInvocationData data) async {
        return throw RpcError(
          message: 'error',
          code: 1,
          data: 'error data',
        );
      });

      try {
        await room.performRpc(PerformRpcParams(
          destinationIdentity: room.localParticipant!.identity,
          method: 'echo',
          payload: 'hello',
        ));
      } catch (e) {
        if (e is RpcError) {
          expect(e.code, 1);
          expect(e.message, 'error');
          expect(e.data, 'error data');
        }
      }
    });

    test('test unpupported method error', () async {
      try {
        await room.performRpc(PerformRpcParams(
          destinationIdentity: room.localParticipant!.identity,
          method: 'no_method',
          payload: 'hello',
        ));
      } catch (e) {
        if (e is RpcError) {
          expect(e.code, RpcError.unsupportedMethod);
        }
      }
    });

    test('test request playload too large', () async {
      try {
        await room.performRpc(PerformRpcParams(
          destinationIdentity: room.localParticipant!.identity,
          method: 'echo',
          payload: 'a' * 1024 * 1024,
        ));
      } catch (e) {
        if (e is RpcError) {
          expect(e.code, RpcError.requestPayloadTooLarge);
        }
      }
    });

    test('test response playload too large', () async {
      room.registerRpcHandler('echo', (RpcInvocationData data) async {
        return 'a' * 1024 * 1024;
      });

      try {
        await room.performRpc(PerformRpcParams(
          destinationIdentity: room.localParticipant!.identity,
          method: 'echo',
          payload: 'hello',
        ));
      } catch (e) {
        if (e is RpcError) {
          expect(e.code, RpcError.responsePayloadTooLarge);
        }
      }
    });

    test('test application error', () async {
      room.registerRpcHandler('echo', (RpcInvocationData data) async {
        throw Exception('application error');
      });

      try {
        await room.performRpc(PerformRpcParams(
          destinationIdentity: room.localParticipant!.identity,
          method: 'echo',
          payload: 'hello',
        ));
      } catch (e) {
        if (e is RpcError) {
          expect(e.code, RpcError.applicationError);
        }
      }
    });
  });
}
