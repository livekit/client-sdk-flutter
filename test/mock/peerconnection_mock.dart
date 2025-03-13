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

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'datachannel_mock.dart';

List<MockDataChannel> _dataChannels = [];

class MockPeerConnection extends RTCPeerConnection {
  static const _offerType = 'offer';
  static const _answerType = 'answer';

  bool closed = false;
  RTCSessionDescription? _localDescription;
  RTCSessionDescription? _remoteDescription;

  RTCPeerConnectionState _connectionState =
      RTCPeerConnectionState.RTCPeerConnectionStateNew;
  RTCIceConnectionState _iceConnectionState =
      RTCIceConnectionState.RTCIceConnectionStateNew;
  RTCIceGatheringState _iceGatheringState =
      RTCIceGatheringState.RTCIceGatheringStateNew;

  @override
  Future<RTCSessionDescription?> getLocalDescription() async =>
      _localDescription;

  @override
  Future<void> setLocalDescription(RTCSessionDescription description) async {
    _localDescription = description;
    _handleIceConnection();
  }

  @override
  Future<RTCSessionDescription?> getRemoteDescription() async =>
      _remoteDescription;

  @override
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    _remoteDescription = description;
    _handleIceConnection();
  }

  void _handleIceConnection() {
    if ((_localDescription?.type == _offerType &&
            _remoteDescription?.type == _answerType) ||
        (_localDescription?.type == _answerType &&
            _remoteDescription?.type == _offerType)) {
      iceConnectionState = RTCIceConnectionState.RTCIceConnectionStateCompleted;
      _connectionState = RTCPeerConnectionState.RTCPeerConnectionStateConnected;
      onConnectionState?.call(_connectionState);

      if (onDataChannel != null) {
        // open data channels
        var dc = MockDataChannel(1, '_reliable');
        _dataChannels.add(dc);
        if (_dataChannels.length == 2) {
          _dataChannels[0].onMessageSend = (RTCDataChannelMessage message) {
            _dataChannels[1].onMessage?.call(message);
          };
          _dataChannels[1].onMessageSend = (RTCDataChannelMessage message) {
            _dataChannels[0].onMessage?.call(message);
          };
        }

        onDataChannel?.call(dc);

        dc.stateChangeStreamController
            .add(RTCDataChannelState.RTCDataChannelOpen);
      }
    }
  }

  @override
  RTCPeerConnectionState get connectionState => _connectionState;

  set connectionState(RTCPeerConnectionState newState) {
    if (newState != _connectionState) {
      _connectionState = newState;
      onConnectionState?.call(newState);
    }
  }

  @override
  RTCIceConnectionState get iceConnectionState => _iceConnectionState;

  set iceConnectionState(RTCIceConnectionState newState) {
    if (newState != _iceConnectionState) {
      _iceConnectionState = newState;
      onIceConnectionState?.call(newState);

      switch (newState) {
        case RTCIceConnectionState.RTCIceConnectionStateNew:
          connectionState = RTCPeerConnectionState.RTCPeerConnectionStateNew;
          break;
        case RTCIceConnectionState.RTCIceConnectionStateChecking:
          connectionState =
              RTCPeerConnectionState.RTCPeerConnectionStateConnecting;
          break;
        case RTCIceConnectionState.RTCIceConnectionStateConnected:
        case RTCIceConnectionState.RTCIceConnectionStateCompleted:
          connectionState =
              RTCPeerConnectionState.RTCPeerConnectionStateConnected;
          break;
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          connectionState = RTCPeerConnectionState.RTCPeerConnectionStateFailed;
          break;
        case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          connectionState =
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected;
          break;
        case RTCIceConnectionState.RTCIceConnectionStateClosed:
          connectionState = RTCPeerConnectionState.RTCPeerConnectionStateClosed;
          break;
        case RTCIceConnectionState.RTCIceConnectionStateCount:
          throw Exception("This state shouldn't exist (not in RFC).");
      }
    }
  }

  @override
  RTCIceGatheringState get iceGatheringState => _iceGatheringState;

  set iceGatheringState(RTCIceGatheringState newState) {
    if (newState != _iceGatheringState) {
      _iceGatheringState = newState;
      onIceGatheringState?.call(newState);
    }
  }

  @override
  Future<void> addCandidate(RTCIceCandidate candidate) async {}

  @override
  Future<void> addStream(MediaStream stream) async {}

  @override
  Future<RTCRtpSender> addTrack(MediaStreamTrack track,
      [MediaStream? stream]) async {
    // TODO: implement addTrack
    throw UnimplementedError();
  }

  @override
  Future<RTCRtpTransceiver> addTransceiver(
      {MediaStreamTrack? track,
      RTCRtpMediaType? kind,
      RTCRtpTransceiverInit? init}) {
    // TODO: implement addTransceiver
    throw UnimplementedError();
  }

  @override
  Future<void> close() async {
    closed = true;
  }

  @override
  Future<RTCSessionDescription> createAnswer(
      [Map<String, dynamic>? constraints]) async {
    return RTCSessionDescription('''
v=0
o=bob 2808844564 2808844564 IN IP4 host.biloxi.example.com
s=
c=IN IP4 host.biloxi.example.com
t=0 0
m=audio 49172 RTP/AVP 0 8
a=rtpmap:0 PCMU/8000
a=rtpmap:8 PCMA/8000
m=video 0 RTP/AVP 31
a=rtpmap:31 H261/90000
''', 'answer');
  }

  @override
  Future<RTCSessionDescription> createOffer(
      [Map<String, dynamic>? constraints]) async {
    return RTCSessionDescription('''
v=0
o=alice 2890844526 2890844526 IN IP4 host.atlanta.example.com
s=
c=IN IP4 host.atlanta.example.com
t=0 0
m=audio 49170 RTP/AVP 0 8 97
a=rtpmap:0 PCMU/8000
a=rtpmap:8 PCMA/8000
a=rtpmap:97 iLBC/8000
m=video 51372 RTP/AVP 31 32
a=rtpmap:31 H261/90000
a=rtpmap:32 MPV/90000
''', 'offer');
  }

  @override
  RTCSignalingState? get signalingState {
    if (closed) {
      return RTCSignalingState.RTCSignalingStateClosed;
    }

    if ((_localDescription?.type == null && _remoteDescription?.type == null) ||
        (_localDescription?.type == _offerType &&
            _remoteDescription?.type == _answerType) ||
        (_localDescription?.type == _answerType &&
            _remoteDescription?.type == _offerType)) {
      return RTCSignalingState.RTCSignalingStateStable;
    }

    if (_localDescription?.type == _offerType &&
        _remoteDescription?.type == null) {
      return RTCSignalingState.RTCSignalingStateHaveLocalOffer;
    }
    if (_remoteDescription?.type == _offerType &&
        _localDescription?.type == null) {
      return RTCSignalingState.RTCSignalingStateHaveRemoteOffer;
    }

    throw Exception(
        'Illegal signalling state? localDesc: $_localDescription, remoteDesc: $_remoteDescription');
  }

  @override
  Future<RTCDataChannel> createDataChannel(
      String label, RTCDataChannelInit dataChannelDict) async {
    var dc = MockDataChannel(dataChannelDict.id, label);
    if (label == '_reliable') {
      _dataChannels.add(dc);
    }
    return dc;
  }

  @override
  RTCDTMFSender createDtmfSender(MediaStreamTrack track) {
    // TODO: implement createDtmfSender
    throw UnimplementedError();
  }

  @override
  Future<void> dispose() async {
    await close();
  }

  @override
  // TODO: implement getConfiguration
  Map<String, dynamic> get getConfiguration => throw UnimplementedError();

  @override
  List<MediaStream?> getLocalStreams() => List.empty();

  @override
  Future<List<RTCRtpReceiver>> getReceivers() async => List.empty();

  @override
  List<MediaStream?> getRemoteStreams() => List.empty();

  @override
  Future<List<RTCRtpSender>> getSenders() async => List.empty();

  @override
  Future<List<StatsReport>> getStats([MediaStreamTrack? track]) async =>
      List.empty();

  @override
  Future<List<RTCRtpTransceiver>> getTransceivers() async => List.empty();

  @override
  Future<void> removeStream(MediaStream stream) async {}

  @override
  Future<bool> removeTrack(RTCRtpSender sender) async => true;

  @override
  Future<void> setConfiguration(Map<String, dynamic> configuration) {
    // TODO: implement setConfiguration
    throw UnimplementedError();
  }

  static Future<RTCPeerConnection> create(Map<String, dynamic> configuration,
          [Map<String, dynamic>? constraints]) async =>
      MockPeerConnection();

  @override
  // TODO: implement restartIce
  Future<void> restartIce() => throw UnimplementedError();
}
