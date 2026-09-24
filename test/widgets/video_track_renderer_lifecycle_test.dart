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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:mockito/mockito.dart';

import 'package:livekit_client/src/events.dart';
import 'package:livekit_client/src/internal/events.dart';
import 'package:livekit_client/src/managers/event.dart';
import 'package:livekit_client/src/track/remote/video.dart';
import 'package:livekit_client/src/types/other.dart';
import 'package:livekit_client/src/widgets/video_track_renderer.dart';

class _Stream extends Mock implements rtc.MediaStream {}

class _MediaTrack extends Mock implements rtc.MediaStreamTrack {}

class _Renderer extends rtc.RTCVideoRenderer {
  final initialized = Completer<void>();
  rtc.MediaStream? _stream;
  int initializationCount = 0;
  int disposeCount = 0;

  @override
  Future<void> initialize() {
    initializationCount++;
    return initialized.future;
  }

  @override
  rtc.MediaStream? get srcObject => _stream;

  @override
  set srcObject(rtc.MediaStream? value) => _stream = value;

  @override
  Future<void> dispose() async {
    disposeCount++;
    await super.dispose();
  }
}

class _Listener extends EventsListener<TrackEvent> {
  _Listener(super.emitter);
  Completer<void>? beforeDispose;
  int disposeCount = 0;

  @override
  Future<bool> dispose() async {
    disposeCount++;
    if (beforeDispose != null) await beforeDispose!.future;
    return super.dispose();
  }
}

class _Track extends RemoteVideoTrack {
  _Track(this.stream) : super(TrackSource.camera, stream, _MediaTrack());
  final rtc.MediaStream stream;
  final created = <_Listener>[];

  @override
  EventsListener<TrackEvent> createListener({bool synchronized = false}) {
    final listener = _Listener(events);
    created.add(listener);
    return listener;
  }

  void updateStream(rtc.MediaStream stream) => events.emit(TrackStreamUpdatedEvent(track: this, stream: stream));
}

void main() {
  late _Renderer renderer;
  setUp(() {
    renderer = _Renderer();
    videoTrackRendererFactory = () => renderer;
  });
  tearDown(() => videoTrackRendererFactory = rtc.RTCVideoRenderer.new);

  Widget view(_Track track, {rtc.RTCVideoRenderer? cached, bool autoDispose = true}) => MaterialApp(
    home: SizedBox(
      width: 100,
      height: 100,
      child: VideoTrackRenderer(
        track,
        key: const ValueKey('video'),
        cachedRenderer: cached,
        autoDisposeRenderer: autoDispose,
      ),
    ),
  );

  testWidgets('dispose during initialize never attaches and disposes the owned renderer once', (tester) async {
    final track = _Track(_Stream());
    await tester.pumpWidget(view(track));
    expect(renderer.initializationCount, 1);
    await tester.pumpWidget(const SizedBox());
    renderer.initialized.complete();
    await tester.runAsync(() async => await Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(renderer.srcObject, isNull);
    expect(track.created, isEmpty);
    expect(renderer.disposeCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('track replacement during initialization attaches only the latest stream', (tester) async {
    final a = _Track(_Stream());
    final b = _Track(_Stream());
    await tester.pumpWidget(view(a));
    await tester.pumpWidget(view(b));
    renderer.initialized.complete();
    await tester.runAsync(() async => await Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(renderer.initializationCount, 1);
    expect(a.created, isEmpty);
    expect(b.created.length, 1);
    expect(renderer.srcObject, same(b.stream));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('rapid replacement leaves only the latest listener and stream', (tester) async {
    final a = _Track(_Stream());
    final b = _Track(_Stream());
    final c = _Track(_Stream());
    renderer.initialized.complete();
    await tester.pumpWidget(view(a));
    await tester.runAsync(() async => await Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(renderer.srcObject, same(a.stream));
    final gate = a.created.single.beforeDispose = Completer<void>();
    await tester.pumpWidget(view(b));
    await tester.pumpWidget(view(c));
    gate.complete();
    await tester.runAsync(() async => await Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(renderer.initializationCount, 1);
    expect(renderer.srcObject, same(c.stream));
    expect(a.created.single.disposeCount, 1);
    expect(b.created, isEmpty);
    expect(c.created.single.isDisposed, isFalse);
    a.updateStream(_Stream());
    await tester.runAsync(() async => await Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(renderer.srcObject, same(c.stream));
    final updated = _Stream();
    c.updateStream(updated);
    await tester.runAsync(() async => await Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(renderer.srcObject, same(updated));
    await tester.pumpWidget(const SizedBox());
    expect(c.created.single.disposeCount, 1);
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('disposing while replacing listener cannot install a new one', (tester) async {
    final a = _Track(_Stream());
    final b = _Track(_Stream());
    renderer.initialized.complete();
    await tester.pumpWidget(view(a));
    await tester.runAsync(() async => await Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    final gate = a.created.single.beforeDispose = Completer<void>();
    await tester.pumpWidget(view(b));
    await tester.pumpWidget(const SizedBox());
    gate.complete();
    await tester.runAsync(() async => await Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(b.created, isEmpty);
    expect(renderer.srcObject, isNull);
    expect(renderer.disposeCount, 1);
    expect(a.created.single.disposeCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cached renderer is borrowed, even when replaced or autoDispose is true', (tester) async {
    final a = _Track(_Stream());
    final b = _Track(_Stream());
    final cached = _Renderer()..initialized.complete();
    final replacement = _Renderer()..initialized.complete();
    await tester.pumpWidget(view(a, cached: cached));
    await tester.runAsync(() async => await Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    await tester.pumpWidget(view(b, cached: cached));
    await tester.runAsync(() async => await Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(cached.srcObject, same(b.stream));
    await tester.pumpWidget(view(b, cached: replacement));
    await tester.runAsync(() async => await Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(cached.disposeCount, 0);
    expect(cached.srcObject, isNull);
    expect(replacement.srcObject, same(b.stream));
    await tester.pumpWidget(const SizedBox());
    expect(replacement.disposeCount, 0);
    expect(replacement.srcObject, isNull);
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('rebuild and autoDispose false do not initialize or dispose twice', (tester) async {
    final track = _Track(_Stream());
    renderer.initialized.complete();
    await tester.pumpWidget(view(track, autoDispose: false));
    await tester.runAsync(() async => await Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    await tester.pumpWidget(view(track, autoDispose: false));
    await tester.runAsync(() async => await Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(renderer.initializationCount, 1);
    expect(track.created.length, 1);
    await tester.pumpWidget(const SizedBox());
    expect(renderer.disposeCount, 0);
    expect(renderer.srcObject, isNull);
    await tester.pump(const Duration(milliseconds: 100));
  });
}
