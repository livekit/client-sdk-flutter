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

import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' show RTCDataChannelMessage;

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/core/engine.dart';
import 'package:livekit_client/src/core/signal_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import '../core/signal_client_test.dart';
import 'peerconnection_mock.dart';
import 'test_data.dart';
import 'websocket_mock.dart';

class E2EContainer {
  late MockWebSocketConnector wsConnector;
  late SignalClient client;
  late Room room;
  late Engine engine;

  /// All `DataPacket`s sent by the SDK over the (publisher) reliable data channel
  /// since [connectRoom] returned. Populated only when [captureOutbound] is true.
  final List<lk_models.DataPacket> capturedDataPackets = [];

  E2EContainer() {
    wsConnector = MockWebSocketConnector();
    client = SignalClient(wsConnector.connect);
    engine = Engine(
      connectOptions: const ConnectOptions(),
      roomOptions: const RoomOptions(),
      signalClient: client,
      peerConnectionCreate: MockPeerConnection.create,
    );
    room = Room(engine: engine);
  }

  Future<void> dispose() async {
    await room.dispose();
  }

  /// Connect the room. If [localClientProtocol] is non-null, the join response
  /// is rewritten so the local participant's [Participant.clientProtocol] takes
  /// that value (used to exercise v1 vs v2 caller paths in self-loop tests).
  /// When [captureOutbound] is true, all DataPackets sent over the reliable
  /// data channel are recorded in [capturedDataPackets].
  Future<void> connectRoom({int? localClientProtocol, bool captureOutbound = false}) async {
    final connectFuture = room.connect(exampleUri, token);
    Future.delayed(const Duration(milliseconds: 1), () {
      final resp = _buildJoinResponse(localClientProtocol);
      wsConnector.onData(resp.writeToBuffer());
      wsConnector.onData(offerResponse.writeToBuffer());
    });

    await connectFuture;

    // Simulate the SFU stamping `participantIdentity` on forwarded packets that
    // don't carry it (data-stream header/chunk/trailer come from streamText without
    // it). Without this shim, the v2 RPC sender-validation check (correctly) rejects
    // every self-loop response as "from an empty sender".
    _installSfuIdentityShim();

    if (captureOutbound) {
      _installOutboundCapture();
    }
  }

  void _installSfuIdentityShim() {
    final localIdentity = room.localParticipant?.identity ?? '';
    if (localIdentity.isEmpty) return;
    for (final dc in mockDataChannels) {
      final existing = dc.onMessageSend;
      dc.onMessageSend = (RTCDataChannelMessage message) {
        RTCDataChannelMessage forwarded = message;
        try {
          final packet = lk_models.DataPacket.fromBuffer(message.binary);
          if (packet.participantIdentity.isEmpty) {
            packet.participantIdentity = localIdentity;
            forwarded = RTCDataChannelMessage.fromBinary(Uint8List.fromList(packet.writeToBuffer()));
          }
        } catch (_) {
          // not a DataPacket — forward unchanged
        }
        existing?.call(forwarded);
      };
    }
  }

  lk_rtc.SignalResponse _buildJoinResponse(int? localClientProtocol) {
    if (localClientProtocol == null) {
      return joinResponse;
    }
    final localInfo = localParticipantData.deepCopy()..clientProtocol = localClientProtocol;
    return lk_rtc.SignalResponse(
      join: lk_rtc.JoinResponse(
        room: lk_models.Room(name: 'room_name', sid: 'room_sid'),
        participant: localInfo,
        subscriberPrimary: true,
        serverVersion: '99.999',
        serverInfo: lk_models.ServerInfo(version: '1.8.0'),
      ),
    );
  }

  void _installOutboundCapture() {
    // Wrap every reliable data channel's onMessageSend so we record outbound packets
    // before the loopback fires. The mock pairs two channels into a publisher/subscriber
    // loop; wrapping both keeps the loop intact.
    for (final dc in mockDataChannels) {
      final existing = dc.onMessageSend;
      dc.onMessageSend = (RTCDataChannelMessage message) {
        try {
          capturedDataPackets.add(lk_models.DataPacket.fromBuffer(message.binary));
        } catch (_) {
          // ignore non-DataPacket messages
        }
        existing?.call(message);
      };
    }
  }

  /// Inject a remote participant into the room with the given identity and
  /// client protocol. Returns the [RemoteParticipant] once the SDK has processed
  /// the synthetic [ParticipantUpdate].
  Future<void> simulateRemoteParticipantJoin(
    String identity, {
    int clientProtocol = kClientProtocolDataStreamRpc,
    String? sid,
  }) async {
    final info = lk_models.ParticipantInfo(
      sid: sid ?? '${identity}_sid',
      identity: identity,
      state: lk_models.ParticipantInfo_State.ACTIVE,
      clientProtocol: clientProtocol,
    );
    final resp = lk_rtc.SignalResponse(
      update: lk_rtc.ParticipantUpdate(participants: [info]),
    );
    wsConnector.onData(resp.writeToBuffer());
    // Let the signal listener process the update.
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  /// Synthesize a disconnect for a previously injected remote participant.
  Future<void> simulateRemoteParticipantDisconnect(String identity, {String? sid}) async {
    final info = lk_models.ParticipantInfo(
      sid: sid ?? '${identity}_sid',
      identity: identity,
      state: lk_models.ParticipantInfo_State.DISCONNECTED,
    );
    final resp = lk_rtc.SignalResponse(
      update: lk_rtc.ParticipantUpdate(participants: [info]),
    );
    wsConnector.onData(resp.writeToBuffer());
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  /// Feed a raw DataPacket into the subscriber-side data channel as if a remote
  /// participant had sent it.
  void deliverInboundDataPacket(lk_models.DataPacket packet) {
    // Find the subscriber data channel (the one whose `onMessage` is wired up by
    // the engine to receive incoming packets). In the mock both channels in a
    // pair end up with an onMessage handler — feed it into the one that the
    // local engine treats as inbound.
    final channel = findMockDataChannelByLabel('_reliable', requireListener: true);
    if (channel == null) {
      throw StateError('No reliable mock data channel available; was connectRoom() awaited?');
    }
    channel.onMessage?.call(RTCDataChannelMessage.fromBinary(Uint8List.fromList(packet.writeToBuffer())));
  }

  void simulateInboundRpcAck(String fromIdentity, String requestId) {
    deliverInboundDataPacket(lk_models.DataPacket(
      kind: lk_models.DataPacket_Kind.RELIABLE,
      participantIdentity: fromIdentity,
      rpcAck: lk_models.RpcAck(requestId: requestId),
    ));
  }

  void simulateInboundRpcResponse(
    String fromIdentity,
    String requestId, {
    String? payload,
    lk_models.RpcError? error,
  }) {
    deliverInboundDataPacket(lk_models.DataPacket(
      kind: lk_models.DataPacket_Kind.RELIABLE,
      participantIdentity: fromIdentity,
      rpcResponse: lk_models.RpcResponse(
        requestId: requestId,
        payload: error == null ? payload : null,
        error: error,
      ),
    ));
  }

  /// Simulate a v2 RPC response data stream from [fromIdentity] for [requestId].
  /// Sends the header, one chunk containing [payload], and a trailer.
  void simulateInboundV2RpcResponseStream(String fromIdentity, String requestId, String payload) {
    _simulateInboundTextStream(
      fromIdentity: fromIdentity,
      topic: kRpcResponseTopic,
      attributes: {kRpcAttrRequestId: requestId},
      body: payload,
    );
  }

  /// Simulate a v2 RPC request data stream from [fromIdentity].
  void simulateInboundV2RpcRequestStream({
    required String fromIdentity,
    required String requestId,
    required String method,
    required String payload,
    int responseTimeoutMs = 10000,
  }) {
    _simulateInboundTextStream(
      fromIdentity: fromIdentity,
      topic: kRpcRequestTopic,
      attributes: {
        kRpcAttrRequestId: requestId,
        kRpcAttrMethod: method,
        kRpcAttrResponseTimeoutMs: responseTimeoutMs.toString(),
        kRpcAttrVersion: '2',
      },
      body: payload,
    );
  }

  void _simulateInboundTextStream({
    required String fromIdentity,
    required String topic,
    required Map<String, String> attributes,
    required String body,
  }) {
    final streamId = '$topic-${attributes[kRpcAttrRequestId] ?? DateTime.now().microsecondsSinceEpoch}';
    final header = lk_models.DataStream_Header(
      streamId: streamId,
      mimeType: 'text/plain',
      topic: topic,
      timestamp: Int64(DateTime.now().millisecondsSinceEpoch),
      totalLength: Int64(body.length),
      attributes: attributes.entries,
      textHeader: lk_models.DataStream_TextHeader(),
    );
    deliverInboundDataPacket(lk_models.DataPacket(
      kind: lk_models.DataPacket_Kind.RELIABLE,
      participantIdentity: fromIdentity,
      streamHeader: header,
    ));

    final chunk = lk_models.DataStream_Chunk(
      streamId: streamId,
      chunkIndex: Int64(0),
      content: Uint8List.fromList(body.codeUnits),
    );
    deliverInboundDataPacket(lk_models.DataPacket(
      kind: lk_models.DataPacket_Kind.RELIABLE,
      participantIdentity: fromIdentity,
      streamChunk: chunk,
    ));

    final trailer = lk_models.DataStream_Trailer(streamId: streamId);
    deliverInboundDataPacket(lk_models.DataPacket(
      kind: lk_models.DataPacket_Kind.RELIABLE,
      participantIdentity: fromIdentity,
      streamTrailer: trailer,
    ));
  }
}
