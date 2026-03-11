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

/// Connection Latency Test - Device Runnable
///
/// This file provides a reusable latency measurement utility that can be
/// run on physical devices where environment variables aren't available.
///
/// Usage:
/// 1. Import this file in your test app
/// 2. Call runLatencyTest() with your credentials
/// 3. Results are printed and returned
///
/// Example:
/// ```dart
/// import 'package:example/latency_test.dart';
///
/// void main() async {
///   await runLatencyTest(
///     url: 'wss://your-server.livekit.cloud',
///     token: 'your_token',
///     iterations: 10,
///   );
/// }
/// ```
library latency_test;

import 'dart:math' as math;

import 'package:flutter/widgets.dart' hide ConnectionState;
import 'package:livekit_client/livekit_client.dart';

/// Statistics calculator for latency measurements
class LatencyStats {
  final List<double> _measurements = [];
  final String name;

  LatencyStats({this.name = 'Latency'});

  void addMeasurement(double latencyMs) {
    _measurements.add(latencyMs);
  }

  int get count => _measurements.length;
  bool get isEmpty => _measurements.isEmpty;

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

  String getStatsString() {
    final buffer = StringBuffer();
    buffer.writeln(name);
    buffer.writeln('Samples:      $count');
    buffer.writeln('Min:          ${min.toStringAsFixed(2)} ms');
    buffer.writeln('Avg:          ${mean.toStringAsFixed(2)} ms');
    buffer.writeln('P50:          ${p50.toStringAsFixed(2)} ms');
    buffer.writeln('P95:          ${p95.toStringAsFixed(2)} ms');
    buffer.writeln('P99:          ${p99.toStringAsFixed(2)} ms');
    buffer.writeln('Max:          ${max.toStringAsFixed(2)} ms');
    return buffer.toString();
  }

  void printStats() {
    print(getStatsString());
  }

  void clear() {
    _measurements.clear();
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'samples': count,
        'min': min,
        'avg': mean,
        'p50': p50,
        'p95': p95,
        'p99': p99,
        'max': max,
        'measurements': _measurements,
      };
}

/// Result of a latency test run
class LatencyTestResult {
  final LatencyStats stats;
  final int successCount;
  final int failureCount;
  final List<String> errors;
  final bool usedV1Path;

  LatencyTestResult({
    required this.stats,
    required this.successCount,
    required this.failureCount,
    required this.errors,
    required this.usedV1Path,
  });

  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('=== Latency Test Results ===');
    buffer.writeln('Signaling Path: ${usedV1Path ? 'V1 (Single PC)' : 'V0 (Legacy)'}');
    buffer.writeln('Success: $successCount, Failed: $failureCount');
    buffer.writeln();
    buffer.write(stats.getStatsString());
    if (errors.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Errors:');
      for (final error in errors) {
        buffer.writeln('  - $error');
      }
    }
    return buffer.toString();
  }
}

/// Callback for progress updates during the test
typedef LatencyTestProgressCallback = void Function(
  int iteration,
  int total,
  double? latencyMs,
  String? error,
);

/// Run a connection latency test
///
/// [url] - LiveKit server URL (e.g., 'wss://your-server.livekit.cloud')
/// [token] - Valid LiveKit access token
/// [iterations] - Number of test iterations (default: 5)
/// [delayBetweenIterations] - Delay between iterations for cleanup (default: 500ms)
/// [roomOptions] - Custom room options (optional)
/// [connectOptions] - Custom connect options (optional)
/// [onProgress] - Callback for progress updates (optional)
Future<LatencyTestResult> runLatencyTest({
  required String url,
  required String token,
  int iterations = 5,
  Duration delayBetweenIterations = const Duration(milliseconds: 500),
  RoomOptions roomOptions = const RoomOptions(
    adaptiveStream: false,
    dynacast: false,
  ),
  ConnectOptions connectOptions = const ConnectOptions(
    autoSubscribe: true,
  ),
  LatencyTestProgressCallback? onProgress,
}) async {
  print('\n=== Connection Latency Test ===');
  print('URL: $url');
  print('Iterations: $iterations');
  print('');

  final stats = LatencyStats(name: 'Connection Time');
  final errors = <String>[];
  int successCount = 0;
  int failureCount = 0;
  bool? usedV1Path;

  for (int i = 0; i < iterations; i++) {
    // Pass roomOptions to Room constructor (not to connect)
    final room = Room(roomOptions: roomOptions);

    try {
      final stopwatch = Stopwatch()..start();

      await room.connect(
        url,
        token,
        connectOptions: connectOptions,
      );

      stopwatch.stop();

      if (room.connectionState == ConnectionState.connected) {
        final latencyMs = stopwatch.elapsedMicroseconds / 1000.0;
        stats.addMeasurement(latencyMs);
        successCount++;

        // Detect which signaling path was used
        usedV1Path ??= room.engine.signalClient.singlePcMode;

        final pathInfo = room.engine.signalClient.singlePcMode ? '[V1]' : '[V0]';
        print('  Iteration ${i + 1}: ${latencyMs.toStringAsFixed(2)} ms $pathInfo');

        onProgress?.call(i + 1, iterations, latencyMs, null);
      } else {
        final error = 'Unexpected state: ${room.connectionState}';
        print('  Iteration ${i + 1}: FAILED - $error');
        errors.add('Iteration ${i + 1}: $error');
        failureCount++;

        onProgress?.call(i + 1, iterations, null, error);
      }
    } catch (e) {
      final error = e.toString();
      print('  Iteration ${i + 1}: FAILED - $error');
      errors.add('Iteration ${i + 1}: $error');
      failureCount++;

      onProgress?.call(i + 1, iterations, null, error);
    } finally {
      await room.disconnect();
      await room.dispose();
    }

    // Delay between iterations
    if (i < iterations - 1) {
      await Future.delayed(delayBetweenIterations);
    }
  }

  print('');
  stats.printStats();

  return LatencyTestResult(
    stats: stats,
    successCount: successCount,
    failureCount: failureCount,
    errors: errors,
    usedV1Path: usedV1Path ?? false,
  );
}

/// Run a comparison test between different configurations
Future<Map<String, LatencyTestResult>> runLatencyComparison({
  required String url,
  required String token,
  int iterations = 5,
  Duration delayBetweenIterations = const Duration(milliseconds: 500),
  LatencyTestProgressCallback? onProgress,
}) async {
  final results = <String, LatencyTestResult>{};

  // Test with fast publish disabled
  print('\n=== Testing WITHOUT Fast Publish ===');
  results['no_fast_publish'] = await runLatencyTest(
    url: url,
    token: token,
    iterations: iterations,
    delayBetweenIterations: delayBetweenIterations,
    roomOptions: const RoomOptions(
      adaptiveStream: false,
      dynacast: false,
      fastPublish: false,
    ),
    connectOptions: const ConnectOptions(autoSubscribe: true),
    onProgress: onProgress,
  );

  // Test with fast publish enabled
  print('\n=== Testing WITH Fast Publish ===');
  results['fast_publish'] = await runLatencyTest(
    url: url,
    token: token,
    iterations: iterations,
    delayBetweenIterations: delayBetweenIterations,
    roomOptions: const RoomOptions(
      adaptiveStream: false,
      dynacast: false,
      fastPublish: true,
    ),
    connectOptions: const ConnectOptions(autoSubscribe: true),
    onProgress: onProgress,
  );

  // Print comparison
  print('\n=== Comparison Summary ===');
  final noFp = results['no_fast_publish']!;
  final fp = results['fast_publish']!;

  if (noFp.stats.count > 0 && fp.stats.count > 0) {
    print('Without Fast Publish: Avg ${noFp.stats.mean.toStringAsFixed(2)} ms');
    print('With Fast Publish:    Avg ${fp.stats.mean.toStringAsFixed(2)} ms');

    final diff = noFp.stats.mean - fp.stats.mean;
    if (diff > 0) {
      print('Fast Publish is ${diff.toStringAsFixed(2)} ms faster (${(diff / noFp.stats.mean * 100).toStringAsFixed(1)}%)');
    } else if (diff < 0) {
      print('No Fast Publish is ${(-diff).toStringAsFixed(2)} ms faster');
    }
  }

  return results;
}

// ============================================================================
// CONFIGURATION - EDIT THESE VALUES FOR DEVICE TESTING
// ============================================================================

/// Default test configuration for device testing.
/// Edit these values or override them when calling the test functions.
class LatencyTestConfig {
  // TODO: Replace with your LiveKit server URL
  static const String url = 'wss://your-server.livekit.cloud';

  // TODO: Replace with a valid token
  // You can generate a token using:
  // - LiveKit CLI: livekit-cli create-token --api-key <key> --api-secret <secret> --join --room test --identity user
  // - LiveKit Cloud dashboard
  // - Your backend server
  static const String token = 'your_token_here';

  // Number of iterations for the test
  static const int iterations = 5;

  // Whether the config is set up (check before running)
  static bool get isConfigured =>
      url != 'wss://your-server.livekit.cloud' && token != 'your_token_here' && token.isNotEmpty;
}

// ============================================================================
// MAIN - Uncomment to run as standalone script
// ============================================================================

/// Standalone entry point for running latency tests on device.
///
/// To use:
/// 1. Edit LatencyTestConfig above with your credentials
/// 2. Run: flutter run -t lib/latency_test.dart
///
/// Or import this file and call runLatencyTest() directly.
void main() async {
  // Initialize Flutter binding for platform channels
  WidgetsFlutterBinding.ensureInitialized();

  print('LiveKit Connection Latency Test');
  print('================================\n');

  if (!LatencyTestConfig.isConfigured) {
    print('ERROR: Test not configured!');
    print('');
    print('Please edit LatencyTestConfig in this file:');
    print('  - Set url to your LiveKit server URL');
    print('  - Set token to a valid access token');
    print('');
    print('Example:');
    print('  static const String url = \'wss://my-app.livekit.cloud\';');
    print('  static const String token = \'eyJhbGciOiJIUzI1NiIs...\';');
    return;
  }

  // Run the latency test
  final result = await runLatencyTest(
    url: LatencyTestConfig.url,
    token: LatencyTestConfig.token,
    iterations: LatencyTestConfig.iterations,
  );

  print('\n');
  print(result);

  // Optionally run comparison test
  // final comparison = await runLatencyComparison(
  //   url: LatencyTestConfig.url,
  //   token: LatencyTestConfig.token,
  //   iterations: LatencyTestConfig.iterations,
  // );
}
