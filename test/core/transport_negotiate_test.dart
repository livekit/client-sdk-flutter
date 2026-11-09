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

/// Tracks the signaling state from the order descriptions are set in, as a real
/// peer connection does, so a second offer after an answer is have-local-offer.
class _OrderedPeerConnection extends MockPeerConnection {
  rtc.RTCSignalingState _state = rtc.RTCSignalingState.RTCSignalingStateStable;

  @override
  rtc.RTCSignalingState? get signalingState => _state;

  @override
  Future<rtc.RTCSignalingState?> getSignalingState() async => _state;

  @override
  Future<void> setLocalDescription(rtc.RTCSessionDescription description) async {
    await super.setLocalDescription(description);
    _state = description.type == 'offer'
        ? rtc.RTCSignalingState.RTCSignalingStateHaveLocalOffer
        : rtc.RTCSignalingState.RTCSignalingStateStable;
  }

  @override
  Future<void> setRemoteDescription(rtc.RTCSessionDescription description) async {
    await super.setRemoteDescription(description);
    _state = description.type == 'offer'
        ? rtc.RTCSignalingState.RTCSignalingStateHaveRemoteOffer
        : rtc.RTCSignalingState.RTCSignalingStateStable;
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

  group('Transport.setRemoteDescription duplicate answers', () {
    Future<(Transport, MockPeerConnection)> makeTransport() async {
      final pc = MockPeerConnection();
      final transport = await Transport.create(
        (Map<String, dynamic> configuration, [Map<String, dynamic>? constraints]) async => pc,
        connectOptions: const ConnectOptions(),
      );
      addTearDown(transport.dispose);
      transport.onOffer = (_) {};
      return (transport, pc);
    }

    test('ignores a second copy of an answer that was already applied', () async {
      final (transport, pc) = await makeTransport();

      await transport.createAndSendOffer();
      expect(pc.signalingState, rtc.RTCSignalingState.RTCSignalingStateHaveLocalOffer);

      await transport.setRemoteDescription(rtc.RTCSessionDescription('v=0\r\nfirst', 'answer'));
      expect(pc.signalingState, rtc.RTCSignalingState.RTCSignalingStateStable);

      // A proxy (or a server retry) can deliver a second copy of the answer that
      // was already applied. There is no local offer left to answer, so applying
      // it again is invalid. The payload differs only so the test can tell.
      await transport.setRemoteDescription(rtc.RTCSessionDescription('v=0\r\nduplicate', 'answer'));

      final remote = await pc.getRemoteDescription();
      expect(
        remote?.sdp,
        'v=0\r\nfirst',
        reason: 'duplicate answer was applied to the peer connection',
      );
    });

    test('still applies the answer to a pending offer', () async {
      final (transport, pc) = await makeTransport();

      await transport.createAndSendOffer();
      expect(pc.signalingState, rtc.RTCSignalingState.RTCSignalingStateHaveLocalOffer);

      await transport.setRemoteDescription(rtc.RTCSessionDescription('v=0\r\nwanted', 'answer'));

      final remote = await pc.getRemoteDescription();
      expect(remote?.sdp, 'v=0\r\nwanted');
    });

    test('still applies a remote offer while in stable', () async {
      final (transport, pc) = await makeTransport();

      // Only answers are gated; a remote offer in stable is normal subscriber traffic.
      await transport.setRemoteDescription(rtc.RTCSessionDescription('v=0\r\nremote-offer', 'offer'));

      final remote = await pc.getRemoteDescription();
      expect(remote?.sdp, 'v=0\r\nremote-offer');
    });
  });

  group('Transport offer ids', () {
    Future<(Transport, _OrderedPeerConnection, List<int>)> makeTransport() async {
      final pc = _OrderedPeerConnection();
      final transport = await Transport.create(
        (Map<String, dynamic> configuration, [Map<String, dynamic>? constraints]) async => pc,
        connectOptions: const ConnectOptions(),
      );
      addTearDown(transport.dispose);
      final ids = <int>[];
      transport.onNumberedOffer = (_, offerId) => ids.add(offerId);
      return (transport, pc, ids);
    }

    test('numbers offers from 1', () async {
      final (transport, _, ids) = await makeTransport();

      await transport.createAndSendOffer();
      await transport.setRemoteDescription(rtc.RTCSessionDescription('v=0\r\na1', 'answer'), offerId: 1);
      await transport.createAndSendOffer();

      expect(ids, [1, 2]);
      expect(transport.latestOfferId, 2);
    });

    test('ignores the answer to an older offer while a newer one is pending', () async {
      final (transport, pc, _) = await makeTransport();

      await transport.createAndSendOffer();
      await transport.setRemoteDescription(rtc.RTCSessionDescription('v=0\r\na1', 'answer'), offerId: 1);
      await transport.createAndSendOffer();
      expect(pc.signalingState, rtc.RTCSignalingState.RTCSignalingStateHaveLocalOffer);

      // A late copy of the first answer arrives while offer 2 waits for its own
      // answer. The signaling state alone would accept it.
      expect(transport.isStaleAnswer(1), isTrue);
      await transport.setRemoteDescription(rtc.RTCSessionDescription('v=0\r\nstale', 'answer'), offerId: 1);
      expect((await pc.getRemoteDescription())?.sdp, 'v=0\r\na1');

      await transport.setRemoteDescription(rtc.RTCSessionDescription('v=0\r\na2', 'answer'), offerId: 2);
      expect((await pc.getRemoteDescription())?.sdp, 'v=0\r\na2');
    });

    test('ignores a numbered duplicate of the applied answer', () async {
      final (transport, pc, _) = await makeTransport();

      await transport.createAndSendOffer();
      await transport.setRemoteDescription(rtc.RTCSessionDescription('v=0\r\na1', 'answer'), offerId: 1);
      await transport.setRemoteDescription(rtc.RTCSessionDescription('v=0\r\ncopy', 'answer'), offerId: 1);
      expect((await pc.getRemoteDescription())?.sdp, 'v=0\r\na1');
    });

    test('applies unnumbered answers from servers that do not echo the id', () async {
      final (transport, pc, _) = await makeTransport();

      await transport.createAndSendOffer();
      await transport.createAndSendOffer(); // deferred: offer 1 is still pending
      expect(transport.isStaleAnswer(0), isFalse);
      await transport.setRemoteDescription(rtc.RTCSessionDescription('v=0\r\nlegacy', 'answer'));
      expect((await pc.getRemoteDescription())?.sdp, 'v=0\r\nlegacy');
    });
  });
}
