import 'platform/io.dart' if (dart.library.html) 'platform/web.dart';

// Returns the current platform which works for both web and devices.
PlatformType lkPlatform() => lkPlatformImplementation();
bool lkPlatformIs(PlatformType type) => lkPlatform() == type;

enum PlatformType {
  web,
  windows,
  linux,
  macOS,
  android,
  fuchsia,
  iOS,
}
