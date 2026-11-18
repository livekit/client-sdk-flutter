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

@TestOn('browser')
library;

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:mockito/mockito.dart';
import 'package:web/web.dart' as web;

import 'package:livekit_client/src/track/remote/video.dart';
import 'package:livekit_client/src/types/other.dart';
import 'package:livekit_client/src/widgets/video_track_renderer.dart';

class _Stream extends Mock implements rtc.MediaStream {}

class _MediaTrack extends Mock implements rtc.MediaStreamTrack {}

class _Renderer extends rtc.RTCVideoRenderer {
  final video = web.HTMLVideoElement();
  rtc.MediaStream? _stream;

  // The analyzer resolves the native renderer; the browser renderer defines this method.
  web.HTMLVideoElement? findHtmlView() => video;

  @override
  bool get renderVideo => _stream != null;

  @override
  rtc.MediaStream? get srcObject => _stream;

  @override
  set srcObject(rtc.MediaStream? value) => _stream = value;
}

RemoteVideoTrack _track() => RemoteVideoTrack(TrackSource.camera, _Stream(), _MediaTrack());

Widget _view(RemoteVideoTrack track, _Renderer renderer) => WidgetsApp(
  color: Color(0xff000000),
  builder: (context, child) => SizedBox(
    width: 100,
    height: 100,
    child: VideoTrackRenderer(track, cachedRenderer: renderer),
  ),
);

void main() {
  testWidgets(
    'muting hides a retained Flutter video frame without unmounting it',
    (tester) async {
      final renderer = _Renderer();
      await renderer.initialize();
      final track = _track();
      final boundaryKey = GlobalKey();

      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xff000000),
          builder: (context, child) => RepaintBoundary(
            key: boundaryKey,
            child: ColoredBox(
              color: const Color(0xffffffff),
              child: VideoTrackRenderer(track, cachedRenderer: renderer, fit: VideoViewFit.cover),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Seed the default flutter_webrtc backend's retained frame, as if a video
      // frame had already been captured before the track was muted.
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(const Color(0xffff0000), BlendMode.src);
      final picture = recorder.endRecording();
      final frame = await tester.runAsync(() => picture.toImage(100, 100));
      picture.dispose();
      final videoState = tester.state(find.byType(rtc.RTCVideoView)) as dynamic;
      videoState.capturedFrame = frame;
      renderer.notifyListeners();
      await tester.pump();

      Future<List<int>> pixel() async {
        final boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return bytes!.buffer.asUint8List().sublist(0, 4);
      }

      expect(await tester.runAsync(pixel), [255, 0, 0, 255]);
      track.updateMuted(true);
      await tester.pumpAndSettle();
      expect(await tester.runAsync(pixel), [255, 255, 255, 255]);
      expect(tester.state(find.byType(rtc.RTCVideoView)), same(videoState));
      expect(renderer.srcObject, same(track.mediaStream));

      track.updateMuted(false);
      await tester.pumpAndSettle();
      expect(await tester.runAsync(pixel), [255, 0, 0, 255]);
      expect(tester.state(find.byType(rtc.RTCVideoView)), same(videoState));
      expect(renderer.srcObject, same(track.mediaStream));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
      await renderer.dispose();
    },
    // The HTML-element backend does not paint retained frames into Flutter.
    skip: const bool.fromEnvironment('WEBRTC_USE_HTML_ELEMENT_VIEW'),
  );

  testWidgets('initially muted track stays attached but hidden until unmuted', (tester) async {
    final renderer = _Renderer();
    await renderer.initialize();
    final track = _track()..updateMuted(true);

    await tester.pumpWidget(_view(track, renderer));
    await tester.pumpAndSettle();
    expect(renderer.srcObject, same(track.mediaStream));
    expect(renderer.video.style.visibility, 'hidden');

    track.updateMuted(false);
    await tester.pumpAndSettle();
    expect(renderer.video.style.visibility, 'visible');
    expect(renderer.srcObject, same(track.mediaStream));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
    await renderer.dispose();
  });

  testWidgets('borrowed renderer visibility is restored on replacement and disposal', (tester) async {
    final first = _Renderer();
    final second = _Renderer();
    await first.initialize();
    await second.initialize();
    first.video.style.visibility = 'collapse';
    second.video.style.visibility = '';
    final track = _track()..updateMuted(true);

    await tester.pumpWidget(_view(track, first));
    await tester.pumpAndSettle();
    expect(first.video.style.visibility, 'hidden');

    await tester.pumpWidget(_view(track, second));
    await tester.pumpAndSettle();
    expect(first.video.style.visibility, 'collapse');
    expect(first.srcObject, isNull);
    expect(second.video.style.visibility, 'hidden');

    await tester.pumpWidget(const SizedBox());
    expect(second.video.style.visibility, '');
    expect(second.srcObject, isNull);
    await tester.pump(const Duration(milliseconds: 100));
    await first.dispose();
    await second.dispose();
  });
}
