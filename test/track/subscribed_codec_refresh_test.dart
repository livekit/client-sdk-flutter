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
import 'package:mockito/mockito.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import '../mock/e2e_container.dart';
import '../mock/mediastream_mock.dart';

lk_rtc.SubscribedCodec _codec(String name, {required bool medium, required bool low}) => lk_rtc.SubscribedCodec(
  codec: name,
  qualities: [
    lk_rtc.SubscribedQuality(quality: lk_models.VideoQuality.HIGH, enabled: true),
    lk_rtc.SubscribedQuality(quality: lk_models.VideoQuality.MEDIUM, enabled: medium),
    lk_rtc.SubscribedQuality(quality: lk_models.VideoQuality.LOW, enabled: low),
  ],
);

/// The dynacast state the SFU last asked for: only the high layer is subscribed.
List<lk_rtc.SubscribedCodec> _onlyHighSubscribed() => [_codec('vp8', medium: false, low: false)];

/// Every layer subscribed, so dynacast has paused nothing.
List<lk_rtc.SubscribedCodec> _allSubscribed() => [_codec('vp8', medium: true, low: true)];

LocalVideoTrack _createTrack(_FakeSender sender) {
  final track = LocalVideoTrack(
    TrackSource.camera,
    FakeMediaStream('stream-1'),
    FakeMediaStreamTrack(id: 'video-1', kind: 'video'),
    const CameraCaptureOptions(),
  );
  track.codec = 'vp8';
  track.transceiver = _FakeTransceiver(sender);
  return track;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalVideoTrack.refreshSubscribedCodecs', () {
    test('writes to the sender even when its parameters already read as paused', () async {
      // The state a native sender is in after the answer: the layers are live
      // again, but `parameters` is a local cache that still reports the pause.
      // Nothing here differs from the target, so only the forced write reaches
      // the sender at all.
      final sender = _FakeSender(cachedActive: [true, false, false]);
      final track = _createTrack(sender);
      track.subscribedCodecs = _onlyHighSubscribed();

      await track.refreshSubscribedCodecs();

      expect(sender.setParametersCalls, 1);
      expect(sender.writtenActiveFlags, [true, false, false]);
    });

    test('re-pauses the layers when the sender reports them re-enabled', () async {
      final sender = _FakeSender(cachedActive: [true, true, true]);
      final track = _createTrack(sender);
      track.subscribedCodecs = _onlyHighSubscribed();

      await track.refreshSubscribedCodecs();

      expect(sender.setParametersCalls, 1);
      expect(sender.writtenActiveFlags, [true, false, false]);
    });

    test('does not touch the sender when no layer is paused', () async {
      // Nothing was paused, so the answer undid nothing and the renegotiation
      // owes no native call.
      final sender = _FakeSender(cachedActive: [true, true, true]);
      final track = _createTrack(sender);
      track.subscribedCodecs = _allSubscribed();

      await track.refreshSubscribedCodecs();

      expect(sender.setParametersCalls, 0);
    });

    test('does nothing when no subscribed codecs have been recorded', () async {
      final sender = _FakeSender(cachedActive: [true, true, true]);
      final track = _createTrack(sender);

      await track.refreshSubscribedCodecs();

      expect(sender.setParametersCalls, 0);
    });

    test('leaves a fully-subscribed backup codec alone while re-pausing the primary', () async {
      // The backup path writes an SDK-owned encoding list wholesale over the
      // sender, so forcing a codec that has nothing paused would clobber
      // whatever the sender had adapted to.
      final primarySender = _FakeSender(cachedActive: [true, false, false]);
      final backupSender = _FakeSender(cachedActive: [true, true, true]);
      final track = _createTrack(primarySender);
      track.addSimulcastTrack('h264', backupSender.parameters.encodings!).sender = backupSender;
      track.subscribedCodecs = [
        _codec('vp8', medium: false, low: false),
        _codec('h264', medium: true, low: true),
      ];

      await track.refreshSubscribedCodecs();

      expect(primarySender.setParametersCalls, 1);
      expect(backupSender.setParametersCalls, 0);
    });

    test('swallows a sender failure rather than throwing into its caller', () async {
      final sender = _FakeSender(throwOnParameters: true);
      final track = _createTrack(sender);
      track.subscribedCodecs = _onlyHighSubscribed();

      // It runs from an engine event handler, where a throw has nowhere to go.
      await expectLater(track.refreshSubscribedCodecs(), completes);
    });
  });

  group('a dynacast update still writes only on a real change', () {
    test('leaves the sender alone when the subscribed qualities already hold', () async {
      final sender = _FakeSender(cachedActive: [true, false, false]);
      final track = _createTrack(sender);

      await track.setPublishingCodecs(_onlyHighSubscribed(), track);

      expect(sender.setParametersCalls, 0);
    });
  });

  group('publisher answer', () {
    Future<_FakeSender> publishedTrackAfterAnswer({bool dynacast = true}) async {
      final container = E2EContainer(roomOptions: RoomOptions(dynacast: dynacast));
      addTearDown(container.dispose);
      await container.connectRoom();

      final sender = _FakeSender(cachedActive: [true, false, false]);
      final track = _createTrack(sender);
      track.subscribedCodecs = _onlyHighSubscribed();
      container.room.localParticipant!.addTrackPublication(
        LocalTrackPublication<LocalVideoTrack>(
          participant: container.room.localParticipant!,
          info: lk_models.TrackInfo(sid: 'video_sid', type: lk_models.TrackType.VIDEO),
          track: track,
        ),
      );

      container.wsConnector.onData(
        lk_rtc.SignalResponse(
          answer: lk_rtc.SessionDescription(type: 'answer', sdp: 'v=0\r\n'),
        ).writeToBuffer(),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      return sender;
    }

    test('re-applies the pause the answer undid', () async {
      final sender = await publishedTrackAfterAnswer();

      expect(sender.setParametersCalls, 1);
      expect(sender.writtenActiveFlags, [true, false, false]);
    });

    test('leaves the sender alone when dynacast is off', () async {
      expect((await publishedTrackAfterAnswer(dynacast: false)).setParametersCalls, 0);
    });
  });
}

class _FakeTransceiver extends Mock implements rtc.RTCRtpTransceiver {
  @override
  final rtc.RTCRtpSender sender;

  _FakeTransceiver(this.sender);
}

/// Models a native sender, whose `parameters` is a local cache that only
/// [setParameters] updates — never a live read of what the layers are doing.
class _FakeSender extends Mock implements rtc.RTCRtpSender {
  final bool throwOnParameters;
  int setParametersCalls = 0;

  rtc.RTCRtpParameters _parameters;

  _FakeSender({
    List<bool> cachedActive = const [true, false, false],
    this.throwOnParameters = false,
  }) : _parameters = rtc.RTCRtpParameters(
         encodings: [
           rtc.RTCRtpEncoding(rid: 'f', active: cachedActive[0]),
           rtc.RTCRtpEncoding(rid: 'h', active: cachedActive[1]),
           rtc.RTCRtpEncoding(rid: 'q', active: cachedActive[2]),
         ],
       );

  /// The layer states as of the last [setParameters]. Snapshotted on the way
  /// in, because the caller mutates the very encodings this fake handed out —
  /// reading them back would pass even if the write never happened.
  List<bool>? writtenActiveFlags;

  @override
  rtc.RTCRtpParameters get parameters {
    if (throwOnParameters) {
      throw Exception('sender is gone');
    }
    return _parameters;
  }

  @override
  String get senderId => 'sender-1';

  @override
  Future<bool> setParameters(rtc.RTCRtpParameters parameters) async {
    setParametersCalls++;
    writtenActiveFlags = parameters.encodings!.map((e) => e.active).toList();
    _parameters = parameters;
    return true;
  }
}
