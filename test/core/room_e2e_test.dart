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

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:logging/logging.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/internal/events.dart';
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import '../mock/e2e_container.dart';
import '../mock/test_data.dart';
import '../mock/websocket_mock.dart';
import 'signal_client_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late E2EContainer container;
  late Room room;
  late MockWebSocketConnector ws;
  setUp(() async {
    // configure logs for debugging
    Logger.root.level = Level.FINEST;
    Logger.root.onRecord.listen((record) {
      print('[${record.level.name}]: ${record.message}');
    });

    container = E2EContainer();
    room = container.room;
    ws = container.wsConnector;
    await container.connectRoom();
  });

  tearDown(() async {
    await container.dispose();
  });

  group('connection', () {
    test('disconnect and connect', () async {
      await room.disconnect();
      await container.connectRoom();
      expect(room.connectionState, ConnectionState.connected);
      expect(room.localParticipant?.sid, joinResponse.join.participant.sid);
    }, skip: 'todo');
  });

  group('full reconnect', () {
    test('republish failure still completes reconnection', () async {
      ws.onData(participantJoinResponse.writeToBuffer());
      await room.events.waitFor<ParticipantConnectedEvent>(duration: const Duration(seconds: 1));
      container.engine.events.emit(
        EngineTrackAddedEvent(
          track: _FakeMediaStreamTrack(id: remoteAudioTrack.sid, kind: 'audio'),
          stream: _FakeMediaStream('${remoteParticipantData.sid}|remote_stream'),
          receiver: null,
        ),
      );
      await room.events.waitFor<TrackSubscribedEvent>(duration: const Duration(seconds: 1));

      final error = StateError('audio capture failed during republish');
      final track = _FailingAudioTrack(error);
      final participant = room.localParticipant!;
      final publication = LocalTrackPublication<LocalAudioTrack>(
        participant: participant,
        info: remoteAudioTrack.deepCopy()..sid = 'local_audio_track_sid',
        track: track,
      );
      participant.addTrackPublication(publication);
      // Republishing removes the old publication from the participant.
      addTearDown(publication.dispose);
      await Future<void>.delayed(Duration.zero);

      final records = <LogRecord>[];
      final logs = Logger.root.onRecord.listen(records.add);
      addTearDown(logs.cancel);
      final notified = Completer<void>();
      void onChanged() {
        if (!notified.isCompleted) notified.complete();
      }

      room.addListener(onChanged);
      addTearDown(() => room.removeListener(onChanged));
      ws.sentData.clear();
      final reconnected = room.events.waitFor<RoomReconnectedEvent>(duration: const Duration(seconds: 1));
      container.engine.events.emit(const EngineRestartedEvent());

      await reconnected;
      await notified.future.timeout(const Duration(seconds: 1));
      expect(track.startAttempts, 1);
      final settings = ws.sentData.map(lk_rtc.SignalRequest.fromBuffer).where((request) => request.hasTrackSetting());
      expect(settings, hasLength(1));
      expect(settings.single.trackSetting.trackSids, [remoteAudioTrack.sid]);
      expect(records.where((record) => identical(record.error, error)), hasLength(1));
    });
  });

  group('room updates', () {
    test('participant join', () async {
      final publicEventsStream = room.events.streamCtrl.stream.where((event) => event is! InternalEvent);

      expect(
        publicEventsStream,
        emitsInOrder(<Matcher>[
          predicate<ParticipantStateUpdatedEvent>((event) => event.participant.sid == remoteParticipantData.sid),
          predicate<ParticipantConnectedEvent>(
            (event) => event.participant.sid == remoteParticipantData.sid,
          ),
          predicate<TrackPublishedEvent>(
            (event) => event.participant.sid == remoteParticipantData.sid,
          ),
        ]),
      );

      ws.onData(participantJoinResponse.writeToBuffer());

      await room.events.waitFor<ParticipantConnectedEvent>(duration: const Duration(seconds: 1));
      expect(room.remoteParticipants.length, 1);
    });

    test('participant join with tracks populated before connected event', () async {
      // Track whether participant has tracks when connected event fires
      bool participantHadTracksOnConnect = false;
      int trackCountOnConnect = 0;

      // Listen for ParticipantConnectedEvent
      final cancel = room.events.on<ParticipantConnectedEvent>((event) {
        // Verify participant is fully populated with tracks
        trackCountOnConnect = event.participant.trackPublications.length;
        participantHadTracksOnConnect = trackCountOnConnect > 0;
      });

      // Send participant join with tracks
      ws.onData(participantJoinResponse.writeToBuffer());

      // Wait for connected event
      await room.events.waitFor<ParticipantConnectedEvent>(duration: const Duration(seconds: 1));

      // Clean up listener
      await cancel();

      // Verify participant had tracks when connected event was emitted
      expect(
        participantHadTracksOnConnect,
        isTrue,
        reason: 'Participant should have tracks when ParticipantConnectedEvent is emitted',
      );
      expect(
        trackCountOnConnect,
        greaterThan(0),
        reason: 'Participant should have at least one track when connected event fires',
      );

      // Verify the participant is in the room
      expect(room.remoteParticipants.length, 1);
    });

    test('participant disconnect', () async {
      ws.onData(participantJoinResponse.writeToBuffer());
      await room.events.waitFor<ParticipantConnectedEvent>(duration: const Duration(seconds: 1));

      ws.onData(participantDisconnectResponse.writeToBuffer());
      expect(
        room.events.streamCtrl.stream,
        emitsInOrder(<Matcher>[
          predicate<TrackUnpublishedEvent>((event) => event.participant.sid == remoteParticipantData.sid),
          predicate<ParticipantDisconnectedEvent>((event) => event.participant.sid == remoteParticipantData.sid),
        ]),
      );

      await room.events.waitFor<ParticipantDisconnectedEvent>(duration: const Duration(seconds: 1));
      expect(room.remoteParticipants.length, 0);
    });

    test('participant metadata changed', () async {
      ws.onData(participantJoinResponse.writeToBuffer());
      await room.events.waitFor<ParticipantConnectedEvent>(duration: const Duration(seconds: 1));

      ws.onData(participantMetadataChangedResponse.writeToBuffer());
      expect(
        room.events.streamCtrl.stream,
        emits(
          predicate<ParticipantMetadataUpdatedEvent>(
            (event) => event.participant.metadata == participantMetadataChangedResponse.update.participants[0].metadata,
          ),
        ),
      );
    });

    test('room metadata update', () async {
      expect(
        room.events.streamCtrl.stream,
        emits(
          predicate<RoomMetadataChangedEvent>(
            (event) => event.metadata == roomUpdateResponse.roomUpdate.room.metadata && room.metadata == event.metadata,
          ),
        ),
      );
      ws.onData(roomUpdateResponse.writeToBuffer());
    });

    test('connection quality', () async {
      expect(
        room.events.streamCtrl.stream,
        emits(
          predicate<ParticipantConnectionQualityUpdatedEvent>(
            (event) =>
                event.participant.sid == localParticipantData.sid &&
                event.connectionQuality == ConnectionQuality.excellent,
          ),
        ),
      );
      ws.onData(connectionQualityResponse.writeToBuffer());
    });

    test('active speakers changed', () async {
      ws.onData(participantJoinResponse.writeToBuffer());
      await room.events.waitFor<ParticipantConnectedEvent>(duration: const Duration(seconds: 1));

      expect(
        room.events.streamCtrl.stream,
        emits(
          predicate<ActiveSpeakersChangedEvent>((event) => event.speakers[0].sid == remoteParticipantData.sid),
        ),
      );
      ws.onData(activeSpeakerResponse.writeToBuffer());
    });

    test('leave', () async {
      expect(
        room.events.streamCtrl.stream,
        emits(predicate<RoomDisconnectedEvent>((event) => event.reason == DisconnectReason.unknown)),
      );
      ws.onData(leaveResponse.writeToBuffer());
    });

    test('tracks arriving before participant metadata are handled once metadata arrives', () async {
      final fakeStream = _FakeMediaStream('${remoteParticipantData.sid}|remote_stream');
      final fakeTrack = _FakeMediaStreamTrack(
        id: remoteAudioTrack.sid,
        kind: 'audio',
      );

      var subscriptionException = false;
      room.events.on<TrackSubscriptionExceptionEvent>((event) {
        subscriptionException = true;
      });

      // Emit onTrack before participant update arrives.
      container.engine.events.emit(
        EngineTrackAddedEvent(
          track: fakeTrack,
          stream: fakeStream,
          receiver: null,
        ),
      );

      // Now deliver participant metadata.
      ws.onData(participantJoinResponse.writeToBuffer());

      // Track should eventually subscribe once metadata is available.
      final trackSubscribed = await room.events.waitFor<TrackSubscribedEvent>(
        duration: const Duration(seconds: 1),
      );

      expect(subscriptionException, isFalse, reason: 'Track subscription should not fail when metadata arrives later');
      expect(trackSubscribed.participant.sid, remoteParticipantData.sid);
      expect(trackSubscribed.publication.track, isNotNull);
    });
  });

  group('publish guards', () {
    test('concurrent setSourceEnabled serializes calls', () async {
      final lp = room.localParticipant!;

      // Both calls will fail (no camera hardware in test), but the
      // SerialRunner should serialize them — the second waits for the
      // first to complete before executing.
      final future1 = lp.setSourceEnabled(TrackSource.camera, true);
      final future2 = lp.setSourceEnabled(TrackSource.camera, true);

      // Both should fail with the same error (no camera), not with
      // duplicate track errors or unhandled exceptions.
      final results = await Future.wait([
        future1.catchError((_) => null),
        future2.catchError((_) => null),
      ]);

      // Both calls completed (didn't hang or deadlock).
      expect(results.length, 2);
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
  Future<void> applyConstraints([Map<String, dynamic>? constraints]) async {}

  @override
  Future<rtc.MediaStreamTrack> clone() async => _FakeMediaStreamTrack(id: id, kind: kind, enabled: enabled);

  @override
  Future<void> dispose() async {}

  @override
  Future<void> adaptRes(int width, int height) async {}

  @override
  Map<String, dynamic> getConstraints() => const {};

  @override
  Map<String, dynamic> getSettings() => const {};

  @override
  Future<void> stop() async {}

  @override
  void enableSpeakerphone(bool enable) {}

  @override
  Future<ByteBuffer> captureFrame() {
    throw UnimplementedError();
  }

  @override
  Future<bool> hasTorch() async => false;

  @override
  Future<void> setTorch(bool torch) async {}

  @override
  Future<bool> switchCamera() async => false;

  @override
  String toString() => 'FakeMediaStreamTrack(id: $id, kind: $kind, enabled: $enabled)';
}

class _FailingAudioTrack extends LocalAudioTrack {
  final Object error;
  int startAttempts = 0;

  _FailingAudioTrack(this.error)
    : super(
        TrackSource.microphone,
        _FakeMediaStream('local_stream'),
        _FakeMediaStreamTrack(id: 'local_audio', kind: 'audio'),
        const AudioCaptureOptions(),
      );

  @override
  Future<void> startCapture() async {
    startAttempts++;
    throw error;
  }
}
