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

MockDataChannel? findMockDataChannelByLabel(String label, {bool requireListener = false}) {
  for (final dc in _dataChannels) {
    if (dc.label == label) {
      if (requireListener && dc.onMessage == null) {
        continue;
      }
      return dc;
    }
  }
  return null;
}

/// All mock data channels created in the current test process. Test code can wrap
/// `onMessageSend` to capture outbound packets without breaking the existing
/// publisher↔subscriber loopback.
List<MockDataChannel> get mockDataChannels => _dataChannels;

/// Called with every reliable channel the SDK creates, so a test can watch the
/// channel a full reconnect creates from the moment it exists.
void Function(MockDataChannel dc)? onMockReliableChannelCreated;

/// Reset the global mock-channel list. Tests that create a fresh `E2EContainer`
/// after an earlier one finished must call this before re-connecting, otherwise
/// the publisher↔subscriber pairing (which only fires when the list reaches
/// length 2) will not happen on the new channels.
void resetMockDataChannels() {
  _dataChannels.clear();
  onMockReliableChannelCreated = null;
  mockReportsSelectedPair = true;
  mockPairReportsHaveUfrags = true;
}

/// Whether new mock peer connections report their selected candidate pair, as flutter_webrtc does
/// on iOS, macOS and Android once it has the event. Reset by [resetMockDataChannels].
bool mockReportsSelectedPair = true;

/// Whether the candidates of those reports carry their ICE username fragment, as libwebrtc's
/// candidate lines do. Reset by [resetMockDataChannels].
bool mockPairReportsHaveUfrags = true;

/// What a mock reports as a selected candidate pair, read the way the SDK reads the plugin's.
class MockCandidatePair {
  MockCandidatePair(String localUfrag, String remoteUfrag)
    : local = RTCIceCandidate(_candidateLine(localUfrag), '0', -1),
      remote = RTCIceCandidate(_candidateLine(remoteUfrag), '0', -1);

  final RTCIceCandidate local;
  final RTCIceCandidate remote;
  final String reason = 'candidate pair state changed';
  final int lastDataReceivedMs = 0;

  static String _candidateLine(String ufrag) =>
      'candidate:1 1 udp 2130706431 192.0.2.1 50000 typ host generation 0'
      '${mockPairReportsHaveUfrags ? ' ufrag $ufrag' : ''} network-id 1';
}

class MockPeerConnection extends RTCPeerConnection {
  static const _offerType = 'offer';
  static const _answerType = 'answer';

  bool closed = false;

  // The SDK sets onSelectedCandidatePairChanged through a dynamic call. A webrtc_interface without
  // the field lands in noSuchMethod, so the mock keeps the callback there and builds with both.
  Function? _pairCallback;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == const Symbol('onSelectedCandidatePairChanged=')) {
      return _pairCallback = invocation.positionalArguments.first as Function?;
    }
    if (invocation.memberName == #onSelectedCandidatePairChanged) return _pairCallback;
    return super.noSuchMethod(invocation);
  }

  /// Whether this connection reports its selected candidate pair, see [mockReportsSelectedPair].
  final bool reportsSelectedPair = mockReportsSelectedPair;

  /// ICE username fragment of the local offers, new after every [restartIce].
  String localUfrag = 'local0';
  int _iceGeneration = 0;
  bool _restartPending = false;

  /// Username fragments of the selected candidate pair, null before one is selected.
  ({String local, String remote})? selectedPair;

  /// Whether [getStats] names the username fragments of the selected pair's candidates.
  bool statsHaveUfrags = false;

  /// Selects the pair with these username fragments, reporting it where the connection reports
  /// pairs, and naming it in the stats.
  void selectPair(String localUfrag, String remoteUfrag) {
    selectedPair = (local: localUfrag, remote: remoteUfrag);
    selectedCandidatePairId = 'pair-$localUfrag-$remoteUfrag';
    if (!reportsSelectedPair) return;
    final dynamic callback = (this as dynamic).onSelectedCandidatePairChanged;
    if (callback != null) callback(MockCandidatePair(localUfrag, remoteUfrag));
  }

  RTCSessionDescription? _localDescription;
  RTCSessionDescription? _remoteDescription;

  RTCPeerConnectionState _connectionState = RTCPeerConnectionState.RTCPeerConnectionStateNew;
  RTCIceConnectionState _iceConnectionState = RTCIceConnectionState.RTCIceConnectionStateNew;
  RTCIceGatheringState _iceGatheringState = RTCIceGatheringState.RTCIceGatheringStateNew;

  @override
  Future<RTCSessionDescription?> getLocalDescription() async => _localDescription;

  @override
  Future<void> setLocalDescription(RTCSessionDescription description) async {
    _localDescription = description;
    _handleIceConnection();
  }

  @override
  Future<RTCSessionDescription?> getRemoteDescription() async => _remoteDescription;

  @override
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    _remoteDescription = description;
    _handleIceConnection();
  }

  void _handleIceConnection() {
    if ((_localDescription?.type == _offerType && _remoteDescription?.type == _answerType) ||
        (_localDescription?.type == _answerType && _remoteDescription?.type == _offerType)) {
      iceConnectionState = RTCIceConnectionState.RTCIceConnectionStateCompleted;
      _connectionState = RTCPeerConnectionState.RTCPeerConnectionStateConnected;
      onConnectionState?.call(_connectionState);
      // The first pair is selected when the connection first connects. A test moves it later.
      if (selectedPair == null) {
        selectPair(_ufragOf(_localDescription) ?? localUfrag, _ufragOf(_remoteDescription) ?? 'remote');
      }

      if (onDataChannel != null) {
        // open data channels
        final dc = MockDataChannel(1, '_reliable');
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

        dc.stateChangeStreamController.add(RTCDataChannelState.RTCDataChannelOpen);
      }
    }
  }

  static String? _ufragOf(RTCSessionDescription? description) =>
      RegExp(r'a=ice-ufrag:(\S+)').firstMatch(description?.sdp ?? '')?.group(1);

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
          connectionState = RTCPeerConnectionState.RTCPeerConnectionStateConnecting;
          break;
        case RTCIceConnectionState.RTCIceConnectionStateConnected:
        case RTCIceConnectionState.RTCIceConnectionStateCompleted:
          connectionState = RTCPeerConnectionState.RTCPeerConnectionStateConnected;
          break;
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          connectionState = RTCPeerConnectionState.RTCPeerConnectionStateFailed;
          break;
        case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          connectionState = RTCPeerConnectionState.RTCPeerConnectionStateDisconnected;
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
  Future<RTCRtpSender> addTrack(MediaStreamTrack track, [MediaStream? stream]) async {
    // TODO: implement addTrack
    throw UnimplementedError();
  }

  @override
  Future<RTCRtpTransceiver> addTransceiver({
    MediaStreamTrack? track,
    RTCRtpMediaType? kind,
    RTCRtpTransceiverInit? init,
  }) async => MockRtpTransceiver(MockRtpSender(track));

  @override
  Future<void> close() async {
    closed = true;
  }

  @override
  Future<RTCSessionDescription> createAnswer([Map<String, dynamic>? constraints]) async {
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
  Future<RTCSessionDescription> createOffer([Map<String, dynamic>? constraints]) async {
    if (_restartPending || constraints?['iceRestart'] == true) {
      _restartPending = false;
      localUfrag = 'local${++_iceGeneration}';
    }
    return RTCSessionDescription('''
v=0
o=alice 2890844526 2890844526 IN IP4 host.atlanta.example.com
s=
c=IN IP4 host.atlanta.example.com
t=0 0
a=ice-ufrag:$localUfrag
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
        (_localDescription?.type == _offerType && _remoteDescription?.type == _answerType) ||
        (_localDescription?.type == _answerType && _remoteDescription?.type == _offerType)) {
      return RTCSignalingState.RTCSignalingStateStable;
    }

    if (_localDescription?.type == _offerType && _remoteDescription?.type == null) {
      return RTCSignalingState.RTCSignalingStateHaveLocalOffer;
    }
    if (_remoteDescription?.type == _offerType && _localDescription?.type == null) {
      return RTCSignalingState.RTCSignalingStateHaveRemoteOffer;
    }

    throw Exception('Illegal signalling state? localDesc: $_localDescription, remoteDesc: $_remoteDescription');
  }

  @override
  Future<RTCDataChannel> createDataChannel(String label, RTCDataChannelInit dataChannelDict) async {
    final dc = MockDataChannel(dataChannelDict.id, label);
    if (label == '_reliable') {
      _dataChannels.add(dc);
      onMockReliableChannelCreated?.call(dc);
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
  Future<List<StatsReport>> getStats([MediaStreamTrack? track]) async => [
    if (selectedCandidatePairId != null) ...[
      StatsReport('T01', 'transport', 0, {'selectedCandidatePairId': selectedCandidatePairId}),
      StatsReport(selectedCandidatePairId!, 'candidate-pair', 0, {
        'localCandidateId': 'L-$selectedCandidatePairId',
        'remoteCandidateId': 'R-$selectedCandidatePairId',
      }),
      StatsReport('L-$selectedCandidatePairId', 'local-candidate', 0, {
        if (statsHaveUfrags && selectedPair != null) 'usernameFragment': selectedPair!.local,
      }),
      StatsReport('R-$selectedCandidatePairId', 'remote-candidate', 0, {
        if (statsHaveUfrags && selectedPair != null) 'usernameFragment': selectedPair!.remote,
      }),
    ],
  ];

  /// Reported as the transport's selected candidate pair by [getStats], which reports no
  /// transport while it is null.
  String? selectedCandidatePairId;

  @override
  Future<List<RTCRtpTransceiver>> getTransceivers() async => List.empty();

  @override
  Future<void> removeStream(MediaStream stream) async {}

  @override
  Future<bool> removeTrack(RTCRtpSender sender) async => true;

  /// Last configuration applied via [setConfiguration] (set on resume, when the
  /// server hands out new ICE servers in the `ReconnectResponse`).
  Map<String, dynamic>? appliedConfiguration;

  @override
  Future<void> setConfiguration(Map<String, dynamic> configuration) async {
    appliedConfiguration = configuration;
  }

  /// Configuration the SDK created this peer connection with.
  Map<String, dynamic>? createConfiguration;

  static Future<RTCPeerConnection> create(
    Map<String, dynamic> configuration, [
    Map<String, dynamic>? constraints,
  ]) async => MockPeerConnection()..createConfiguration = configuration;

  // The next offer carries new ICE credentials. The mock has no ICE agent to restart.
  @override
  Future<void> restartIce() async => _restartPending = true;
}

class MockRtpSender implements RTCRtpSender {
  MockRtpSender(this.track);

  @override
  MediaStreamTrack? track;

  @override
  Future<void> replaceTrack(MediaStreamTrack? track) async => this.track = track;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockRtpTransceiver implements RTCRtpTransceiver {
  MockRtpTransceiver(this.sender);

  @override
  final RTCRtpSender sender;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
