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
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/internal/events.dart';
import '../mock/datachannel_mock.dart';
import '../mock/e2e_container.dart';
import '../mock/peerconnection_mock.dart';

void main() {
  setUp(resetMockDataChannels);

  group('subscriber data channel state events', () {
    // Regression: _onDataChannel used to register a nested listener on the
    // publisher reliable channel instead of emitting the subscriber channel's
    // own state. Subscriber state changes produced no immediate event, later
    // events carried the wrong channel's state, and inner listeners
    // accumulated on every state change.
    test('emit the subscriber channel state with the correct reliability type', () async {
      final container = E2EContainer();
      addTearDown(container.dispose);
      await container.connectRoom();

      final engine = container.room.engine;
      final events = <SubscriberDataChannelStateUpdatedEvent>[];
      final listener = engine.createListener()..on<SubscriberDataChannelStateUpdatedEvent>(events.add);
      addTearDown(listener.dispose);

      // Simulate the server opening subscriber-side channels.
      final reliableSub = MockDataChannel(8, '_reliable');
      final lossySub = MockDataChannel(9, '_lossy');
      final onDataChannel = engine.subscriber!.pc.onDataChannel!;
      onDataChannel(reliableSub);
      onDataChannel(lossySub);

      reliableSub.stateChangeStreamController.add(rtc.RTCDataChannelState.RTCDataChannelClosing);
      lossySub.stateChangeStreamController.add(rtc.RTCDataChannelState.RTCDataChannelClosed);
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(2));
      expect(events[0].type, Reliability.reliable);
      expect(events[0].state, rtc.RTCDataChannelState.RTCDataChannelClosing);
      expect(events[1].type, Reliability.lossy);
      expect(events[1].state, rtc.RTCDataChannelState.RTCDataChannelClosed);
    });

    test('repeated state changes do not multiply events', () async {
      final container = E2EContainer();
      addTearDown(container.dispose);
      await container.connectRoom();

      final engine = container.room.engine;
      final events = <SubscriberDataChannelStateUpdatedEvent>[];
      final listener = engine.createListener()..on<SubscriberDataChannelStateUpdatedEvent>(events.add);
      addTearDown(listener.dispose);

      final reliableSub = MockDataChannel(8, '_reliable');
      engine.subscriber!.pc.onDataChannel!(reliableSub);

      for (var i = 0; i < 3; i++) {
        reliableSub.stateChangeStreamController.add(rtc.RTCDataChannelState.RTCDataChannelOpen);
      }
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(3));
      expect(events.every((e) => e.state == rtc.RTCDataChannelState.RTCDataChannelOpen), isTrue);
    });
  });
}
