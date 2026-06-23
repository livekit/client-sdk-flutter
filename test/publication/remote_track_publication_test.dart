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

@Timeout(Duration(seconds: 10))
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/core/engine.dart';
import 'package:livekit_client/src/core/signal_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import 'package:livekit_client/src/support/websocket.dart';
import '../core/signal_client_test.dart';
import '../mock/peerconnection_mock.dart';

/// A websocket that records every outgoing [lk_rtc.SignalRequest] so tests can
/// assert on what the SDK actually sends to the server.
class _CapturingWebSocket extends LiveKitWebSocket {
  final List<lk_rtc.SignalRequest> sent = [];

  @override
  void send(List<int> data) => sent.add(lk_rtc.SignalRequest.fromBuffer(data));
}

class _CapturingConnector {
  final socket = _CapturingWebSocket();
  WebSocketEventHandlers? handlers;

  WebSocketOnData get onData => handlers!.onData!;

  Future<LiveKitWebSocket> connect(
    Uri uri, {
    WebSocketEventHandlers? options,
    Map<String, String>? headers,
    NetworkOptions? networkOptions,
  }) async {
    handlers = options;
    return socket;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CapturingConnector connector;
  late Room room;

  Future<void> connectTestRoom({
    RoomOptions roomOptions = const RoomOptions(),
  }) async {
    connector = _CapturingConnector();
    final client = SignalClient(connector.connect);
    final engine = Engine(
      connectOptions: const ConnectOptions(),
      roomOptions: roomOptions,
      signalClient: client,
      peerConnectionCreate: MockPeerConnection.create,
    );
    room = Room(engine: engine);

    final connectFuture = room.connect(exampleUri, token);
    Future.delayed(const Duration(milliseconds: 1), () {
      connector.onData(joinResponse.writeToBuffer());
      connector.onData(offerResponse.writeToBuffer());
    });
    await connectFuture;

    connector.onData(participantJoinResponse.writeToBuffer());
    await room.events.waitFor<ParticipantConnectedEvent>(duration: const Duration(seconds: 1));
  }

  setUp(() async {
    // adaptiveStream defaults to false, so no visibility timer runs and the
    // emitted settings depend only on the explicit enable/disable preference.
    await connectTestRoom();
  });

  tearDown(() async {
    await room.dispose();
  });

  /// The most recent [lk_rtc.UpdateTrackSettings] the SDK sent for [sid], if any.
  lk_rtc.UpdateTrackSettings? lastSettingsFor(String sid) {
    final matches =
        connector.socket.sent.where((r) => r.hasTrackSetting() && r.trackSetting.trackSids.contains(sid)).toList();
    return matches.isEmpty ? null : matches.last.trackSetting;
  }

  group('enable/disable wiring', () {
    test('disable() then enable() emit the disabled flag through the real publication path', () async {
      final participant = room.remoteParticipants.values.first;
      const sid = 'TR_remote_pub_test';
      final pub = RemoteTrackPublication<RemoteVideoTrack>(
        participant: participant,
        info: lk_models.TrackInfo(
          sid: sid,
          name: 'video',
          type: lk_models.TrackType.VIDEO,
        ),
      );
      addTearDown(() async => await pub.dispose());

      // No explicit preference yet: enabled by default, nothing sent.
      expect(pub.enabled, isTrue);
      expect(lastSettingsFor(sid), isNull);

      await pub.disable();
      final disabled = lastSettingsFor(sid);
      expect(disabled, isNotNull, reason: 'disable() should send an UpdateTrackSettings');
      expect(disabled!.disabled, isTrue);
      expect(disabled.trackSids, [sid]);
      // The default video path resolves to HIGH quality.
      expect(disabled.quality, lk_models.VideoQuality.HIGH);
      expect(pub.enabled, isFalse);

      await pub.enable();
      final enabled = lastSettingsFor(sid);
      expect(enabled!.disabled, isFalse);
      expect(pub.enabled, isTrue);
    });

    test('repeated disable() is a no-op (no duplicate send)', () async {
      final participant = room.remoteParticipants.values.first;
      const sid = 'TR_remote_pub_dedup';
      final pub = RemoteTrackPublication<RemoteVideoTrack>(
        participant: participant,
        info: lk_models.TrackInfo(
          sid: sid,
          name: 'video',
          type: lk_models.TrackType.VIDEO,
        ),
      );
      addTearDown(() async => await pub.dispose());

      await pub.disable();
      final countAfterFirst =
          connector.socket.sent.where((r) => r.hasTrackSetting() && r.trackSetting.trackSids.contains(sid)).length;

      await pub.disable();
      final countAfterSecond =
          connector.socket.sent.where((r) => r.hasTrackSetting() && r.trackSetting.trackSids.contains(sid)).length;

      expect(countAfterFirst, 1);
      expect(countAfterSecond, 1, reason: 'a second disable() with no state change should not re-send');
    });

    test('enabled follows adaptive visibility when there is no explicit preference', () async {
      await room.dispose();
      await connectTestRoom(
        roomOptions: const RoomOptions(adaptiveStream: true),
      );

      final participant = room.remoteParticipants.values.first;
      const sid = 'TR_remote_pub_adaptive_hidden';
      final pub = RemoteTrackPublication<RemoteVideoTrack>(
        participant: participant,
        info: lk_models.TrackInfo(
          sid: sid,
          name: 'video',
          type: lk_models.TrackType.VIDEO,
        ),
      );
      addTearDown(() async => await pub.dispose());

      final stream = _FakeMediaStream('stream-$sid');
      final track = _FakeMediaStreamTrack(id: sid, kind: 'video');
      await stream.addTrack(track);

      expect(pub.enabled, isTrue);

      await pub.updateTrack(RemoteVideoTrack(
        TrackSource.camera,
        stream,
        track,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(pub.enabled, isFalse);

      await pub.enable();
      expect(pub.enabled, isTrue, reason: 'an explicit enable still overrides adaptive visibility');
    });

    test('adaptive visibility is computed immediately when track is attached', () async {
      await room.dispose();
      await connectTestRoom(
        roomOptions: const RoomOptions(adaptiveStream: true),
      );

      final participant = room.remoteParticipants.values.first;
      const sid = 'TR_remote_pub_adaptive_initial';
      final pub = RemoteTrackPublication<RemoteVideoTrack>(
        participant: participant,
        info: lk_models.TrackInfo(
          sid: sid,
          name: 'video',
          type: lk_models.TrackType.VIDEO,
        ),
      );
      addTearDown(() async => await pub.dispose());

      final stream = _FakeMediaStream('stream-$sid');
      final track = _FakeMediaStreamTrack(id: sid, kind: 'video');
      await stream.addTrack(track);

      await pub.updateTrack(RemoteVideoTrack(
        TrackSource.camera,
        stream,
        track,
      ));

      final initialSettings = lastSettingsFor(sid);
      expect(initialSettings, isNotNull);
      expect(initialSettings!.disabled, isTrue);

      await pub.setVideoQuality(VideoQuality.LOW);
      final manualSettings = lastSettingsFor(sid);
      expect(manualSettings!.disabled, isTrue, reason: 'manual video settings should keep hidden tracks disabled');
      expect(manualSettings.quality, lk_models.VideoQuality.LOW);
    });
  });
}

class _FakeMediaStream extends rtc.MediaStream {
  final List<rtc.MediaStreamTrack> _tracks = [];

  _FakeMediaStream(String id) : super(id, 'fake-owner');

  @override
  bool? get active => true;

  @override
  Future<void> addTrack(rtc.MediaStreamTrack track, {bool addToNative = true}) async {
    _tracks.add(track);
  }

  @override
  Future<rtc.MediaStream> clone() async => _FakeMediaStream('${id}_clone');

  @override
  List<rtc.MediaStreamTrack> getAudioTracks() => _tracks.where((t) => t.kind == 'audio').toList();

  @override
  Future<void> getMediaTracks() async {}

  @override
  List<rtc.MediaStreamTrack> getTracks() => List<rtc.MediaStreamTrack>.from(_tracks);

  @override
  List<rtc.MediaStreamTrack> getVideoTracks() => _tracks.where((t) => t.kind == 'video').toList();

  @override
  Future<void> removeTrack(rtc.MediaStreamTrack track, {bool removeFromNative = true}) async {
    _tracks.remove(track);
  }
}

class _FakeMediaStreamTrack implements rtc.MediaStreamTrack {
  @override
  rtc.StreamTrackCallback? onEnded;

  @override
  rtc.StreamTrackCallback? onMute;

  @override
  rtc.StreamTrackCallback? onUnMute;

  @override
  bool enabled;

  @override
  final String id;

  @override
  final String kind;

  @override
  String? get label => '$kind-track';

  @override
  bool? get muted => false;

  _FakeMediaStreamTrack({
    required this.id,
    required this.kind,
    this.enabled = true,
  });

  @override
  Future<void> adaptRes(int width, int height) async {}

  @override
  Future<void> applyConstraints([Map<String, dynamic>? constraints]) async {}

  @override
  Future<ByteBuffer> captureFrame() {
    throw UnimplementedError();
  }

  @override
  Future<rtc.MediaStreamTrack> clone() async => _FakeMediaStreamTrack(id: id, kind: kind, enabled: enabled);

  @override
  Future<void> dispose() async {}

  @override
  Map<String, dynamic> getConstraints() => const {};

  @override
  Map<String, dynamic> getSettings() => const {};

  @override
  Future<bool> hasTorch() async => false;

  @override
  void enableSpeakerphone(bool enable) {}

  @override
  Future<void> setTorch(bool torch) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<bool> switchCamera() async => false;
}
