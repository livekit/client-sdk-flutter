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

import 'package:livekit_client/src/publication/track_settings.dart';
import 'package:livekit_client/src/types/other.dart';
import 'package:livekit_client/src/types/video_dimensions.dart';

/// Test helper: returns layer dimensions for a standard 3-layer SVC/simulcast track.
VideoDimensions? _testLayerDimensions(VideoQuality quality) {
  return {
    VideoQuality.LOW: VideoDimensions(320, 180),
    VideoQuality.MEDIUM: VideoDimensions(640, 360),
    VideoQuality.HIGH: VideoDimensions(1280, 720),
  }[quality];
}

void main() {
  group('resolveVideoSettings', () {
    group('no adaptive stream', () {
      test('defaults to HIGH quality when nothing set', () {
        final r = resolveVideoSettings();
        expect(r.quality, VideoQuality.HIGH);
        expect(r.dimensions, isNull);
      });

      test('uses preferred quality', () {
        final r = resolveVideoSettings(
          userPreference: VideoSettings.quality(VideoQuality.LOW),
        );
        expect(r.quality, VideoQuality.LOW);
        expect(r.dimensions, isNull);
      });

      test('uses preferred dimensions', () {
        final r = resolveVideoSettings(
          userPreference: VideoSettings.dimensions(VideoDimensions(800, 600)),
        );
        expect(r.dimensions, VideoDimensions(800, 600));
        expect(r.quality, isNull);
      });
    });

    group('adaptive stream only', () {
      test('uses adaptive stream dimensions', () {
        final r = resolveVideoSettings(
          adaptiveStreamDimensions: VideoDimensions(480, 270),
        );
        expect(r.dimensions, VideoDimensions(480, 270));
        expect(r.quality, isNull);
      });
    });

    group('adaptive stream + preferred dimensions', () {
      test('adaptive wins when smaller', () {
        final r = resolveVideoSettings(
          adaptiveStreamDimensions: VideoDimensions(320, 180),
          userPreference: VideoSettings.dimensions(VideoDimensions(1280, 720)),
        );
        expect(r.dimensions, VideoDimensions(320, 180));
      });

      test('preferred wins when smaller', () {
        final r = resolveVideoSettings(
          adaptiveStreamDimensions: VideoDimensions(1920, 1080),
          userPreference: VideoSettings.dimensions(VideoDimensions(640, 360)),
        );
        expect(r.dimensions, VideoDimensions(640, 360));
      });

      test('equal areas keep preferred', () {
        final r = resolveVideoSettings(
          adaptiveStreamDimensions: VideoDimensions(640, 360),
          userPreference: VideoSettings.dimensions(VideoDimensions(640, 360)),
        );
        expect(r.dimensions, VideoDimensions(640, 360));
      });
    });

    group('adaptive stream + preferred quality', () {
      test('adaptive wins when smaller than quality layer', () {
        final r = resolveVideoSettings(
          adaptiveStreamDimensions: VideoDimensions(320, 180),
          userPreference: VideoSettings.quality(VideoQuality.HIGH),
          layerDimensionsForQuality: _testLayerDimensions,
        );
        // adaptive 320*180 < HIGH 1280*720 → sends adaptive dimensions
        expect(r.dimensions, VideoDimensions(320, 180));
        expect(r.quality, isNull);
      });

      test('quality wins when adaptive is larger than quality layer', () {
        final r = resolveVideoSettings(
          adaptiveStreamDimensions: VideoDimensions(1920, 1080),
          userPreference: VideoSettings.quality(VideoQuality.LOW),
          layerDimensionsForQuality: _testLayerDimensions,
        );
        // adaptive 1920*1080 > LOW 320*180 → sends quality directly
        expect(r.quality, VideoQuality.LOW);
        expect(r.dimensions, isNull);
      });

      test('quality sent directly when no layer info available', () {
        final r = resolveVideoSettings(
          adaptiveStreamDimensions: VideoDimensions(320, 180),
          userPreference: VideoSettings.quality(VideoQuality.LOW),
        );
        expect(r.quality, VideoQuality.LOW);
        expect(r.dimensions, isNull);
      });

      test('quality sent when layer lookup returns null', () {
        final r = resolveVideoSettings(
          adaptiveStreamDimensions: VideoDimensions(320, 180),
          userPreference: VideoSettings.quality(VideoQuality.MEDIUM),
          layerDimensionsForQuality: (_) => null,
        );
        expect(r.quality, VideoQuality.MEDIUM);
        expect(r.dimensions, isNull);
      });
    });
  });
}
