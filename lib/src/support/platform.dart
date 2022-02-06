import 'dart:io';

import 'package:meta/meta.dart';

import 'platform/io.dart' if (dart.library.html) 'platform/web.dart';

// Returns the current platform which works for both web and devices.
PlatformType lkPlatform() => lkPlatformImplementation();

bool lkPlatformIs(PlatformType type) => lkPlatform() == type;

@internal
bool lkPlatformIsTest() => Platform.environment.containsKey('FLUTTER_TEST');

enum PlatformType {
  web,
  windows,
  linux,
  macOS,
  android,
  fuchsia,
  iOS,
}
