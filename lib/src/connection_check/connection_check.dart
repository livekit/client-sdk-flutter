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

import '../managers/event.dart';
import '../support/disposable.dart';
import 'checks/checker.dart';
import 'checks/cloud_region.dart';
import 'checks/connection_protocol.dart';
import 'checks/publish_audio.dart';
import 'checks/publish_video.dart';
import 'checks/reconnect.dart';
import 'checks/turn.dart';
import 'checks/webrtc.dart';
import 'checks/websocket.dart';
import 'events.dart';

/// Utility to diagnose connection issues with a LiveKit server, a Dart port
/// of the `ConnectionCheck` helper from client-sdk-js.
///
/// Run it proactively (e.g. at app start) or reactively when connecting to a
/// room fails, to determine why a connection cannot be established (firewall,
/// VPN, blocked TURN, etc.).
///
/// ```dart
/// final connectionCheck = ConnectionCheck(url, token);
/// final listener = connectionCheck.createListener();
/// listener.on<ConnectionCheckUpdateEvent>((event) {
///   print('check ${event.info.name}: ${event.info.status}');
/// });
///
/// // the recommended minimum set of checks
/// await connectionCheck.checkWebsocket();
/// await connectionCheck.checkWebRTC();
/// await connectionCheck.checkTURN();
///
/// print('all checks passed: ${connectionCheck.isSuccess}');
/// await listener.dispose();
/// await connectionCheck.dispose();
/// ```
///
/// Each check connects to the server independently and returns a [CheckInfo]
/// describing the outcome. [checkPublishAudio], [checkPublishVideo] and
/// [checkConnectionProtocol] capture from the microphone/camera and therefore
/// require the corresponding permissions to be granted beforehand.
class ConnectionCheck extends Disposable with EventsEmittable<ConnectionCheckEvent> {
  ConnectionCheck(
    this.url,
    this.token, {
    CheckerOptions? options,
  }) : options = options ?? CheckerOptions() {
    onDispose(() async {
      await events.dispose();
    });
  }

  /// URL of the LiveKit server to run the checks against.
  final String url;

  /// Access token used for the checks.
  final String token;

  /// Options shared by all checks of this run.
  final CheckerOptions options;

  final Map<int, CheckInfo> _checkResults = {};

  /// True when no check has failed (so far).
  bool get isSuccess => _checkResults.values.every((r) => r.status != CheckStatus.failed);

  /// Results of all checks that have been run (or are running).
  List<CheckInfo> getResults() => List.unmodifiable(_checkResults.values);

  int _getNextCheckId() {
    final nextId = _checkResults.length;
    _checkResults[nextId] = const CheckInfo(
      name: '',
      description: '',
      status: CheckStatus.idle,
      logs: [],
    );
    return nextId;
  }

  void _updateCheck(int checkId, CheckInfo info) {
    _checkResults[checkId] = info;
    events.emit(ConnectionCheckUpdateEvent(checkId: checkId, info: info));
  }

  /// Runs a single [Checker], reporting its progress through
  /// [ConnectionCheckUpdateEvent]s, and disposes it when done.
  ///
  /// Used by all `check*` methods; can also be used to run a custom
  /// [Checker] subclass as part of this run.
  Future<CheckInfo> runCheck(Checker check) async {
    if (check.status != CheckStatus.idle) {
      throw StateError('check is running already');
    }
    final checkId = _getNextCheckId();
    final listener = check.createListener();
    listener.on<CheckerUpdateEvent>((event) => _updateCheck(checkId, event.info));
    try {
      return await check.run();
    } finally {
      _updateCheck(checkId, check.getInfo());
      await listener.dispose();
      await check.dispose();
    }
  }

  /// Verifies that a WebSocket connection to the server can be established.
  Future<CheckInfo> checkWebsocket() => runCheck(WebSocketCheck(url, token, options: options));

  /// Verifies that a WebRTC (peer) connection can be established.
  Future<CheckInfo> checkWebRTC() => runCheck(WebRTCCheck(url, token, options: options));

  /// Verifies that a connection via a TURN relay can be established.
  Future<CheckInfo> checkTURN() => runCheck(TURNCheck(url, token, options: options));

  /// Verifies that a connection can be resumed after an interruption.
  Future<CheckInfo> checkReconnect() => runCheck(ReconnectCheck(url, token, options: options));

  /// Verifies that microphone audio can be captured and published.
  Future<CheckInfo> checkPublishAudio() => runCheck(PublishAudioCheck(url, token, options: options));

  /// Verifies that camera video can be captured and published.
  Future<CheckInfo> checkPublishVideo() => runCheck(PublishVideoCheck(url, token, options: options));

  /// Compares connection quality between UDP and TCP.
  ///
  /// The better protocol is stored in [CheckerOptions.protocol] so that
  /// subsequent checks (e.g. [checkCloudRegion]) use it. The returned
  /// [CheckInfo.data] contains the winning [ProtocolStats].
  Future<CheckInfo> checkConnectionProtocol() async {
    final info = await runCheck(ConnectionProtocolCheck(url, token, options: options));
    final data = info.data;
    if (data is ProtocolStats) {
      options.protocol = data.protocol;
    }
    return info;
  }

  /// Checks connection quality to the closest LiveKit Cloud regions and
  /// determines the best one. Skipped for non-Cloud servers. The returned
  /// [CheckInfo.data] contains the best region's [RegionStats].
  Future<CheckInfo> checkCloudRegion() => runCheck(CloudRegionCheck(url, token, options: options));
}
