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

/// Connection Latency Measurement Test
///
/// IMPORTANT: This test requires native WebRTC plugins and CANNOT run with
/// `flutter test` (which runs in a pure Dart VM without native plugins).
///
/// To run these tests, use one of these methods:
///
/// 1. On a REAL DEVICE or EMULATOR using integration_test:
///    flutter test integration_test/connection_latency_test.dart
///
/// 2. On DESKTOP (macOS/Linux/Windows):
///    flutter run -d macos -t test/integration/connection_latency_test.dart
///
/// 3. Use the EXAMPLE APP version (recommended for devices):
///    Edit example/lib/latency_test.dart with your credentials, then:
///    cd example && flutter run -t lib/latency_test.dart
///
/// Environment variables:
/// - LIVEKIT_URL: The LiveKit server URL
/// - LIVEKIT_CALLER_TOKEN: A valid token for authentication
/// - LIVEKIT_TEST_ITERATIONS: (optional) Number of test iterations (default: 5)

@Timeout(Duration(minutes: 5))
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart';

/// Statistics calculator for latency measurements
class LatencyStats {
  final List<double> _measurements = [];

  void addMeasurement(double latencyMs) {
    _measurements.add(latencyMs);
  }

  int get count => _measurements.length;

  double get min => _measurements.isEmpty ? 0 : _measurements.reduce(math.min);

  double get max => _measurements.isEmpty ? 0 : _measurements.reduce(math.max);

  double get mean {
    if (_measurements.isEmpty) return 0;
    return _measurements.reduce((a, b) => a + b) / _measurements.length;
  }

  double get p50 {
    if (_measurements.isEmpty) return 0;
    final sorted = List<double>.from(_measurements)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[middle];
    }
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  double get p95 {
    if (_measurements.isEmpty) return 0;
    final sorted = List<double>.from(_measurements)..sort();
    final index = ((sorted.length - 1) * 0.95).floor();
    return sorted[index];
  }

  double get p99 {
    if (_measurements.isEmpty) return 0;
    final sorted = List<double>.from(_measurements)..sort();
    final index = ((sorted.length - 1) * 0.99).floor();
    return sorted[index];
  }

  void printStats(String title) {
    print('\n$title');
    print('Samples:      $count');
    print('Min:          ${min.toStringAsFixed(2)} ms');
    print('Avg:          ${mean.toStringAsFixed(2)} ms');
    print('P50:          ${p50.toStringAsFixed(2)} ms');
    print('P95:          ${p95.toStringAsFixed(2)} ms');
    print('P99:          ${p99.toStringAsFixed(2)} ms');
    print('Max:          ${max.toStringAsFixed(2)} ms');
  }

  void clear() {
    _measurements.clear();
  }
}

/// Test configuration loaded from environment variables
class TestConfig {
  final String url;
  final String token;
  final int iterations;

  TestConfig({
    required this.url,
    required this.token,
    required this.iterations,
  });

  static TestConfig? fromEnvironment() {
    final url = Platform.environment['LIVEKIT_URL'];
    final token = Platform.environment['LIVEKIT_CALLER_TOKEN'];
    final iterationsStr = Platform.environment['LIVEKIT_TEST_ITERATIONS'];

    if (url == null || url.isEmpty) {
      return null;
    }
    if (token == null || token.isEmpty) {
      return null;
    }

    final iterations = int.tryParse(iterationsStr ?? '5') ?? 5;

    return TestConfig(
      url: url,
      token: token,
      iterations: iterations,
    );
  }

  bool get isConfigured => url.isNotEmpty && token.isNotEmpty;
}

void main() {
  // Initialize Flutter binding for platform channels
  TestWidgetsFlutterBinding.ensureInitialized();

  final config = TestConfig.fromEnvironment();

  /// Skip helper for tests when environment is not configured
  void skipIfNotConfigured() {
    if (config == null) {
      print('\n*** SKIPPING TEST ***');
      print('Environment variables not configured.');
      print('Required: LIVEKIT_URL, LIVEKIT_CALLER_TOKEN');
      print('Optional: LIVEKIT_TEST_ITERATIONS (default: 5)');
      print('');
      print('Example:');
      print('  LIVEKIT_URL=wss://your-server.livekit.cloud \\');
      print('  LIVEKIT_CALLER_TOKEN=your_token \\');
      print('  dart test test/integration/connection_latency_test.dart');
      print('');
    }
  }

  group('Connection Latency Measurement Tests', () {
    test('Connection Time Measurement', () async {
      skipIfNotConfigured();
      if (config == null) {
        return;
      }

      print('\n=== Connection Time Measurement Test ===');
      print('URL: ${config.url}');
      print('Iterations: ${config.iterations}');

      final stats = LatencyStats();
      const roomOptions = RoomOptions(
        adaptiveStream: false,
        dynacast: false,
      );
      const connectOptions = ConnectOptions(
        autoSubscribe: true,
      );

      for (int i = 0; i < config.iterations; i++) {
        final room = Room();

        try {
          final stopwatch = Stopwatch()..start();

          await room.connect(
            config.url,
            config.token,
            roomOptions: roomOptions,
            connectOptions: connectOptions,
          );

          stopwatch.stop();

          if (room.connectionState == ConnectionState.connected) {
            final latencyMs = stopwatch.elapsedMicroseconds / 1000.0;
            stats.addMeasurement(latencyMs);
            print('  Iteration ${i + 1}: ${latencyMs.toStringAsFixed(2)} ms');
          } else {
            print('  Iteration ${i + 1}: FAILED - unexpected state: ${room.connectionState}');
          }
        } catch (e) {
          print('  Iteration ${i + 1}: FAILED to connect - $e');
        } finally {
          await room.disconnect();
          await room.dispose();
        }

        // Small delay between iterations to allow cleanup
        await Future.delayed(const Duration(milliseconds: 500));
      }

      stats.printStats('Connection Time Statistics');

      expect(stats.count, greaterThan(0), reason: 'At least one connection should succeed');
    });

    test('Connection Time Comparison: V0 vs V1 Signaling', () async {
      skipIfNotConfigured();
      if (config == null) {
        return;
      }

      print('\n=== Connection Time Comparison: V0 vs V1 Signaling ===');
      print('URL: ${config.url}');
      print('Iterations per path: ${config.iterations}');

      final statsV0 = LatencyStats();
      final statsV1 = LatencyStats();

      const roomOptions = RoomOptions(
        adaptiveStream: false,
        dynacast: false,
      );

      // Note: The V0/V1 path selection is automatic based on platform and server support.
      // For mobile/desktop (non-web), it tries V1 first with fallback to V0.
      // For web, it always uses V0.
      //
      // To test both paths explicitly, you would need to modify the SDK or use
      // a test server that supports both paths.

      print('\nTesting default signaling path (auto-selected)...');
      print('Note: On non-web platforms, V1 is tried first with V0 fallback.');

      for (int i = 0; i < config.iterations; i++) {
        final room = Room();

        try {
          final stopwatch = Stopwatch()..start();

          await room.connect(
            config.url,
            config.token,
            roomOptions: roomOptions,
            connectOptions: const ConnectOptions(autoSubscribe: true),
          );

          stopwatch.stop();

          if (room.connectionState == ConnectionState.connected) {
            final latencyMs = stopwatch.elapsedMicroseconds / 1000.0;
            // Check which path was used by examining the signal client
            final singlePcMode = room.engine.signalClient.singlePcMode;
            if (singlePcMode) {
              statsV1.addMeasurement(latencyMs);
              print('  Iteration ${i + 1} [V1]: ${latencyMs.toStringAsFixed(2)} ms');
            } else {
              statsV0.addMeasurement(latencyMs);
              print('  Iteration ${i + 1} [V0]: ${latencyMs.toStringAsFixed(2)} ms');
            }
          } else {
            print('  Iteration ${i + 1}: FAILED - unexpected state: ${room.connectionState}');
          }
        } catch (e) {
          print('  Iteration ${i + 1}: FAILED to connect - $e');
        } finally {
          await room.disconnect();
          await room.dispose();
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (statsV0.count > 0) {
        statsV0.printStats('V0 Signaling Path Statistics');
      }

      if (statsV1.count > 0) {
        statsV1.printStats('V1 Signaling Path Statistics');
      }

      if (statsV0.count > 0 && statsV1.count > 0) {
        print('\n=== Comparison Summary ===');
        print('  V0 Mean: ${statsV0.mean.toStringAsFixed(2)} ms');
        print('  V1 Mean: ${statsV1.mean.toStringAsFixed(2)} ms');
        final diff = statsV0.mean - statsV1.mean;
        final percentDiff = (diff / statsV0.mean * 100).abs();
        if (diff > 0) {
          print('  V1 is ${percentDiff.toStringAsFixed(1)}% faster');
        } else if (diff < 0) {
          print('  V0 is ${percentDiff.toStringAsFixed(1)}% faster');
        } else {
          print('  Both paths have similar latency');
        }
      }

      final totalCount = statsV0.count + statsV1.count;
      expect(totalCount, greaterThan(0), reason: 'At least one connection should succeed');
    });

    test('Connection Time With Fast Publish', () async {
      skipIfNotConfigured();
      if (config == null) {
        return;
      }

      print('\n=== Connection Time With Fast Publish ===');
      print('URL: ${config.url}');
      print('Iterations: ${config.iterations}');

      final statsNormal = LatencyStats();
      final statsFastPublish = LatencyStats();

      // Test without fast publish
      print('\nWithout fast publish:');
      for (int i = 0; i < config.iterations; i++) {
        final room = Room();

        try {
          final stopwatch = Stopwatch()..start();

          await room.connect(
            config.url,
            config.token,
            roomOptions: const RoomOptions(
              adaptiveStream: false,
              dynacast: false,
              fastPublish: false,
            ),
            connectOptions: const ConnectOptions(autoSubscribe: true),
          );

          stopwatch.stop();

          if (room.connectionState == ConnectionState.connected) {
            final latencyMs = stopwatch.elapsedMicroseconds / 1000.0;
            statsNormal.addMeasurement(latencyMs);
            print('  Iteration ${i + 1}: ${latencyMs.toStringAsFixed(2)} ms');
          } else {
            print('  Iteration ${i + 1}: FAILED - unexpected state: ${room.connectionState}');
          }
        } catch (e) {
          print('  Iteration ${i + 1}: FAILED to connect - $e');
        } finally {
          await room.disconnect();
          await room.dispose();
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Test with fast publish
      print('\nWith fast publish:');
      for (int i = 0; i < config.iterations; i++) {
        final room = Room();

        try {
          final stopwatch = Stopwatch()..start();

          await room.connect(
            config.url,
            config.token,
            roomOptions: const RoomOptions(
              adaptiveStream: false,
              dynacast: false,
              fastPublish: true,
            ),
            connectOptions: const ConnectOptions(autoSubscribe: true),
          );

          stopwatch.stop();

          if (room.connectionState == ConnectionState.connected) {
            final latencyMs = stopwatch.elapsedMicroseconds / 1000.0;
            statsFastPublish.addMeasurement(latencyMs);
            print('  Iteration ${i + 1}: ${latencyMs.toStringAsFixed(2)} ms');
          } else {
            print('  Iteration ${i + 1}: FAILED - unexpected state: ${room.connectionState}');
          }
        } catch (e) {
          print('  Iteration ${i + 1}: FAILED to connect - $e');
        } finally {
          await room.disconnect();
          await room.dispose();
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (statsNormal.count > 0) {
        statsNormal.printStats('Normal Connection Statistics');
      }

      if (statsFastPublish.count > 0) {
        statsFastPublish.printStats('Fast Publish Connection Statistics');
      }

      final totalCount = statsNormal.count + statsFastPublish.count;
      expect(totalCount, greaterThan(0), reason: 'At least one connection should succeed');
    });

    test('Reconnection Time Measurement', () async {
      skipIfNotConfigured();
      if (config == null) {
        return;
      }

      print('\n=== Reconnection Time Measurement ===');
      print('URL: ${config.url}');
      print('Iterations: ${config.iterations}');

      final statsInitial = LatencyStats();
      final statsReconnect = LatencyStats();

      for (int i = 0; i < config.iterations; i++) {
        final room = Room();

        try {
          // Measure initial connection
          final stopwatchInitial = Stopwatch()..start();

          await room.connect(
            config.url,
            config.token,
            roomOptions: const RoomOptions(
              adaptiveStream: false,
              dynacast: false,
            ),
            connectOptions: const ConnectOptions(autoSubscribe: true),
          );

          stopwatchInitial.stop();

          if (room.connectionState == ConnectionState.connected) {
            final latencyMs = stopwatchInitial.elapsedMicroseconds / 1000.0;
            statsInitial.addMeasurement(latencyMs);
            print('  Iteration ${i + 1} [Initial]: ${latencyMs.toStringAsFixed(2)} ms');

            // Disconnect and reconnect
            await room.disconnect();
            await Future.delayed(const Duration(milliseconds: 200));

            // Measure reconnection
            final stopwatchReconnect = Stopwatch()..start();

            await room.connect(
              config.url,
              config.token,
              roomOptions: const RoomOptions(
                adaptiveStream: false,
                dynacast: false,
              ),
              connectOptions: const ConnectOptions(autoSubscribe: true),
            );

            stopwatchReconnect.stop();

            if (room.connectionState == ConnectionState.connected) {
              final reconnectLatencyMs = stopwatchReconnect.elapsedMicroseconds / 1000.0;
              statsReconnect.addMeasurement(reconnectLatencyMs);
              print('  Iteration ${i + 1} [Reconnect]: ${reconnectLatencyMs.toStringAsFixed(2)} ms');
            } else {
              print('  Iteration ${i + 1} [Reconnect]: FAILED - unexpected state: ${room.connectionState}');
            }
          } else {
            print('  Iteration ${i + 1} [Initial]: FAILED - unexpected state: ${room.connectionState}');
          }
        } catch (e) {
          print('  Iteration ${i + 1}: FAILED - $e');
        } finally {
          await room.disconnect();
          await room.dispose();
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (statsInitial.count > 0) {
        statsInitial.printStats('Initial Connection Statistics');
      }

      if (statsReconnect.count > 0) {
        statsReconnect.printStats('Reconnection Statistics');
      }

      final totalCount = statsInitial.count + statsReconnect.count;
      expect(totalCount, greaterThan(0), reason: 'At least one connection should succeed');
    });
  });
}
