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
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:sdp_transform/sdp_transform.dart' as sdp_transform;

import 'package:livekit_client/src/options.dart' show ConnectOptions, VideoPublishOptions;
import 'package:livekit_client/src/utils.dart' show computeStartTargetBitrate;
import '../mock/peerconnection_mock.dart';

import 'package:livekit_client/src/core/transport.dart'
    show
        TrackBitrateInfo,
        Transport,
        applyVideoStartBitrate,
        computeConnectionStartBitrate,
        computeTrackStartBitrate,
        findTrackCodecPayload;

/// Parse the `key[=value]` pairs of an fmtp config into a comparable set.
Set<String> paramSet(String config) => config.split(';').where((e) => e.isNotEmpty).toSet();

String? fmtpOf(List<dynamic> media, String mid, int payload) {
  final m = media.firstWhere((section) => '${section['mid']}' == mid);
  for (final fmtp in (m['fmtp'] as List? ?? const [])) {
    if (fmtp['payload'] == payload) return fmtp['config'] as String;
  }
  return null;
}

// Two published video sections: a screen share on mid 0 and a camera on mid 1.
const twoVideoSections = '''v=0
o=- 0 0 IN IP4 127.0.0.1
s=-
t=0 0
a=group:BUNDLE 0 1
m=video 9 UDP/TLS/RTP/SAVPF 96
c=IN IP4 0.0.0.0
a=mid:0
a=sendonly
a=msid:stream other-track
a=rtpmap:96 VP8/90000
m=video 9 UDP/TLS/RTP/SAVPF 96
c=IN IP4 0.0.0.0
a=mid:1
a=sendonly
a=msid:stream camera-cid
a=rtpmap:96 VP8/90000''';

// The same bundle after the screen share is unpublished. `removeTrack` moves the sendonly
// transceiver to inactive, but the section keeps its `a=msid`, so it still matches the
// append-only bitrate tracker. Only the camera is still sending.
const unpublishedScreenShare = '''v=0
o=- 0 0 IN IP4 127.0.0.1
s=-
t=0 0
a=group:BUNDLE 0 1
m=video 9 UDP/TLS/RTP/SAVPF 96
c=IN IP4 0.0.0.0
a=mid:0
a=inactive
a=msid:stream other-track
a=rtpmap:96 VP8/90000
m=video 9 UDP/TLS/RTP/SAVPF 96
c=IN IP4 0.0.0.0
a=mid:1
a=sendonly
a=msid:stream camera-cid
a=rtpmap:96 VP8/90000''';

// A sendrecv section and one with no direction attribute at all, which SDP defaults to
// sendrecv. Both can carry local media.
const sendrecvSections = '''v=0
o=- 0 0 IN IP4 127.0.0.1
s=-
t=0 0
a=group:BUNDLE 0 1
m=video 9 UDP/TLS/RTP/SAVPF 96
c=IN IP4 0.0.0.0
a=mid:0
a=sendrecv
a=msid:stream camera-cid
a=rtpmap:96 VP8/90000
m=video 9 UDP/TLS/RTP/SAVPF 96
c=IN IP4 0.0.0.0
a=mid:1
a=msid:stream other-track
a=rtpmap:96 VP8/90000''';

List<dynamic> mediaOf(String sdp) => sdp_transform.parse(sdp)['media'] as List<dynamic>;

void main() {
  group('video start bitrate', () {
    test('matches only the section whose msid track ID matches the cid', () {
      final media = mediaOf(twoVideoSections);

      expect(findTrackCodecPayload(media[0], 'camera-cid', 'VP8'), isNull);
      expect(findTrackCodecPayload(media[1], 'camera-cid', 'VP8'), 96);
      // Section belongs to the track but does not offer the codec.
      expect(findTrackCodecPayload(media[1], 'camera-cid', 'AV1'), 0);
    });

    test('applies the bitrate only to the section it is given', () {
      final media = mediaOf(twoVideoSections);

      applyVideoStartBitrate(media[1], 96, 900);

      expect(fmtpOf(media, '0', 96), isNull);
      expect(paramSet(fmtpOf(media, '1', 96)!), contains('x-google-start-bitrate=900'));
    });

    test('caps camera at 1 Mbps but leaves screen share uncapped', () {
      final camera = TrackBitrateInfo(cid: 'c', transceiver: null, codec: 'VP8', maxbr: 3000);
      final screenShare = TrackBitrateInfo(
        cid: 'c',
        transceiver: null,
        codec: 'VP8',
        maxbr: 3000,
        isScreenShare: true,
      );

      expect(computeTrackStartBitrate(camera), 1000);
      expect(computeTrackStartBitrate(screenShare), 2700);
    });

    test('gives no hint below the 300 kbps target floor', () {
      expect(
        computeTrackStartBitrate(TrackBitrateInfo(cid: 'c', transceiver: null, codec: 'VP8', maxbr: 299)),
        isNull,
      );
      expect(
        computeTrackStartBitrate(TrackBitrateInfo(cid: 'c', transceiver: null, codec: 'VP8', maxbr: 300)),
        270,
      );
    });

    test('uses one connection-level value: the largest hint across video sections', () {
      final startBitrate = computeConnectionStartBitrate(mediaOf(twoVideoSections), [
        TrackBitrateInfo(cid: 'camera-cid', transceiver: null, codec: 'VP8', maxbr: 1000),
        TrackBitrateInfo(cid: 'other-track', transceiver: null, codec: 'VP8', maxbr: 3000, isScreenShare: true),
      ]);

      expect(startBitrate, 2700);
    });

    test('ignores registered tracks with no section in the current SDP', () {
      final startBitrate = computeConnectionStartBitrate(mediaOf(twoVideoSections), [
        TrackBitrateInfo(cid: 'camera-cid', transceiver: null, codec: 'VP8', maxbr: 1000),
        // Stale entry: the tracker list is append-only and outlives an unpublish.
        TrackBitrateInfo(cid: 'unpublished-cid', transceiver: null, codec: 'VP8', maxbr: 8000, isScreenShare: true),
      ]);

      expect(startBitrate, 900);
    });

    test('ignores a section that stopped sending but kept its msid', () {
      List<TrackBitrateInfo> trackers() => [
        TrackBitrateInfo(cid: 'camera-cid', transceiver: null, codec: 'VP8', maxbr: 1000),
        TrackBitrateInfo(cid: 'other-track', transceiver: null, codec: 'VP8', maxbr: 8000, isScreenShare: true),
      ];

      // While both send, the uncapped screen share wins the connection-level max.
      expect(computeConnectionStartBitrate(mediaOf(twoVideoSections), trackers()), 7200);
      // Once unpublished its entry is stale, so only the capped camera counts. Both
      // directions a removed sender can land on are excluded: `inactive` from a sendonly
      // transceiver, `recvonly` from a sendrecv one.
      expect(computeConnectionStartBitrate(mediaOf(unpublishedScreenShare), trackers()), 900);
      expect(
        computeConnectionStartBitrate(
          mediaOf(unpublishedScreenShare.replaceAll('a=inactive', 'a=recvonly')),
          trackers(),
        ),
        900,
      );
    });

    test('counts sendrecv and direction-less sections, which still send local media', () {
      final media = mediaOf(sendrecvSections);

      expect(
        computeConnectionStartBitrate(media, [
          TrackBitrateInfo(cid: 'camera-cid', transceiver: null, codec: 'VP8', maxbr: 1000),
        ]),
        900,
      );
      expect(
        computeConnectionStartBitrate(media, [
          TrackBitrateInfo(cid: 'other-track', transceiver: null, codec: 'VP8', maxbr: 2000, isScreenShare: true),
        ]),
        1800,
      );
    });

    test('republishing a track replaces its tracker instead of shadowing it', () async {
      final transport = await Transport.create(MockPeerConnection.create, connectOptions: const ConnectOptions());
      addTearDown(transport.dispose);

      // First publish below the floor: no hint, so the one-shot latch stays unset.
      transport.setTrackBitrateInfo(
        TrackBitrateInfo(cid: 'camera-cid', transceiver: null, codec: 'VP8', maxbr: 250),
      );
      expect(computeConnectionStartBitrate(mediaOf(twoVideoSections), transport.bitrateTrackers), isNull);

      // A LocalTrack keeps its cid across unpublish and republish, and the lookup stops at the
      // first entry whose cid the section carries — so a leftover entry would shadow this one.
      transport.setTrackBitrateInfo(
        TrackBitrateInfo(cid: 'camera-cid', transceiver: null, codec: 'VP8', maxbr: 1500),
      );

      expect(computeConnectionStartBitrate(mediaOf(twoVideoSections), transport.bitrateTrackers), 1000);
      expect(transport.bitrateTrackers.length, 1);
    });

    test('gives no connection value when nothing sending matches', () {
      expect(computeConnectionStartBitrate(mediaOf(twoVideoSections), []), isNull);
      expect(
        computeConnectionStartBitrate(mediaOf(unpublishedScreenShare), [
          TrackBitrateInfo(cid: 'other-track', transceiver: null, codec: 'VP8', maxbr: 8000, isScreenShare: true),
        ]),
        isNull,
      );
    });
  });

  group('computeStartTargetBitrate', () {
    final simulcast = [
      rtc.RTCRtpEncoding(rid: 'q', maxBitrate: 150000),
      rtc.RTCRtpEncoding(rid: 'h', maxBitrate: 500000),
      rtc.RTCRtpEncoding(rid: 'f', maxBitrate: 1700000),
    ];

    test('sums simulcast encodings rather than reading the lowest layer', () {
      expect(computeStartTargetBitrate('vp8', const VideoPublishOptions(), simulcast), 2350000);
    });

    test('uses the single encoding for an SVC stream', () {
      expect(
        computeStartTargetBitrate('vp9', const VideoPublishOptions(scalabilityMode: 'L3T3_KEY'), [
          rtc.RTCRtpEncoding(maxBitrate: 1700000),
        ]),
        1700000,
      );
    });

    test('sums encodings for SVC published as simulcast (L1T*)', () {
      expect(
        computeStartTargetBitrate(
          'vp9',
          const VideoPublishOptions(simulcast: true, scalabilityMode: 'L1T3'),
          simulcast,
        ),
        2350000,
      );
    });

    test('returns zero when there are no encodings', () {
      expect(computeStartTargetBitrate('vp8', const VideoPublishOptions(), null), 0);
      expect(computeStartTargetBitrate('vp8', const VideoPublishOptions(), []), 0);
    });
  });
}
