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

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:sdp_transform/sdp_transform.dart' as sdp_transform;

import 'package:livekit_client/src/core/transport.dart' show Transport, ensureOpusNack, mungeOpusNackForAnswer;
import 'package:livekit_client/src/exceptions.dart' show NegotiationError;
import 'package:livekit_client/src/options.dart' show ConnectOptions;
import '../mock/peerconnection_mock.dart';

const _offer =
    'v=0\r\n'
    'o=- 1 1 IN IP4 127.0.0.1\r\n'
    's=-\r\n'
    't=0 0\r\n'
    'm=audio 9 UDP/TLS/RTP/SAVPF 109\r\n'
    'a=mid:0\r\n'
    'a=sendonly\r\n'
    'a=rtpmap:109 opus/48000/2\r\n'
    'm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'
    'a=mid:1\r\n'
    'a=recvonly\r\n'
    'a=rtpmap:111 opus/48000/2\r\n'
    'm=audio 9 UDP/TLS/RTP/SAVPF 112\r\n'
    'a=mid:2\r\n'
    'a=sendrecv\r\n'
    'a=rtpmap:112 opus/48000/2\r\n';

class _AudioPeerConnection extends MockPeerConnection {
  String offer = _offer;
  String answer = _offer;
  bool rejectNack = false;
  bool rejectAll = false;
  int rejectedNackOffers = 0;

  @override
  Future<rtc.RTCSessionDescription> createOffer([Map<String, dynamic>? constraints]) async {
    return rtc.RTCSessionDescription(offer, 'offer');
  }

  @override
  Future<rtc.RTCSessionDescription> createAnswer([Map<String, dynamic>? constraints]) async {
    return rtc.RTCSessionDescription(answer, 'answer');
  }

  @override
  Future<void> setLocalDescription(rtc.RTCSessionDescription description) async {
    if (rejectAll) throw StateError('All local descriptions rejected');
    if (rejectNack && (description.sdp ?? '').contains('a=rtcp-fb:109 nack\r\n')) {
      rejectedNackOffers++;
      throw StateError('NACK munging rejected');
    }
    await super.setLocalDescription(description);
  }
}

void _expectNack(String sdp, {required int audioSections, required bool enabled}) {
  final sections = (sdp_transform.parse(sdp)['media'] as List).where((m) => m['type'] == 'audio').toList();
  expect(sections, hasLength(audioSections));
  for (final section in sections) {
    final opus = (section['rtp'] as List).where((rtp) => (rtp['codec'] as String).toLowerCase() == 'opus');
    expect(opus, isNotEmpty);
    for (final mapping in opus) {
      final feedback = section['rtcpFb'] as List? ?? const [];
      final nack = feedback.where(
        (fb) =>
            fb['payload'] == mapping['payload'] &&
            fb['type'] == 'nack' &&
            (fb['subtype'] == null || fb['subtype'] == ''),
      );
      expect(nack, hasLength(enabled ? 1 : 0));
    }
  }
}

Future<(Transport, _AudioPeerConnection, List<rtc.RTCSessionDescription>)> _makeTransport({
  required bool singlePC,
  bool requestedSinglePC = false,
}) async {
  final pc = _AudioPeerConnection();
  final transport = await Transport.create(
    (Map<String, dynamic> configuration, [Map<String, dynamic>? constraints]) async => pc,
    connectOptions: ConnectOptions(singlePeerConnection: requestedSinglePC),
  );
  transport.negotiateOpusNack = singlePC;
  addTearDown(transport.dispose);
  final offers = <rtc.RTCSessionDescription>[];
  transport.onOffer = (offer, _) => offers.add(offer);
  return (transport, pc, offers);
}

void main() {
  group('Opus NACK SDP', () {
    for (final direction in ['sendonly', 'recvonly', 'sendrecv', 'inactive']) {
      test('adds plain NACK to all Opus payloads in a $direction section', () {
        final media = <String, dynamic>{
          'type': 'audio',
          'direction': direction,
          'rtp': [
            {'payload': 109, 'codec': 'OPUS'},
            {'payload': 112, 'codec': 'opus'},
          ],
          'rtcpFb': [
            {'payload': 109, 'type': 'nack', 'subtype': 'pli'},
          ],
        };
        final expectedFeedback = [
          {'payload': 109, 'type': 'nack', 'subtype': 'pli'},
          {'payload': 109, 'type': 'nack'},
          {'payload': 112, 'type': 'nack'},
        ];
        ensureOpusNack(media);
        expect(media['rtcpFb'], expectedFeedback);
        ensureOpusNack(media);
        expect(media['rtcpFb'], expectedFeedback, reason: 'repeated munging must not duplicate feedback');
      });
    }

    for (final feedback in [
      {'payload': 109, 'type': 'nack'},
      {'payload': '*', 'type': 'nack'},
      {'payload': 109, 'type': 'nack', 'subtype': ''},
    ]) {
      test('preserves existing feedback $feedback', () {
        final media = <String, dynamic>{
          'type': 'audio',
          'rtp': [
            {'payload': 109, 'codec': 'opus'},
          ],
          'rtcpFb': [feedback],
        };
        ensureOpusNack(media);
        expect(media['rtcpFb'], [feedback]);
      });
    }

    test('payload types and feedback stay scoped to their audio sections', () {
      final media = [
        <String, dynamic>{
          'type': 'audio',
          'rtp': [
            {'payload': 109, 'codec': 'opus'},
          ],
        },
        <String, dynamic>{
          'type': 'video',
          'rtp': [
            {'payload': 109, 'codec': 'VP8'},
          ],
          'rtcpFb': [
            {'payload': 109, 'type': 'nack'},
          ],
        },
        <String, dynamic>{
          'type': 'audio',
          'rtp': [
            {'payload': 109, 'codec': 'PCMU'},
          ],
        },
        <String, dynamic>{'type': 'audio'},
      ];
      for (final section in media) {
        ensureOpusNack(section);
      }
      expect(media[0]['rtcpFb'], [
        {'payload': 109, 'type': 'nack'},
      ]);
      expect(media[1]['rtcpFb'], [
        {'payload': 109, 'type': 'nack'},
      ]);
      expect(media[2].containsKey('rtcpFb'), isFalse);
      expect(media[3].containsKey('rtcpFb'), isFalse);
    });

    test('parsed wildcard NACK covers every Opus payload without duplication', () {
      final parsed = sdp_transform.parse(
        _offer.replaceFirst(
          'a=rtpmap:109 opus/48000/2',
          'a=rtpmap:109 opus/48000/2\r\na=rtcp-fb:* nack',
        ),
      );
      final first = (parsed['media'] as List).first as Map<String, dynamic>;
      ensureOpusNack(first);
      expect(first['rtcpFb'], [
        {'payload': '*', 'type': 'nack', 'subtype': null},
      ]);
    });
  });

  group('Opus NACK subscriber answers', () {
    final offeredNack = _offer.replaceFirst('a=mid:0\r\n', 'a=mid:0\r\na=rtcp-fb:109 nack\r\n');

    test('accepts NACK only on the offered MID and returns the applied answer', () async {
      final (transport, pc, _) = await _makeTransport(singlePC: false);
      final offer = rtc.RTCSessionDescription(offeredNack, 'offer');
      await transport.setRemoteDescription(offer);
      final answer = await transport.createAndSetAnswer(offer);
      final sections = sdp_transform.parse(answer.sdp!)['media'] as List;
      expect(
        sections[0]['rtcpFb'],
        equals([
          {'payload': 109, 'type': 'nack', 'subtype': null},
        ]),
      );
      expect(sections[1]['rtcpFb'] ?? [], isEmpty);
      expect(sections[2]['rtcpFb'] ?? [], isEmpty);
      expect((await pc.getLocalDescription())!.sdp, answer.sdp);
    });

    test('does not add NACK when the offer lacks it or only offers NACK PLI', () async {
      for (final feedback in ['', 'a=rtcp-fb:109 nack pli\r\n']) {
        final (transport, pc, _) = await _makeTransport(singlePC: false);
        final offer = rtc.RTCSessionDescription(_offer.replaceFirst('a=mid:0\r\n', 'a=mid:0\r\n$feedback'), 'offer');
        await transport.setRemoteDescription(offer);
        final answer = await transport.createAndSetAnswer(offer);
        expect(answer.sdp, pc.answer);
        _expectNack(answer.sdp!, audioSections: 3, enabled: false);
      }
    });

    test('rejected NACK falls back and returns the original applied answer', () async {
      final (transport, pc, _) = await _makeTransport(singlePC: false);
      pc.rejectNack = true;
      final offer = rtc.RTCSessionDescription(offeredNack, 'offer');
      await transport.setRemoteDescription(offer);
      final answer = await transport.createAndSetAnswer(offer);
      expect(pc.rejectedNackOffers, 1);
      expect(answer.sdp, pc.answer);
      expect((await pc.getLocalDescription())!.sdp, answer.sdp);
    });

    test('propagates failure if the original answer is rejected too', () async {
      final (transport, pc, _) = await _makeTransport(singlePC: false);
      pc.rejectAll = true;
      final offer = rtc.RTCSessionDescription(offeredNack, 'offer');
      await transport.setRemoteDescription(offer);
      await expectLater(transport.createAndSetAnswer(offer), throwsStateError);
      expect(await pc.getLocalDescription(), isNull);
    });

    test('matches reordered MIDs and resolves the answer payload independently', () {
      final answer =
          'v=0\r\no=- 1 1 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\n'
          'm=audio 9 UDP/TLS/RTP/SAVPF 108\r\na=mid:1\r\na=rtpmap:108 opus/48000/2\r\n'
          'm=audio 9 UDP/TLS/RTP/SAVPF 110\r\na=mid:0\r\na=rtpmap:110 opus/48000/2\r\n';
      for (final payload in ['109', '*']) {
        final offer = offeredNack.replaceFirst('a=rtcp-fb:109 nack', 'a=rtcp-fb:$payload nack');
        final munged = mungeOpusNackForAnswer(answer, offer);
        final sections = sdp_transform.parse(munged)['media'] as List;
        expect(sections[0]['rtcpFb'] ?? [], isEmpty);
        expect(
          sections[1]['rtcpFb'],
          equals([
            {'payload': 110, 'type': 'nack', 'subtype': null},
          ]),
        );
        expect(mungeOpusNackForAnswer(munged, offer), munged);
      }
    });
  });

  group('Opus NACK offers', () {
    test('single-PC first offer includes NACK in every audio direction', () async {
      final (transport, pc, offers) = await _makeTransport(singlePC: true);
      await transport.createAndSendOffer();
      expect(offers, hasLength(1));
      _expectNack(offers.single.sdp!, audioSections: 3, enabled: true);
      expect((await pc.getLocalDescription())?.sdp, offers.single.sdp);
    });

    test('dual-PC publisher keeps NACK absent', () async {
      final (transport, _, offers) = await _makeTransport(singlePC: false);
      await transport.createAndSendOffer();
      _expectNack(offers.single.sdp!, audioSections: 3, enabled: false);
    });

    test('does not enable NACK from the requested option when the effective mode is dual-PC', () async {
      final (transport, _, offers) = await _makeTransport(singlePC: false, requestedSinglePC: true);
      await transport.createAndSendOffer();
      _expectNack(offers.single.sdp!, audioSections: 3, enabled: false);
    });

    test('send-only audio offers NACK before receive sections exist and after renegotiation', () async {
      final (transport, pc, offers) = await _makeTransport(singlePC: true);
      pc.offer = _offer.split('m=audio 9 UDP/TLS/RTP/SAVPF 111').first;
      await transport.createAndSendOffer();
      _expectNack(offers.single.sdp!, audioSections: 1, enabled: true);
      await transport.setRemoteDescription(rtc.RTCSessionDescription('v=0\r\n', 'answer'));
      pc.offer = _offer;
      await transport.createAndSendOffer();
      expect(offers, hasLength(2));
      _expectNack(offers.last.sdp!, audioSections: 3, enabled: true);
    });

    test('falls back to the original offer if NACK munging is rejected', () async {
      final (transport, pc, offers) = await _makeTransport(singlePC: true);
      pc.rejectNack = true;
      await transport.createAndSendOffer();
      expect(pc.rejectedNackOffers, 1);
      expect(offers.single.sdp, _offer);
      expect((await pc.getLocalDescription())?.sdp, _offer);
      _expectNack(offers.single.sdp!, audioSections: 3, enabled: false);
    });

    test('does not signal an offer if both munged and original descriptions are rejected', () async {
      final (transport, pc, offers) = await _makeTransport(singlePC: true);
      pc.rejectAll = true;
      await expectLater(transport.createAndSendOffer(), throwsA(isA<NegotiationError>()));
      expect(offers, isEmpty);
    });
  });
}
