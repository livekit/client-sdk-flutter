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

@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/src/uniffi/uniffi_io.dart' as ffi;

/// Records the calls the core makes into a Dart instrument.
class _SpyInstrument implements ffi.TelemetryInstrument {
  final calls = <String>[];

  @override
  void start() => calls.add('start');

  @override
  void stop() => calls.add('stop');
}

/// Answers every export with 200 so shutdown drains quickly; ends when
/// `finish()` lets `next()` resolve null, like the SDK's `_serve`.
Future<void> _serve(ffi.TelemetryExportQueue queue) async {
  while (true) {
    final pending = await queue.next();
    if (pending == null) return;
    queue.complete(
      id: pending.id,
      response: ffi.ExportResponse(status: 200, headers: {}, body: Uint8List(0)),
    );
  }
}

void main() {
  // uniffi-dart callbacks are isolate-bound: the core may only invoke an
  // instrument synchronously from the Dart thread that configures or shuts the
  // pipeline down. This is what makes Dart instruments possible at all.
  test('instruments are started on configure and stopped on shutdown, on the Dart thread', () async {
    final spy = _SpyInstrument();
    final queue = ffi.telemetryConfigurePulled(
      config: ffi.TelemetryConfig(endpoint: 'http://127.0.0.1:1/v1/logs', headers: {}, logSeverity: ffi.Severity.warn),
      instruments: [spy],
    );
    final serving = _serve(queue);
    expect(spy.calls, ['start'], reason: 'started synchronously inside telemetryConfigurePulled');
    expect(ffi.telemetryScope(), isNotNull);

    await ffi.telemetryShutdown();
    expect(spy.calls, ['start', 'stop'], reason: 'stopped synchronously inside telemetryShutdown');
    expect(ffi.telemetryScope(), isNull);

    queue.finish();
    await serving.timeout(const Duration(seconds: 5));
  });
}
