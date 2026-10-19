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

@Timeout(Duration(seconds: 5))
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'package:livekit_client/src/core/transport.dart' show Transport;
import 'package:livekit_client/src/exceptions.dart' show NegotiationError;
import 'package:livekit_client/src/options.dart' show ConnectOptions;
import '../mock/peerconnection_mock.dart';

class _RejectingPeerConnection extends MockPeerConnection {
  @override
  Future<void> setLocalDescription(rtc.RTCSessionDescription description) async {
    throw Exception('The order of m-lines in subsequent offer doesn\'t match order from previous offer/answer.');
  }
}

Future<rtc.RTCPeerConnection> _createRejecting(
  Map<String, dynamic> configuration, [
  Map<String, dynamic>? constraints,
]) async => _RejectingPeerConnection();

class _RejectAfterAnswerPeerConnection extends MockPeerConnection {
  bool rejectLocal = false;

  @override
  Future<void> setLocalDescription(rtc.RTCSessionDescription description) async {
    if (rejectLocal) {
      throw Exception('The order of m-lines in subsequent offer doesn\'t match order from previous offer/answer.');
    }
    await super.setLocalDescription(description);
  }
}

void main() {
  group('Transport.negotiate', () {
    test('reports a failed offer to onNegotiationError instead of leaking an unhandled error', () async {
      final uncaught = <Object>[];
      final reported = Completer<Object>();

      await runZonedGuarded(() async {
        final transport = await Transport.create(_createRejecting, connectOptions: const ConnectOptions());
        addTearDown(transport.dispose);
        transport.onOffer = (_) {};
        transport.onNegotiationError = reported.complete;

        transport.negotiate(null);

        // Outlast the debounce and the rejected setLocalDescription.
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }, (error, stack) => uncaught.add(error));

      expect(uncaught, isEmpty);
      expect(reported.isCompleted, isTrue);
      expect(await reported.future, isA<NegotiationError>());
    });

    test('does not report when the offer is sent', () async {
      final offers = <rtc.RTCSessionDescription>[];
      final transport = await Transport.create(MockPeerConnection.create, connectOptions: const ConnectOptions());
      addTearDown(transport.dispose);
      transport.onOffer = offers.add;
      transport.onNegotiationError = (error) => fail('unexpected negotiation error: $error');

      transport.negotiate(null);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(offers, hasLength(1));
    });

    test('reports a failed deferred offer to onNegotiationError', () async {
      final pc = _RejectAfterAnswerPeerConnection();
      final transport = await Transport.create(
        (Map<String, dynamic> configuration, [Map<String, dynamic>? constraints]) async => pc,
        connectOptions: const ConnectOptions(),
      );
      addTearDown(transport.dispose);
      transport.onOffer = (_) {};
      final reported = Completer<Object>();
      transport.onNegotiationError = reported.complete;

      // An offer is already waiting for its answer, so the next one is deferred.
      await pc.setLocalDescription(await pc.createOffer());
      await transport.createAndSendOffer();
      expect(transport.renegotiate, isTrue);

      pc.rejectLocal = true;
      await transport.setRemoteDescription(rtc.RTCSessionDescription('v=0', 'answer'));

      expect(reported.isCompleted, isTrue);
      expect(await reported.future, isA<NegotiationError>());
    });

    test('throws from setRemoteDescription when a deferred offer fails and no handler is set', () async {
      final pc = _RejectAfterAnswerPeerConnection();
      final transport = await Transport.create(
        (Map<String, dynamic> configuration, [Map<String, dynamic>? constraints]) async => pc,
        connectOptions: const ConnectOptions(),
      );
      addTearDown(transport.dispose);
      transport.onOffer = (_) {};

      await pc.setLocalDescription(await pc.createOffer());
      await transport.createAndSendOffer();
      expect(transport.renegotiate, isTrue);

      pc.rejectLocal = true;
      await expectLater(
        transport.setRemoteDescription(rtc.RTCSessionDescription('v=0', 'answer')),
        throwsA(isA<NegotiationError>()),
      );
    });

    test('still throws from a direct createAndSendOffer', () async {
      final transport = await Transport.create(_createRejecting, connectOptions: const ConnectOptions());
      addTearDown(transport.dispose);
      transport.onOffer = (_) {};
      transport.onNegotiationError = (error) => fail('unexpected negotiation error: $error');

      await expectLater(transport.createAndSendOffer(), throwsA(isA<NegotiationError>()));
    });
  });
}
