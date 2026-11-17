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
    await first.dispose();
    await second.dispose();
  });
}
