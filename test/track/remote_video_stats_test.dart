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

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:mockito/mockito.dart';

import 'package:livekit_client/src/track/remote/video.dart';
import 'package:livekit_client/src/types/other.dart';

class _Stream extends Mock implements rtc.MediaStream {}

class _MediaTrack extends Mock implements rtc.MediaStreamTrack {}

class _Receiver extends Mock implements rtc.RTCRtpReceiver {
  List<rtc.StatsReport> reports = [];

  @override
  Future<List<rtc.StatsReport>> getStats() async => reports;
}

void main() {
  test('receiver codec metadata follows codecId, independent of report order', () async {
    final receiver = _Receiver();
    final track = RemoteVideoTrack(TrackSource.camera, _Stream(), _MediaTrack(), receiver: receiver);
    final unrelated = rtc.StatsReport('audio-codec', 'codec', 1, {
      'mimeType': 'audio/opus',
      'payloadType': 111,
      'channels': 2,
      'clockRate': 48000,
    });
    final selected = rtc.StatsReport('video-codec', 'codec', 1, {
      'mimeType': 'video/VP8',
      'payloadType': 96,
      'channels': 1,
      'clockRate': 90000,
    });
    final inbound = rtc.StatsReport('inbound-video', 'inbound-rtp', 1, {
      'codecId': 'video-codec',
      'bytesReceived': 100,
    });
    for (final reports in [
      [unrelated, inbound, selected],
      [selected, inbound, unrelated],
    ]) {
      receiver.reports = reports;
      final result = await track.getReceiverStats();
      expect(result?.mimeType, 'video/VP8');
      expect(result?.payloadType, 96);
      expect(result?.channels, 1);
      expect(result?.clockRate, 90000);
      expect(result?.bytesReceived, 100);
    }
    await track.dispose();
  });

  test('missing or unknown codecId leaves codec metadata absent', () async {
    final receiver = _Receiver();
    final track = RemoteVideoTrack(TrackSource.camera, _Stream(), _MediaTrack(), receiver: receiver);
    final codec = rtc.StatsReport('other', 'codec', 1, {'mimeType': 'video/H264'});
    for (final values in [
      <String, dynamic>{},
      <String, dynamic>{'codecId': 'missing'},
    ]) {
      receiver.reports = [rtc.StatsReport('inbound', 'inbound-rtp', 1, values), codec];
      final result = await track.getReceiverStats();
      expect(result, isNotNull);
      expect(result?.mimeType, isNull);
    }
    await track.dispose();
  });
}
