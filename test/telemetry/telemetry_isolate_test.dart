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

/// The core outlives the isolate that installed its pipeline (hot restart, a recreated engine):
/// it must hold nothing that calls back into a dead isolate. Its own process: the opt-out is
/// process-wide.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/telemetry/telemetry_io.dart' show storageDirectory;
import 'package:livekit_client/src/uniffi/uniffi_io.dart' as ffi;

void main() {
  test('pipelines installed by isolates that are gone are replaced and disabled safely', () async {
    // Hot restart twice: each isolate installs the pipeline (replacing its predecessor's), gives it
    // a destination and records to ship, sends the app to the background (which uploads them), and
    // dies before serving the request.
    for (var i = 0; i < 2; i++) {
      if (!await Isolate.run(_installAndQueue)) {
        markTestSkipped('no native library');
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500)); // the request is queued
    }
    // Their successor opts out before its first Room. The core stops the installed pipeline's
    // instruments on replace and on opt-out, and withdraws the queued requests: an instrument or a
    // pending Rust future it held would call into a dead isolate and abort the VM.
    final leftover = File('${storageDirectory!}/leftover')..createSync(recursive: true);
    final purged = LiveKitClient.disableTelemetry();
    expect(Room().telemetry, isNull, reason: 'in effect at once');
    await purged;
    expect(leftover.existsSync(), isFalse, reason: 'the cache is deleted before any Room installed');
  });
}

bool _installAndQueue() {
  if (Room().telemetry == null) return false;
  // A Cloud project and a token with the observability grant (claims only: the core reads, the
  // server would verify). Nothing is sent: the isolate is gone before its first poll.
  final scope = ffi.telemetryScope()!..setServer(url: 'wss://isolate-probe.livekit.cloud', token: _grantedToken());
  for (var i = 0; i < 5; i++) {
    scope.emitCustom(name: 'isolate.probe', attributes: {'i': '$i'});
  }
  // Going to the background uploads the whole cache; no Rust future is left waiting on this isolate.
  ffi.telemetrySetDeviceState(
    state: ffi.DeviceState(
      thermal: ffi.ThermalState.unknown,
      appState: ffi.AppState.background,
      memory: ffi.MemoryPressure.normal,
      network: ffi.NetworkType.wifi,
    ),
  );
  return true;
}

String _grantedToken() {
  String part(Object json) => base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final exp = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
  return '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part({
    'exp': exp,
    'observability': {'write': true},
  })}.signature';
}
