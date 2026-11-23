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

@Timeout(Duration(seconds: 10))
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RTCConfiguration.continualGatheringPolicy', () {
    test('toMap omits the key when unset', () {
      expect(const RTCConfiguration().toMap().containsKey('continualGatheringPolicy'), isFalse);
    });

    test('toMap writes the values flutter_webrtc reads', () {
      expect(
        const RTCConfiguration(
          continualGatheringPolicy: RTCContinualGatheringPolicy.gatherContinually,
        ).toMap()['continualGatheringPolicy'],
        'gather_continually',
      );
      expect(
        const RTCConfiguration(
          continualGatheringPolicy: RTCContinualGatheringPolicy.gatherOnce,
        ).toMap()['continualGatheringPolicy'],
        'gather_once',
      );
    });

    test('copyWith keeps and overrides the policy', () {
      const config = RTCConfiguration(continualGatheringPolicy: RTCContinualGatheringPolicy.gatherOnce);
      expect(
        config.copyWith(iceTransportPolicy: RTCIceTransportPolicy.relay).continualGatheringPolicy,
        RTCContinualGatheringPolicy.gatherOnce,
      );
      expect(
        config
            .copyWith(continualGatheringPolicy: RTCContinualGatheringPolicy.gatherContinually)
            .continualGatheringPolicy,
        RTCContinualGatheringPolicy.gatherContinually,
      );
    });
  });

  group('peer connections', () {
    late E2EContainer container;

    setUp(() {
      resetMockDataChannels();
      container = E2EContainer();
    });

    tearDown(() async {
      await container.dispose();
    });

    List<Map<String, dynamic>?> createConfigurations() => [
      (container.engine.publisher?.pc as MockPeerConnection?)?.createConfiguration,
      (container.engine.subscriber?.pc as MockPeerConnection?)?.createConfiguration,
    ];

    test('gather continually by default', () async {
      await container.connectRoom();

      for (final config in createConfigurations()) {
        expect(config, isNotNull);
        expect(config!['continualGatheringPolicy'], 'gather_continually');
      }
    });

    test('keep the policy the app sets', () async {
      await container.connectRoom(
        connectOptions: const ConnectOptions(
          rtcConfiguration: RTCConfiguration(
            continualGatheringPolicy: RTCContinualGatheringPolicy.gatherOnce,
          ),
        ),
      );

      for (final config in createConfigurations()) {
        expect(config, isNotNull);
        expect(config!['continualGatheringPolicy'], 'gather_once');
      }
    });

    test('combine with a relay-only transport policy', () async {
      await container.connectRoom(
        connectOptions: const ConnectOptions(
          rtcConfiguration: RTCConfiguration(iceTransportPolicy: RTCIceTransportPolicy.relay),
        ),
      );

      for (final config in createConfigurations()) {
        expect(config, isNotNull);
        expect(config!['iceTransportPolicy'], 'relay');
        expect(config['continualGatheringPolicy'], 'gather_continually');
      }
    });
  });
}
