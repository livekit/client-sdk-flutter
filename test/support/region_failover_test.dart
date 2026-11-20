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

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/src/exceptions.dart';
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_models;
import 'package:livekit_client/src/support/region_url_provider.dart';
import 'package:livekit_client/src/support/websocket.dart' show WebSocketException;

void main() {
  group('canFailOverToAnotherRegion', () {
    test('allows failover on 403, which LiveKit Cloud uses to signal region pinning', () {
      // The RTC paths 403 when the project is not allowed in the region the client
      // geo-routed to. /settings/regions stays reachable so the client can discover
      // where it is allowed to connect.
      expect(
        canFailOverToAnotherRegion(
          ConnectException(
            'project not allowed in this region.',
            reason: ConnectionErrorReason.NotAllowed,
            statusCode: 403,
          ),
        ),
        isTrue,
      );
    });

    test('does not allow failover on 401 — no other region will accept the same token', () {
      expect(
        canFailOverToAnotherRegion(
          ConnectException(
            'unauthorized',
            reason: ConnectionErrorReason.NotAllowed,
            statusCode: 401,
          ),
        ),
        isFalse,
      );
    });

    test('allows failover on a websocket error', () {
      expect(canFailOverToAnotherRegion(const WebSocketException('failed')), isTrue);
    });

    test('allows failover on non-NotAllowed connect errors', () {
      for (final reason in [ConnectionErrorReason.InternalError, ConnectionErrorReason.Timeout]) {
        expect(
          canFailOverToAnotherRegion(ConnectException('failed', reason: reason)),
          isTrue,
          reason: 'expected failover for $reason',
        );
      }
    });

    test('does not allow failover on unrelated errors', () {
      expect(canFailOverToAnotherRegion(StateError('boom')), isFalse);
    });
  });

  group('isCloudUrl', () {
    test('accepts LiveKit Cloud hosts', () {
      for (final url in [
        'wss://project.livekit.cloud',
        'wss://project.otokyo1a.production.livekit.cloud',
        'wss://project.livekit.run',
        'wss://PROJECT.LIVEKIT.CLOUD',
      ]) {
        expect(isCloudUrl(Uri.parse(url)), isTrue, reason: url);
      }
    });

    test('matches the suffix, not a substring anywhere in the host', () {
      // `project.livekit.cloud.example.com` contains `.livekit.cloud` but belongs to someone
      // else; treating it as Cloud would send it the region request with the token attached.
      for (final url in [
        'wss://project.livekit.cloud.example.com',
        'wss://livekit.run.example.com',
        'wss://not-livekit.cloud',
        'wss://self-hosted.example.com',
        'ws://localhost:7880',
      ]) {
        expect(isCloudUrl(Uri.parse(url)), isFalse, reason: url);
      }
    });
  });

  group('isTrustedRegionUrl', () {
    test('accepts encrypted LiveKit Cloud urls', () {
      for (final url in [
        'wss://eu.livekit.cloud',
        'https://eu.livekit.cloud',
        'https://eu.livekit.cloud:443/rtc',
        'wss://staging.livekit.run',
      ]) {
        expect(isTrustedRegionUrl(url), isTrue, reason: url);
      }
    });

    test('rejects cleartext schemes even for a real cloud host', () {
      for (final url in ['ws://eu.livekit.cloud', 'http://eu.livekit.cloud']) {
        expect(isTrustedRegionUrl(url), isFalse, reason: url);
      }
    });

    test('rejects foreign hosts and suffix near-misses', () {
      for (final url in [
        'https://other.example.com',
        'wss://other.example.com/rtc',
        'https://not-livekit.cloud',
        'https://livekit.cloud.example.com',
        // The one a `contains` match would wrongly accept: the dot-prefixed domain appears in
        // the middle of someone else's host.
        'https://project.livekit.cloud.example.com',
      ]) {
        expect(isTrustedRegionUrl(url), isFalse, reason: url);
      }
    });

    test('rejects malformed and hostless urls', () {
      for (final url in ['', 'eu.livekit.cloud', 'file:///etc/passwd', '::::']) {
        expect(isTrustedRegionUrl(url), isFalse, reason: url);
      }
    });
  });

  group('region ingestion', () {
    lk_models.RegionInfo region(String name, String url) =>
        lk_models.RegionInfo(region: name, url: url, distance: Int64(1));

    test('server reported regions drop entries the SDK must not fail over to', () async {
      final provider = RegionUrlProvider(url: 'wss://project.livekit.cloud', token: 'token');

      provider.setServerReportedRegions(
        lk_models.RegionSettings(
          regions: [
            region('foreign', 'https://other.example.com'),
            region('cleartext', 'ws://cleartext.livekit.cloud'),
            region('near-miss', 'https://livekit.cloud.example.com'),
            region('good', 'https://good.livekit.cloud'),
          ],
        ),
      );

      expect(provider.regionSettings!.regions.map((r) => r.url), ['https://good.livekit.cloud']);
      expect(await provider.getNextBestRegionUrl(), 'https://good.livekit.cloud');
      expect(await provider.getNextBestRegionUrl(), isNull);
    });
  });
}
