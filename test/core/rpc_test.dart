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

      room.registerRpcMethod('echo', (RpcInvocationData data) async {
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

      room.unregisterRpcMethod('echo');

      expect(room.rpcHandlers.keys.length, 0);
    });

    test('test rpc perform', () async {
      room.registerRpcMethod('echo', (RpcInvocationData data) async {
        return 'echo: => ${data.callerIdentity} ${data.payload}';
      });

      /// test performRpc
      var response = await room.localParticipant?.performRpc(PerformRpcParams(
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
}
