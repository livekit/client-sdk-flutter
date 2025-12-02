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

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/src/core/pending_track_queue.dart';
import 'package:livekit_client/src/events.dart';
import 'package:livekit_client/src/types/other.dart';

void main() {
  group('PendingTrackQueue', () {
    late PendingTrackQueue queue;
    late List<TrackSubscriptionExceptionEvent> emitted;

    setUp(() {
      emitted = [];
      queue = PendingTrackQueue(
        metadataTimeout: const Duration(seconds: 5),
        emitException: emitted.add,
        maxSize: 4,
      );
    });

    test('removeParticipant purges pending entries and emits exceptions', () {
      queue.enqueue(
        track: _FakeMediaStreamTrack(id: 't1', kind: 'audio'),
        stream: _FakeMediaStream('s1'),
        receiver: null,
        participantSid: 'remote_participant',
        trackSid: 'sid_t1',
        connectionState: ConnectionState.connected,
      );

      expect(queue.stats.totalEntries, 1);

      queue.removeParticipant('remote_participant', reason: 'test cleanup');

      expect(queue.stats.totalEntries, 0);
      expect(emitted, hasLength(1));
      expect(emitted.single.sid, 'sid_t1');
    });

    test('per-participant capacity prevents starvation', () {
      queue.enqueue(
        track: _FakeMediaStreamTrack(id: 't1', kind: 'audio'),
        stream: _FakeMediaStream('s1'),
        receiver: null,
        participantSid: 'remote_a',
        trackSid: 'sid_t1',
        connectionState: ConnectionState.connected,
      );

      // Second track for the same participant should be dropped because per-participant limit is 1.
      queue.enqueue(
        track: _FakeMediaStreamTrack(id: 't2', kind: 'audio'),
        stream: _FakeMediaStream('s2'),
        receiver: null,
        participantSid: 'remote_a',
        trackSid: 'sid_t2',
        connectionState: ConnectionState.connected,
      );

      // Another participant can still enqueue successfully.
      queue.enqueue(
        track: _FakeMediaStreamTrack(id: 't3', kind: 'audio'),
        stream: _FakeMediaStream('s3'),
        receiver: null,
        participantSid: 'remote_b',
        trackSid: 'sid_t3',
        connectionState: ConnectionState.connected,
      );

      expect(queue.stats.totalEntries, 2);
      expect(queue.stats.entriesPerParticipant['remote_a'], 1);
      expect(queue.stats.entriesPerParticipant['remote_b'], 1);
      expect(emitted.length, 1, reason: 'Exceeded entries should emit failure events.');
    });

    test('refreshParticipant extends expiration', () {
      queue.enqueue(
        track: _FakeMediaStreamTrack(id: 't1', kind: 'audio'),
        stream: _FakeMediaStream('s1'),
        receiver: null,
        participantSid: 'remote_participant',
        trackSid: 'sid_t1',
        connectionState: ConnectionState.connected,
      );

      final pending = queue.debugPendingFor('remote_participant').single;
      pending.expiresAt = DateTime.now().subtract(const Duration(seconds: 1));

      queue.refreshParticipant('remote_participant', reason: 'metadata update');

      expect(pending.expiresAt.isAfter(DateTime.now()), isTrue);
    });

    test('flush reports transient failures and keeps entries for retry', () async {
      queue.enqueue(
        track: _FakeMediaStreamTrack(id: 't1', kind: 'audio'),
        stream: _FakeMediaStream('s1'),
        receiver: null,
        participantSid: 'remote_participant',
        trackSid: 'sid_t1',
        connectionState: ConnectionState.connected,
      );

      final firstResult = await queue.flush(
        isConnected: true,
        subscriber: (_) async => false,
      );

      expect(firstResult.transientFailures, 1);
      expect(firstResult.hasPending, isTrue);
      expect(queue.debugPendingFor('remote_participant').single.retryCount, 1);

      final secondResult = await queue.flush(
        isConnected: true,
        subscriber: (_) async => true,
      );

      expect(secondResult.succeeded, 1);
      expect(queue.stats.totalEntries, 0);
    });

    test('flush skips work when disconnected but preserves queue', () async {
      queue.enqueue(
        track: _FakeMediaStreamTrack(id: 't1', kind: 'audio'),
        stream: _FakeMediaStream('s1'),
        receiver: null,
        participantSid: 'remote_participant',
        trackSid: 'sid_t1',
        connectionState: ConnectionState.connected,
      );

      final result = await queue.flush(
        isConnected: false,
        subscriber: (_) async => true,
      );

      expect(result.skippedForDisconnect, isTrue);
      expect(queue.stats.totalEntries, 1);
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
  Future<rtc.MediaStreamTrack> clone() async => _FakeMediaStreamTrack(id: '$id-clone', kind: kind, enabled: enabled);

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
}
