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

/// Connection Latency Measurement Integration Test
///
/// Run from the example directory:
///   cd example
///   flutter test integration_test/connection_latency_test.dart -d <device_id>

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:logging/logging.dart';

// ============================================================================
// CONFIGURATION - EDIT THESE VALUES
// ============================================================================

class TestConfig {
  // TODO: Replace with your LiveKit server URL
  static const String url = 'wss://xianstaging-hixkk74p.staging.livekit.cloud';

  // Caller participant config (used by existing tests)
  static const String callerIdentity = 'sxian';
  static const String callerToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NzYzMjcyMDQsImlkZW50aXR5Ijoic3hpYW4iLCJpc3MiOiJBUElHejJLUXU0UGJ6YkEiLCJuYW1lIjoic3hpYW4iLCJuYmYiOjE3NzAzMjcyMDQsInN1YiI6InN4aWFuIiwidmlkZW8iOnsicm9vbSI6ImNwcCIsInJvb21Kb2luIjp0cnVlfX0.oI0DCLyCMK-y6yxyQ3cFPArGJa03XHeeUrC_t2LUCgU';

  // Receiver participant config (required by RPC latency test)
  // TODO: Replace with a second token whose identity matches receiverIdentity.
  static const String receiverIdentity = 'receiver';
  static const String receiverToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NzYzMjcyMTgsImlkZW50aXR5IjoidGVzdCIsImlzcyI6IkFQSUd6MktRdTRQYnpiQSIsIm5hbWUiOiJ0ZXN0IiwibmJmIjoxNzcwMzI3MjE4LCJzdWIiOiJ0ZXN0IiwidmlkZW8iOnsicm9vbSI6ImNwcCIsInJvb21Kb2luIjp0cnVlfX0.xWNZ4Hz1AmXblr8V1GWPm9fcbhuj_f9C5qa0sJxdTFA';

  // Backward-compatible alias for existing tests in this file.
  static const String token = callerToken;

  // Number of iterations for the test
  static const int iterations = 5;

  // Check if configured
  static bool get isConfigured =>
      url.isNotEmpty &&
      token != 'YOUR_TOKEN_HERE' &&
      token.isNotEmpty;

  static bool get isRpcConfigured =>
      isConfigured &&
      receiverToken != 'RECEIVER_TOKEN_HERE' &&
      receiverToken.isNotEmpty;
}

void _enableLiveKitLogs() {
  hierarchicalLoggingEnabled = true;
  setLoggingLevel(LoggerLevel.kOFF);
}

Future<void> _waitForRemoteParticipantByIdentity(
  Room room,
  String identity, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    final participant = room.getParticipantByIdentity(identity);
    if (participant is RemoteParticipant) return;
    await Future.delayed(const Duration(milliseconds: 50));
  }
  throw TimeoutException('Timed out waiting for remote participant identity=$identity');
}

Future<void> _safeDisconnectAndDispose(Room room, String label) async {
  try {
    await room.disconnect();
  } catch (e) {
    print('  [$label] disconnect warning: $e');
  }

  try {
    await room.dispose();
  } catch (e) {
    print('  [$label] dispose warning: $e');
  }
}

// ============================================================================
// LATENCY STATISTICS
// ============================================================================

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

  void printStats() {
    print('\n$name');
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

// ============================================================================
// TESTS
// ============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  _enableLiveKitLogs();

  group('Connection Latency Tests', () {
    testWidgets('Connection Time Measurement', (tester) async {
      if (!TestConfig.isConfigured) {
        print('\n*** TEST NOT CONFIGURED ***');
        print('Edit TestConfig in this file with your LiveKit credentials:');
        print('  - url: Your LiveKit server URL');
        print('  - token: A valid access token');
        return;
      }

      print('\n=== Connection Time Measurement ===');
      print('URL: ${TestConfig.url}');
      print('Iterations: ${TestConfig.iterations}');

      final stats = LatencyStats(name: 'Connection Time');

      for (int i = 0; i < TestConfig.iterations; i++) {
        final room = Room(
          roomOptions: const RoomOptions(
            adaptiveStream: false,
            dynacast: false,
          ),
        );

        try {
          final stopwatch = Stopwatch()..start();

          await room.connect(
            TestConfig.url,
            TestConfig.token,
            connectOptions: const ConnectOptions(autoSubscribe: true),
          );

          stopwatch.stop();

          if (room.connectionState == ConnectionState.connected) {
            final latencyMs = stopwatch.elapsedMicroseconds / 1000.0;
            stats.addMeasurement(latencyMs);

            final pathInfo = room.engine.signalClient.singlePcMode ? '[V1]' : '[V0]';
            print('  Iteration ${i + 1}: ${latencyMs.toStringAsFixed(2)} ms $pathInfo');
          } else {
            print('  Iteration ${i + 1}: FAILED - state: ${room.connectionState}');
          }
        } catch (e) {
          print('  Iteration ${i + 1}: FAILED - $e');
        } finally {
          await room.disconnect();
          await room.dispose();
        }

        // Delay between iterations
        await Future.delayed(const Duration(milliseconds: 500));
      }

      stats.printStats();

      expect(stats.count, greaterThan(0), reason: 'At least one connection should succeed');
    });

    testWidgets('Single PC Mode Comparison (V0 vs V1)', (tester) async {
      if (!TestConfig.isConfigured) {
        print('\n*** TEST NOT CONFIGURED ***');
        return;
      }

      print('\n=== Single PC Mode Comparison (V0 vs V1) ===');
      print('URL: ${TestConfig.url}');

      final statsV0 = LatencyStats(name: 'V0 (Legacy Dual PC)');
      final statsV1 = LatencyStats(name: 'V1 (Single PC)');

      // Test V0 (legacy dual PeerConnection mode)
      print('\nV0 - Legacy Dual PeerConnection (singlePeerConnection: false):');
      for (int i = 0; i < TestConfig.iterations; i++) {
        final room = Room(
          roomOptions: const RoomOptions(
            adaptiveStream: false,
            dynacast: false,
          ),
        );

        try {
          final stopwatch = Stopwatch()..start();
          await room.connect(
            TestConfig.url,
            TestConfig.token,
            connectOptions: const ConnectOptions(
              autoSubscribe: true,
              singlePeerConnection: false,  // Force V0 path
            ),
          );
          stopwatch.stop();

          if (room.connectionState == ConnectionState.connected) {
            final latencyMs = stopwatch.elapsedMicroseconds / 1000.0;
            statsV0.addMeasurement(latencyMs);
            final mode = room.engine.signalClient.singlePcMode ? 'V1' : 'V0';
            print('  Iteration ${i + 1}: ${latencyMs.toStringAsFixed(2)} ms [$mode]');
          }
        } catch (e) {
          print('  Iteration ${i + 1}: FAILED - $e');
        } finally {
          await room.disconnect();
          await room.dispose();
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Test V1 (single PeerConnection mode)
      print('\nV1 - Single PeerConnection (singlePeerConnection: true):');
      for (int i = 0; i < TestConfig.iterations; i++) {
        final room = Room(
          roomOptions: const RoomOptions(
            adaptiveStream: false,
            dynacast: false,
          ),
        );

        try {
          final stopwatch = Stopwatch()..start();
          await room.connect(
            TestConfig.url,
            TestConfig.token,
            connectOptions: const ConnectOptions(
              autoSubscribe: true,
              singlePeerConnection: true,  // Enable V1 path (default)
            ),
          );
          stopwatch.stop();

          if (room.connectionState == ConnectionState.connected) {
            final latencyMs = stopwatch.elapsedMicroseconds / 1000.0;
            statsV1.addMeasurement(latencyMs);
            final mode = room.engine.signalClient.singlePcMode ? 'V1' : 'V0';
            print('  Iteration ${i + 1}: ${latencyMs.toStringAsFixed(2)} ms [$mode]');
          }
        } catch (e) {
          print('  Iteration ${i + 1}: FAILED - $e');
        } finally {
          await room.disconnect();
          await room.dispose();
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }

      statsV0.printStats();
      statsV1.printStats();

      // Print comparison
      if (statsV0.count > 0 && statsV1.count > 0) {
        print('\n=== Comparison ===');
        final diff = statsV0.mean - statsV1.mean;
        print('V0 (Legacy):    ${statsV0.mean.toStringAsFixed(2)} ms avg');
        print('V1 (Single PC): ${statsV1.mean.toStringAsFixed(2)} ms avg');
        if (diff > 0) {
          print('V1 is ${diff.toStringAsFixed(2)} ms faster (${(diff / statsV0.mean * 100).toStringAsFixed(1)}% improvement)');
        } else if (diff < 0) {
          print('V0 is ${(-diff).toStringAsFixed(2)} ms faster');
        } else {
          print('Both modes have similar latency');
        }
      }

      final totalCount = statsV0.count + statsV1.count;
      expect(totalCount, greaterThan(0), reason: 'At least one connection should succeed');
    });

    testWidgets('RPC Latency Right After Connect (V0 vs V1, two participants)', (tester) async {
      if (!TestConfig.isRpcConfigured) {
        print('\n*** RPC TEST NOT CONFIGURED ***');
        print('Set TestConfig.receiverToken and ensure it matches TestConfig.receiverIdentity.');
        print('callerIdentity: ${TestConfig.callerIdentity}');
        print('receiverIdentity: ${TestConfig.receiverIdentity}');
        return;
      }

      print('\n=== RPC Latency Right After Connect (V0 vs V1) ===');
      print('URL: ${TestConfig.url}');
      print('Iterations: ${TestConfig.iterations}');
      print('Caller identity: ${TestConfig.callerIdentity}');
      print('Receiver identity: ${TestConfig.receiverIdentity}');

      final statsV0 = LatencyStats(name: 'RPC Latency V0 (dual PC)');
      final statsV1 = LatencyStats(name: 'RPC Latency V1 (single PC)');
      final errors = <String>[];

      Future<void> runMode({
        required bool singlePeerConnection,
        required LatencyStats stats,
        required String label,
      }) async {
        print('\n$label (singlePeerConnection: $singlePeerConnection):');

        for (int i = 0; i < TestConfig.iterations; i++) {
          final receiverRoom = Room(
            roomOptions: const RoomOptions(adaptiveStream: false, dynacast: false),
          );
          final callerRoom = Room(
            roomOptions: const RoomOptions(adaptiveStream: false, dynacast: false),
          );

          receiverRoom.registerRpcMethod('latency_echo', (data) async => data.payload);

          try {
            final connectOptions = ConnectOptions(
              autoSubscribe: true,
              singlePeerConnection: singlePeerConnection,
            );

            await receiverRoom.connect(
              TestConfig.url,
              TestConfig.receiverToken,
              connectOptions: connectOptions,
            );
            final connectedReceiverIdentity = receiverRoom.localParticipant?.identity;
            if (connectedReceiverIdentity == null || connectedReceiverIdentity.isEmpty) {
              throw Exception('Receiver room connected without a valid local participant identity');
            }

            await callerRoom.connect(
              TestConfig.url,
              TestConfig.callerToken,
              connectOptions: connectOptions,
            );

            await _waitForRemoteParticipantByIdentity(callerRoom, connectedReceiverIdentity);

            final stopwatch = Stopwatch()..start();
            final payload = 'ping-$i-${DateTime.now().microsecondsSinceEpoch}';
            final response = await callerRoom.localParticipant!.performRpc(
              PerformRpcParams(
                destinationIdentity: connectedReceiverIdentity,
                method: 'latency_echo',
                payload: payload,
                responseTimeoutMs: const Duration(seconds: 10),
              ),
            );
            stopwatch.stop();

            if (response != payload) {
              throw Exception('Unexpected RPC response payload: $response');
            }

            final latencyMs = stopwatch.elapsedMicroseconds / 1000.0;
            stats.addMeasurement(latencyMs);

            final callerMode = callerRoom.engine.signalClient.singlePcMode ? 'V1' : 'V0';
            final receiverMode = receiverRoom.engine.signalClient.singlePcMode ? 'V1' : 'V0';
            print(
              '  Iteration ${i + 1}: ${latencyMs.toStringAsFixed(2)} ms '
              '[caller:$callerMode receiver:$receiverMode]'
              ' [dest:$connectedReceiverIdentity]',
            );
          } catch (e) {
            final errorText = e is RpcError ? 'RpcError(code=${e.code}, message=${e.message})' : e.toString();
            errors.add('$label iteration ${i + 1}: $errorText');
            print('  Iteration ${i + 1}: FAILED - $errorText');
          } finally {
            await _safeDisconnectAndDispose(callerRoom, 'caller');
            await _safeDisconnectAndDispose(receiverRoom, 'receiver');
          }

          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      await runMode(
        singlePeerConnection: false,
        stats: statsV0,
        label: 'V0 - Legacy Dual PeerConnection',
      );
      await runMode(
        singlePeerConnection: true,
        stats: statsV1,
        label: 'V1 - Single PeerConnection',
      );

      statsV0.printStats();
      statsV1.printStats();

      if (statsV0.count > 0 && statsV1.count > 0) {
        print('\n=== RPC Latency Comparison ===');
        final diff = statsV0.mean - statsV1.mean;
        print('V0 (Legacy):    ${statsV0.mean.toStringAsFixed(2)} ms avg');
        print('V1 (Single PC): ${statsV1.mean.toStringAsFixed(2)} ms avg');
        if (diff > 0) {
          print('V1 is ${diff.toStringAsFixed(2)} ms faster (${(diff / statsV0.mean * 100).toStringAsFixed(1)}% improvement)');
        } else if (diff < 0) {
          print('V0 is ${(-diff).toStringAsFixed(2)} ms faster');
        } else {
          print('Both modes have similar RPC latency');
        }
      }

      final totalCount = statsV0.count + statsV1.count;
      if (totalCount == 0 && errors.isNotEmpty) {
        print('\nRPC failures:');
        for (final err in errors) {
          print('  - $err');
        }
      }
      expect(totalCount, greaterThan(0), reason: 'At least one RPC call should succeed');
    });
  });
}
