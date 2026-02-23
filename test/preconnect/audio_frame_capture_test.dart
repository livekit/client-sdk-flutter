import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/src/preconnect/audio_frame_capture.dart';
import 'package:livekit_client/src/support/audio_pcm_utils.dart';
import 'package:livekit_client/src/support/byte_ring_buffer.dart';

/// A mock AudioFrameCapture that emits frames from a StreamController.
class MockAudioFrameCapture implements AudioFrameCapture {
  final _controller = StreamController<AudioFrame>.broadcast();
  bool started = false;
  bool stopped = false;

  @override
  Stream<AudioFrame> get frameStream => _controller.stream;

  @override
  Future<bool> start({
    required dynamic track,
    required String rendererId,
    required int sampleRate,
    required int channels,
    required String commonFormat,
  }) async {
    started = true;
    return true;
  }

  @override
  Future<void> stop() async {
    stopped = true;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  /// Emit a frame for testing.
  void emitFrame(AudioFrame frame) => _controller.add(frame);
}

/// Helper: build int16 PCM bytes from a list of sample values.
Uint8List int16Bytes(List<int> samples) {
  final data = ByteData(samples.length * 2);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(i * 2, samples[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

/// Helper: build float32 bytes from a list of sample values.
Uint8List float32Bytes(List<double> samples) {
  final data = ByteData(samples.length * 4);
  for (var i = 0; i < samples.length; i++) {
    data.setFloat32(i * 4, samples[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

/// Helper: read int16 sample at index from bytes (little-endian).
int readInt16(Uint8List bytes, int index) {
  return ByteData.sublistView(bytes).getInt16(index * 2, Endian.little);
}

/// Helper: read float32 sample at index from bytes (little-endian).
double readFloat32(Uint8List bytes, int index) {
  return ByteData.sublistView(bytes).getFloat32(index * 4, Endian.little);
}

void main() {
  group('AudioFrame', () {
    test('stores sample rate, channels, data, and format', () {
      final frame = AudioFrame(
        sampleRate: 48000,
        channels: 1,
        data: int16Bytes([100, -200, 300]),
        commonFormat: 'int16',
      );

      expect(frame.sampleRate, 48000);
      expect(frame.channels, 1);
      expect(frame.commonFormat, 'int16');
      expect(frame.data.length, 6); // 3 samples * 2 bytes
    });
  });

  group('MockAudioFrameCapture', () {
    test('start returns true and sets started flag', () async {
      final capture = MockAudioFrameCapture();
      final result = await capture.start(
        track: null,
        rendererId: 'test-id',
        sampleRate: 24000,
        channels: 1,
        commonFormat: 'int16',
      );

      expect(result, true);
      expect(capture.started, true);
    });

    test('emitted frames arrive on frameStream', () async {
      final capture = MockAudioFrameCapture();
      await capture.start(
        track: null,
        rendererId: 'test-id',
        sampleRate: 24000,
        channels: 1,
        commonFormat: 'int16',
      );

      final frames = <AudioFrame>[];
      final sub = capture.frameStream.listen(frames.add);

      capture.emitFrame(AudioFrame(
        sampleRate: 24000,
        channels: 1,
        data: int16Bytes([1000, -1000]),
        commonFormat: 'int16',
      ));

      capture.emitFrame(AudioFrame(
        sampleRate: 24000,
        channels: 1,
        data: int16Bytes([2000, -2000]),
        commonFormat: 'int16',
      ));

      // Let microtasks run.
      await Future<void>.delayed(Duration.zero);

      expect(frames.length, 2);
      expect(frames[0].data.length, 4);
      expect(frames[1].data.length, 4);

      await sub.cancel();
      await capture.stop();
    });

    test('stop sets stopped flag', () async {
      final capture = MockAudioFrameCapture();
      await capture.start(
        track: null,
        rendererId: 'test-id',
        sampleRate: 24000,
        channels: 1,
        commonFormat: 'int16',
      );
      await capture.stop();

      expect(capture.stopped, true);
    });
  });

  group('float32ToInt16Bytes', () {
    test('converts silence to zeros', () {
      final src = Float32List.fromList([0.0, 0.0, 0.0, 0.0]);
      final bytes = float32ToInt16Bytes(src, 1, 1, 4);

      expect(bytes.length, 8); // 4 frames * 1 ch * 2 bytes
      for (var i = 0; i < 4; i++) {
        expect(readInt16(bytes, i), 0);
      }
    });

    test('converts full-scale float to int16 range', () {
      final src = Float32List.fromList([1.0, -1.0]);
      final bytes = float32ToInt16Bytes(src, 1, 1, 2);

      expect(readInt16(bytes, 0), 32767);
      expect(readInt16(bytes, 1), -32767);
    });

    test('clamps values outside [-1.0, 1.0]', () {
      final src = Float32List.fromList([2.5, -3.0]);
      final bytes = float32ToInt16Bytes(src, 1, 1, 2);

      expect(readInt16(bytes, 0), 32767);
      expect(readInt16(bytes, 1), -32767);
    });

    test('converts mid-range values correctly', () {
      final src = Float32List.fromList([0.5, -0.5]);
      final bytes = float32ToInt16Bytes(src, 1, 1, 2);

      // 0.5 * 32767 = 16383.5 → rounds to 16384
      expect(readInt16(bytes, 0), 16384);
      // -0.5 * 32767 = -16383.5 → rounds to -16384
      expect(readInt16(bytes, 1), -16384);
    });

    test('stereo to mono downmix keeps first channel', () {
      // Interleaved stereo: [L0, R0, L1, R1]
      final src = Float32List.fromList([0.5, -0.5, 0.25, -0.25]);
      final bytes = float32ToInt16Bytes(src, 2, 1, 2);

      expect(bytes.length, 4); // 2 frames * 1 ch * 2 bytes
      // Should contain L0 and L1 only.
      expect(readInt16(bytes, 0), (0.5 * 32767).round());
      expect(readInt16(bytes, 1), (0.25 * 32767).round());
    });

    test('stereo pass-through preserves both channels', () {
      final src = Float32List.fromList([0.5, -0.5, 0.25, -0.25]);
      final bytes = float32ToInt16Bytes(src, 2, 2, 2);

      expect(bytes.length, 8); // 2 frames * 2 ch * 2 bytes
      expect(readInt16(bytes, 0), (0.5 * 32767).round());
      expect(readInt16(bytes, 1), (-0.5 * 32767).round());
      expect(readInt16(bytes, 2), (0.25 * 32767).round());
      expect(readInt16(bytes, 3), (-0.25 * 32767).round());
    });
  });

  group('float32ToFloat32Bytes', () {
    test('same channel count returns buffer directly (zero-copy)', () {
      final src = Float32List.fromList([0.1, 0.2, 0.3, 0.4]);
      final bytes = float32ToFloat32Bytes(src, 1, 1, 4);

      expect(bytes.length, 16); // 4 frames * 1 ch * 4 bytes
      for (var i = 0; i < 4; i++) {
        expect(readFloat32(bytes, i), closeTo(src[i], 1e-6));
      }
    });

    test('stereo to mono keeps first channel', () {
      final src = Float32List.fromList([0.1, 0.9, 0.2, 0.8]);
      final bytes = float32ToFloat32Bytes(src, 2, 1, 2);

      expect(bytes.length, 8); // 2 frames * 1 ch * 4 bytes
      expect(readFloat32(bytes, 0), closeTo(0.1, 1e-6));
      expect(readFloat32(bytes, 1), closeTo(0.2, 1e-6));
    });

    test('preserves negative values', () {
      final src = Float32List.fromList([-1.0, 0.0, 1.0]);
      final bytes = float32ToFloat32Bytes(src, 1, 1, 3);

      expect(readFloat32(bytes, 0), closeTo(-1.0, 1e-6));
      expect(readFloat32(bytes, 1), closeTo(0.0, 1e-6));
      expect(readFloat32(bytes, 2), closeTo(1.0, 1e-6));
    });
  });

  group('Buffer flow end-to-end', () {
    test('frames flow into ByteRingBuffer correctly', () async {
      final capture = MockAudioFrameCapture();
      final buffer = ByteRingBuffer(4096);

      await capture.start(
        track: null,
        rendererId: 'test-id',
        sampleRate: 24000,
        channels: 1,
        commonFormat: 'int16',
      );

      int? capturedSampleRate;
      int? capturedChannels;

      final sub = capture.frameStream.listen((frame) {
        capturedSampleRate = frame.sampleRate;
        capturedChannels = frame.channels;
        buffer.write(frame.data);
      });

      // Simulate 3 frames of 480 samples each (10ms at 48kHz mono int16).
      for (var i = 0; i < 3; i++) {
        final samples = List<int>.generate(480, (j) => (j * 10) - 2400);
        capture.emitFrame(AudioFrame(
          sampleRate: 48000,
          channels: 1,
          data: int16Bytes(samples),
          commonFormat: 'int16',
        ));
      }

      await Future<void>.delayed(Duration.zero);

      expect(capturedSampleRate, 48000);
      expect(capturedChannels, 1);
      // 3 frames * 480 samples * 2 bytes = 2880
      expect(buffer.length, 2880);

      final bytes = buffer.takeBytes();
      expect(bytes.length, 2880);
      // Buffer should be empty after takeBytes.
      expect(buffer.length, 0);

      await sub.cancel();
      await capture.stop();
    });

    test('buffer overflow drops oldest data', () async {
      final capture = MockAudioFrameCapture();
      // Small buffer: 100 bytes.
      final buffer = ByteRingBuffer(100);

      await capture.start(
        track: null,
        rendererId: 'test-id',
        sampleRate: 24000,
        channels: 1,
        commonFormat: 'int16',
      );

      bool overflowed = false;
      final sub = capture.frameStream.listen((frame) {
        if (buffer.write(frame.data)) {
          overflowed = true;
        }
      });

      // Write 60 bytes, then 60 more → should overflow at 100.
      capture.emitFrame(AudioFrame(
        sampleRate: 24000,
        channels: 1,
        data: Uint8List(60),
        commonFormat: 'int16',
      ));
      capture.emitFrame(AudioFrame(
        sampleRate: 24000,
        channels: 1,
        data: Uint8List(60),
        commonFormat: 'int16',
      ));

      await Future<void>.delayed(Duration.zero);

      expect(overflowed, true);
      expect(buffer.length, 100);

      await sub.cancel();
      await capture.stop();
    });

    test('float32 frames through conversion then buffer', () async {
      final capture = MockAudioFrameCapture();
      final buffer = ByteRingBuffer(4096);

      await capture.start(
        track: null,
        rendererId: 'test-id',
        sampleRate: 48000,
        channels: 1,
        commonFormat: 'int16',
      );

      // Simulate what the web implementation does: receive float32 from
      // worklet, convert to int16 bytes, then buffer.
      final sub = capture.frameStream.listen((frame) {
        final srcFloat32 = frame.data.buffer.asFloat32List();
        final int16Bytes = float32ToInt16Bytes(srcFloat32, 1, 1, srcFloat32.length);
        buffer.write(int16Bytes);
      });

      // Emit raw float32 data (as if from the worklet).
      final samples = Float32List.fromList(List<double>.generate(128, (i) => i / 128.0));
      capture.emitFrame(AudioFrame(
        sampleRate: 48000,
        channels: 1,
        data: samples.buffer.asUint8List(),
        commonFormat: 'float32',
      ));

      await Future<void>.delayed(Duration.zero);

      // 128 samples * 2 bytes (int16) = 256
      expect(buffer.length, 256);

      // Verify first and last converted values.
      final result = buffer.takeBytes();
      final view = ByteData.sublistView(result);

      // Sample 0: 0.0 → int16 = 0
      expect(view.getInt16(0, Endian.little), 0);
      // Sample 127: 127/128 ≈ 0.9921875 → int16 ≈ 32511
      final last = view.getInt16(127 * 2, Endian.little);
      expect(last, closeTo((127 / 128.0 * 32767).round(), 1));

      await sub.cancel();
      await capture.stop();
    });

    test('stereo to mono conversion in buffer pipeline', () async {
      final capture = MockAudioFrameCapture();
      final buffer = ByteRingBuffer(4096);

      await capture.start(
        track: null,
        rendererId: 'test-id',
        sampleRate: 48000,
        channels: 1,
        commonFormat: 'int16',
      );

      final sub = capture.frameStream.listen((frame) {
        final srcFloat32 = frame.data.buffer.asFloat32List();
        // 2 src channels → 1 out channel (mono downmix)
        final int16Data = float32ToInt16Bytes(srcFloat32, 2, 1, srcFloat32.length ~/ 2);
        buffer.write(int16Data);
      });

      // Interleaved stereo: [L0=0.5, R0=-0.5, L1=0.25, R1=-0.25]
      final stereo = Float32List.fromList([0.5, -0.5, 0.25, -0.25]);
      capture.emitFrame(AudioFrame(
        sampleRate: 48000,
        channels: 2,
        data: stereo.buffer.asUint8List(),
        commonFormat: 'float32',
      ));

      await Future<void>.delayed(Duration.zero);

      // 2 frames * 1 channel * 2 bytes = 4
      expect(buffer.length, 4);

      final result = buffer.takeBytes();
      final view = ByteData.sublistView(result);
      // Only left channel: 0.5 → 16384, 0.25 → 8192
      expect(view.getInt16(0, Endian.little), (0.5 * 32767).round());
      expect(view.getInt16(2, Endian.little), (0.25 * 32767).round());

      await sub.cancel();
      await capture.stop();
    });
  });
}
