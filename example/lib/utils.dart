// The Rust core facade is experimental, the example is its smoke test.
// ignore_for_file: experimental_member_use

import 'dart:async';
import 'package:livekit_client/livekit_client.dart';

FutureOr<void> Function()? onWindowShouldClose;

/// One synchronous call into the Rust core through the uniffi facade. The
/// example shows the result at startup and on the connect page as a smoke
/// test that the native library was bundled and loads on this platform.
String rustCoreVersionLabel() {
  if (!LiveKitUniffi.isAvailable) {
    return 'Rust core not available on this platform';
  }
  try {
    return 'Rust core ${LiveKitUniffi.buildVersion}';
  } catch (error) {
    return 'Rust core failed to load: $error';
  }
}
