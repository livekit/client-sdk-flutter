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
import 'package:livekit_client/src/internal/types.dart' show RTCOfferOptions;
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

/// A peer connection whose remote description takes a while to read, the way
/// a platform call does when the native side is busy.
class _SlowRemoteDescriptionPeerConnection extends MockPeerConnection {
  @override
  Future<rtc.RTCSessionDescription?> getRemoteDescription() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return super.getRemoteDescription();
  }
}

/// A peer connection that can deliver one signaling state reply late, after
/// the state it reports has already changed. Platform replies are not
/// guaranteed to arrive in the order the calls were made.
class _LateStateReplyPeerConnection extends MockPeerConnection {
  bool delayNextStateReply = false;

  @override
  Future<rtc.RTCSignalingState?> getSignalingState() async {
    final state = signalingState;
    if (delayNextStateReply) {
      delayNextStateReply = false;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    return state;
  }
}

/// A peer connection that takes a while to apply a remote description, and
/// can be told to reject the next one.
class _SlowApplyPeerConnection extends MockPeerConnection {
  bool rejectNextRemote = false;

  @override
  Future<void> setRemoteDescription(rtc.RTCSessionDescription description) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (rejectNextRemote) {
      rejectNextRemote = false;
      throw Exception('Failed to set remote answer sdp');
    }
    await super.setRemoteDescription(description);
  }
}

/// A peer connection that reports a local offer waiting for its answer on top
/// of an earlier negotiation, which the plain mock cannot express. It records
/// what an ICE restart does to it.
class _PendingOfferPeerConnection extends MockPeerConnection {
  final remoteDescriptionsApplied = <rtc.RTCSessionDescription>[];
  int iceRestarts = 0;

  @override
  Future<rtc.RTCSignalingState?> getSignalingState() async => rtc.RTCSignalingState.RTCSignalingStateHaveLocalOffer;

  @override
  Future<void> setRemoteDescription(rtc.RTCSessionDescription description) async {
    remoteDescriptionsApplied.add(description);
    await super.setRemoteDescription(description);
  }

  @override
  Future<void> restartIce() async {
    iceRestarts++;
  }
}

Future<Transport> _transportFor(rtc.RTCPeerConnection pc) async {
  final transport = await Transport.create(
    (Map<String, dynamic> configuration, [Map<String, dynamic>? constraints]) async => pc,
    connectOptions: const ConnectOptions(),
  );
  addTearDown(transport.dispose);
  return transport;
}

void main() {
  group('Transport negotiation lock', () {
    test('sends the deferred offer even when the state reply arrives after the answer is applied', () async {
      final pc = _LateStateReplyPeerConnection();
      final transport = await _transportFor(pc);
      final offers = <rtc.RTCSessionDescription>[];
      transport.onOffer = offers.add;

      await transport.createAndSendOffer();
      expect(offers, hasLength(1));

      // The second request reads "offer pending", but that reply is slow. Without the lock the
      // answer is applied and the flag checked before the request gets to set it.
      pc.delayNextStateReply = true;
      final second = transport.createAndSendOffer();
      await transport.setRemoteDescription(rtc.RTCSessionDescription('v=0', 'answer'));
      await second;

      expect(offers, hasLength(2), reason: 'the second offer was never sent');
      expect(transport.renegotiate, isFalse);
    });

    test('an offer requested while an answer is applied waits and is sent afterwards', () async {
      final pc = _SlowApplyPeerConnection();
      final transport = await _transportFor(pc);
      final offers = <rtc.RTCSessionDescription>[];
      transport.onOffer = offers.add;

      await transport.createAndSendOffer();

      final apply = transport.setRemoteDescription(rtc.RTCSessionDescription('v=0', 'answer'));
      final request = transport.createAndSendOffer();
      await Future.wait([apply, request]);

      expect(offers, hasLength(2));
      expect(transport.renegotiate, isFalse);
    });

    test('the deferred offer is sent from inside the answer path without waiting on the lock', () async {
      final pc = MockPeerConnection();
      final transport = await _transportFor(pc);
      final offers = <rtc.RTCSessionDescription>[];
      transport.onOffer = offers.add;

      await transport.createAndSendOffer();
      await transport.createAndSendOffer();
      expect(transport.renegotiate, isTrue);

      // Hangs until the file timeout if the deferred offer takes the lock again.
      await transport.setRemoteDescription(rtc.RTCSessionDescription('v=0', 'answer'));

      expect(offers, hasLength(2));
      expect(transport.renegotiate, isFalse);
    });

    test('ignores a copy of an answer that arrives while the first one is applied', () async {
      final pc = _SlowApplyPeerConnection();
      final transport = await _transportFor(pc);
      transport.onOffer = (_) {};

      await transport.createAndSendOffer();

      final first = transport.setRemoteDescription(rtc.RTCSessionDescription('v=0\r\nfirst', 'answer'));
      final copy = transport.setRemoteDescription(rtc.RTCSessionDescription('v=0\r\nduplicate', 'answer'));
      await Future.wait([first, copy]);

      expect((await pc.getRemoteDescription())?.sdp, 'v=0\r\nfirst');
    });

    test('applies a retried answer after the first apply failed', () async {
      final pc = _SlowApplyPeerConnection();
      final transport = await _transportFor(pc);
      transport.onOffer = (_) {};

      await transport.createAndSendOffer();

      pc.rejectNextRemote = true;
      await transport.setRemoteDescription(rtc.RTCSessionDescription('v=0\r\nrejected', 'answer'));
      expect(await pc.getRemoteDescription(), isNull);

      // The offer is still waiting, so this is not a duplicate.
      await transport.setRemoteDescription(rtc.RTCSessionDescription('v=0\r\nretry', 'answer'));
      expect((await pc.getRemoteDescription())?.sdp, 'v=0\r\nretry');
    });
  });

  group('Transport.createAndSendOffer ICE restart with an offer pending', () {
    test('rolls back to the last remote description and sends a new offer', () async {
      final pc = _PendingOfferPeerConnection();
      final transport = await _transportFor(pc);
      final offers = <rtc.RTCSessionDescription>[];
      transport.onOffer = offers.add;
      final previous = rtc.RTCSessionDescription('v=0\r\nprevious', 'answer');
      await pc.setRemoteDescription(previous);
      pc.remoteDescriptionsApplied.clear();

      await transport.createAndSendOffer(const RTCOfferOptions(iceRestart: true));

      expect(pc.remoteDescriptionsApplied.map((sd) => sd.sdp), ['v=0\r\nprevious']);
      expect(pc.iceRestarts, 1);
      expect(offers, hasLength(1));
      expect(transport.renegotiate, isFalse);
    });

    test('waits for the answer when there is no remote description to roll back to', () async {
      final pc = _PendingOfferPeerConnection();
      final transport = await _transportFor(pc);
      final offers = <rtc.RTCSessionDescription>[];
      transport.onOffer = offers.add;

      await transport.createAndSendOffer(const RTCOfferOptions(iceRestart: true));

      expect(pc.remoteDescriptionsApplied, isEmpty);
      expect(pc.iceRestarts, 0);
      expect(offers, isEmpty);
      expect(transport.renegotiate, isTrue);
      expect(transport.restartingIce, isTrue);
    });
  });

  group('Transport.negotiate', () {
    test('sends an offer that was requested while the answer to the previous one is applied', () async {
      final pc = _SlowRemoteDescriptionPeerConnection();
      final transport = await Transport.create(
        (Map<String, dynamic> configuration, [Map<String, dynamic>? constraints]) async => pc,
        connectOptions: const ConnectOptions(),
      );
      addTearDown(transport.dispose);
      final offers = <rtc.RTCSessionDescription>[];
      transport.onOffer = offers.add;

      // The first track is offered and waits for its answer.
      await transport.createAndSendOffer();
      expect(offers, hasLength(1));

      // A second track asks for an offer while the first one is still pending,
      // and the answer lands before that request has finished deciding to wait.
      final second = transport.createAndSendOffer();
      await transport.setRemoteDescription(rtc.RTCSessionDescription('v=0', 'answer'));
      await second;
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(offers, hasLength(2), reason: 'the second track was never offered');
      expect(transport.renegotiate, isFalse);
    });

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
}
